"use client";

import React from "react";
import { KeyRound, Compass, Cpu, CheckCircle } from "lucide-react";

export function HowItWorks() {
  const steps = [
    {
      icon: KeyRound,
      step: "01",
      title: "Hold Shift While Dragging",
      description:
        "Select one or more files in Finder and hold the Shift key. ShiftKit monitors the interaction securely through native macOS Accessibility APIs without touching other apps.",
    },
    {
      icon: Compass,
      step: "02",
      title: "Choose from the Radial Canvas",
      description:
        "The circular menu blooms right at your cursor. It automatically inspects the file headers to present only valid, high-impact operations for that exact format.",
    },
    {
      icon: Cpu,
      step: "03",
      title: "Asynchronous Local Processing",
      description:
        "Work executes entirely on your Mac’s CPU and Apple Silicon media engines. The UI stays snappy, and memory usage is throttled with a strict concurrency pool.",
    },
    {
      icon: CheckCircle,
      step: "04",
      title: "Verified Output on Disk",
      description:
        "ShiftKit verifies that the resulting file exists, has a positive byte size, and is readable before marking it complete and revealing it in Finder.",
    },
  ];

  return (
    <section id="how-it-works" className="py-20 md:py-28 bg-[#F3EEE4] border-t border-[#E5D8C7]">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="max-w-2xl mx-auto text-center space-y-3 mb-16">
          <span className="text-xs font-mono font-bold uppercase tracking-wider text-[#D98768]">
            Under The Hood
          </span>
          <h2 className="font-serif text-3xl sm:text-4xl font-bold tracking-tight text-[#34312D]">
            Engineered for pure speed and focus.
          </h2>
          <p className="text-sm sm:text-base text-[#34312D]/80 leading-relaxed">
            Designed from day one to feel like a native part of macOS. No web wrappers, no background daemons hogging battery, and zero cloud dependencies.
          </p>
        </div>

        {/* 4-Step Architecture Flow */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
          {steps.map((item) => {
            const Icon = item.icon;
            return (
              <div
                key={item.step}
                className="p-6 rounded-2xl bg-[#FAF8F3] border border-[#E5D8C7] shadow-xs flex flex-col justify-between space-y-4 hover:border-[#D98768] transition-colors"
              >
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <div className="w-10 h-10 rounded-lg bg-[#F3EEE4] border border-[#E5D8C7] flex items-center justify-center text-[#465343]">
                      <Icon size={20} className="stroke-[2]" />
                    </div>
                    <span className="font-mono text-xs font-bold text-[#D98768]">
                      {item.step}
                    </span>
                  </div>
                  <h3 className="font-serif text-lg font-bold text-[#34312D]">
                    {item.title}
                  </h3>
                  <p className="text-xs text-[#34312D]/75 leading-relaxed">
                    {item.description}
                  </p>
                </div>

                <div className="pt-2 border-t border-[#E5D8C7]/50 text-[10px] font-mono text-[#465343] font-medium">
                  Native Swift & AppKit
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
