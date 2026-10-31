CREATE DATABASE IF NOT EXISTS hotel_reservations
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE hotel_reservations;

CREATE TABLE hotel_franchises (
  franchise_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  franchise_name VARCHAR(100) NOT NULL,
  contact_email VARCHAR(100),
  contact_number VARCHAR(30),
  address VARCHAR(255) NOT NULL,
  CONSTRAINT uq_franchises_name UNIQUE (franchise_name)
) ENGINE = InnoDB;

CREATE TABLE hotels (
  hotel_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  city VARCHAR(80) NOT NULL,
  address VARCHAR(255) NOT NULL,
  state VARCHAR(80),
  country VARCHAR(80) NOT NULL DEFAULT 'India',
  email VARCHAR(255),
  phone VARCHAR(30),
  rating TINYINT UNSIGNED,
  franchise_id BIGINT UNSIGNED NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uq_hotels_name_city UNIQUE (name, city),
  CONSTRAINT fk_hotels_franchise FOREIGN KEY (franchise_id) REFERENCES hotel_franchises (franchise_id),
  CONSTRAINT chk_hotels_rating CHECK (rating IS NULL OR rating BETWEEN 1 AND 5)
) ENGINE = InnoDB;

CREATE TABLE room_types (
  room_type_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(30) NOT NULL,
  name VARCHAR(80) NOT NULL,
  capacity TINYINT UNSIGNED NOT NULL,
  base_rate DECIMAL(10, 2) NOT NULL,
  CONSTRAINT uq_room_types_code UNIQUE (code),
  CONSTRAINT chk_room_types_capacity CHECK (capacity > 0),
  CONSTRAINT chk_room_types_rate CHECK (base_rate >= 0)
) ENGINE = InnoDB;

CREATE TABLE rooms (
  room_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  hotel_id BIGINT UNSIGNED NOT NULL,
  room_type_id BIGINT UNSIGNED NOT NULL,
  room_number VARCHAR(10) NOT NULL,
  floor_number SMALLINT,
  status ENUM('AVAILABLE', 'MAINTENANCE', 'OUT_OF_SERVICE') NOT NULL DEFAULT 'AVAILABLE',
  CONSTRAINT uq_rooms_hotel_number UNIQUE (hotel_id, room_number),
  CONSTRAINT fk_rooms_hotel FOREIGN KEY (hotel_id) REFERENCES hotels (hotel_id),
  CONSTRAINT fk_rooms_type FOREIGN KEY (room_type_id) REFERENCES room_types (room_type_id)
) ENGINE = InnoDB;

CREATE TABLE hotel_room_types (
  hotel_id BIGINT UNSIGNED NOT NULL,
  room_type_id BIGINT UNSIGNED NOT NULL,
  total_rooms SMALLINT UNSIGNED NOT NULL,
  overbooking_percent DECIMAL(5, 2) NOT NULL DEFAULT 0,
  PRIMARY KEY (hotel_id, room_type_id),
  CONSTRAINT fk_hrt_hotel FOREIGN KEY (hotel_id) REFERENCES hotels (hotel_id),
  CONSTRAINT fk_hrt_room_type FOREIGN KEY (room_type_id) REFERENCES room_types (room_type_id),
  CONSTRAINT chk_hrt_total_rooms CHECK (total_rooms > 0),
  CONSTRAINT chk_hrt_overbooking CHECK (overbooking_percent BETWEEN 0 AND 100)
) ENGINE = InnoDB;

CREATE TABLE guests (
  guest_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  full_name VARCHAR(120) NOT NULL,
  email VARCHAR(255) NOT NULL,
  phone VARCHAR(30),
  address VARCHAR(255),
  city VARCHAR(80),
  country VARCHAR(80),
  id_proof_type VARCHAR(50),
  id_proof_number VARCHAR(80),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uq_guests_email UNIQUE (email)
) ENGINE = InnoDB;

