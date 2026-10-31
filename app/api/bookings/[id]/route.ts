import { NextResponse } from "next/server";
import { auditEvent } from "@/lib/mongo";
import { db } from "@/lib/db";
import { getCurrentUser } from "@/lib/auth";

export async function DELETE(
  _request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const user = await getCurrentUser();
  if (!user) return NextResponse.json({ error: "Authentication required" }, { status: 401 });
  const bookingId = Number((await params).id);
  if (!Number.isInteger(bookingId) || bookingId < 1) {
    return NextResponse.json({ error: "Invalid booking id" }, { status: 400 });
  }
  try {
    await db.query("CALL sp_cancel_booking(?)", [bookingId]);
    try {
      await auditEvent({
        bookingId,
        eventType: "BOOKING_CANCELLED",
        actor: { userId: user.user_id, role: user.role },
      });
    } catch (auditError) {
      console.error("MongoDB audit event failed", auditError);
    }
    return NextResponse.json({ success: true });
  } catch (error) {
    console.error("Booking cancellation failed", error);
    return NextResponse.json({ error: "Booking could not be cancelled" }, { status: 409 });
  }
}
