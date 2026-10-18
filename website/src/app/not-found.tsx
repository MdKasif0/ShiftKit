"use client";

import React from "react";
import Link from "next/link";
import { ShiftKitLogo } from "@/components/ShiftKitLogo";
import { ArrowLeft, Home, Download } from "lucide-react";

export default function NotFound() {
  return (
    <div className="min-h-screen bg-[#FAF8F3] text-[#34312D] flex flex-col justify-between">
      {/* Top Bar */}
      <header className="p-6 border-b border-[#E5D8C7]">
        <div className="max-w-6xl mx-auto flex items-center justify-between">
          <Link href="/" className="flex items-center gap-2">
            <ShiftKitLogo size={28} />
            <span className="font-serif text-lg font-bold text-[#34312D]">ShiftKit</span>
          </Link>
          <span className="text-xs font-mono text-[#D98768] font-bold">404 ERROR</span>
        </div>
      </header>

      {/* Main error card */}
      <main className="max-w-md mx-auto px-4 py-16 text-center space-y-6">
        <div className="w-16 h-16 mx-auto rounded-2xl bg-[#F3EEE4] border border-[#E5D8C7] flex items-center justify-center text-[#D98768] shadow-xs">
          <ShiftKitLogo size={36} />
        </div>

        <div className="space-y-2">
          <h1 className="font-serif text-3xl font-bold text-[#34312D]">
            Page Not Found
          </h1>
          <p className="text-xs sm:text-sm text-[#34312D]/75 leading-relaxed">
            The page or resource you are looking for has been moved or does not exist.
          </p>
        </div>

        <div className="flex flex-col sm:flex-row gap-3 pt-2 justify-center">
          <Link
            href="/"
            className="inline-flex items-center justify-center gap-2 px-5 py-2.5 rounded-lg text-xs font-semibold bg-[#D98768] text-[#FAF8F3] hover:bg-[#c97556] transition-colors"
          >
            <Home size={14} />
            <span>Return Home</span>
          </Link>
          <Link
            href="/#download"
            className="inline-flex items-center justify-center gap-2 px-5 py-2.5 rounded-lg text-xs font-medium bg-[#FFFFFF] border border-[#E5D8C7] text-[#34312D] hover:bg-[#F3EEE4] transition-colors"
          >
            <Download size={14} />
            <span>Download ShiftKit</span>
          </Link>
        </div>
      </main>

      {/* Simple footer */}
      <footer className="p-6 text-center text-xs text-[#34312D]/60 border-t border-[#E5D8C7]">
        © 2026 ShiftKit • Every file. One gesture.
      </footer>
    </div>
  );
}
