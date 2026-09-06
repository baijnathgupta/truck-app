CREATE TABLE IF NOT EXISTS users (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  phone VARCHAR(30) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('OWNER','DRIVER','ADMIN') NOT NULL DEFAULT 'OWNER',
  owner_id INT UNSIGNED NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_users_owner FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS trucks (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  owner_id INT UNSIGNED NULL,
  number VARCHAR(40) NOT NULL,
  model VARCHAR(80),
  capacity VARCHAR(50),
  status VARCHAR(30) DEFAULT 'AVAILABLE',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_trucks_owner FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS trips (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  owner_id INT UNSIGNED NOT NULL,
  driver_id INT UNSIGNED NULL,
  truck_id INT UNSIGNED NULL,
  trip_number VARCHAR(50) NOT NULL UNIQUE,
  source VARCHAR(150) NOT NULL,
  destination VARCHAR(150) NOT NULL,
  goods_type VARCHAR(100),
  weight VARCHAR(50),
  freight DECIMAL(12,2) DEFAULT 0,
  advance DECIMAL(12,2) DEFAULT 0,
  status VARCHAR(30) DEFAULT 'ASSIGNED',
  start_date DATE NULL,
  expected_delivery DATE NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_trips_owner FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_trips_driver FOREIGN KEY (driver_id) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT fk_trips_truck FOREIGN KEY (truck_id) REFERENCES trucks(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS expense_categories (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(80) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS expenses (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  trip_id INT UNSIGNED NULL,
  created_by INT UNSIGNED NULL,
  category_id INT UNSIGNED NULL,
  amount DECIMAL(12,2) NOT NULL,
  description TEXT,
  status ENUM('PENDING','APPROVED','REJECTED') DEFAULT 'PENDING',
  rejection_reason TEXT,
  receipt_url TEXT,
  voice_text TEXT,
  voice_url TEXT,
  approved_by INT UNSIGNED NULL,
  approved_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_expenses_trip FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE,
  CONSTRAINT fk_expenses_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT fk_expenses_category FOREIGN KEY (category_id) REFERENCES expense_categories(id) ON DELETE SET NULL,
  CONSTRAINT fk_expenses_approved_by FOREIGN KEY (approved_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

INSERT IGNORE INTO expense_categories(name) VALUES
('Diesel'),('Toll'),('Bilty'),('Commission'),('Loading'),('Unloading'),
('Food'),('Repair'),('Maintenance'),('Parking'),('Other');
