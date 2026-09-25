const router = require("express").Router();
const axios = require("axios");
const crypto = require("crypto");

// ─── Supabase Admin client (service role — backend only) ───────────────────
const supabaseAdmin = require("../config/supabase");

// ─── OTP store (MongoDB) ────────────────────────────────────────────────────
const Otp = require("../models/Otp");

// ─── Helpers ────────────────────────────────────────────────────────────────
const fmtPhone = (p) => (p.startsWith("+91") ? p : "+91" + p.replace(/\s+/g, ""));

// Fast2SMS wants the plain 10-digit Indian mobile (no +91, no spaces).
const fast2smsNumber = (fmt) => fmt.replace("+91", "").replace(/\D/g, "").slice(-10);

// SECURITY: USER_SALT has NO fallback — index.js refuses to boot without it.
const USER_SALT = process.env.USER_SALT;

const phoneToPassword = (phone) =>
  crypto.createHmac("sha256", USER_SALT).update(phone).digest("hex");

const phoneToEmail = (phone) => phone.replace("+", "") + "@namasteindia.app";

// ─── Input validation ───────────────────────────────────────────────────────
const PHONE_RE = /^\+?\d[\d\s-]{6,16}$/;   // digits, optional +, spaces/dashes
const OTP_RE   = /^\d{4,8}$/;              // numeric OTP only
const ROLES    = ["customer", "driver", "admin"];

const validPhone = (p) => typeof p === "string" && PHONE_RE.test(p.trim());

// ─── MOCK OTP (set MOCK_OTP=true in .env for testing without SMS) ───────────
const MOCK_OTP_ENABLED = process.env.MOCK_OTP === "true";
const MOCK_OTP_CODE    = process.env.MOCK_OTP_CODE || "123456";

// ─── Fast2SMS (OTP SMS without DLT registration) ───────────────────────────
// POST https://www.fast2sms.com/dev/bulkV2
//   Headers: { authorization: FAST2SMS_API_KEY, Content-Type: application/json }
//   Body:    { route: "otp", variables_values: "<otp>", numbers: "<10-digit>" }
// The "otp" route delivers through Fast2SMS's own DLT-registered template as
// "Your OTP: <code>" — no DLT registration needed on our side.
// Response: { return: true, request_id: "..." } on success.
//
// NOTE: MSG91's classic OTP API was tried first but cannot deliver SMS in
// India without a DLT-registered template_id (API returns "success" while the
// SMS is silently blocked). The Flutter app's contract is unchanged.
const FAST2SMS_API_KEY = process.env.FAST2SMS_API_KEY;

const OTP_TTL_MS   = 5 * 60 * 1000;  // OTP valid 5 minutes
const OTP_MAX_ATTEMPTS = 5;          // >5 wrong tries invalidates the OTP

const sha256 = (s) => crypto.createHash("sha256").update(s).digest("hex");

// SECURITY: crypto.randomInt, never Math.random. 6 digits to match app UI.
const generateOtp = () => String(crypto.randomInt(100000, 1000000));

