import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Harborlight Central Reservations",
  description: "Hotel franchise inventory and overbooking operations",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
