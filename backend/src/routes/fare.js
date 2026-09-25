const router = require("express").Router();
const { calcOutstation, calcLocal, VEHICLES, LOCAL } = require("../services/fareCalculator");

router.post("/outstation", (req, res) => {
  try { res.json({ success: true, ...calcOutstation(req.body.vehicleType, parseFloat(req.body.distanceKm)) }); }
  catch (e) { res.status(400).json({ success: false, message: e.message }); }
});
router.post("/local", (req, res) => {
  try { res.json({ success: true, ...calcLocal(req.body.vehicleType, req.body.localPackage) }); }
  catch (e) { res.status(400).json({ success: false, message: e.message }); }
});
router.get("/rates", (req, res) => res.json({ success: true, vehicleRates: VEHICLES, localRates: LOCAL }));
module.exports = router;
