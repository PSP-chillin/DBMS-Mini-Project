USE hotel_reservations;

-- DML, JOIN, GROUP BY, HAVING, ORDER BY and aggregate demonstration.
SELECT h.name AS hotel_name, rt.name AS room_type,
       COUNT(r.room_id) AS physical_rooms,
       AVG(rt.base_rate) AS average_rate
FROM hotels h
JOIN rooms r ON r.hotel_id = h.hotel_id
JOIN room_types rt ON rt.room_type_id = r.room_type_id
GROUP BY h.hotel_id, h.name, rt.room_type_id, rt.name
HAVING COUNT(r.room_id) > 0
ORDER BY physical_rooms DESC, hotel_name;

-- Availability view and overbooking risk view.
SELECT * FROM v_room_availability
WHERE stay_date = CURRENT_DATE()
ORDER BY remaining_sellable, hotel_name;

SELECT * FROM v_overbooking_risk
WHERE stay_date = CURRENT_DATE()
  AND risk_level <> 'NORMAL'
ORDER BY occupancy_percent DESC;

-- Stored procedure demonstration.
CALL sp_create_booking(
  'DEMO0001', 1, 1, 1,
  DATE_ADD(CURRENT_DATE(), INTERVAL 14 DAY),
  DATE_ADD(CURRENT_DATE(), INTERVAL 16 DAY),
  9000.00
);

-- Transactional cancellation demonstration.
-- Replace 1 with the booking_id returned above.
-- CALL sp_cancel_booking(1);

-- Subquery demonstration: hotels with at least one high-risk night.
SELECT h.name, h.city
FROM hotels h
WHERE h.hotel_id IN (
  SELECT hotel_id FROM v_overbooking_risk
  WHERE risk_level IN ('HIGH', 'OVERBOOKED')
);

-- Index/plan demonstration.
EXPLAIN SELECT *
FROM bookings
WHERE hotel_id = 1 AND status = 'CONFIRMED';
