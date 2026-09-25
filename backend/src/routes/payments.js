const router   = require("express").Router();
const mongoose = require("mongoose");
const Booking  = require("../models/Booking");
const Driver   = require("../models/Driver");
const { authMiddleware } = require("../middleware/auth");

// UPI transaction IDs: alphanumeric, 6-32 chars (covers bank/PSP formats)
const UPI_TXN_RE = /^[A-Za-z0-9]{6,32}$/;

// Cash or UPI payment — only the booking's customer or assigned driver may record it.
router.post("/:bookingId/pay", authMiddleware, async (req, res) => {
  try {
    const { bookingId } = req.params;
    if (!mongoose.Types.ObjectId.isValid(bookingId))
      return res.status(400).json({ success: false, message: "Invalid booking id" });

    const { method, upiTransactionId, amount } = req.body || {};
    if (!["cash", "upi"].includes(method))
      return res.status(400).json({ success: false, message: "Method must be cash or upi" });
    if (upiTransactionId !== undefined && !UPI_TXN_RE.test(String(upiTransactionId)))
      return res.status(400).json({ success: false, message: "Invalid UPI transaction ID format" });
    if (amount !== undefined) {
      const amt = Number(amount);
      if (!Number.isFinite(amt) || amt <= 0)
        return res.status(400).json({ success: false, message: "amount must be a positive number" });
    }

    const booking = await Booking.findById(bookingId);
    if (!booking) return res.status(404).json({ success: false, message: "Booking not found" });

    // Ownership: customer who booked, or the assigned driver.
    const driver = await Driver.findOne({ userId: req.user.id });
    const isCustomer = String(booking.customerId) === String(req.user.id);
    const isDriver = driver && booking.driverId && String(booking.driverId) === String(driver.userId);
    if (!isCustomer && !isDriver)
      return res.status(403).json({ success: false, message: "Not your booking" });

    if (booking.status !== "completed")
      return res.status(400).json({ success: false, message: "Payment can only be recorded for completed rides" });

    const update = { paymentMethod: method, paymentStatus: method };
    if (method === "upi" && upiTransactionId) update.upiTransactionId = String(upiTransactionId);
    const updated = await Booking.findByIdAndUpdate(bookingId, update, { new: true });

    if (updated.driverId)
      req.app.get("io").to("driver_" + updated.driverId).emit("payment_received",
        { bookingId: updated._id, method, amount: updated.finalFare || updated.estimatedFare });
    res.json({ success: true, booking: updated, message: "Payment via " + method.toUpperCase() + " recorded" });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

// Company UPI info
router.get("/upi-info", authMiddleware, (req, res) => res.json({
  success: true,
  upiId: process.env.COMPANY_UPI_ID || "namasteindia@upi",
  companyName: "Namaste India",
  qrImageUrl: "/assets/company_qr.png",
}));

module.exports = router;
