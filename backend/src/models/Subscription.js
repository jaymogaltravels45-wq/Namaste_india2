const mongoose = require("mongoose");
// Driver premium subscription: Rs.300 / 30 days / 0% commission.
const s = new mongoose.Schema({
  driverId: { type: String, required: true, index: true }, // Supabase UUID
  plan:     { type: String, enum: ["premium"], default: "premium" },
  amount:   { type: Number, required: true },
  startsAt: { type: Date, required: true },
  endsAt:   { type: Date, required: true, index: true },
}, { timestamps: true });
module.exports = mongoose.model("Subscription", s);