CREATE TABLE users (
  user_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  hotel_id BIGINT UNSIGNED NULL,
  email VARCHAR(255) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('ADMIN', 'MANAGER', 'FRONT_DESK') NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uq_users_email UNIQUE (email),
  CONSTRAINT fk_users_hotel FOREIGN KEY (hotel_id) REFERENCES hotels (hotel_id)
) ENGINE = InnoDB;

CREATE TABLE inventory (
  hotel_id BIGINT UNSIGNED NOT NULL,
  room_type_id BIGINT UNSIGNED NOT NULL,
  stay_date DATE NOT NULL,
  total_rooms SMALLINT UNSIGNED NOT NULL,
  booked_rooms SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (hotel_id, room_type_id, stay_date),
  CONSTRAINT fk_inventory_hotel_type FOREIGN KEY (hotel_id, room_type_id)
    REFERENCES hotel_room_types (hotel_id, room_type_id),
  CONSTRAINT chk_inventory_booked CHECK (booked_rooms <= total_rooms * 2)
) ENGINE = InnoDB;

CREATE TABLE bookings (
  booking_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  confirmation_code CHAR(8) NOT NULL,
  guest_id BIGINT UNSIGNED NOT NULL,
  hotel_id BIGINT UNSIGNED NOT NULL,
  room_type_id BIGINT UNSIGNED NOT NULL,
  check_in DATE NOT NULL,
  check_out DATE NOT NULL,
  status ENUM('HELD', 'CONFIRMED', 'CANCELLED', 'WALKED', 'NO_SHOW') NOT NULL DEFAULT 'HELD',
  amount DECIMAL(10, 2) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  cancelled_at TIMESTAMP NULL,
  CONSTRAINT uq_bookings_confirmation UNIQUE (confirmation_code),
  CONSTRAINT fk_bookings_guest FOREIGN KEY (guest_id) REFERENCES guests (guest_id),
  CONSTRAINT fk_bookings_hotel_type FOREIGN KEY (hotel_id, room_type_id)
    REFERENCES hotel_room_types (hotel_id, room_type_id),
  CONSTRAINT chk_bookings_dates CHECK (check_out > check_in),
  CONSTRAINT chk_bookings_amount CHECK (amount >= 0),
  INDEX idx_bookings_hotel_status (hotel_id, status),
  INDEX idx_bookings_stay (hotel_id, room_type_id, check_in, check_out)
) ENGINE = InnoDB;

CREATE TABLE payments (
  payment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  booking_id BIGINT UNSIGNED NOT NULL,
  amount DECIMAL(10, 2) NOT NULL,
  status ENUM('PENDING', 'PAID', 'REFUNDED') NOT NULL DEFAULT 'PENDING',
  paid_at TIMESTAMP NULL,
  CONSTRAINT fk_payments_booking FOREIGN KEY (booking_id) REFERENCES bookings (booking_id),
  CONSTRAINT chk_payments_amount CHECK (amount > 0)
) ENGINE = InnoDB;

CREATE TABLE overbookings (
  overbooking_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  overbooking_date DATE NOT NULL,
  stay_date DATE NOT NULL,
  hotel_id BIGINT UNSIGNED NOT NULL,
  room_type_id BIGINT UNSIGNED NOT NULL,
  total_rooms SMALLINT UNSIGNED NOT NULL,
  reserved_rooms SMALLINT UNSIGNED NOT NULL,
  overbooking_limit SMALLINT UNSIGNED NOT NULL,
  overbooked_rooms SMALLINT UNSIGNED NOT NULL,
  status ENUM('OPEN', 'RESOLVED') NOT NULL DEFAULT 'OPEN',
  CONSTRAINT fk_overbookings_hotel_type FOREIGN KEY (hotel_id, room_type_id)
    REFERENCES hotel_room_types (hotel_id, room_type_id),
  CONSTRAINT chk_overbookings_count CHECK (reserved_rooms >= total_rooms),
  INDEX idx_overbookings_hotel_date (hotel_id, stay_date)
) ENGINE = InnoDB;

