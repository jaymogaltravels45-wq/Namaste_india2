const mongoose = require("mongoose");
module.exports = mongoose.model("User", new mongoose.Schema({
  phone:      { type: String, required: true, unique: true },
  name:       String, email: String,
  role:       { type: String, enum: ["customer","driver","admin"], default: "customer" },
  avatar:     String,
  isActive:   { type: Boolean, default: true },
  isVerified: { type: Boolean, default: false },
  supabaseId: String,
}, { timestamps: true }));
