"use client";

import React from "react";
import Link from "next/link";
import { Download, Terminal, AlertCircle, CheckCircle2, ArrowRight } from "lucide-react";

export function DownloadSection() {
  const dmgUrl = process.env.NEXT_PUBLIC_SHIFTKIT_DMG_URL;
  const isDmgAvailable = Boolean(dmgUrl && dmgUrl.trim().length > 0);

  return (
    <section id="download" className="py-20 md:py-28 bg-[#FAF8F3]">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="p-8 sm:p-12 rounded-3xl bg-[#F3EEE4] border border-[#E5D8C7] shadow-md text-center space-y-6">
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#FAF8F3] border border-[#E5D8C7] text-xs font-mono font-bold text-[#D98768] uppercase tracking-wider">
            Official Release
          </span>

          <h2 className="font-serif text-3xl sm:text-4xl md:text-5xl font-bold tracking-tight text-[#34312D]">
            Get ShiftKit for Mac
          </h2>

          <p className="text-sm sm:text-base text-[#34312D]/80 max-w-xl mx-auto leading-relaxed">
            Accelerate your file workflow with instant circular radial actions. 100% on-device processing.
          </p>

          {/* Conditional Download Action */}
          <div className="pt-2 flex flex-col items-center justify-center space-y-4">
            {isDmgAvailable ? (
              <a
                href={dmgUrl}
                download
                className="inline-flex items-center justify-center gap-2.5 px-8 py-4 rounded-xl text-base font-semibold bg-[#D98768] hover:bg-[#c97556] text-[#FAF8F3] shadow-md transition-all transform hover:-translate-y-0.5 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-[#D98768]"
              >
                <Download size={19} className="stroke-[2.2]" />
                <span>Download ShiftKit 1.0.0 (.dmg)</span>
              </a>
            ) : (
              <div className="w-full max-w-md p-4 rounded-xl bg-[#FAF8F3] border border-[#E5D8C7] text-left space-y-3">
                <div className="flex items-start gap-2.5 text-xs text-[#34312D]">
                  <AlertCircle size={16} className="text-[#D98768] shrink-0 mt-0.5" />
                  <div>
                    <p className="font-bold text-[#34312D]">
                      Release DMG in Final Packaging
                    </p>
                    <p className="text-[#34312D]/75 mt-0.5">
                      The notarized .dmg binary is currently in preparation. To enable this button, set <code className="font-mono text-[#D98768] bg-[#F3EEE4] px-1 py-0.5 rounded text-[11px]">NEXT_PUBLIC_SHIFTKIT_DMG_URL</code> in your environment.
                    </p>
                  </div>
                </div>

                <div className="pt-1 border-t border-[#E5D8C7] flex flex-col sm:flex-row gap-2.5">
                  <Link
                    href="https://github.com/MdKasif0/ShiftKit"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex-1 inline-flex items-center justify-center gap-1.5 py-2.5 px-3 rounded-lg text-xs font-semibold bg-[#D98768] text-[#FAF8F3] hover:bg-[#c97556] transition-colors"
                  >
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/></svg>
                    <span>View Repository & Source</span>
                  </Link>
                  <Link
                    href="https://github.com/MdKasif0/ShiftKit/releases"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex-1 inline-flex items-center justify-center gap-1.5 py-2.5 px-3 rounded-lg text-xs font-medium bg-[#FFFFFF] border border-[#E5D8C7] text-[#34312D] hover:bg-[#F3EEE4] transition-colors"
                  >
                    <span>Release Notes</span>
                    <ArrowRight size={12} />
                  </Link>
                </div>
              </div>
            )}

            {/* Quick Terminal Build Command */}
            <div className="w-full max-w-md p-3 rounded-lg bg-[#34312D] text-[#FAF8F3] text-left flex items-center justify-between font-mono text-[11px] shadow-xs">
              <div className="flex items-center gap-2 overflow-x-auto py-0.5">
                <Terminal size={13} className="text-[#A8B5A0] shrink-0" />
                <span className="select-all text-[#FAF8F3]">
                  git clone https://github.com/MdKasif0/ShiftKit.git
                </span>
              </div>
            </div>
          </div>

          {/* Verified Specifications Grid */}
          <div className="pt-6 border-t border-[#E5D8C7] grid grid-cols-2 sm:grid-cols-4 gap-4 text-xs font-mono text-left max-w-2xl mx-auto">
            <div>
              <span className="text-[#465343] block">VERSION</span>
              <span className="font-bold text-[#34312D] text-sm">1.0.0</span>
            </div>
            <div>
              <span className="text-[#465343] block">ARCHITECTURE</span>
              <span className="font-bold text-[#34312D] text-sm">Universal Mac</span>
            </div>
            <div>
              <span className="text-[#465343] block">MINIMUM OS</span>
              <span className="font-bold text-[#34312D] text-sm">macOS 14.0+</span>
            </div>
            <div>
              <span className="text-[#465343] block">LICENSE</span>
              <span className="font-bold text-[#34312D] text-sm">MIT Open Source</span>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
