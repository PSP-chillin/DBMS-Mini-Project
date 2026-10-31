import { NextResponse } from "next/server";
import type { RowDataPacket } from "mysql2";
import { auditEvent } from "@/lib/mongo";
import { db } from "@/lib/db";
import { getCurrentUser } from "@/lib/auth";

type ProcedureResult = RowDataPacket & { booking_id: number; confirmation_code: string };

function validDate(value: unknown): value is string {
  return typeof value === "string" && /^\d{4}-\d{2}-\d{2}$/.test(value);
}

export async function POST(request: Request) {
  const user = await getCurrentUser();
  if (!user || !["ADMIN", "MANAGER", "FRONT_DESK"].includes(user.role)) {
    return NextResponse.json({ error: "Authentication required" }, { status: 401 });
  }
  const body = await request.json().catch(() => null);
  const email = String(body?.guest?.email ?? "").trim().toLowerCase();
  const fullName = String(body?.guest?.fullName ?? "").trim();
  const checkIn = body?.checkIn;
  const checkOut = body?.checkOut;
  const hotelId = Number(body?.hotelId);
  const roomTypeId = Number(body?.roomTypeId);
  const amount = Number(body?.amount);

  if (!email || !fullName || !validDate(checkIn) || !validDate(checkOut)
    || !Number.isInteger(hotelId) || !Number.isInteger(roomTypeId)
    || !Number.isFinite(amount) || amount < 0 || checkOut <= checkIn) {
    return NextResponse.json({ error: "Invalid booking details" }, { status: 400 });
  }
  if (user.role !== "ADMIN" && user.hotel_id !== null && user.hotel_id !== hotelId) {
    return NextResponse.json({ error: "You cannot book rooms at this property" }, { status: 403 });
  }

  const confirmationCode = crypto.randomUUID().replaceAll("-", "").slice(0, 8).toUpperCase();
  try {
    const [guestResult] = await db.query(
      `INSERT INTO guests (full_name, email) VALUES (?, ?)
       ON DUPLICATE KEY UPDATE guest_id = LAST_INSERT_ID(guest_id), full_name = VALUES(full_name)`,
      [fullName, email],
    );
    const guestId = Number((guestResult as { insertId: number }).insertId);
    const [resultSets] = await db.query<ProcedureResult[][]>(
      "CALL sp_create_booking(?, ?, ?, ?, ?, ?, ?)",
      [confirmationCode, guestId, hotelId, roomTypeId, checkIn, checkOut, amount],
    );
    const result = resultSets[0]?.[0];
    if (!result) throw new Error("Booking procedure returned no booking");

    try {
      await auditEvent({
        bookingId: result.booking_id,
        eventType: "BOOKING_CREATED",
        actor: { userId: user.user_id, role: user.role },
        payload: { hotelId, roomTypeId, checkIn, checkOut, amount },
      });
    } catch (auditError) {
      console.error("MongoDB audit event failed", auditError);
    }
    return NextResponse.json({ booking: result }, { status: 201 });
  } catch (error) {
    console.error("Booking creation failed", error);
    return NextResponse.json({ error: "Booking could not be created" }, { status: 409 });
  }
}
