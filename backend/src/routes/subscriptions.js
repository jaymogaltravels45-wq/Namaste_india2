const router   = require("express").Router();
const Driver       = require("../models/Driver");
const Subscription = require("../models/Subscription");
const WalletTransaction = require("../models/Wallet");
const { authMiddleware } = require("../middleware/auth");

const PREMIUM_PRICE = 300;      // Rs.300
const PREMIUM_DAYS  = 30;       // 30 days, 0% commission

// Shared helper: is this driver's premium currently active?
async function hasActivePremium(userId) {
  const sub = await Subscription.findOne({
    driverId: String(userId), endsAt: { $gt: new Date() },
  }).sort({ endsAt: -1 }).lean();
  return sub || null;
}

// ─── Buy premium (driver only): Rs.300 debited from wallet ───────────────────
router.post("/buy", authMiddleware, async (req, res) => {
  try {
    const driver = await Driver.findOne({ userId: req.user.id });
    if (!driver) return res.status(403).json({ success: false, message: "Drivers only" });
    if (driver.walletBalance < PREMIUM_PRICE) {
      return res.status(400).json({
        success: false,
        message: `Insufficient wallet balance (Rs.${driver.walletBalance}). Need Rs.${PREMIUM_PRICE}.`,
        walletBalance: driver.walletBalance,
      });
    }
    driver.walletBalance -= PREMIUM_PRICE;
    await driver.save(); // pre-save updates canAcceptBookings
    const tx = await WalletTransaction.create({
      driverId: driver._id.toString(), type: "subscription",
      amount: PREMIUM_PRICE, balance: driver.walletBalance,
      description: `Premium subscription (${PREMIUM_DAYS} days, 0% commission)`,
    });
    const startsAt = new Date();
    const endsAt = new Date(startsAt.getTime() + PREMIUM_DAYS * 24 * 60 * 60 * 1000);
    const sub = await Subscription.create({
      driverId: driver.userId, plan: "premium",
      amount: PREMIUM_PRICE, startsAt, endsAt,
    });
    res.status(201).json({ success: true, subscription: sub, balance: driver.walletBalance, transaction: tx });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

// ─── Subscription status (driver only) ──────────────────────────────────────
router.get("/status", authMiddleware, async (req, res) => {
  try {
    const driver = await Driver.findOne({ userId: req.user.id });
    if (!driver) return res.status(403).json({ success: false, message: "Drivers only" });
    const sub = await hasActivePremium(driver.userId);
    res.json({ success: true, active: !!sub, endsAt: sub ? sub.endsAt : null, subscription: sub });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

module.exports = router;
module.exports.hasActivePremium = hasActivePremium;
module.exports.PREMIUM_PRICE = PREMIUM_PRICE;
module.exports.PREMIUM_DAYS = PREMIUM_DAYS;
