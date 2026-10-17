import type { Metadata } from "next";
import "./globals.css";
export const metadata: Metadata = {
  title: "سينماك | منصة مشاهدة مرخّصة",
  description: "شاهد المحتوى المرخّص وتابع قائمتك على سينماك."
};
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="ar" dir="rtl"><body>{children}</body></html>;
}
