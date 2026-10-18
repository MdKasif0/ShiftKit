"use client";

import React, { useState } from "react";
import Link from "next/link";
import { ShiftKitLogo } from "./ShiftKitLogo";
import { Download, Menu, X } from "lucide-react";

export function Navbar() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  return (
    <header className="sticky top-0 z-50 w-full bg-[#FAF8F3]/90 backdrop-blur-md border-b border-[#E5D8C7]">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
        {/* Brand */}
        <Link
          href="/"
          className="flex items-center gap-2.5 group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#D98768] rounded-md py-1"
        >
          <ShiftKitLogo size={32} />
          <div className="flex items-baseline gap-1.5">
            <span className="font-serif text-xl font-bold tracking-tight text-[#34312D] group-hover:text-[#465343] transition-colors">
              ShiftKit
            </span>
            <span className="text-[10px] font-mono tracking-wider px-1.5 py-0.5 rounded bg-[#F3EEE4] border border-[#E5D8C7] text-[#465343]">
              1.0
            </span>
          </div>
        </Link>

        {/* Desktop Navigation */}
        <nav className="hidden md:flex items-center gap-7 text-[13px] font-medium text-[#34312D]/85">
          <Link
            href="#features"
            className="hover:text-[#D98768] transition-colors focus-visible:outline-none focus-visible:underline"
          >
            Features
          </Link>
          <Link
            href="#how-it-works"
            className="hover:text-[#D98768] transition-colors focus-visible:outline-none focus-visible:underline"
          >
            How It Works
          </Link>
          <Link
            href="#showcase"
            className="hover:text-[#D98768] transition-colors focus-visible:outline-none focus-visible:underline"
          >
            Showcase
          </Link>
          <Link
            href="#privacy"
            className="hover:text-[#D98768] transition-colors focus-visible:outline-none focus-visible:underline"
          >
            Privacy
          </Link>
          <Link
            href="#faq"
            className="hover:text-[#D98768] transition-colors focus-visible:outline-none focus-visible:underline"
          >
            FAQ
          </Link>
        </nav>

        {/* Actions */}
        <div className="hidden md:flex items-center gap-3">
          <Link
            href="https://github.com/MdKasif0/ShiftKit"
            target="_blank"
            rel="noopener noreferrer"
            className="text-[13px] font-medium text-[#465343] hover:text-[#34312D] px-2.5 py-1.5 transition-colors"
          >
            GitHub
          </Link>
          <Link
            href="#download"
            className="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-md text-[13px] font-semibold bg-[#D98768] hover:bg-[#c97556] text-[#FAF8F3] shadow-xs transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-[#D98768]"
          >
            <Download size={14} className="stroke-[2.2]" />
            <span>Download</span>
          </Link>
        </div>

        {/* Mobile menu button */}
        <button
          type="button"
          onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
          className="md:hidden p-2 rounded-md text-[#34312D] hover:bg-[#F3EEE4] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#D98768]"
          aria-expanded={mobileMenuOpen}
          aria-label="Toggle Navigation Menu"
        >
          {mobileMenuOpen ? <X size={20} /> : <Menu size={20} />}
        </button>
      </div>

      {/* Mobile Drawer */}
      {mobileMenuOpen && (
        <div className="md:hidden border-b border-[#E5D8C7] bg-[#FAF8F3] px-4 pt-3 pb-5 space-y-3">
          <nav className="flex flex-col space-y-2.5 text-sm font-medium text-[#34312D]">
            <Link
              href="#features"
              onClick={() => setMobileMenuOpen(false)}
              className="px-2 py-1.5 rounded hover:bg-[#F3EEE4] transition-colors"
            >
              Features
            </Link>
            <Link
              href="#how-it-works"
              onClick={() => setMobileMenuOpen(false)}
              className="px-2 py-1.5 rounded hover:bg-[#F3EEE4] transition-colors"
            >
              How It Works
            </Link>
            <Link
              href="#showcase"
              onClick={() => setMobileMenuOpen(false)}
              className="px-2 py-1.5 rounded hover:bg-[#F3EEE4] transition-colors"
            >
              Showcase
            </Link>
            <Link
              href="#privacy"
              onClick={() => setMobileMenuOpen(false)}
              className="px-2 py-1.5 rounded hover:bg-[#F3EEE4] transition-colors"
            >
              Privacy
            </Link>
            <Link
              href="#faq"
              onClick={() => setMobileMenuOpen(false)}
              className="px-2 py-1.5 rounded hover:bg-[#F3EEE4] transition-colors"
            >
              FAQ
            </Link>
          </nav>
          <div className="pt-2 border-t border-[#E5D8C7] flex flex-col gap-2">
            <Link
              href="https://github.com/MdKasif0/ShiftKit"
              target="_blank"
              rel="noopener noreferrer"
              className="text-center py-2 text-sm text-[#465343] font-medium rounded hover:bg-[#F3EEE4]"
            >
              View on GitHub
            </Link>
            <Link
              href="#download"
              onClick={() => setMobileMenuOpen(false)}
              className="w-full flex items-center justify-center gap-2 py-2.5 rounded-md text-sm font-semibold bg-[#D98768] text-[#FAF8F3]"
            >
              <Download size={15} />
              <span>Download ShiftKit for Mac</span>
            </Link>
          </div>
        </div>
      )}
    </header>
  );
}
