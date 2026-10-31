"use client";

import { FormEvent, useEffect, useState } from "react";

type User = { id: number; email: string; role: string; hotel: string | null };
type Availability = {
  hotel_id: number; hotel_name: string; room_type_id: number; room_type_name: string;
  stay_date: string; remaining_sellable: number; occupancy_percent: number;
};

async function request<T>(url: string, init?: RequestInit): Promise<T> {
  const response = await fetch(url, { ...init, headers: { "Content-Type": "application/json", ...init?.headers } });
  const body = await response.json();
  if (!response.ok) throw new Error(body.error ?? "Request failed");
  return body;
}

export default function Home() {
  const [user, setUser] = useState<User | null>(null);
  const [login, setLogin] = useState({ email: "", password: "" });
  const [dates, setDates] = useState({ from: "", to: "" });
  const [availability, setAvailability] = useState<Availability[]>([]);
  const [selected, setSelected] = useState<Availability | null>(null);
  const [guest, setGuest] = useState({ fullName: "", email: "" });
  const [message, setMessage] = useState("");

  useEffect(() => {
    request<{ user: User }>("/api/auth/me").then(({ user: current }) => setUser(current)).catch(() => undefined);
  }, []);

  async function submitLogin(event: FormEvent) {
    event.preventDefault();
    try {
      const result = await request<{ user: User }>("/api/auth/login", { method: "POST", body: JSON.stringify(login) });
      setUser(result.user);
      setMessage(`Signed in as ${result.user.role.toLowerCase().replace("_", " ")}.`);
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Login failed");
    }
  }

  async function searchAvailability(event: FormEvent) {
    event.preventDefault();
    if (!dates.from || !dates.to) return;
    try {
      const result = await request<{ data: Availability[] }>(
        `/api/availability?from=${dates.from}&to=${dates.to}`,
      );
      setAvailability(result.data);
      setMessage(`${result.data.length} inventory rows found.`);
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Search failed");
    }
  }

  async function logout() {
    await request("/api/auth/logout", { method: "POST" });
    setUser(null);
    setMessage("Signed out.");
  }

  async function createBooking(event: FormEvent) {
    event.preventDefault();
    if (!selected || !user) return;
    try {
      const result = await request<{ booking: { confirmation_code: string } }>("/api/bookings", {
        method: "POST",
        body: JSON.stringify({
          guest,
          hotelId: selected.hotel_id,
          roomTypeId: selected.room_type_id,
          checkIn: dates.from,
          checkOut: dates.to,
          amount: 0,
        }),
      });
      setMessage(`Booking ${result.booking.confirmation_code} confirmed.`);
      setSelected(null);
      setGuest({ fullName: "", email: "" });
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Booking failed");
    }
  }

  return (
    <main className="shell">
      <header className="topbar"><p className="eyebrow">HARBORLIGHT HOTELS</p>
        {user ? <div className="session"><span>{user.email} · {user.role}</span><button className="button secondary" onClick={logout}>Sign out</button></div> : null}
      </header>
      <section className="hero">
        <p className="eyebrow">CENTRAL RESERVATIONS</p>
        <h1>Protect every room, even when demand changes.</h1>
        <p className="lede">A franchise-wide reservation control room with transaction-safe inventory and explainable overbooking decisions.</p>
      </section>

      {!user ? <section className="panel auth-panel"><div><p className="eyebrow">STAFF ACCESS</p><h2>Sign in to operate</h2><p>Managers and front-desk staff are restricted to their property.</p></div>
        <form className="search-form" onSubmit={submitLogin}>
          <label>Email<input type="email" required value={login.email} onChange={(e) => setLogin({ ...login, email: e.target.value })} /></label>
          <label>Password<input type="password" required value={login.password} onChange={(e) => setLogin({ ...login, password: e.target.value })} /></label>
          <button className="button primary">Sign in</button>
        </form></section> : null}

      <section className="metrics"><article className="metric"><p>Inventory model</p><strong>ACID</strong><span>MySQL row locking</span></article><article className="metric"><p>Audit stream</p><strong>MongoDB</strong><span>Flexible event payloads</span></article><article className="metric"><p>Access control</p><strong>3 roles</strong><span>Admin · Manager · Front desk</span></article></section>

      <section className="panel" id="availability"><div><p className="eyebrow">OPERATIONS</p><h2>Availability search</h2><p>Search initialized inventory before creating a reservation.</p></div>
        <form className="search-form" onSubmit={searchAvailability}><label>Check-in<input type="date" required value={dates.from} onChange={(e) => setDates({ ...dates, from: e.target.value })} /></label><label>Check-out<input type="date" required value={dates.to} onChange={(e) => setDates({ ...dates, to: e.target.value })} /></label><button className="button primary">Find rooms</button></form>
      </section>
      {message ? <p className="notice" role="status">{message}</p> : null}
      {availability.length > 0 ? <section className="table-panel"><table><thead><tr><th>Property</th><th>Room type</th><th>Night</th><th>Sellable</th><th>Occupancy</th><th /></tr></thead><tbody>{availability.map((row) => <tr key={`${row.hotel_id}-${row.room_type_id}-${row.stay_date}`}><td>{row.hotel_name}</td><td>{row.room_type_name}</td><td>{row.stay_date.slice(0, 10)}</td><td>{row.remaining_sellable}</td><td>{row.occupancy_percent}%</td><td><button className="button secondary" onClick={() => setSelected(row)}>Reserve</button></td></tr>)}</tbody></table></section> : null}
      {selected && user ? <section className="panel booking-panel"><div><p className="eyebrow">NEW RESERVATION</p><h2>{selected.hotel_name} · {selected.room_type_name}</h2><p>{dates.from} to {dates.to}. The database will re-check every night inside one transaction.</p></div><form className="search-form" onSubmit={createBooking}><label>Guest name<input required value={guest.fullName} onChange={(e) => setGuest({ ...guest, fullName: e.target.value })} /></label><label>Guest email<input required type="email" value={guest.email} onChange={(e) => setGuest({ ...guest, email: e.target.value })} /></label><button className="button primary">Confirm reservation</button></form></section> : null}

      <section className="panel risk"><div><p className="eyebrow">GUARDRAILS</p><h2>Overbooking is a controlled decision.</h2><p>The booking procedure locks each night&apos;s inventory row, checks the configured sellable limit, and commits all nights atomically. Every action can be audited in MongoDB.</p></div><div className="risk-card"><span>Required for every booking</span><strong>Availability → lock → commit</strong><small>Invalid dates and exhausted limits are rejected by the database.</small></div></section>
    </main>
  );
}
