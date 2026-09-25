const mongoose = require("mongoose");
module.exports = mongoose.model("WalletTransaction", new mongoose.Schema({
  driverId:    { type: String, required: true }, // Driver Mongo _id as string
  type:        { type: String, enum: ["credit","debit","penalty","refund"], required: true },
  amount:      { type: Number, required: true },
  balance:     { type: Number, required: true },
  description: String,
  bookingId:   { type: String }, // Booking Mongo _id as string
  status:      { type: String, enum: ["pending","completed","failed"], default: "completed" },
}, { timestamps: true }));
