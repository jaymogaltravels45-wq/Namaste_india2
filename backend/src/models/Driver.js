const mongoose = require("mongoose");
const s = new mongoose.Schema({
  userId:       { type: String, required: true, unique: true }, // Supabase UUID (NOT ObjectId)
  phone:        { type: String, required: true },
  name:         { type: String, required: true },
  vehicleType:  { type: String, enum: ["hatchback","sedan","suv","innova"], required: true },
  vehicleNumber:{ type: String, required: true },
  vehicleModel: String, licenseNumber: String,
  kycStatus:    { type: String, enum: ["pending","verified","rejected"], default: "pending" },
  isOnline:     { type: Boolean, default: false },
  isAvailable:  { type: Boolean, default: true },
  walletBalance:{ type: Number, default: 0 },
  // Auto-maintained: walletBalance >= 0
  canAcceptBookings: { type: Boolean, default: true },
  location:     { type: { type: String, default: "Point" }, coordinates: { type: [Number], default: [0,0] } },
  rating:       { type: Number, default: 0 },
  totalTrips:   { type: Number, default: 0 },
  experience:   { type: Number, default: 0 }, // years of driving experience (shown on bids)
}, { timestamps: true });
// KEY RULE: auto-update canAcceptBookings on save
s.pre("save", function(next) { this.canAcceptBookings = this.walletBalance >= 0; next(); });
s.index({ location: "2dsphere" });
module.exports = mongoose.model("Driver", s);
