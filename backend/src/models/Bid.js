const mongoose = require("mongoose");
// Driver counter-bids on open_for_bids bookings.
// Identity: driverId is the Supabase UUID string (same convention as Booking).
const s = new mongoose.Schema({
  bookingId: { type: mongoose.Schema.Types.ObjectId, ref: "Booking", required: true, index: true },
  driverId:  { type: String, required: true, index: true },
  amount:    { type: Number, required: true, min: 1 },
  message:   { type: String, maxlength: 500 },
  status:    { type: String, enum: ["pending", "accepted", "rejected", "withdrawn"], default: "pending" },
}, { timestamps: true });
s.index({ bookingId: 1, driverId: 1 }, { unique: true }); // one active bid slot per driver per booking
module.exports = mongoose.model("Bid", s);
