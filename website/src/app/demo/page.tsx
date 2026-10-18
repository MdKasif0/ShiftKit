"use client";

import React, { useState } from "react";
import Demo from "@/components/ui/demo";
import ShiftKitHalftoneFooter from "@/components/ShiftKitHalftoneFooter";

export default function DemoPage() {
  const [mode, setMode] = useState<"shiftkit" | "original">("shiftkit");

  return (
    <div className="min-h-screen bg-[#FAF8F3] text-[#34312D] flex flex-col justify-between">
      <div className="max-w-4xl mx-auto px-4 py-8 text-center space-y-4">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#F3EEE4] border border-[#E5D8C7] text-xs font-mono font-bold text-[#D98768]">
          <span>COMPONENT PREVIEW</span>
        </div>
        <h1 className="font-serif text-3xl sm:text-4xl font-bold text-[#34312D]">
          Halftone Wordmark Footer
        </h1>
        <p className="text-sm text-[#34312D]/80 max-w-lg mx-auto">
          Interactive 2D canvas with spring physics, dot halftone dispersion on cursor hover, and shock ring on click.
        </p>

        <div className="flex justify-center gap-3 pt-2">
          <button
            type="button"
            onClick={() => setMode("shiftkit")}
            className={`px-4 py-2 rounded-xl text-xs font-mono font-bold transition-all cursor-pointer ${
              mode === "shiftkit"
                ? "bg-[#D98768] text-[#FFFFFF] shadow-xs"
                : "bg-[#F3EEE4] text-[#34312D] border border-[#E5D8C7]"
            }`}
          >
            ShiftKit Brand Palette (Warm Ivory + Charcoal + Terracotta)
          </button>
          <button
            type="button"
            onClick={() => setMode("original")}
            className={`px-4 py-2 rounded-xl text-xs font-mono font-bold transition-all cursor-pointer ${
              mode === "original"
                ? "bg-[#D98768] text-[#FFFFFF] shadow-xs"
                : "bg-[#F3EEE4] text-[#34312D] border border-[#E5D8C7]"
            }`}
          >
            Original Halden Preset (Night)
          </button>
        </div>
      </div>

      <div className="w-full mt-auto">
        {mode === "shiftkit" ? <ShiftKitHalftoneFooter /> : <Demo />}
      </div>
    </div>
  );
}
