const router   = require("express").Router();
const mongoose = require("mongoose");
const Requirement         = require("../models/Requirement");
const RequirementResponse = require("../models/RequirementResponse");
const Driver   = require("../models/Driver");
const { authMiddleware } = require("../middleware/auth");

const validId = (id) => mongoose.Types.ObjectId.isValid(id);

// Driver-only guard. Returns driver or sends 403.
async function driverOnly(req, res) {
  const driver = await Driver.findOne({ userId: req.user.id });
  if (!driver) { res.status(403).json({ success: false, message: "Drivers only" }); return null; }
  return driver;
}

const driverPublic = (d) => d ? {
  userId: d.userId, name: d.name, phone: d.phone,
  vehicleType: d.vehicleType, vehicleNumber: d.vehicleNumber,
  vehicleModel: d.vehicleModel, rating: d.rating, experience: d.experience,
} : null;

// ─── Create a requirement (driver only) ─────────────────────────────────────
router.post("/", authMiddleware, async (req, res) => {
  try {
    const driver = await driverOnly(req, res);
    if (!driver) return;
    const { pickup, drop, date, time, vehicleType, passengers, budget, notes } = req.body || {};
    if (!pickup || typeof pickup.address !== "string" || !pickup.address.trim())
      return res.status(400).json({ success: false, message: "pickup.address is required" });
    if (!drop || typeof drop.address !== "string" || !drop.address.trim())
      return res.status(400).json({ success: false, message: "drop.address is required" });
    if (!date || !time)
      return res.status(400).json({ success: false, message: "date and time are required" });
    if (!vehicleType)
      return res.status(400).json({ success: false, message: "vehicleType is required" });
    const pax = passengers === undefined ? 1 : Number(passengers);
    if (!Number.isInteger(pax) || pax < 1)
      return res.status(400).json({ success: false, message: "passengers must be a positive integer" });
    if (budget !== undefined && (!Number.isFinite(Number(budget)) || Number(budget) < 0))
      return res.status(400).json({ success: false, message: "budget must be a non-negative number" });

    const r = await Requirement.create({
      driverId: driver.userId, pickup, drop, date, time, vehicleType,
      passengers: pax, budget: budget === undefined ? undefined : Number(budget), notes,
    });
    res.status(201).json({ success: true, requirement: r });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

// ─── Open requirements from OTHER drivers (driver only) ─────────────────────
router.get("/", authMiddleware, async (req, res) => {
  try {
    const driver = await driverOnly(req, res);
    if (!driver) return;
    const list = await Requirement.find({ status: "open", driverId: { $ne: driver.userId } })
      .sort({ createdAt: -1 }).limit(50).lean();
    res.json({ success: true, requirements: list });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

// ─── Own requirements (driver only) ─────────────────────────────────────────
router.get("/my", authMiddleware, async (req, res) => {
  try {
    const driver = await driverOnly(req, res);
    if (!driver) return;
    const list = await Requirement.find({ driverId: driver.userId })
      .sort({ createdAt: -1 }).limit(50).lean();
    res.json({ success: true, requirements: list });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

// ─── Responses on a requirement (owner only) ────────────────────────────────
router.get("/:id/responses", authMiddleware, async (req, res) => {
  try {
    const driver = await driverOnly(req, res);
    if (!driver) return;
    if (!validId(req.params.id))
      return res.status(400).json({ success: false, message: "Invalid requirement id" });
    const r = await Requirement.findById(req.params.id);
    if (!r) return res.status(404).json({ success: false, message: "Requirement not found" });
    if (String(r.driverId) !== String(driver.userId))
      return res.status(403).json({ success: false, message: "Only the owner can view responses" });
    const responses = await RequirementResponse.find({ requirementId: r._id })
      .sort({ createdAt: -1 }).lean();
    for (const resp of responses) {
      const d = await Driver.findOne({ userId: resp.driverId }).lean();
      resp.driver = driverPublic(d);
    }
    res.json({ success: true, responses });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

// ─── Respond with an offer (driver only, not own requirement) ───────────────
router.post("/:id/respond", authMiddleware, async (req, res) => {
  try {
    const driver = await driverOnly(req, res);
    if (!driver) return;
    if (!validId(req.params.id))
      return res.status(400).json({ success: false, message: "Invalid requirement id" });
    const r = await Requirement.findById(req.params.id);
    if (!r) return res.status(404).json({ success: false, message: "Requirement not found" });
    if (r.status !== "open")
      return res.status(400).json({ success: false, message: "Requirement is closed" });
    if (String(r.driverId) === String(driver.userId))
      return res.status(400).json({ success: false, message: "You cannot respond to your own requirement" });

    const amount = Number(req.body?.amount);
    if (!Number.isFinite(amount) || amount <= 0)
      return res.status(400).json({ success: false, message: "amount must be a positive number" });
    const message = req.body?.message;
    if (message !== undefined && (typeof message !== "string" || message.length > 500))
      return res.status(400).json({ success: false, message: "message must be text up to 500 characters" });

    // One offer slot per driver per requirement — update if already responded.
    const resp = await RequirementResponse.findOneAndUpdate(
      { requirementId: r._id, driverId: driver.userId },
      { $set: { amount, message, status: "pending" } },
      { new: true, upsert: true }
    );
    res.status(201).json({ success: true, response: resp });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

// ─── Close a requirement (owner only) ───────────────────────────────────────
router.post("/:id/close", authMiddleware, async (req, res) => {
  try {
    const driver = await driverOnly(req, res);
    if (!driver) return;
    if (!validId(req.params.id))
      return res.status(400).json({ success: false, message: "Invalid requirement id" });
    const r = await Requirement.findOne({ _id: req.params.id, driverId: driver.userId });
    if (!r) return res.status(404).json({ success: false, message: "Requirement not found" });
    r.status = "closed";
    await r.save();
    res.json({ success: true, requirement: r });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

module.exports = router;
