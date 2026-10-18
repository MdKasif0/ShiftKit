"use client";

import React from "react";
import Link from "next/link";
import { ShiftKitLogo } from "./ShiftKitLogo";

export function Footer() {
  return (
    <footer className="w-full bg-[#FAF8F3] border-t border-[#E5D8C7] py-12 md:py-16 text-[#34312D]">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-8 pb-10 border-b border-[#E5D8C7]">
          {/* Brand info */}
          <div className="space-y-2 max-w-sm">
            <div className="flex items-center gap-2.5">
              <ShiftKitLogo size={28} />
              <span className="font-serif text-lg font-bold tracking-tight text-[#34312D]">
                ShiftKit
              </span>
            </div>
            <p className="text-xs text-[#34312D]/75 leading-relaxed">
              Every file. One gesture. A local-first circular radial utility for macOS.
            </p>
          </div>

          {/* Quick links */}
          <div className="flex flex-wrap gap-x-8 gap-y-3 text-xs font-medium text-[#465343]">
            <Link href="#features" className="hover:text-[#D98768] transition-colors">
              Features
            </Link>
            <Link href="#how-it-works" className="hover:text-[#D98768] transition-colors">
              How It Works
            </Link>
            <Link href="#showcase" className="hover:text-[#D98768] transition-colors">
              Showcase
            </Link>
            <Link href="/privacy" className="hover:text-[#D98768] transition-colors">
              Privacy Policy
            </Link>
            <Link href="#faq" className="hover:text-[#D98768] transition-colors">
              FAQ
            </Link>
            <Link
              href="https://github.com/MdKasif0/ShiftKit"
              target="_blank"
              rel="noopener noreferrer"
              className="hover:text-[#D98768] transition-colors"
            >
              GitHub
            </Link>
          </div>
        </div>

        {/* Bottom copyright & local statement */}
        <div className="pt-6 flex flex-col sm:flex-row items-center justify-between text-[11px] text-[#34312D]/60 gap-3">
          <p>© 2026 ShiftKit. All rights reserved. Handcrafted for macOS.</p>
          <p className="font-mono text-[#465343]">
            Local-First • Swift 5.0 • SwiftUI & AppKit
          </p>
        </div>
      </div>
    </footer>
  );
}
