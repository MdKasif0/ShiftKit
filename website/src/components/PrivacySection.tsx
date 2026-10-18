"use client";

import React from "react";
import { ShieldCheck, HardDrive, WifiOff, FileLock, Trash2 } from "lucide-react";

export function PrivacySection() {
  const points = [
    {
      icon: HardDrive,
      title: "100% On-Device Processing",
      description:
        "All image encoding, video trimming, and PDF merging happen directly within native macOS system frameworks and your local media engine. No remote server is ever involved in processing your documents.",
    },
    {
      icon: WifiOff,
      title: "Zero File Content Uploads",
      description:
        "Your documents, client files, and private photos never leave your Mac. ShiftKit operates completely offline without requiring an account or network connection for any file transformation.",
    },
    {
      icon: Trash2,
      title: "Ephemeral Working Cache",
      description:
        "Temporary files created during complex conversions are stored in your user cache directory and purged automatically after validation, or instantly via the Purge Temporary Files button in Settings.",
    },
    {
      icon: FileLock,
      title: "Local-Only History Log",
      description:
        "Recent operations are saved in a simple local JSON file on your Mac for quick access in Finder. No file contents or sensitive metadata are retained, and the history can be wiped with one click.",
    },
  ];

  return (
    <section id="privacy" className="py-20 md:py-28 bg-[#F3EEE4] border-t border-[#E5D8C7]">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="max-w-2xl mx-auto text-center space-y-3 mb-16">
          <span className="text-xs font-mono font-bold uppercase tracking-wider text-[#D98768]">
            Privacy First Architecture
          </span>
          <h2 className="font-serif text-3xl sm:text-4xl md:text-5xl font-bold tracking-tight text-[#34312D]">
            Your files stay yours.
          </h2>
          <p className="text-sm sm:text-base text-[#34312D]/80 leading-relaxed">
            Most online conversion tools upload your confidential documents to an unknown cloud server. ShiftKit runs locally on your Mac, keeping your private data strictly in your hands.
          </p>
        </div>

        {/* 4 Privacy Pillars */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 max-w-4xl mx-auto">
          {points.map((p, idx) => {
            const Icon = p.icon;
            return (
              <div
                key={idx}
                className="p-6 sm:p-7 rounded-2xl bg-[#FAF8F3] border border-[#E5D8C7] shadow-xs space-y-3"
              >
                <div className="w-10 h-10 rounded-lg bg-[#F3EEE4] border border-[#E5D8C7] flex items-center justify-center text-[#465343]">
                  <Icon size={20} className="stroke-[2]" />
                </div>
                <h3 className="font-serif text-lg font-bold text-[#34312D]">
                  {p.title}
                </h3>
                <p className="text-xs sm:text-sm text-[#34312D]/75 leading-relaxed">
                  {p.description}
                </p>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
