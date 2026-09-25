const mongoose = require("mongoose");
// Driver-to-driver requirement posts. Visible to OTHER drivers only.
// NO photo upload on requirements (explicit scope decision).
const s = new mongoose.Schema({
  driverId:    { type: String, required: true, index: true }, // Supabase UUID
  pickup:      { address: { type: String, required: true }, lat: Number, lng: Number },
  drop:        { address: { type: String, required: true }, lat: Number, lng: Number },
  date:        { type: String, required: true },  // YYYY-MM-DD
  time:        { type: String, required: true },  // HH:mm
  vehicleType: { type: String, required: true },
  passengers:  { type: Number, default: 1, min: 1 },
  budget:      { type: Number, min: 0 },
  notes:       { type: String, maxlength: 1000 },
  status:      { type: String, enum: ["open", "closed"], default: "open", index: true },
}, { timestamps: true });
module.exports = mongoose.model("Requirement", s);
