require("dotenv").config();

// ─── FAIL-FAST ENV VALIDATION (runs before any other require) ────────────────
// Security: never boot half-configured (missing secrets = broken auth/crypto).
const REQUIRED_ENV = ["SUPABASE_URL", "SUPABASE_SERVICE_ROLE_KEY", "MONGODB_URI", "USER_SALT"];
const missingEnv = REQUIRED_ENV.filter((k) => !process.env[k]);
if (missingEnv.length) {
  console.error("\n❌ FATAL: missing required environment variables: " + missingEnv.join(", "));
  console.error("   Copy backend/.env.example to backend/.env and fill in every value.\n");
  process.exit(1);
}
if (process.env.MOCK_OTP === "true") {
  console.warn("\n⚠️  WARNING: MOCK_OTP=true — OTP '123456' is accepted for ANY phone number.");
  console.warn("   This is for local testing ONLY. NEVER enable in production!\n");
}

const express   = require("express");
const helmet    = require("helmet");
const rateLimit = require("express-rate-limit");
const cors      = require("cors");
const morgan    = require("morgan");
const http      = require("http");
const { Server } = require("socket.io");

const connectMongo = require("./config/mongodb");

const app    = express();
const server = http.createServer(app);

// Minimal trust proxy: trust only the first hop (Render/Railway/Heroku LB).
// Required so express-rate-limit sees the real client IP behind a proxy.
app.set("trust proxy", 1);

// ─── Security headers ────────────────────────────────────────────────────────
app.use(helmet());

// ─── CORS ────────────────────────────────────────────────────────────────────
const FRONTEND_URL = process.env.FRONTEND_URL;
if (!FRONTEND_URL) {
  console.warn("\n⚠️  SECURITY WARNING: FRONTEND_URL is not set — CORS will allow ANY origin (*).");
  console.warn("   Set FRONTEND_URL to your admin panel URL, e.g. https://admin.namasteindia.app\n");
}
const corsOrigin = FRONTEND_URL || "*";
const io = new Server(server, {
  cors: { origin: corsOrigin, methods: ["GET","POST"] }
});
app.use(cors({ origin: corsOrigin, credentials: true }));

app.use(express.json({ limit: "10mb" }));
app.use(morgan("dev"));

// ─── Rate limiting ───────────────────────────────────────────────────────────
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, max: 100, // 100 req / 15 min / IP
  standardHeaders: true, legacyHeaders: false,
  message: { success: false, message: "Too many requests — slow down and try again later." },
});
// Socket.io polling/long-polling must not consume the HTTP rate budget.
app.use((req, res, next) =>
  req.path.startsWith("/socket.io") ? next() : globalLimiter(req, res, next)
);

// STRICT OTP limits: blocks SMS bombing + OTP brute-force.
const otpSendLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, max: 5, // 5 OTP sends / 15 min / IP
  standardHeaders: true, legacyHeaders: false,
  message: { success: false, message: "Too many OTP requests. Try again in 15 minutes." },
});
const otpVerifyLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, max: 10, // 10 OTP guesses / 15 min / IP
  standardHeaders: true, legacyHeaders: false,
  message: { success: false, message: "Too many OTP attempts. Try again in 15 minutes." },
});
app.use("/api/auth/send-otp", otpSendLimiter);
app.use("/api/auth/verify-otp", otpVerifyLimiter);

// Realtime socket setup
io.on("connection", socket => {
  console.log("Socket connected:", socket.id);
  socket.on("join_driver",   id => socket.join("driver_"   + id));
  socket.on("join_customer", id => socket.join("customer_" + id));
  socket.on("driver_location", d => io.to("booking_" + d.bookingId).emit("location_update", d));
  socket.on("disconnect", () => console.log("Socket disconnected:", socket.id));
});
app.set("io", io);

// API Routes
app.use("/api/auth",      require("./routes/auth"));
app.use("/api/fare",      require("./routes/fare"));
app.use("/api/bookings",  require("./routes/bookings"));
app.use("/api/drivers",   require("./routes/drivers"));
app.use("/api/payments",  require("./routes/payments"));
app.use("/api/admin",     require("./routes/admin"));
app.use("/api/customers", require("./routes/customers"));

app.get("/health", (req, res) => res.json({ status: "OK", app: "Namaste India API", time: new Date() }));
app.use((err, req, res, next) => res.status(err.status || 500).json({ success: false, message: err.message }));

const PORT = process.env.PORT || 5000;
server.listen(PORT, () => console.log("Namaste India API running on port " + PORT));
connectMongo();
