import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "ShiftKit — Every file. One gesture. Native macOS Utility",
  description:
    "Convert, compress, crop, trim, and merge files from your Mac with a beautifully simple radial menu. Your files stay on your device.",
  icons: {
    icon: "/favicon.svg",
    shortcut: "/favicon.svg",
    apple: "/favicon.svg",
  },
  openGraph: {
    title: "ShiftKit — Every file. One gesture.",
    description:
      "Convert, compress, crop, trim, and merge files from your Mac with a beautifully simple radial menu. 100% local processing.",
    url: "https://shiftkit.mac",
    siteName: "ShiftKit",
    locale: "en_US",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "ShiftKit — Every file. One gesture.",
    description:
      "Convert, compress, crop, trim, and merge files from your Mac with a beautifully simple radial menu. 100% local processing.",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="scroll-smooth">
      <body className="bg-[#FAF8F3] text-[#34312D] antialiased selection:bg-[#F5D5C2] selection:text-[#34312D]">
        {children}
      </body>
    </html>
  );
}
