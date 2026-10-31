import { NextResponse } from "next/server";
import type { RowDataPacket } from "mysql2";
import { db } from "@/lib/db";
import { getCurrentUser } from "@/lib/auth";

type MetricRow = RowDataPacket & {
  total_inventory: number;
  occupied_inventory: number;
  high_risk_rooms: number;
};

export async function GET() {
  const user = await getCurrentUser();
  if (!user) return NextResponse.json({ error: "Authentication required" }, { status: 401 });
  try {
    const hotelFilter = user.role === "ADMIN" || user.hotel_id === null ? "" : "AND hotel_id = ?";
    const args = user.role === "ADMIN" || user.hotel_id === null ? [] : [user.hotel_id];
    const [rows] = await db.query<MetricRow[]>(
      `SELECT COALESCE(SUM(total_rooms), 0) AS total_inventory,
              COALESCE(SUM(booked_rooms), 0) AS occupied_inventory,
              COALESCE(SUM(CASE WHEN risk_level = 'HIGH' OR risk_level = 'OVERBOOKED' THEN 1 ELSE 0 END), 0) AS high_risk_rooms
       FROM v_overbooking_risk WHERE stay_date = CURRENT_DATE() ${hotelFilter}`,
      args,
    );
    return NextResponse.json({ data: rows[0] });
  } catch (error) {
    console.error("Dashboard query failed", error);
    return NextResponse.json({ error: "Dashboard is temporarily unavailable" }, { status: 503 });
  }
}