CREATE TABLE auth_sessions (
  session_id CHAR(64) PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  expires_at DATETIME NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_sessions_user FOREIGN KEY (user_id) REFERENCES users (user_id),
  INDEX idx_sessions_expiry (expires_at)
) ENGINE = InnoDB;

DELIMITER //

CREATE TRIGGER trg_bookings_validate_dates
BEFORE INSERT ON bookings
FOR EACH ROW
BEGIN
  IF NEW.check_in < CURRENT_DATE() THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Check-in cannot be in the past';
  END IF;
  IF NEW.check_out <= NEW.check_in THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Check-out must be after check-in';
  END IF;
END//

CREATE TRIGGER trg_bookings_validate_update
BEFORE UPDATE ON bookings
FOR EACH ROW
BEGIN
  IF NEW.status = 'CANCELLED' AND OLD.status = 'CANCELLED' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Booking is already cancelled';
  END IF;
END//

CREATE VIEW v_room_availability AS
SELECT
  i.hotel_id,
  h.name AS hotel_name,
  i.room_type_id,
  rt.name AS room_type_name,
  i.stay_date,
  i.total_rooms,
  i.booked_rooms,
  ROUND((i.booked_rooms / NULLIF(i.total_rooms, 0)) * 100, 2) AS occupancy_percent,
  FLOOR(i.total_rooms * (1 + hrt.overbooking_percent / 100)) - i.booked_rooms AS remaining_sellable
FROM inventory i
JOIN hotels h ON h.hotel_id = i.hotel_id
JOIN room_types rt ON rt.room_type_id = i.room_type_id
JOIN hotel_room_types hrt
  ON hrt.hotel_id = i.hotel_id AND hrt.room_type_id = i.room_type_id//

CREATE VIEW v_overbooking_risk AS
SELECT
  hotel_id,
  room_type_id,
  stay_date,
  total_rooms,
  booked_rooms,
  ROUND((booked_rooms / NULLIF(total_rooms, 0)) * 100, 2) AS occupancy_percent,
  CASE
    WHEN booked_rooms >= total_rooms THEN 'OVERBOOKED'
    WHEN booked_rooms >= total_rooms * 0.9 THEN 'HIGH'
    ELSE 'NORMAL'
  END AS risk_level
FROM inventory//

CREATE PROCEDURE sp_initialize_inventory(IN p_from DATE, IN p_to DATE)
BEGIN
  DECLARE v_date DATE;
  IF p_to <= p_from THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Inventory end date must be after start date';
  END IF;
  SET v_date = p_from;
  WHILE v_date < p_to DO
    INSERT INTO inventory (hotel_id, room_type_id, stay_date, total_rooms)
    SELECT hotel_id, room_type_id, v_date, total_rooms
    FROM hotel_room_types
    ON DUPLICATE KEY UPDATE total_rooms = VALUES(total_rooms);
    SET v_date = DATE_ADD(v_date, INTERVAL 1 DAY);
  END WHILE;
END//

