const mongoose = require("mongoose");
const Counter = require("./Counter");
const s = new mongoose.Schema({
  bookingNumber: { type: String, unique: true },
  // Identity fields are Supabase UUID strings (NOT Mongo ObjectIds).
  // The auth layer issues Supabase JWTs, so all user/driver references are UUIDs.
  customerId:    { type: String, required: true },
  driverId:      { type: String },
  bookingType:   { type: String, enum: ["outstation","local","round_trip","bid"], required: true },
  vehicleType:   { type: String, enum: ["hatchback","sedan","suv","innova"], required: true },
  pickup:        { address: { type: String, required: true }, lat: Number, lng: Number },
  drop:          { address: String, lat: Number, lng: Number },
  // TIME BUG FIX: all times always stored
  pickupTime:    { type: Date, required: true },
  scheduledTime: Date,
  startTime:     Date,
  endTime:       Date,
  assignedAt:    Date,
  distanceKm:    { type: Number, default: 0 },
  localPackage:  { type: String, enum: ["4h/40km","8h/80km","12h/120km"] },
  estimatedFare: Number, finalFare: Number,
  customerBid:   Number, // customer's own bid amount for bookingType "bid"
  status:        { type: String, enum: ["pending","driver_assigned","open_for_bids","confirmed","arrived","ongoing","started","completed","cancelled"], default: "pending" },
  paymentStatus: { type: String, enum: ["pending","cash","upi","refunded"], default: "pending" },
  paymentMethod: { type: String, enum: ["cash","upi"] },
  upiTransactionId: String,
  bids: [{
    driverId: { type: String }, // Supabase UUID
    amount: Number, createdAt: { type: Date, default: Date.now },
    status: { type: String, enum: ["pending","accepted","rejected"], default: "pending" },
  }],
  otp: String, notes: String,
  // Ride Start OTP (4-digit): only the SHA256 hash is persisted; the plain
  // OTP lives transiently in the server-side rideOtpStore until expiry.
  rideOtpHash: String, rideOtpExpires: Date,
  rating: { type: Number, min: 1, max: 5 }, review: String,
  assignedByDriverId: { type: String }, // Supabase UUID
}, { timestamps: true });
s.pre("save", async function(next) {
  if (!this.bookingNumber) {
    // Atomic increment — safe under concurrency (no countDocuments race).
    const seq = await Counter.getNextSequence("booking");
    this.bookingNumber = "NI" + Date.now() + "-" + seq;
  }
  next();
});
module.exports = mongoose.model("Booking", s);
