const router   = require("express").Router();
const mongoose = require("mongoose");
const crypto   = require("crypto");
const Booking  = require("../models/Booking");
const Bid      = require("../models/Bid");
const Driver   = require("../models/Driver");
const WalletTransaction = require("../models/Wallet");
const { hasActivePremium } = require("./subscriptions");
const { setRideOtp, getRideOtp, clearRideOtp } = require("../services/rideOtpStore");
const { sendPushToUser } = require("../services/push");
const { attachParties } = require("../services/partyInfo");
const { authMiddleware } = require("../middleware/auth");
const { calcOutstation, calcLocal } = require("../services/fareCalculator");
const moment = require("moment-timezone");

// ─── Validation helpers ─────────────────────────────────────────────────────
const BOOKING_TYPES  = ["outstation", "local", "round_trip", "bid"];
const VEHICLE_TYPES  = ["hatchback", "sedan", "suv", "innova"];
const LOCAL_PACKAGES = ["4h/40km", "8h/80km", "12h/120km"];
const validId = (id) => mongoose.Types.ObjectId.isValid(id);

/**
 * Load a booking and verify the caller is its assigned driver.
 * Returns { driver, booking } or { err: { status, message } }.
 */
async function driverBookingOrError(userId, bookingId) {
  const driver = await Driver.findOne({ userId });
  if (!driver) return { err: { status: 403, message: "Drivers only" } };
  if (!validId(bookingId)) return { err: { status: 400, message: "Invalid booking id" } };
  const booking = await Booking.findById(bookingId);
  if (!booking) return { err: { status: 404, message: "Booking not found" } };
  if (!booking.driverId || String(booking.driverId) !== String(driver.userId))
    return { err: { status: 403, message: "Not your booking" } };
  return { driver, booking };
}