CREATE PROCEDURE sp_create_booking(
  IN p_confirmation_code CHAR(8),
  IN p_guest_id BIGINT UNSIGNED,
  IN p_hotel_id BIGINT UNSIGNED,
  IN p_room_type_id BIGINT UNSIGNED,
  IN p_check_in DATE,
  IN p_check_out DATE,
  IN p_amount DECIMAL(10, 2)
)
BEGIN
  DECLARE v_date DATE;
  DECLARE v_allowed INT;
  DECLARE v_booked INT;
  DECLARE v_total INT;
  DECLARE v_exists INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  IF p_check_out <= p_check_in THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid stay dates';
  END IF;

  START TRANSACTION;
  SELECT COUNT(*) INTO v_exists
  FROM hotel_room_types
  WHERE hotel_id = p_hotel_id AND room_type_id = p_room_type_id;
  IF v_exists = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Room type is not available at this hotel';
  END IF;

  SET v_date = p_check_in;
  WHILE v_date < p_check_out DO
    INSERT INTO inventory (hotel_id, room_type_id, stay_date, total_rooms)
    SELECT p_hotel_id, p_room_type_id, v_date, total_rooms
    FROM hotel_room_types
    WHERE hotel_id = p_hotel_id AND room_type_id = p_room_type_id
    ON DUPLICATE KEY UPDATE total_rooms = VALUES(total_rooms);

    SELECT i.booked_rooms, i.total_rooms,
           FLOOR(i.total_rooms * (1 + hrt.overbooking_percent / 100))
      INTO v_booked, v_total, v_allowed
    FROM inventory i
    JOIN hotel_room_types hrt
      ON hrt.hotel_id = i.hotel_id AND hrt.room_type_id = i.room_type_id
    WHERE i.hotel_id = p_hotel_id
      AND i.room_type_id = p_room_type_id
      AND i.stay_date = v_date
    FOR UPDATE;

    IF v_booked >= v_allowed THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No sellable inventory for one or more stay dates';
    END IF;
    UPDATE inventory
    SET booked_rooms = booked_rooms + 1
    WHERE hotel_id = p_hotel_id AND room_type_id = p_room_type_id AND stay_date = v_date;
    IF v_booked + 1 > v_total THEN
      INSERT INTO overbookings (
        overbooking_date, stay_date, hotel_id, room_type_id,
        total_rooms, reserved_rooms, overbooking_limit, overbooked_rooms
      ) VALUES (
        CURRENT_DATE(), v_date, p_hotel_id, p_room_type_id,
        v_total, v_booked + 1, v_allowed, (v_booked + 1) - v_total
      );
    END IF;
    SET v_date = DATE_ADD(v_date, INTERVAL 1 DAY);
  END WHILE;

  INSERT INTO bookings (
    confirmation_code, guest_id, hotel_id, room_type_id, check_in, check_out, status, amount
  ) VALUES (
    p_confirmation_code, p_guest_id, p_hotel_id, p_room_type_id, p_check_in, p_check_out, 'CONFIRMED', p_amount
  );
  COMMIT;
  SELECT LAST_INSERT_ID() AS booking_id, p_confirmation_code AS confirmation_code;
END//

CREATE PROCEDURE sp_cancel_booking(IN p_booking_id BIGINT UNSIGNED)
BEGIN
  DECLARE v_hotel_id BIGINT UNSIGNED;
  DECLARE v_room_type_id BIGINT UNSIGNED;
  DECLARE v_check_in DATE;
  DECLARE v_check_out DATE;
  DECLARE v_status VARCHAR(20);
  DECLARE v_date DATE;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SELECT hotel_id, room_type_id, check_in, check_out, status
    INTO v_hotel_id, v_room_type_id, v_check_in, v_check_out, v_status
  FROM bookings WHERE booking_id = p_booking_id FOR UPDATE;
  IF v_status IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Booking not found';
  END IF;
  IF v_status IN ('CANCELLED', 'WALKED') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Booking cannot be cancelled';
  END IF;

  SET v_date = v_check_in;
  WHILE v_date < v_check_out DO
    UPDATE inventory
    SET booked_rooms = booked_rooms - 1
    WHERE hotel_id = v_hotel_id AND room_type_id = v_room_type_id
      AND stay_date = v_date AND booked_rooms > 0;
    SET v_date = DATE_ADD(v_date, INTERVAL 1 DAY);
  END WHILE;
  UPDATE bookings SET status = 'CANCELLED', cancelled_at = CURRENT_TIMESTAMP
  WHERE booking_id = p_booking_id;
  COMMIT;
END//

DELIMITER ;
