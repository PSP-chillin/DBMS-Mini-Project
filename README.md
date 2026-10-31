# Hotel Franchise Central Reservation System

MySQL + MongoDB + Next.js project for managing hotel-franchise availability and
safe overbooking decisions.

## Current implementation

- MySQL relational schema in [`database/mysql/001_schema.sql`](database/mysql/001_schema.sql)
- Seed records in [`database/mysql/002_seed.sql`](database/mysql/002_seed.sql)
- Transactional `sp_create_booking` with `SELECT ... FOR UPDATE`
- Cancellation procedure, validation triggers, availability and risk views
- MongoDB audit-event model and aggregation in [`database/mongo/README.md`](database/mongo/README.md)
- Next.js operations landing page
- Cookie-based authentication with Admin, Manager, and Front Desk roles
- Availability, booking, cancellation, dashboard, login, and audit API routes
- Submission documentation and test cases in [`docs/project-documentation.md`](docs/project-documentation.md)

## Run the database

```bash
mysql -u root -p < database/mysql/001_schema.sql
mysql -u root -p < database/mysql/002_seed.sql
```

Or start both local databases with:

```bash
docker compose up -d
```

The Compose MySQL container is exposed on host port `3307` to avoid conflicts
with an existing local MySQL installation. Use `MYSQL_PORT=3307` in `.env.local`
when connecting to the Compose database.

The procedure accepts one booking only when every requested night has sellable
inventory. It locks each inventory row before incrementing `booked_rooms`, so
concurrent requests cannot consume the same final slot.

## Run the web app

```bash
npm install
copy .env.example .env.local
npm run dev
```

Do not commit `.env.local`; database credentials must remain in environment
variables.

## Demo accounts

The seed script creates these accounts with the password `Admin@123`:

- `admin@harborlight.example` — franchise-wide Admin
- `manager@harborlight.example` — Chennai Manager

Change these credentials before any real deployment.

The prerequisite ER diagram and relational-schema screenshots are preserved in
[`Hotel_CRS_Mini_project.pdf`](Hotel_CRS_Mini_project.pdf). The written
deliverable is in [`docs/project-documentation.md`](docs/project-documentation.md).

## API surface

- `POST /api/auth/login`, `POST /api/auth/logout`, `GET /api/auth/me`
- `GET /api/availability?from=YYYY-MM-DD&to=YYYY-MM-DD`
- `POST /api/bookings` and `DELETE /api/bookings/:id`
- `GET /api/dashboard`

MongoDB audit events require `MONGODB_URI`. If MongoDB is unavailable, the
transactional MySQL booking still completes but the audit failure is logged by
the API; configure MongoDB before demonstrating the audit requirement.

## Database demonstration checklist

1. Show `sp_create_booking` locking inventory with `SELECT ... FOR UPDATE`.
2. Run two concurrent bookings for the final sellable slot and show one is rejected.
3. Show `v_room_availability` and `v_overbooking_risk`.
4. Show the validation trigger rejecting past or invalid dates.
5. Run the MongoDB aggregation in [`database/mongo/README.md`](database/mongo/README.md).
