"use client";

import React, { useState } from "react";
import { ChevronDown } from "lucide-react";

export function FAQ() {
  const [openIndex, setOpenIndex] = useState<number | null>(0);

  const faqs = [
    {
      q: "Is ShiftKit available for macOS?",
      a: "Yes. ShiftKit is built specifically for macOS 14.0 (Sonoma) and macOS 15 (Sequoia). It is compiled as a Universal Binary supporting both Apple Silicon (M1/M2/M3/M4) and 64-bit Intel Mac computers.",
    },
    {
      q: "Which formats does ShiftKit support?",
      a: "ShiftKit supports image workflows (PNG, JPEG, WebP, HEIC, TIFF, BMP, GIF, AVIF), document formats (PDF creation, compression, extraction, and merging), audio formats (MP3, WAV, AAC, M4A), and video conversions (MP4, MOV, WebM).",
    },
    {
      q: "Are files uploaded to a server?",
      a: "No. ShiftKit is a local-first desktop application. Every conversion, crop, trim, and metadata inspection executes entirely on your Mac using native Apple frameworks and local engines. Your files never leave your device.",
    },
    {
      q: "Where are converted files saved?",
      a: "By default, ShiftKit saves converted files beside your original files or into a dedicated ShiftKit Output folder. You can configure this in Settings under Output, or choose \"Ask every time\" to prompt for a custom location.",
    },
    {
      q: "Can I process multiple files?",
      a: "Yes. When you drag multiple files, ShiftKit launches the Multi-File Studio. You can choose to merge compatible files into a single multi-page PDF or batch convert each file with automatic queue throttling and per-item progress.",
    },
    {
      q: "How do I install ShiftKit?",
      a: "Download the ShiftKit disk image (.dmg), open it, and drag ShiftKit.app into your Applications folder. On first launch, grant Accessibility permissions in System Settings so ShiftKit can recognize when the Shift key is held during drag gestures.",
    },
    {
      q: "What happens if macOS displays a security warning?",
      a: "If macOS displays a warning that the developer cannot be verified (Gatekeeper), right-click (or Control-click) ShiftKit.app in your Applications folder and select \"Open\", then click \"Open\" in the confirmation dialog. Once an official Developer ID certificate is applied to release builds, this warning will not appear.",
    },
    {
      q: "Is ShiftKit free?",
      a: "ShiftKit is currently provided as an open-source evaluation build. The complete source code is public on GitHub under an open-source license. Commercial licensing and optional App Store editions may be introduced in the future.",
    },
  ];

  return (
    <section id="faq" className="py-20 md:py-28 bg-[#F3EEE4] border-t border-[#E5D8C7]">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="text-center space-y-3 mb-14">
          <span className="text-xs font-mono font-bold uppercase tracking-wider text-[#D98768]">
            Frequently Asked Questions
          </span>
          <h2 className="font-serif text-3xl sm:text-4xl font-bold tracking-tight text-[#34312D]">
            Everything you need to know.
          </h2>
          <p className="text-sm sm:text-base text-[#34312D]/80 leading-relaxed">
            Clear, honest answers about privacy, formats, and desktop integration.
          </p>
        </div>

        {/* Accordion List */}
        <div className="space-y-3.5">
          {faqs.map((item, idx) => {
            const isOpen = openIndex === idx;
            return (
              <div
                key={idx}
                className="rounded-xl bg-[#FAF8F3] border border-[#E5D8C7] transition-colors overflow-hidden"
              >
                <button
                  type="button"
                  onClick={() => setOpenIndex(isOpen ? null : idx)}
                  className="w-full p-5 text-left flex items-center justify-between gap-4 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#D98768] cursor-pointer"
                  aria-expanded={isOpen}
                >
                  <span className="font-serif text-base font-bold text-[#34312D]">
                    {item.q}
                  </span>
                  <ChevronDown
                    size={18}
                    className={`text-[#465343] shrink-0 transition-transform duration-200 ${
                      isOpen ? "transform rotate-180 text-[#D98768]" : ""
                    }`}
                  />
                </button>
                {isOpen && (
                  <div className="px-5 pb-5 pt-1 text-xs sm:text-sm text-[#34312D]/80 leading-relaxed border-t border-[#E5D8C7]/50 animate-fadeIn">
                    {item.a}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
