# MongoDB audit model

MySQL owns bookings and inventory because those records require foreign keys,
transactions, and row-level locking. MongoDB stores append-only operational
events because event payloads vary by event type and are queried as audit
streams.

Database: `hotel_reservations_audit`

Collection: `booking_events`

Example document:

```json
{
  "bookingId": 1001,
  "eventType": "OVERBOOKING_ACCEPTED",
  "hotelId": 1,
  "occurredAt": "2026-10-31T06:10:00.000Z",
  "actor": { "userId": 4, "role": "FRONT_DESK" },
  "payload": {
    "roomType": "STD",
    "requestedRooms": 1,
    "physicalRooms": 40,
    "sellableLimit": 44,
    "compensationRequired": false
  }
}
```

Create the audit index:

```javascript
db.booking_events.createIndex({ hotelId: 1, occurredAt: -1 });
db.booking_events.createIndex({ eventType: 1, occurredAt: -1 });
```

Example aggregation used by the dashboard:

```javascript
db.booking_events.aggregate([
  { $match: { eventType: "OVERBOOKING_ACCEPTED" } },
  { $group: {
    _id: "$hotelId",
    overbookingCount: { $sum: 1 },
    latestEvent: { $max: "$occurredAt" }
  } },
  { $sort: { overbookingCount: -1 } }
]);
```
