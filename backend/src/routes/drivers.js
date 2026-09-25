const router = require("express").Router();
const Driver = require("../models/Driver");
const WalletTransaction = require("../models/Wallet");
const { authMiddleware } = require("../middleware/auth");

const VEHICLE_TYPES = ["hatchback", "sedan", "suv", "innova"];
const fmtPhone = (p) => (String(p).startsWith("+91") ? String(p) : "+91" + String(p).replace(/\s+/g, ""));
const validPhone = (p) => /^\+91[6-9]\d{9}$/.test(fmtPhone(p));

// ─── Driver onboarding / KYC registration ───────────────────────────────────
// Creates the Driver document linked to the caller's Supabase UUID.
// kycStatus starts "pending"; an admin verifies it before the driver can earn.
// ─── Public: online drivers for "Available Cars & Drivers" ─────────────────
// No auth: customers browse before login. Only safe public fields exposed.
router.get("/online", async (req, res) => {
  try {
    const { vehicleType } = req.query || {};
    const q = { isOnline: true, kycStatus: "verified" };
    if (vehicleType && VEHICLE_TYPES.includes(vehicleType)) q.vehicleType = vehicleType;
    const drivers = await Driver.find(q)
      .sort({ rating: -1 }).limit(40)
      .select("name vehicleType vehicleModel rating totalTrips")
      .lean();
    const list = drivers.map((d) => ({
      id: d._id,
      // Privacy: sirf pehla naam dikhao
      name: String(d.name || "Driver").trim().split(/\s+/)[0],
      vehicleType: d.vehicleType,
      vehicleModel: d.vehicleModel || "",
      rating: d.rating || 0,
      totalTrips: d.totalTrips || 0,
    }));
    res.json({ success: true, drivers: list });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

router.post("/register", authMiddleware, async (req, res) => {
  try {
    const { name, phone, vehicleType, vehicleNumber, vehicleModel, licenseNumber } = req.body || {};

    if (!name || typeof name !== "string" || !name.trim())
      return res.status(400).json({ success: false, message: "name is required" });
    if (!phone || !validPhone(phone))
      return res.status(400).json({ success: false, message: "phone must be a valid 10-digit Indian mobile number" });
    if (!VEHICLE_TYPES.includes(vehicleType))
      return res.status(400).json({ success: false, message: "vehicleType must be one of: " + VEHICLE_TYPES.join(", ") });
    if (!vehicleNumber || typeof vehicleNumber !== "string" || !vehicleNumber.trim())
      return res.status(400).json({ success: false, message: "vehicleNumber is required" });

    const existing = await Driver.findOne({ userId: req.user.id });
    if (existing)
      return res.status(409).json({ success: false, message: "Driver already registered", driver: existing });

    const d = await Driver.create({
      userId: req.user.id,
      phone: fmtPhone(phone),
      name: name.trim(),
      vehicleType,
      vehicleNumber: vehicleNumber.trim().toUpperCase(),
      vehicleModel: typeof vehicleModel === "string" ? vehicleModel : undefined,
      licenseNumber: typeof licenseNumber === "string" ? licenseNumber.trim() : undefined,
      kycStatus: "pending",
    });
    res.status(201).json({ success: true, driver: d });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

router.get("/profile", authMiddleware, async (req, res) => {
  const d = await Driver.findOne({ userId: req.user.id });
  res.json({ success: true, driver: d });
});

router.get("/wallet", authMiddleware, async (req, res) => {
  const d = await Driver.findOne({ userId: req.user.id });
  if (!d) return res.status(404).json({ success: false, message: "Driver not found" });
  const txs = await WalletTransaction.find({ driverId: d._id.toString() }).sort({ createdAt: -1 }).limit(20);
  res.json({ success: true, balance: d.walletBalance, canAcceptBookings: d.canAcceptBookings, transactions: txs });
});

router.post("/wallet/add", authMiddleware, async (req, res) => {
  try {
    const amount = parseFloat(req.body?.amount);
    if (!Number.isFinite(amount) || amount <= 0)
      return res.status(400).json({ success: false, message: "amount must be a positive number" });
    const d = await Driver.findOne({ userId: req.user.id });
    if (!d) return res.status(404).json({ success: false, message: "Driver not found" });
    d.walletBalance += amount;
    await d.save(); // pre-save updates canAcceptBookings
    const tx = await WalletTransaction.create({
      driverId: d._id.toString(), type: "credit", amount,
      balance: d.walletBalance, description: "Wallet recharge",
    });
    res.json({ success: true, balance: d.walletBalance, canAcceptBookings: d.canAcceptBookings, transaction: tx });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

router.patch("/status", authMiddleware, async (req, res) => {
  const d = await Driver.findOne({ userId: req.user.id });
  if (!d) return res.status(404).json({ success: false, message: "Driver not found" });
  if (typeof req.body?.isOnline !== "boolean")
    return res.status(400).json({ success: false, message: "isOnline must be true or false" });
  if (req.body.isOnline && d.walletBalance < 0)
    return res.status(403).json({ success: false, message: "Negative balance - add money to go online" });
  d.isOnline = req.body.isOnline;
  await d.save();
  res.json({ success: true, isOnline: d.isOnline });
});

module.exports = router;
