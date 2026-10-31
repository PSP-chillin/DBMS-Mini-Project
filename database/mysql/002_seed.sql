USE hotel_reservations;

INSERT INTO hotel_franchises (franchise_name, contact_email, contact_number, address)
VALUES ('Harborlight Hospitality Group', 'hq@harborlight.example', '+91-9000000000', '1 Marina Road, Chennai');

INSERT INTO hotels (name, city, address) VALUES
  ('Harborlight Grand', 'Chennai', '1 Marina Road', 'Tamil Nadu', 'India', 'grand@harborlight.example', '+91-9000000011', 5, 1),
  ('Harborlight Residency', 'Bengaluru', '22 Residency Road', 'Karnataka', 'India', 'residency@harborlight.example', '+91-9000000012', 4, 1),
  ('Harborlight Suites', 'Hyderabad', '8 Jubilee Hills', 'Telangana', 'India', 'suites@harborlight.example', '+91-9000000013', 4, 1);

INSERT INTO room_types (code, name, capacity, base_rate) VALUES
  ('STD', 'Standard Room', 2, 4500.00),
  ('DLX', 'Deluxe Room', 3, 7000.00),
  ('STE', 'Executive Suite', 4, 11000.00);

INSERT INTO hotel_room_types (hotel_id, room_type_id, total_rooms, overbooking_percent)
SELECT h.hotel_id, rt.room_type_id,
  CASE rt.code WHEN 'STD' THEN 40 WHEN 'DLX' THEN 20 ELSE 8 END,
  CASE rt.code WHEN 'STD' THEN 10.00 WHEN 'DLX' THEN 5.00 ELSE 0.00 END
FROM hotels h CROSS JOIN room_types rt;

INSERT INTO rooms (hotel_id, room_type_id, room_number, floor_number)
SELECT h.hotel_id, rt.room_type_id,
  CONCAT(CASE rt.code WHEN 'STD' THEN '1' WHEN 'DLX' THEN '2' ELSE '3' END, LPAD(n.number, 2, '0')),
  CASE rt.code WHEN 'STD' THEN 1 WHEN 'DLX' THEN 2 ELSE 3 END
FROM hotels h
CROSS JOIN room_types rt
CROSS JOIN (
  SELECT 1 AS number UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL
  SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
) n;

INSERT INTO guests (full_name, email, phone) VALUES
  ('Aarav Sharma', 'aarav@example.com', '+91-9000000001'),
  ('Meera Iyer', 'meera@example.com', '+91-9000000002'),
  ('Daniel Thomas', 'daniel@example.com', '+91-9000000003');

INSERT INTO users (hotel_id, email, password_hash, role) VALUES
  (NULL, 'admin@harborlight.example',
   'dbfbef99890e0c3f3144ac36d0db03eb:e291082c31456be95ca2a154595a959ac5940971b008668166a424f40bf9adcf78938a5e303832703afa950ea5ec0c0994a6aed286fc5a741918a4e126072d0f',
   'ADMIN'),
  (1, 'manager@harborlight.example',
   'dbfbef99890e0c3f3144ac36d0db03eb:e291082c31456be95ca2a154595a959ac5940971b008668166a424f40bf9adcf78938a5e303832703afa950ea5ec0c0994a6aed286fc5a741918a4e126072d0f',
   'MANAGER');

CALL sp_initialize_inventory(CURRENT_DATE(), DATE_ADD(CURRENT_DATE(), INTERVAL 180 DAY));
