import { NextResponse } from "next/server";
import { authenticate, createSession } from "@/lib/auth";

export async function POST(request: Request) {
  const body = await request.json().catch(() => null);
  if (!body?.email || !body?.password) {
    return NextResponse.json({ error: "Email and password are required" }, { status: 400 });
  }
  try {
    const user = await authenticate(String(body.email), String(body.password));
    if (!user) return NextResponse.json({ error: "Invalid credentials" }, { status: 401 });
    await createSession(user.user_id);
    return NextResponse.json({
      user: { id: user.user_id, email: user.email, role: user.role, hotel: user.hotel_name },
    });
  } catch (error) {
    console.error("Login failed", error);
    return NextResponse.json({ error: "Authentication service unavailable" }, { status: 503 });
  }
}
