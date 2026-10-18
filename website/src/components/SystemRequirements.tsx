"use client";

import React from "react";
import { Cpu, Apple, Shield, WifiOff } from "lucide-react";

export function SystemRequirements() {
  const specs = [
    {
      icon: Apple,
      label: "Operating System",
      value: "macOS 14.0 Sonoma or macOS 15 Sequoia",
      detail: "Optimized for modern macOS windowing & Swift Concurrency",
    },
    {
      icon: Cpu,
      label: "Hardware Architecture",
      value: "Apple Silicon (M1/M2/M3/M4) & Intel 64-bit",
      detail: "Universal binary with native hardware media engine acceleration",
    },
    {
      icon: Shield,
      label: "Permissions",
      value: "Standard Accessibility Event Monitor",
      detail: "Needed exclusively to detect the physical Shift key during file dragging",
    },
    {
      icon: WifiOff,
      label: "Network Access",
      value: "100% Offline Capable",
      detail: "No internet connection required for core conversions",
    },
  ];

  return (
    <section className="py-16 md:py-20 bg-[#FAF8F3]">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="max-w-4xl mx-auto p-8 rounded-2xl bg-[#F3EEE4] border border-[#E5D8C7] shadow-xs space-y-6">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between pb-4 border-b border-[#E5D8C7] gap-2">
            <div>
              <span className="text-xs font-mono font-bold uppercase tracking-wider text-[#D98768]">
                Compatibility
              </span>
              <h3 className="font-serif text-2xl font-bold text-[#34312D]">
                System Requirements
              </h3>
            </div>
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#FAF8F3] border border-[#E5D8C7] text-xs font-mono text-[#465343] font-medium">
              Universal Release
            </span>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
            {specs.map((item, idx) => {
              const Icon = item.icon;
              return (
                <div key={idx} className="space-y-1.5">
                  <div className="flex items-center gap-2 text-xs font-medium text-[#465343]">
                    <Icon size={15} className="text-[#D98768]" />
                    <span>{item.label}</span>
                  </div>
                  <p className="font-serif text-base font-bold text-[#34312D]">
                    {item.value}
                  </p>
                  <p className="text-xs text-[#34312D]/70">
                    {item.detail}
                  </p>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </section>
  );
}
