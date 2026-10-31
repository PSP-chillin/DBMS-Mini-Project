import { createHash, randomBytes, scryptSync, timingSafeEqual } from "node:crypto";
import { cookies } from "next/headers";
import { db } from "@/lib/db";
import type { RowDataPacket } from "mysql2";

export type Role = "ADMIN" | "MANAGER" | "FRONT_DESK";
export type AuthUser = RowDataPacket & {
  user_id: number;
  hotel_id: number | null;
  email: string;
  role: Role;
  hotel_name: string | null;
};

function hashPassword(password: string, salt: string) {
  return scryptSync(password, salt, 64).toString("hex");
}

export function verifyPassword(password: string, encoded: string) {
  const [salt, expected] = encoded.split(":");
  if (!salt || !expected) return false;
  const actual = Buffer.from(hashPassword(password, salt), "hex");
  const expectedBuffer = Buffer.from(expected, "hex");
  return actual.length === expectedBuffer.length && timingSafeEqual(actual, expectedBuffer);
}

export async function authenticate(email: string, password: string) {
  const [rows] = await db.query<AuthUser[]>(
    `SELECT u.user_id, u.hotel_id, u.email, u.password_hash, u.role, h.name AS hotel_name
     FROM users u LEFT JOIN hotels h ON h.hotel_id = u.hotel_id
     WHERE u.email = ?`,
    [email.trim().toLowerCase()],
  );
  const user = rows[0] as (AuthUser & { password_hash: string }) | undefined;
  if (!user || !verifyPassword(password, user.password_hash)) return null;
  return user;
}

export async function createSession(userId: number) {
  const token = randomBytes(32).toString("hex");
  const sessionId = createHash("sha256").update(token).digest("hex");
  await db.query(
    `INSERT INTO auth_sessions (session_id, user_id, expires_at)
     VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 8 HOUR))`,
    [sessionId, userId],
  );
  const cookieStore = await cookies();
  cookieStore.set("hotel_session", token, {
    httpOnly: true,
    sameSite: "lax",
    secure: process.env.NODE_ENV === "production",
    maxAge: 8 * 60 * 60,
    path: "/",
  });
}

export async function getCurrentUser() {
  const token = (await cookies()).get("hotel_session")?.value;
  if (!token) return null;
  const sessionId = createHash("sha256").update(token).digest("hex");
  const [rows] = await db.query<AuthUser[]>(
    `SELECT u.user_id, u.hotel_id, u.email, u.role, h.name AS hotel_name
     FROM auth_sessions s
     JOIN users u ON u.user_id = s.user_id
     LEFT JOIN hotels h ON h.hotel_id = u.hotel_id
     WHERE s.session_id = ? AND s.expires_at > NOW()`,
    [sessionId],
  );
  return rows[0] ?? null;
}

export async function destroySession() {
  const cookieStore = await cookies();
  const token = cookieStore.get("hotel_session")?.value;
  if (token) {
    const sessionId = createHash("sha256").update(token).digest("hex");
    await db.query("DELETE FROM auth_sessions WHERE session_id = ?", [sessionId]);
  }
  cookieStore.delete("hotel_session");
}
