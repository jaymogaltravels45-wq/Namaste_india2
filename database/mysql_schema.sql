-- ============================================
--  Namaste India Cab App - MySQL Schema
-- ============================================
CREATE DATABASE IF NOT EXISTS namaste_india;
USE namaste_india;

CREATE TABLE IF NOT EXISTS users (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  phone VARCHAR(15) NOT NULL UNIQUE,
  name VARCHAR(100), email VARCHAR(100),
  role ENUM('customer','driver','admin') DEFAULT 'customer',
  avatar VARCHAR(255),
  is_active BOOLEAN DEFAULT TRUE,
  is_verified BOOLEAN DEFAULT FALSE,
  supabase_id VARCHAR(100),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS drivers (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  vehicle_type ENUM('hatchback','sedan','suv','innova') NOT NULL,
  vehicle_number VARCHAR(20) NOT NULL,
  vehicle_model VARCHAR(50),
  license_number VARCHAR(30),
  kyc_status ENUM('pending','verified','rejected') DEFAULT 'pending',
  is_online BOOLEAN DEFAULT FALSE,
  is_available BOOLEAN DEFAULT TRUE,
  wallet_balance DECIMAL(10,2) DEFAULT 0.00,
  -- RULE: wallet_balance < 0 => driver BLOCKED from accepting bookings
  can_accept_bookings BOOLEAN GENERATED ALWAYS AS (wallet_balance >= 0) VIRTUAL,
  lat DECIMAL(10,8) DEFAULT 0,
  lng DECIMAL(11,8) DEFAULT 0,
  rating DECIMAL(3,2) DEFAULT 0.00,
  total_trips INT DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS bookings (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  booking_number VARCHAR(30) NOT NULL UNIQUE,
  customer_id BIGINT UNSIGNED NOT NULL,
  driver_id BIGINT UNSIGNED,
  booking_type ENUM('outstation','local','round_trip','bid') NOT NULL,
  vehicle_type ENUM('hatchback','sedan','suv','innova') NOT NULL,
  pickup_address TEXT NOT NULL,
  pickup_lat DECIMAL(10,8), pickup_lng DECIMAL(11,8),
  drop_address TEXT,
  drop_lat DECIMAL(10,8), drop_lng DECIMAL(11,8),
  -- TIME BUG FIX: all times always stored, NEVER NULL for pickupTime
  pickup_time DATETIME NOT NULL,
  scheduled_time DATETIME,
  start_time DATETIME,
  end_time DATETIME,
  assigned_at DATETIME,
  distance_km DECIMAL(8,2) DEFAULT 0,
  local_package ENUM('4h/40km','8h/80km','12h/120km'),
  estimated_fare DECIMAL(10,2),
  final_fare DECIMAL(10,2),
  status ENUM('pending','driver_assigned','started','completed','cancelled') DEFAULT 'pending',
  payment_status ENUM('pending','cash','upi','refunded') DEFAULT 'pending',
  payment_method ENUM('cash','upi'),
  upi_transaction_id VARCHAR(100),
  otp VARCHAR(6),
  notes TEXT,
  rating TINYINT CHECK (rating BETWEEN 1 AND 5),
  review TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES users(id),
  FOREIGN KEY (driver_id) REFERENCES drivers(id)
);

CREATE TABLE IF NOT EXISTS wallet_transactions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  driver_id BIGINT UNSIGNED NOT NULL,
  type ENUM('credit','debit','penalty','refund') NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  balance DECIMAL(10,2) NOT NULL,
  description VARCHAR(255),
  booking_id BIGINT UNSIGNED,
  status ENUM('pending','completed','failed') DEFAULT 'completed',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (driver_id) REFERENCES drivers(id),
  FOREIGN KEY (booking_id) REFERENCES bookings(id)
);

CREATE TABLE IF NOT EXISTS fare_config (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  vehicle_type ENUM('hatchback','sedan','suv','innova') NOT NULL UNIQUE,
  base_fixed_100 DECIMAL(10,2) NOT NULL COMMENT 'Fixed rate for 0-100km',
  per_km_rate    DECIMAL(6,2)  NOT NULL COMMENT 'Per km rate above 100km',
  local_4h_40km  DECIMAL(10,2) NOT NULL,
  local_8h_80km  DECIMAL(10,2) NOT NULL,
  local_12h_120km DECIMAL(10,2) NOT NULL,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

INSERT INTO fare_config VALUES
  (1,'hatchback',1500,10, 900, 1500,2200),
  (2,'sedan',    1500,12,1200, 1900,2600),
  (3,'suv',      2000,14,1500, 2300,3100),
  (4,'innova',   3000,22,2000, 3000,4000)
ON DUPLICATE KEY UPDATE per_km_rate=VALUES(per_km_rate);

CREATE TABLE IF NOT EXISTS kyc_documents (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  driver_id BIGINT UNSIGNED NOT NULL,
  doc_type ENUM('aadhaar','pan','license','vehicle_rc','insurance') NOT NULL,
  doc_url VARCHAR(500) NOT NULL,
  status ENUM('pending','approved','rejected') DEFAULT 'pending',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (driver_id) REFERENCES drivers(id)
);

SELECT 'Namaste India MySQL schema ready!' AS status;
