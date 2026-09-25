const router = require("express").Router();
const axios = require("axios");
const crypto = require("crypto");

// ─── Supabase Admin client (service role — backend only) ───────────────────
const supabaseAdmin = require("../config/supabase");

// ─── Helpers ────────────────────────────────────────────────────────────────
const fmtPhone = (p) => (p.startsWith("+91") ? p : "+91" + p.replace(/\s+/g, ""));

// SECURITY: USER_SALT has NO fallback — index.js refuses to boot without it.
// (The old "namaste_default_salt_change_me" default meant every deployment
// shared the same password derivation secret.)
const USER_SALT = process.env.USER_SALT;

const phoneToPassword = (phone) =>
  crypto.createHmac("sha256", USER_SALT).update(phone).digest("hex");

const phoneToEmail = (phone) => phone.replace("+", "") + "@namasteindia.app";

// ─── Input validation ───────────────────────────────────────────────────────
const PHONE_RE = /^\+?\d[\d\s-]{6,16}$/;   // digits, optional +, spaces/dashes
const OTP_RE   = /^\d{4,8}$/;              // numeric OTP only
const ROLES    = ["customer", "driver", "admin"];

const validPhone = (p) => typeof p === "string" && PHONE_RE.test(p.trim());

// ─── MOCK OTP (set MOCK_OTP=true in .env for testing without MSG91) ─────────
const MOCK_OTP_ENABLED = process.env.MOCK_OTP === "true";
const MOCK_OTP_CODE    = process.env.MOCK_OTP_CODE || "123456";

// MSG91 classic OTP API (v5) requires the identifier with country code but
// WITHOUT the "+" prefix (e.g. "919106177858", not "+919106177858").
const msg91Identifier = (fmt) => fmt.replace("+", "");

// ─── MSG91 classic OTP API (server-side) ────────────────────────────────────
// Send:    POST https://control.msg91.com/api/v5/otp?mobile=91XXXXXXXXXX&otp_length=4
// Verify:  GET  https://control.msg91.com/api/v5/otp/verify?mobile=91XXXXXXXXXX&otp=1234
// Auth: account authkey in the `authkey` header. (The OTP *Widget* tokenAuth
// flow has no server-side REST endpoint — widget send/verify is client-SDK
// only — so the backend uses the classic OTP API instead.)
const MSG91_AUTH_KEY = process.env.MSG91_AUTH_KEY;

// MSG91 v5 APIs can return HTTP 200 with an error in the body:
// { "type": "error", "message": "..." } — so the body must be checked too.
const msg91Success = (data) => data && data.type === "success";

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

    // ── MOCK mode: skip MSG91, always return success ──
    if (MOCK_OTP_ENABLED) {
      console.log(`[MOCK OTP] send-otp called for ${fmt} — mock code: ${MOCK_OTP_CODE}`);
      return res.json({ success: true, message: `OTP sent (mock: use ${MOCK_OTP_CODE})`, mock: true, reqId: "mock-req-id" });
    }

    if (!MSG91_AUTH_KEY) {
      console.error("send-otp: MSG91_AUTH_KEY not configured");
      return res.status(500).json({ success: false, message: "OTP service not configured" });
    }

    // ── REAL MSG91 classic OTP API ──
    // Auth = account authkey in the `authkey` header.
    const { status, data } = await axios.post(
      "https://control.msg91.com/api/v5/otp",
      null,
      {
        params: {
          mobile: msg91Identifier(fmt),
          otp_length: 4,
          otp_expiry: 5,
        },
        headers: { authkey: MSG91_AUTH_KEY, "Content-Type": "application/json" },
      }
    );

    // Log the raw MSG91 response for debugging delivery issues
    console.log("MSG91 sendOTP response:", JSON.stringify(data));

    if (status !== 200 || !msg91Success(data)) {
      const msg = data?.message || "MSG91 rejected the OTP request";
      console.error("send-otp failed:", msg);
      return res.status(502).json({ success: false, message: "Failed to send OTP: " + msg });
    }

    // Classic API verifies with mobile+otp; no reqId is needed. We still return
    // MSG91's request_id as reqId so the Flutter app (which threads reqId
    // through its screens) keeps working unchanged — verify ignores it.
    const reqId = data.request_id || data.reqId || null;
    if (!reqId) console.warn("send-otp: MSG91 response had no request_id");
    res.json({ success: true, message: "OTP sent successfully", reqId });
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

    // ── Step 1: Verify OTP ──
    if (MOCK_OTP_ENABLED) {
      // MOCK: only accept the mock code
      console.log(`[MOCK OTP] verify-otp: received ${otp}, expected ${MOCK_OTP_CODE}`);
      if (String(otp) !== String(MOCK_OTP_CODE)) {
        return res.status(400).json({ success: false, message: "Invalid OTP (mock mode)" });
      }
    } else {
      // REAL MSG91 classic OTP verify — needs only mobile + otp.
      // reqId is optional/ignored (kept in the contract for the Flutter app,
      // which threads it through; the classic API does not use it).
      if (!MSG91_AUTH_KEY) {
        console.error("verify-otp: MSG91_AUTH_KEY not configured");
        return res.status(500).json({ success: false, message: "OTP service not configured" });
      }
      try {
        const { data } = await axios.get(
          "https://control.msg91.com/api/v5/otp/verify",
          {
            params: {
              mobile: msg91Identifier(fmt),
              otp: String(otp).trim(),
            },
            headers: { authkey: MSG91_AUTH_KEY },
          }
        );
        console.log("MSG91 verifyOTP response:", JSON.stringify(data));
        if (!msg91Success(data)) {
          return res.status(400).json({
            success: false,
            message: data?.message || "Invalid or expired OTP",
          });
        }
      } catch (msgErr) {
        console.error("MSG91 verify error:", msgErr.response?.data || msgErr.message);
        return res.status(400).json({ success: false, message: "Invalid or expired OTP" });
      }
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