async function sendSmsViaFast2Sms(number10, otp) {
  const { status, data } = await axios.post(
    "https://www.fast2sms.com/dev/bulkV2",
    { route: "otp", variables_values: otp, numbers: number10 },
    {
      headers: {
        authorization: FAST2SMS_API_KEY,
        "Content-Type": "application/json",
      },
      timeout: 30000,
    }
  );
  console.log("Fast2SMS response:", JSON.stringify(data));
  if (status !== 200 || !data || data.return !== true) {
    throw new Error(data?.message || "Fast2SMS rejected the request");
  }
  return data.request_id || null;
}

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/auth/send-otp
// Body: { phone: "9876543210" }
// Returns: { success, message, reqId } — reqId must be sent back to verify-otp
// ─────────────────────────────────────────────────────────────────────────────
router.post("/send-otp", async (req, res) => {
  try {
    const { phone } = req.body;
    if (!validPhone(phone))
      return res.status(400).json({ success: false, message: "Valid phone number is required" });

    const fmt = fmtPhone(phone.trim());

    // ── MOCK mode: generate REAL random OTP, skip SMS, return it in response ──
    // User requirement: mock me bhi OTP "aana chahiye" — fixed 123456 se
    // app khul jana nahi chahiye. Isliye har bar random OTP banta hai,
    // DB me hash store hota hai, aur response me mockOtp ke sath wapas
    // aata hai taaki tester use dekh ke enter kare. Verify bhi DB se hota hai.
    if (MOCK_OTP_ENABLED) {
      const otp = generateOtp();
      const doc = await Otp.createForPhone(fmt, sha256(otp), OTP_TTL_MS);
      console.log(`[MOCK OTP] ${fmt} -> ${otp} (reqId: ${doc._id})`);
      return res.json({
        success: true,
        message: "OTP sent (mock mode — use the OTP in response/logs)",
        mock: true,
        mockOtp: otp,
        reqId: String(doc._id),
      });
    }

    if (!FAST2SMS_API_KEY) {
      console.error("send-otp: FAST2SMS_API_KEY not configured");
      return res.status(500).json({ success: false, message: "OTP service not configured" });
    }

    // ── Generate OTP locally, store only its hash ──
    const otp = generateOtp();
    const doc = await Otp.createForPhone(fmt, sha256(otp), OTP_TTL_MS);

    // ── Send via Fast2SMS ──
    try {
      await sendSmsViaFast2Sms(fast2smsNumber(fmt), otp);
    } catch (smsErr) {
      // SMS failed — remove the OTP so a stale code can't linger.
      await Otp.deleteMany({ phone: fmt }).catch(() => {});
      console.error("send-otp SMS failed:", smsErr.message);
      return res.status(502).json({ success: false, message: "Failed to send OTP. Try again." });
    }

    // reqId is the OTP doc id — the Flutter app threads it through its
    // screens; verify-otp accepts it but looks the OTP up by phone.
    res.json({ success: true, message: "OTP sent successfully", reqId: String(doc._id) });
  } catch (e) {
    console.error("send-otp error:", e.response?.data || e.message);
    res.status(500).json({ success: false, message: "Failed to send OTP. Try again." });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/auth/verify-otp
// Body: { phone, otp, reqId, role? } — reqId comes from send-otp's response
// Returns: { success, session: { access_token, refresh_token }, user, is_new_user }
// ─────────────────────────────────────────────────────────────────────────────
router.post("/verify-otp", async (req, res) => {
  try {
    const { phone, otp, reqId, role } = req.body;
    if (!validPhone(phone) || !OTP_RE.test(String(otp || "").trim()))
      return res.status(400).json({ success: false, message: "Valid phone and OTP are required" });
    if (role && !ROLES.includes(role))
      return res.status(400).json({ success: false, message: "Invalid role" });

    const fmt      = fmtPhone(phone.trim());
    const email    = phoneToEmail(fmt);
    const password = phoneToPassword(fmt);
    const userRole = role || "customer";

    // ── Step 1: Verify OTP (mock bhi DB se verify hota hai — koi fixed bypass nahi) ──
    {
      // REAL + MOCK dono ke liye DB me hashed OTP se verify.
      const doc = await Otp.findOne({ phone: fmt });
      if (!doc) {
        return res.status(400).json({ success: false, message: "Invalid or expired OTP" });
      }
      if (doc.attempts >= OTP_MAX_ATTEMPTS) {
        await Otp.deleteMany({ phone: fmt }).catch(() => {});
        return res.status(400).json({ success: false, message: "Too many attempts. Request a new OTP." });
      }
      if (doc.expiresAt.getTime() < Date.now()) {
        await Otp.deleteMany({ phone: fmt }).catch(() => {});
        return res.status(400).json({ success: false, message: "OTP expired. Request a new one." });
      }
      if (sha256(String(otp).trim()) !== doc.otpHash) {
        doc.attempts += 1;
        await doc.save().catch(() => {});
        return res.status(400).json({ success: false, message: "Invalid OTP" });
      }
      // OTP correct — single-use, delete it.
      await Otp.deleteMany({ phone: fmt }).catch(() => {});
    }

    // ── Step 2: Find or create Supabase Auth user ──
    let supabaseUserId;

    const { data: signInData, error: signInErr } = await supabaseAdmin.auth.signInWithPassword({
      email,
      password,
    });

    if (!signInErr && signInData?.user) {
      supabaseUserId = signInData.user.id;

      const { data: profile } = await supabaseAdmin
        .from("profiles")
        .select("*")
        .eq("id", supabaseUserId)
        .single();

      return res.json({
        success: true,
        is_new_user: false,
        session: signInData.session,
        user: {
          id: supabaseUserId,
          phone: fmt,
          role: profile?.role || userRole,
          name: profile?.name || null,
          profile_complete: !!profile?.name,
        },
      });
    }

    // New user — create
    const { data: createData, error: createErr } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      phone: fmt,
      user_metadata: { phone: fmt, role: userRole },
      email_confirm: true,
      phone_confirm: true,
    });

    if (createErr) throw new Error("Failed to create user: " + createErr.message);
    supabaseUserId = createData.user.id;

    // ── Step 3: Upsert profile ──
    await supabaseAdmin.from("profiles").upsert({
      id: supabaseUserId,
      phone: fmt,
      role: userRole,
      updated_at: new Date().toISOString(),
    });

    // ── Step 4: Sign in to get session ──
    const { data: newSignIn, error: newSignInErr } = await supabaseAdmin.auth.signInWithPassword({
      email,
      password,
    });

    if (newSignInErr) throw new Error("Sign-in after create failed: " + newSignInErr.message);

    res.json({
      success: true,
      is_new_user: true,
      session: newSignIn.session,
      user: {
        id: supabaseUserId,
        phone: fmt,
        role: userRole,
        name: null,
        profile_complete: false,
      },
    });
  } catch (e) {
    console.error("verify-otp error:", e.message);
    res.status(400).json({ success: false, message: "OTP verification failed" });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/auth/me  (protected)
// ─────────────────────────────────────────────────────────────────────────────
router.get("/me", require("../middleware/auth").authMiddleware, async (req, res) => {
  try {
    const { data: profile } = await supabaseAdmin
      .from("profiles")
      .select("*")
      .eq("id", req.user.id)
      .single();

    res.json({ success: true, user: { id: req.user.id, ...profile } });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

module.exports = router;
