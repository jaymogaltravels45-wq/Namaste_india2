const router = require("express").Router();
const User = require("../models/User");
const { authMiddleware } = require("../middleware/auth");

// ─── Save FCM push token (any authenticated user) ───────────────────────────
router.post("/fcm-token", authMiddleware, async (req, res) => {
  try {
    const { token } = req.body || {};
    if (!token || typeof token !== "string" || token.length > 500)
      return res.status(400).json({ success: false, message: "token is required" });
    const supabaseId = String(req.user.id);
    let user = await User.findOne({ supabaseId });
    if (!user) {
      // Mongo User doc may not exist yet (auth lives in Supabase) — create it.
      user = new User({
        supabaseId,
        phone: req.user.phone || ("uuid:" + supabaseId),
        fcmToken: token,
      });
    } else {
      user.fcmToken = token;
    }
    await user.save();
    res.json({ success: true, message: "FCM token saved" });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

module.exports = router;
