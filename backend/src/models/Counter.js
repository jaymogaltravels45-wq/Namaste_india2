const mongoose = require("mongoose");

// Atomic sequence counter (avoids the countDocuments() race condition where
// two concurrent inserts could compute the same booking number).
// Usage: Counter.getNextSequence("booking") -> 1, 2, 3, ...
const s = new mongoose.Schema({
  _id: { type: String, required: true },
  seq: { type: Number, default: 0 },
});

s.statics.getNextSequence = async function (name) {
  const doc = await this.findOneAndUpdate(
    { _id: name },
    { $inc: { seq: 1 } },
    { upsert: true, new: true }
  );
  return doc.seq;
};

module.exports = mongoose.model("Counter", s);
