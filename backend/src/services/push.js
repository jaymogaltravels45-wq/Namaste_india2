// FCM push notifications (graceful degradation).
// Initializes firebase-admin ONLY when FCM_SERVICE_ACCOUNT_JSON env var is set.
// Otherwise every call is a console.log no-op — requests must never fail
// because push is unavailable.
const User = require("../models/User");

let messaging = null;
(function init() {
  const raw = process.env.FCM_SERVICE_ACCOUNT_JSON;
  if (!raw) {
    console.warn("[push] FCM_SERVICE_ACCOUNT_JSON not set — push notifications disabled (no-op).");
    return;
  }
  try {
    const admin = require("firebase-admin");
    const svc = JSON.parse(raw);
    if (!admin.apps.length) {
      admin.initializeApp({ credential: admin.credential.cert(svc) });
    }
    messaging = admin.messaging();
    console.log("[push] FCM initialized.");
  } catch (e) {
    console.warn("[push] FCM init failed, running as no-op:", e.message);
    messaging = null;
  }
})();

/**
 * Fire-and-forget push. Never throws — callers must not await it critically.
 * Usage: sendPushToUser(userId, title, body, data).catch(() => {});
 */
async function sendPushToUser(userId, title, body, data) {
  try {
    if (!messaging) {
      console.log(`[push:no-op] to=${userId} title=${title}`);
      return;
    }
    const user = await User.findOne({ supabaseId: String(userId) }).lean();
    const token = user && user.fcmToken;
    if (!token) {
      console.log(`[push] no fcmToken for user ${userId}, skipping.`);
      return;
    }
    await messaging.send({
      token,
      notification: { title: String(title), body: String(body) },
      data: data ? Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])) : {},
    });
    console.log(`[push] sent to user ${userId}`);
  } catch (e) {
    console.warn(`[push] failed for user ${userId}:`, e.message);
  }
}

module.exports = { sendPushToUser, isEnabled: () => !!messaging };
