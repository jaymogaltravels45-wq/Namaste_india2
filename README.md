# Namaste India - Full Stack Cab App

```
namaste_india/
├── flutter_app/    Flutter Mobile App (Customer + Driver)
├── backend/        Node.js + Express + MongoDB API
├── frontend/       React Admin Panel (Vite + Tailwind)
└── database/       MySQL Schema (optional SQL store)
```

## Quick Start

### 1 Backend
```bash
cd backend
cp .env.example .env   # fill EVERY value — server refuses to boot without them
# generate the password salt once (never change it afterwards):
openssl rand -hex 32   # → paste into USER_SALT
npm install
npm run dev            # http://localhost:5000
```

### 2 React Admin
```bash
cd frontend && npm install
npm run dev            # http://localhost:3000
# optional: VITE_API_URL=https://your-backend.onrender.com/api (in frontend/.env)
```
Login with the admin phone number via OTP (role `admin`).

### 3 Flutter
```bash
cd flutter_app
flutter pub get
# Supabase credentials are injected at build time — never hardcoded:
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co \
            --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

### 4 MySQL (optional)
```bash
mysql -u root -p < database/mysql_schema.sql
```

## Business Rules Implemented
| Rule | Where |
|------|-------|
| Outstation: fixed up to 100km, then per-km | fareCalculator.js + pricing.dart |
| Local: 3 packages per vehicle | fareCalculator.js + pricing.dart |
| Negative wallet = driver blocked | Driver.js pre-save, drivers.js route |
| TIME BUG FIX: pickupTime always stored | Booking.js schema required:true |
| Payment: Cash or UPI (company QR) | payments.js route |
| Atomic booking numbers (no race) | Counter model + Booking.js pre-save |

## Security (2026-09-25 hardening)

- **No secrets in client code.** MSG91 `widgetId`/`authToken` were removed from
  `flutter_app/lib/core/config/app_config.dart` (the Flutter app never used them —
  OTP always goes through the backend). Supabase URL + anon key are injected via
  `--dart-define`; if missing, the app shows a setup screen instead of crashing.
  _Exception to the "DO NOT MODIFY" list below — ordered by the user for hard security._
- **Secrets live only in `backend/.env`** (never committed). The server exits(1)
  on boot if `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `MONGODB_URI` or
  `USER_SALT` is missing. There is no default salt anymore.
- **Rate limiting:** 100 req/15min per IP globally; `/api/auth/send-otp` 5/15min,
  `/api/auth/verify-otp` 10/15min (blocks SMS bombing + OTP brute-force).
  Security headers via `helmet`.
- **CORS:** set `FRONTEND_URL` to the admin panel origin. If unset, the server
  logs a loud warning instead of silently allowing `*`.
- **MOCK_OTP:** local testing only (`MOCK_OTP=true` accepts `123456` for any phone).
  **NEVER true in production** — the server warns loudly on boot.
- **Input validation** on all booking/payment/driver/admin write endpoints (400s
  with clear messages); ownership checks (403) on ride start/complete/rating/payment.
- ⚠️ A previous `.env.example` contained **real keys** — rotate the Supabase
  service_role key and MSG91 auth key immediately (see `.env.example`).

## DO NOT MODIFY
- flutter_app/lib/services/auth/msg91_service.dart
- flutter_app/lib/services/auth/auth_service.dart
- flutter_app/lib/core/config/app_config.dart  ← security exception 2026-09-25 (see above)
