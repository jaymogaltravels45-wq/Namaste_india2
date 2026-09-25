const router = require("express").Router();
const User   = require("../models/User");
const { authMiddleware } = require("../middleware/auth");
router.get("/profile", authMiddleware, async (req, res) => {
  const u = await User.findById(req.user.id);
  res.json({ success: true, user: u });
});
router.patch("/profile", authMiddleware, async (req, res) => {
  const u = await User.findByIdAndUpdate(req.user.id, { name: req.body.name, email: req.body.email }, { new: true });
  res.json({ success: true, user: u });
});
module.exports = router;
