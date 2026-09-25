const mongoose = require("mongoose");
module.exports = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI || "mongodb://localhost:27017/namaste_india");
    console.log("MongoDB connected");
  } catch (e) {
    console.error("MongoDB error:", e.message);
    process.exit(1);
  }
};