// ─── Create booking (with input validation) ─────────────────────────────────
router.post("/", authMiddleware, async (req, res) => {
  try {
    const { bookingType, vehicleType, pickup, drop, pickupTime, distanceKm, localPackage } = req.body || {};

    if (!BOOKING_TYPES.includes(bookingType))
      return res.status(400).json({ success: false, message: "bookingType must be one of: " + BOOKING_TYPES.join(", ") });
    if (!VEHICLE_TYPES.includes(vehicleType))
      return res.status(400).json({ success: false, message: "vehicleType must be one of: " + VEHICLE_TYPES.join(", ") });
    if (!pickup || typeof pickup.address !== "string" || !pickup.address.trim())
      return res.status(400).json({ success: false, message: "pickup.address is required" });

    let km = 0;
    if (bookingType === "local") {
      if (!LOCAL_PACKAGES.includes(localPackage))
        return res.status(400).json({ success: false, message: "localPackage must be one of: " + LOCAL_PACKAGES.join(", ") });
    } else {
      km = Number(distanceKm || 0);
      if (!Number.isFinite(km) || km < 0)
        return res.status(400).json({ success: false, message: "distanceKm must be a valid non-negative number" });
    }

    let when = new Date();
    if (pickupTime) {
      when = new Date(pickupTime);
      if (isNaN(when.getTime()))
        return res.status(400).json({ success: false, message: "pickupTime must be a valid date" });
    }

    const fare = bookingType === "local" ? calcLocal(vehicleType, localPackage) : calcOutstation(vehicleType, km);

    // Bid bookings: customer posts their own price, booking opens for driver bids.
    // (No minimum-distance rule — explicitly excluded from scope.)
    let status = "pending";
    let customerBid;
    let estFare = fare.totalFare;
    if (bookingType === "bid") {
      customerBid = Number(req.body.customerBid);
      if (!Number.isFinite(customerBid) || customerBid <= 0)
        return res.status(400).json({ success: false, message: "customerBid must be a positive number for bid bookings" });
      status = "open_for_bids";
      estFare = customerBid;
    }

    const booking = await Booking.create({
      customerId: req.user.id, bookingType, vehicleType, pickup, drop,
      // TIME BUG FIX: always set pickupTime
      pickupTime: when,
      distanceKm: km, localPackage,
      estimatedFare: estFare, customerBid, status,
      otp: Math.floor(100000 + Math.random() * 900000).toString(),
    });
    req.app.get("io").emit("new_booking", { booking });
    res.status(201).json({ success: true, booking });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

// ─── Available pending bookings (drivers only, latest 30) ───────────────────
router.get("/available", authMiddleware, async (req, res) => {
  try {
    const driver = await Driver.findOne({ userId: req.user.id });
    if (!driver) return res.status(403).json({ success: false, message: "Drivers only" });
    const bookings = await Booking.find({ status: { $in: ["pending", "open_for_bids"] }, vehicleType: driver.vehicleType })
      .sort({ createdAt: -1 }).limit(30).lean();
    await attachParties(bookings);
    res.json({ success: true, bookings });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

// ─── Driver's own bookings ───────────────────────────────────────────────────
router.get("/driver/my", authMiddleware, async (req, res) => {
  try {
    const driver = await Driver.findOne({ userId: req.user.id });
    if (!driver) return res.status(403).json({ success: false, message: "Drivers only" });
    const bookings = await Booking.find({ driverId: driver.userId })
      .sort({ createdAt: -1 }).limit(50).lean();
    await attachParties(bookings);
    res.json({ success: true, bookings });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

// ─── Customer's own bookings ─────────────────────────────────────────────────
router.get("/customer/my", authMiddleware, async (req, res) => {
  const b = await Booking.find({ customerId: req.user.id }).sort({ createdAt: -1 }).limit(20).lean();
  await attachParties(b);
  res.json({ success: true, bookings: b });
});

// Get booking by id - TIME BUG FIX: always return all times in IST
router.get("/:id", authMiddleware, async (req, res) => {
  try {
    if (!validId(req.params.id))
      return res.status(400).json({ success: false, message: "Invalid booking id" });
    const b = await Booking.findById(req.params.id).lean();
    if (!b) return res.status(404).json({ success: false, message: "Not found" });
    await attachParties([b]);
    const IST = "Asia/Kolkata";
    b.pickupTimeIST  = b.pickupTime  ? moment(b.pickupTime).tz(IST).format("hh:mm A, DD MMM") : "N/A";
    b.startTimeIST   = b.startTime   ? moment(b.startTime).tz(IST).format("hh:mm A") : null;
    b.endTimeIST     = b.endTime     ? moment(b.endTime).tz(IST).format("hh:mm A") : null;
    b.assignedAtIST  = b.assignedAt  ? moment(b.assignedAt).tz(IST).format("hh:mm A") : null;
    // Ride Start OTP: shown ONLY to the booking's customer while driver is arrived.
    if (String(b.customerId) === String(req.user.id) && b.status === "arrived") {
      const rideOtp = getRideOtp(b._id);
      if (rideOtp) b.rideOtp = rideOtp;
    }
    res.json({ success: true, booking: b });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

// Accept booking - NEGATIVE BALANCE CHECK
router.post("/:id/accept", authMiddleware, async (req, res) => {
  try {
    const driver = await Driver.findOne({ userId: req.user.id });
    if (!driver) return res.status(404).json({ success: false, message: "Driver not found" });
    // RULE: Block if negative balance
    if (driver.walletBalance < 0) {
      return res.status(403).json({
        success: false,
        message: "Wallet balance Rs." + driver.walletBalance + " - negative. Add money first.",
        walletBalance: driver.walletBalance,
      });
    }
    if (!validId(req.params.id))
      return res.status(400).json({ success: false, message: "Invalid booking id" });
    const booking = await Booking.findOneAndUpdate(
      { _id: req.params.id, status: "pending" }, // only pending bookings can be accepted
      { driverId: driver.userId, status: "driver_assigned", assignedAt: new Date() },
      { new: true });
    if (!booking)
      return res.status(400).json({ success: false, message: "Booking not available (already taken or invalid)" });
    req.app.get("io").to("customer_" + booking.customerId).emit("booking_accepted", { booking, driver });
    res.json({ success: true, booking });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

// ─── Submit / update own counter-bid (driver only) ───────────────────────────
// Only on bookings with status "open_for_bids". Blocked on negative wallet.
router.post("/:id/bids", authMiddleware, async (req, res) => {
  try {
    const driver = await Driver.findOne({ userId: req.user.id });
    if (!driver) return res.status(403).json({ success: false, message: "Drivers only" });
    if (driver.walletBalance < 0) {
      return res.status(403).json({
        success: false,
        message: "Wallet balance Rs." + driver.walletBalance + " - negative. Add money first.",
        walletBalance: driver.walletBalance,
      });
    }
    if (!validId(req.params.id))
      return res.status(400).json({ success: false, message: "Invalid booking id" });
    const booking = await Booking.findById(req.params.id);
    if (!booking) return res.status(404).json({ success: false, message: "Booking not found" });
    if (booking.status !== "open_for_bids")
      return res.status(400).json({ success: false, message: "Booking is not open for bids" });

    const amount = Number(req.body?.amount);
    if (!Number.isFinite(amount) || amount <= 0)
      return res.status(400).json({ success: false, message: "amount must be a positive number" });
    const message = req.body?.message;
    if (message !== undefined && (typeof message !== "string" || message.length > 500))
      return res.status(400).json({ success: false, message: "message must be text up to 500 characters" });

    // One bid slot per driver per booking — resubmitting updates the counter-bid.
    const bid = await Bid.findOneAndUpdate(
      { bookingId: booking._id, driverId: driver.userId },
      { $set: { amount, message, status: "pending" } },
      { new: true, upsert: true }
    );
    sendPushToUser(booking.customerId, "New bid received \u{1F695}",
      `Driver ${driver.name} bid Rs.${amount} on your trip.`,
      { type: "new_bid", bookingId: String(booking._id), bidId: String(bid._id) }).catch(() => {});
    req.app.get("io").to("customer_" + booking.customerId).emit("new_bid", { booking, bid });
    res.status(201).json({ success: true, bid });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

// ─── List bids on a booking (customer, own booking) ──────────────────────────
router.get("/:id/bids", authMiddleware, async (req, res) => {
  try {
    if (!validId(req.params.id))
      return res.status(400).json({ success: false, message: "Invalid booking id" });
    const booking = await Booking.findById(req.params.id);
    if (!booking) return res.status(404).json({ success: false, message: "Booking not found" });
    if (String(booking.customerId) !== String(req.user.id))
      return res.status(403).json({ success: false, message: "You can only view bids on your own bookings" });
    const bids = await Bid.find({ bookingId: booking._id }).sort({ amount: 1 }).lean();
    for (const b of bids) {
      const d = await Driver.findOne({ userId: b.driverId }).lean();
      b.driver = d ? {
        name: d.name, rating: d.rating, vehicleType: d.vehicleType,
        vehicleNumber: d.vehicleNumber, vehicleModel: d.vehicleModel, experience: d.experience,
      } : null;
    }
    res.json({ success: true, bids });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

// ─── Driver arrived: generate 4-digit Ride Start OTP (driver only) ───────────
router.post("/:id/arrived", authMiddleware, async (req, res) => {
  try {
    const { err, booking } = await driverBookingOrError(req.user.id, req.params.id);
    if (err) return res.status(err.status).json({ success: false, message: err.message });
    if (!["driver_assigned", "confirmed"].includes(booking.status))
      return res.status(400).json({ success: false, message: "Ride can only be marked arrived from 'driver_assigned' or 'confirmed' state" });
    const otp = String(crypto.randomInt(1000, 10000)); // 4-digit, crypto-secure
    booking.rideOtpHash = crypto.createHash("sha256").update(otp).digest("hex");
    booking.rideOtpExpires = new Date(Date.now() + 15 * 60 * 1000); // 15 min
    booking.status = "arrived";
    await booking.save();
    setRideOtp(booking._id, otp, 15 * 60 * 1000);
    req.app.get("io").to("customer_" + booking.customerId).emit("driver_arrived", { bookingId: booking._id });
    res.json({ success: true, booking, message: "Ask the customer for the ride OTP shown in their app to start the trip" });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

// ─── Verify Ride Start OTP (driver only) → trip goes ongoing ─────────────────
router.post("/:id/verify-start", authMiddleware, async (req, res) => {
  try {
    const { err, booking } = await driverBookingOrError(req.user.id, req.params.id);
    if (err) return res.status(err.status).json({ success: false, message: err.message });
    if (booking.status !== "arrived")
      return res.status(400).json({ success: false, message: "Mark arrived first to generate a ride OTP" });
    const { otp } = req.body || {};
    if (otp === undefined || otp === null || String(otp).trim() === "")
      return res.status(400).json({ success: false, message: "otp is required" });
    if (!booking.rideOtpHash || !booking.rideOtpExpires || booking.rideOtpExpires < new Date())
      return res.status(400).json({ success: false, message: "Ride OTP expired. Mark arrived again." });
    const hash = crypto.createHash("sha256").update(String(otp).trim()).digest("hex");
    if (hash !== booking.rideOtpHash)
      return res.status(400).json({ success: false, message: "Wrong OTP" });
    booking.status = "ongoing";
    booking.startTime = new Date();
    booking.rideOtpHash = undefined;
    booking.rideOtpExpires = undefined;
    await booking.save();
    clearRideOtp(booking._id);
    req.app.get("io").to("customer_" + booking.customerId).emit("ride_started", { bookingId: booking._id });
    res.json({ success: true, booking });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

// ─── Start ride (driver only, must own booking) ───────────────────────────────
router.post("/:id/start", authMiddleware, async (req, res) => {
  try {
    const { err, booking } = await driverBookingOrError(req.user.id, req.params.id);
    if (err) return res.status(err.status).json({ success: false, message: err.message });
    if (!["driver_assigned", "confirmed"].includes(booking.status))
      return res.status(400).json({ success: false, message: "Ride can only start from 'driver_assigned' or 'confirmed' state" });
    booking.status = "started";
    booking.startTime = new Date();
    await booking.save();
    req.app.get("io").to("customer_" + booking.customerId).emit("ride_started", { bookingId: booking._id });
    res.json({ success: true, booking });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

// ─── Complete ride (driver only, must own booking) ───────────────────────────
router.post("/:id/complete", authMiddleware, async (req, res) => {
  try {
    const { err, booking } = await driverBookingOrError(req.user.id, req.params.id);
    if (err) return res.status(err.status).json({ success: false, message: err.message });
    if (!["started", "ongoing"].includes(booking.status))
      return res.status(400).json({ success: false, message: "Ride can only complete from 'started' or 'ongoing' state" });
    booking.status = "completed";
    booking.endTime = new Date();
    if (booking.finalFare == null) booking.finalFare = booking.estimatedFare;
    await booking.save();

    // Commission: 0 with active premium, else 5% of fare (rounded).
    const driver = await Driver.findOne({ userId: req.user.id });
    const fare = booking.finalFare != null ? booking.finalFare : (booking.estimatedFare || 0);
    const premium = await hasActivePremium(req.user.id);
    const commission = premium ? 0 : Math.round(fare * 0.05);
    if (commission > 0 && driver) {
      driver.walletBalance -= commission;
      await driver.save(); // pre-save updates canAcceptBookings
      await WalletTransaction.create({
        driverId: driver._id.toString(), type: "commission", amount: commission,
        balance: driver.walletBalance, bookingId: booking._id.toString(),
        description: `5% commission on booking ${booking.bookingNumber || booking._id}`,
      });
    }
    clearRideOtp(booking._id);

    sendPushToUser(booking.customerId, "Trip completed ✅",
      `Fare Rs.${fare}. Thanks for riding with Namaste India!`,
      { type: "trip_completed", bookingId: String(booking._id), fare: String(fare) }).catch(() => {});
    req.app.get("io").to("customer_" + booking.customerId).emit("ride_completed", { bookingId: booking._id, fare: booking.finalFare });
    res.json({ success: true, booking, commission });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

// ─── Rate ride (customer only, must own booking, only when completed) ─────────
router.patch("/:id/rating", authMiddleware, async (req, res) => {
  try {
    if (!validId(req.params.id))
      return res.status(400).json({ success: false, message: "Invalid booking id" });
    const { rating, review } = req.body || {};
    const r = Number(rating);
    if (!Number.isInteger(r) || r < 1 || r > 5)
      return res.status(400).json({ success: false, message: "rating must be an integer from 1 to 5" });
    if (review !== undefined && (typeof review !== "string" || review.length > 500))
      return res.status(400).json({ success: false, message: "review must be text up to 500 characters" });

    const booking = await Booking.findById(req.params.id);
    if (!booking) return res.status(404).json({ success: false, message: "Booking not found" });
    if (String(booking.customerId) !== String(req.user.id))
      return res.status(403).json({ success: false, message: "You can only rate your own bookings" });
    if (booking.status !== "completed")
      return res.status(400).json({ success: false, message: "You can only rate completed rides" });

    booking.rating = r;
    if (review !== undefined) booking.review = review;
    await booking.save();
    res.json({ success: true, booking });
  } catch (e) { res.status(500).json({ success: false, message: e.message }); }
});

module.exports = router;
