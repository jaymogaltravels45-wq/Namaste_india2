const mongoose = require("mongoose");
// Offers from other drivers on a Requirement.
const s = new mongoose.Schema({
  requirementId: { type: mongoose.Schema.Types.ObjectId, ref: "Requirement", required: true, index: true },
  driverId:      { type: String, required: true, index: true }, // Supabase UUID
  amount:        { type: Number, required: true, min: 1 },
  message:       { type: String, maxlength: 500 },
  status:        { type: String, enum: ["pending", "accepted", "rejected"], default: "pending" },
}, { timestamps: true });
s.index({ requirementId: 1, driverId: 1 }, { unique: true });
module.exports = mongoose.model("RequirementResponse", s);
