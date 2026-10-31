import { NextResponse } from "next/server";
import { getCurrentUser } from "@/lib/auth";

export async function GET() {
  try {
    const user = await getCurrentUser();
    if (!user) return NextResponse.json({ user: null }, { status: 401 });
    return NextResponse.json({
      user: { id: user.user_id, email: user.email, role: user.role, hotel: user.hotel_name },
    });
  } catch (error) {
    console.error("Session lookup failed", error);
    return NextResponse.json({ error: "Authentication service unavailable" }, { status: 503 });
  }
}
