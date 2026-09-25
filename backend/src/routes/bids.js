const router   = require("express").Router();
const mongoose = require("mongoose");
const Bid      = require("../models/Bid");
const Booking  = require("../models/Booking");
const Driver   = require("../models/Driver");
const { authMiddleware } = require("../middleware/auth");
const { sendPushToUser } = require("../services/push");

const validId = (id) => mongoose.Types.ObjectId.isValid(id);

// ─── Driver withdraws own bid ───────────────────────────────────────────────
router.post("/:bidId/withdraw", authMiddleware, async (req, res) => {
  try {
    const driver = await Driver.findOne({ userId: req.user.id });
    if (!driver) return res.status(403).json({ success: false, message: "Drivers only" });
    if (!validId(req.params.bidId))
      return res.status(400).json({ success: false, message: "Invalid bid id" });
    const bid = await Bid.findOne({ _id: req.params.bidId, driverId: driver.userId });
    if (!bid) return res.status(404).json({ success: false, message: "Bid not found" });
    if (bid.status !== "pending")
      return res.status(400).json({ success: false, message: "Only pending bids can be withdrawn" });
    bid.status = "withdrawn";
    await bid.save();
    res.json({ success: true, bid });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

// ─── Customer accepts a bid on their own booking ────────────────────────────
router.post("/:bidId/accept", authMiddleware, async (req, res) => {
  try {
    if (!validId(req.params.bidId))
      return res.status(400).json({ success: false, message: "Invalid bid id" });
    const bid = await Bid.findById(req.params.bidId);
    if (!bid) return res.status(404).json({ success: false, message: "Bid not found" });
    if (bid.status !== "pending")
      return res.status(400).json({ success: false, message: "Bid is no longer pending" });

    const booking = await Booking.findById(bid.bookingId);
    if (!booking) return res.status(404).json({ success: false, message: "Booking not found" });
    if (String(booking.customerId) !== String(req.user.id))
      return res.status(403).json({ success: false, message: "You can only accept bids on your own bookings" });
    if (booking.status !== "open_for_bids")
      return res.status(400).json({ success: false, message: "Booking is not open for bids" });

    // One accepted bid; everything else rejected.
    await Bid.updateMany(
      { bookingId: booking._id, status: "pending", _id: { $ne: bid._id } },
      { $set: { status: "rejected" } }
    );
    bid.status = "accepted";
    await bid.save();

    booking.driverId = bid.driverId;
    booking.estimatedFare = bid.amount;
    booking.finalFare = bid.amount;
    booking.status = "confirmed";
    booking.assignedAt = new Date();
    await booking.save();

    // Push to the winning driver (fire-and-forget).
    sendPushToUser(bid.driverId, "Bid accepted! 🎉",
      `Customer accepted your bid of Rs.${bid.amount}. Booking ${booking.bookingNumber || ""} confirmed.`,
      { type: "bid_accepted", bookingId: String(booking._id) }).catch(() => {});
    req.app.get("io").to("driver_" + bid.driverId).emit("bid_accepted", { booking, bid });

    res.json({ success: true, booking, bid });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

module.exports = router;
