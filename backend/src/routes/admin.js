const router  = require("express").Router();
const mongoose = require("mongoose");
const supabaseAdmin = require("../config/supabase");
const { attachParties } = require("../services/partyInfo");
const User    = require("../models/User");
const Driver  = require("../models/Driver");
const Booking = require("../models/Booking");
const WalletTransaction = require("../models/Wallet");
const { authMiddleware, adminOnly } = require("../middleware/auth");

router.use(authMiddleware, adminOnly);

// Note: customers live in Supabase Auth/profiles (source of truth), not Mongo.

const validId = (id) => mongoose.Types.ObjectId.isValid(id);
const KYC_STATUSES = ["pending", "verified", "rejected"];
const WALLET_TYPES = ["credit", "debit", "penalty", "refund", "commission", "subscription"];

router.get("/dashboard", async (req, res) => {
  try {
    const [customers, drivers, bookings, pendingKyc] = await Promise.all([
      User.countDocuments({ role: "customer" }),
      Driver.countDocuments(),
      Booking.countDocuments(),
      Driver.countDocuments({ kycStatus: "pending" }),
    ]);
    const rev = await Booking.aggregate([
      { $match: { paymentStatus: { $in: ["cash","upi"] } } },
      { $group: { _id: null, total: { $sum: "$estimatedFare" } } },
    ]);
    res.json({ success: true, data: { customers, drivers, bookings, pendingKyc, revenue: rev[0]?.total || 0 } });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

router.get("/drivers", async (req, res) => {
  const d = await Driver.find().sort({ createdAt: -1 });
  res.json({ success: true, data: d });
});

// Verify / reject driver KYC
router.patch("/drivers/:id/kyc", async (req, res) => {
  try {
    if (!validId(req.params.id))
      return res.status(400).json({ success: false, message: "Invalid driver id" });
    const { kycStatus = "verified" } = req.body || {};
    if (!KYC_STATUSES.includes(kycStatus))
      return res.status(400).json({ success: false, message: "kycStatus must be one of: " + KYC_STATUSES.join(", ") });
    const d = await Driver.findByIdAndUpdate(req.params.id, { kycStatus }, { new: true });
    if (!d) return res.status(404).json({ success: false, message: "Driver not found" });
    res.json({ success: true, data: d });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

// Admin wallet adjustment (credit/debit/penalty/refund)
router.patch("/drivers/:id/wallet", async (req, res) => {
  try {
    if (!validId(req.params.id))
      return res.status(400).json({ success: false, message: "Invalid driver id" });
    const { amount, type, description } = req.body || {};
    const amt = parseFloat(amount);
    if (!Number.isFinite(amt) || amt === 0)
      return res.status(400).json({ success: false, message: "amount must be a non-zero number (negative for debit)" });
    if (!WALLET_TYPES.includes(type))
      return res.status(400).json({ success: false, message: "type must be one of: " + WALLET_TYPES.join(", ") });
    const d = await Driver.findById(req.params.id);
    if (!d) return res.status(404).json({ success: false, message: "Driver not found" });
    d.walletBalance += amt;
    await d.save(); // pre-save updates canAcceptBookings
    await WalletTransaction.create({
      driverId: d._id.toString(), type, amount: amt,
      balance: d.walletBalance, description: description || "Admin adjustment",
    });
    res.json({ success: true, newBalance: d.walletBalance, canAcceptBookings: d.canAcceptBookings });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

router.get("/bookings", async (req, res) => {
  const b = await Booking.find().sort({ createdAt: -1 }).limit(200).lean();
  await attachParties(b);
  res.json({ success: true, data: b });
});

// Customers (from Supabase profiles — the source of truth for app users)
router.get("/customers", async (req, res) => {
  try {
    const { data, error } = await supabaseAdmin
      .from("profiles")
      .select("id, phone, name, role, created_at")
      .eq("role", "customer")
      .order("created_at", { ascending: false })
      .limit(100);
    if (error) throw new Error(error.message);
    res.json({ success: true, data });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

// All wallet transactions (latest 100) with driver names attached
router.get("/wallets", async (req, res) => {
  try {
    const txs = await WalletTransaction.find().sort({ createdAt: -1 }).limit(100).lean();
    const driverIds = [...new Set(txs.map((t) => t.driverId).filter(Boolean))];
    const drivers = await Driver.find({ _id: { $in: driverIds } })
      .select("name phone").lean().catch(() => []);
    const byId = Object.fromEntries(drivers.map((d) => [String(d._id), d]));
    for (const t of txs) {
      const d = byId[String(t.driverId)];
      if (d) t.driver = { name: d.name, phone: d.phone };
    }
    res.json({ success: true, data: txs });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

module.exports = router;
