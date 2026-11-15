import type { Metadata } from "next";
import localFont from "next/font/local";
import "./globals.css";

const font = localFont({
  src: [
    { path: "./fonts/Inter-Regular.ttf", weight: "400" },
    { path: "./fonts/Inter-Medium.ttf", weight: "500" },
    { path: "./fonts/Inter-SemiBold.ttf", weight: "600" },
    { path: "./fonts/Inter-Bold.ttf", weight: "700" },
    { path: "./fonts/Inter-ExtraBold.ttf", weight: "800" },
    { path: "./fonts/Inter-Black.ttf", weight: "900" },
  ],
});

export const metadata: Metadata = {
  title: "App Store Screenshots",
  description: "Design and export App Store + Google Play screenshots.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className={font.className}>{children}</body>
    </html>
  );
}
