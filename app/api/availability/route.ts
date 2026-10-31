import { NextResponse } from "next/server";
import type { RowDataPacket } from "mysql2";
import { db } from "@/lib/db";

type AvailabilityRow = RowDataPacket & {
  hotel_id: number;
  hotel_name: string;
  room_type_id: number;
  room_type_name: string;
  stay_date: string;
  total_rooms: number;
  booked_rooms: number;
  occupancy_percent: number;
  remaining_sellable: number;
};

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const hotelId = searchParams.get("hotelId");
  const from = searchParams.get("from");
  const to = searchParams.get("to");

  if (!from || !to || to <= from) {
    return NextResponse.json(
      { error: "from and to are required, and to must be after from" },
      { status: 400 },
    );
  }

  const conditions = ["stay_date >= ?", "stay_date < ?"];
  const values: (string | number)[] = [from, to];
  if (hotelId) {
    conditions.push("hotel_id = ?");
    values.push(Number(hotelId));
  }

  try {
    const [rows] = await db.query<AvailabilityRow[]>(
      `SELECT hotel_id, hotel_name, room_type_id, room_type_name, stay_date,
              total_rooms, booked_rooms, occupancy_percent, remaining_sellable
       FROM v_room_availability
       WHERE ${conditions.join(" AND ")}
       ORDER BY stay_date, hotel_name, room_type_name`,
      values,
    );
    return NextResponse.json({ data: rows });
  } catch (error) {
    console.error("Availability query failed", error);
    return NextResponse.json(
      { error: "Availability is temporarily unavailable" },
      { status: 503 },
    );
  }
}
