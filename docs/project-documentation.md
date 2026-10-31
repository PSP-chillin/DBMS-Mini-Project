# Hotel Franchise Central Reservation System

## Objective

Provide one reservation control room for a hotel franchise while preventing
double-selling of rooms and making controlled overbooking decisions visible to
staff.

## Functional requirements

- Staff can authenticate as Admin, Manager, or Front Desk.
- Admins can operate across the franchise; hotel staff are restricted to their
  assigned property.
- Staff can search room availability by date range.
- Staff can create and cancel reservations.
- The database must reject invalid dates and unavailable inventory.
- A booking spanning multiple nights must succeed or fail atomically.
- Overbooking decisions must be recorded for later review.
- Operational booking events must be retained as an append-only audit stream.

## Database choice and justification

MySQL stores hotels, rooms, guests, reservations, payments, and inventory.
These records have stable relationships and require foreign keys, constraints,
transactions, and row-level locking.

MongoDB stores `booking_events`. Event payloads vary by event type
(`BOOKING_CREATED`, `BOOKING_CANCELLED`, `OVERBOOKING_ACCEPTED`, or a future
`GUEST_WALKED` event), so a document collection is more suitable than adding
many nullable relational columns. MongoDB also supports the operational
aggregation used by the dashboard.

## Relational design

The supplied prerequisite ER diagram and relational-schema work are preserved
in `Hotel_CRS_Mini_project.pdf`. The executable MySQL implementation is in
`database/mysql/001_schema.sql` and includes:

- `hotel_franchises`, `hotels`, `room_types`, `rooms`
- `hotel_room_types`, `inventory`, `guests`, `users`
- `bookings`, `payments`, `overbookings`, `auth_sessions`

`hotel_room_types` defines physical inventory and the permitted
`overbooking_percent`. `inventory` stores one row per hotel, room type, and
night. `bookings` references the guest and hotel room type and uses a
check-in/check-out range.

## Advanced database features

1. **Transactions and row locks:** `sp_create_booking` locks every inventory
   row using `SELECT ... FOR UPDATE`, then commits all nights together.
2. **Stored procedures:** `sp_create_booking`, `sp_cancel_booking`, and
   `sp_initialize_inventory`.
3. **Triggers:** booking dates are validated in the database, and repeated
   cancellation is rejected.
4. **Views:** `v_room_availability` and `v_overbooking_risk`.
5. **Indexes:** composite indexes support hotel/status and stay-range queries.
6. **NoSQL aggregation:** MongoDB groups overbooking events by hotel.

## Overbooking logic

For each night, sellable inventory is:

`FLOOR(total_rooms * (1 + overbooking_percent / 100))`

The procedure rejects a booking when `booked_rooms` has reached that limit.
When the accepted booking exceeds physical rooms, an `overbookings` record is
created so the manager can resolve the risk.

## Architecture

The browser uses the Next.js App Router. Route Handlers validate input and
enforce the session role, then call MySQL procedures or views. MySQL remains
the source of truth for inventory. Successful booking and cancellation actions
also write flexible event documents to MongoDB.

## Demonstration and testing

1. Start MySQL and MongoDB with `docker compose up -d`.
2. Copy `.env.example` to `.env.local`.
3. Run `npm run dev`.
4. Sign in using the seeded Admin or Manager account.
5. Search a date range, select a row, and create a reservation.
6. Run two concurrent calls against a final sellable slot; one must be
   rejected by the locked procedure.
7. Query `v_overbooking_risk` and the MongoDB aggregation.

Detailed SQL demonstrations are in `database/mysql/003_demo_queries.sql`.

## Test cases

| ID | Scenario | Expected result |
|---|---|---|
| T01 | Invalid check-out before check-in | API/database rejects the request |
| T02 | Booking a valid two-night stay | One booking and two inventory increments |
| T03 | Two concurrent requests for the last sellable slot | Only one succeeds |
| T04 | Cancel a confirmed booking | Status changes and each night is decremented |
| T05 | Manager accesses another hotel | API returns 403 |
| T06 | Invalid login | API returns 401 and no session cookie |
| T07 | Overbooking crosses physical inventory | `overbookings` row is created |
| T08 | Booking succeeds but MongoDB is unavailable | MySQL booking remains committed and audit failure is logged |

## Conclusion

The application goes beyond CRUD by combining relational integrity, atomic
reservation logic, controlled overbooking, role-based authorization, and a
flexible audit stream.
