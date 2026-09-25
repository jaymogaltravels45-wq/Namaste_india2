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

// MSG91 Widget API requires the identifier with country code but WITHOUT
// the "+" prefix (e.g. "919106177858", not "+919106177858") — per MSG91 docs.
const msg91Identifier = (fmt) => fmt.replace("+", "");

// ─── MSG91 Widget API auth (server-side) ────────────────────────────────────
// The OTP Widget send/verify endpoints authenticate with the WIDGET TOKEN
// (tokenAuth) — NOT the account authkey. The widget token is generated under
// OTP > OTP Widget/SDK > Tokens in the MSG91 panel ("Namasteindia", Enabled).
const MSG91_TOKEN_AUTH = process.env.MSG91_TOKEN_AUTH;
const MSG91_WIDGET_ID  = process.env.MSG91_WIDGET_ID;

// MSG91 v5 APIs can return HTTP 200 with an error in the body:
// { "type": "error", "message": "..." } — so the body must be checked too.
const msg91Success = (data) => data && data.type === "success";

// sendOTP returns a reqId that MUST be passed to verifyOTP.
const msg91ReqId = (data) =>
  data ? (data.reqId || data.req_id || data.requestId || null) : null;

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

    if (!MSG91_TOKEN_AUTH || !MSG91_WIDGET_ID) {
      console.error("send-otp: MSG91_TOKEN_AUTH or MSG91_WIDGET_ID not configured");
      return res.status(500).json({ success: false, message: "OTP service not configured" });
    }

    // ── REAL MSG91 Widget API ──
    // Auth = widget token (tokenAuth) in the body, NOT the account authkey.
    const { status, data } = await axios.post(
      "https://control.msg91.com/api/v5/widget/sendOTP",
      {
        tokenAuth: MSG91_TOKEN_AUTH,
        widgetId: MSG91_WIDGET_ID,
        identifier: msg91Identifier(fmt),
      },
      { headers: { "Content-Type": "application/json" } }
    );

    // Log the raw MSG91 response for debugging delivery issues
    console.log("MSG91 sendOTP response:", JSON.stringify(data));

    if (status !== 200 || !msg91Success(data)) {
      const msg = data?.message || "MSG91 rejected the OTP request";
      console.error("send-otp failed:", msg);
      return res.status(502).json({ success: false, message: "Failed to send OTP: " + msg });
    }

    const reqId = msg91ReqId(data);
    if (!reqId) console.warn("send-otp: MSG91 response had no reqId — verify will fail");
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
      // REAL MSG91 Widget verify — needs the reqId returned by sendOTP
      if (!reqId) {
        return res.status(400).json({ success: false, message: "OTP session expired. Please resend the OTP." });
      }
      try {
        const { data } = await axios.post(
          "https://control.msg91.com/api/v5/widget/verifyOTP",
          {
            tokenAuth: MSG91_TOKEN_AUTH,   // ✅ widget token, NOT account authkey
            widgetId: MSG91_WIDGET_ID,
            reqId: String(reqId),
            otp: String(otp),
          },
          { headers: { "Content-Type": "application/json" } }
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
