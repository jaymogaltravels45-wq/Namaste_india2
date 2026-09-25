// Transient server-side store for plain Ride Start OTPs.
// Only the SHA256 hash is persisted in Mongo (Booking.rideOtpHash);
// the plain OTP lives here until expiry so the customer app can display it.
const store = new Map(); // bookingId -> { otp, expiresAt }

function setRideOtp(bookingId, otp, ttlMs) {
  store.set(String(bookingId), { otp: String(otp), expiresAt: Date.now() + ttlMs });
}

function getRideOtp(bookingId) {
  const e = store.get(String(bookingId));
  if (!e) return null;
  if (Date.now() > e.expiresAt) { store.delete(String(bookingId)); return null; }
  return e.otp;
}

function clearRideOtp(bookingId) {
  store.delete(String(bookingId));
}

// Periodic cleanup of expired entries (unref'd so it never keeps the process alive).
setInterval(() => {
  const now = Date.now();
  for (const [k, v] of store) if (v.expiresAt < now) store.delete(k);
}, 5 * 60 * 1000).unref();

module.exports = { setRideOtp, getRideOtp, clearRideOtp };
