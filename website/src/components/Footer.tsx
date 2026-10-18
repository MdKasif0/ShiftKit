"use client";

import React from "react";
import HalftoneWordmarkFooter, {
  FooterColumn,
} from "@/components/ui/halftone-wordmark-footer";

const SHIFTKIT_COLUMNS: FooterColumn[] = [
  {
    title: "Product",
    links: [
      { label: "Features", href: "/#features" },
      { label: "How It Works", href: "/#how-it-works" },
      { label: "Showcase", href: "/#showcase" },
      { label: "Download", href: "/#download" },
    ],
  },
  {
    title: "Architecture",
    links: [
      { label: "100% Local", href: "/#privacy" },
      { label: "Zero Telemetry", href: "/#privacy" },
      { label: "Universal Binary", href: "/#download" },
      { label: "macOS 14 & 15", href: "/#faq" },
    ],
  },
  {
    title: "Project",
    links: [
      { label: "GitHub Repository", href: "https://github.com/MdKasif0/ShiftKit" },
      { label: "Release Notes", href: "https://github.com/MdKasif0/ShiftKit/releases" },
      { label: "FAQ", href: "/#faq" },
      { label: "Privacy Policy", href: "/privacy" },
    ],
  },
];

export function Footer() {
  return (
    <HalftoneWordmarkFooter
      wordmark="shiftkit"
      label="ShiftKit"
      meta="© 2026 · Native macOS File Utility"
      columns={SHIFTKIT_COLUMNS}
      backToTop={true}
      palette={{
        background: "#FAF8F3",
        ink: "#34312D",
        warm: "#D98768",
      }}
      fontFamily='"New York", "Iowan Old Style", "Charter", "Palatino", serif'
      fontWeight={800}
      height="560px"
      className="border-t border-[#E5D8C7]"
    />
  );
}

export default Footer;
