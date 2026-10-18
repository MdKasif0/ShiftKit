"use client";

import React, { useState, useEffect } from "react";
import { MousePointer, Sparkles, CheckCircle2, FileText, CornerDownRight, Zap, RefreshCw } from "lucide-react";

export function InteractiveDemo() {
  const [activeStep, setActiveStep] = useState<number>(1);
  const [isAutoPlaying, setIsAutoPlaying] = useState<boolean>(true);

  useEffect(() => {
    if (!isAutoPlaying) return;
    const interval = setInterval(() => {
      setActiveStep((prev) => (prev % 3) + 1);
    }, 4500);
    return () => clearInterval(interval);
  }, [isAutoPlaying]);

  const steps = [
    {
      num: 1,
      title: "Hold Shift & Drag",
      subtitle: "Start dragging any file from Finder while holding the Shift key.",
      detail: "ShiftKit silently listens via macOS Accessibility event monitors without intercepting other apps or modifying Finder events.",
    },
    {
      num: 2,
      title: "Radial Menu Blooms",
      subtitle: "A circular HUD appears at your pointer with contextual actions.",
      detail: "Only operations strictly compatible with the inspected file type are shown: Convert, Compress, Crop/Trim, Merge, or Clean Metadata.",
    },
    {
      num: 3,
      title: "Instant Local Result",
      subtitle: "Your transformed file is written directly to disk.",
      detail: "No upload queue, zero cloud roundtrips. Every file is strictly validated for non-zero integrity before completion.",
    },
  ];

  return (
    <section id="interactive-demo" className="py-16 md:py-24 bg-[#F3EEE4] border-y border-[#E5D8C7]">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Section Header */}
        <div className="text-center max-w-2xl mx-auto space-y-3 mb-12">
          <span className="text-xs font-mono font-bold uppercase tracking-wider text-[#D98768]">
            Interactive Product Flow
          </span>
          <h2 className="font-serif text-3xl sm:text-4xl font-bold tracking-tight text-[#34312D]">
            Three steps. Zero friction.
          </h2>
          <p className="text-[#34312D]/80 text-base leading-relaxed">
            Experience how seamlessly ShiftKit fits into your daily macOS workflow without breaking your focus.
          </p>
        </div>

        {/* Step Selector Buttons */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-3.5 mb-8">
          {steps.map((s) => (
            <button
              key={s.num}
              type="button"
              onClick={() => {
                setIsAutoPlaying(false);
                setActiveStep(s.num);
              }}
              className={`p-5 rounded-xl text-left border transition-all cursor-pointer ${
                activeStep === s.num
                  ? "bg-[#FAF8F3] border-[#D98768] shadow-sm"
                  : "bg-[#FFFFFF] border-[#E5D8C7] hover:border-[#A8B5A0] opacity-80 hover:opacity-100"
              }`}
            >
              <div className="flex items-center justify-between mb-2">
                <span
                  className={`w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold font-mono ${
                    activeStep === s.num
                      ? "bg-[#D98768] text-[#FAF8F3]"
                      : "bg-[#F3EEE4] text-[#465343]"
                  }`}
                >
                  {s.num}
                </span>
                {activeStep === s.num && (
                  <span className="text-[11px] font-mono text-[#D98768] font-semibold uppercase tracking-wider">
                    Active Step
                  </span>
                )}
              </div>
              <h3 className="font-serif text-base font-bold text-[#34312D] mb-1">
                {s.title}
              </h3>
              <p className="text-xs text-[#34312D]/75 leading-relaxed">
                {s.subtitle}
              </p>
            </button>
          ))}
        </div>

        {/* Interactive Visual Stage */}
        <div className="rounded-2xl bg-[#FAF8F3] border border-[#E5D8C7] p-6 sm:p-10 shadow-sm relative overflow-hidden min-h-[380px] flex items-center justify-center">
          {/* Step 1 Visual */}
          {activeStep === 1 && (
            <div className="w-full max-w-lg space-y-6 text-center animate-fadeIn">
              <div className="inline-flex items-center gap-3 p-3 px-5 rounded-xl bg-[#FFFFFF] border border-[#E5D8C7] shadow-xs">
                <kbd className="px-2.5 py-1 text-sm font-mono font-bold bg-[#F3EEE4] border border-[#E5D8C7] rounded text-[#465343] shadow-2xs">
                  ⇧ Shift
                </kbd>
                <span className="text-xs font-medium text-[#34312D]">+</span>
                <span className="flex items-center gap-1.5 text-xs font-medium text-[#465343]">
                  <MousePointer size={14} className="text-[#D98768]" />
                  Drag File from Finder
                </span>
              </div>

              {/* Mock desktop dragging representation */}
              <div className="relative p-6 rounded-xl bg-[#F3EEE4] border border-[#E5D8C7] flex flex-col items-center justify-center space-y-3">
                <div className="w-48 p-3 rounded-lg bg-[#FFFFFF] border-2 border-dashed border-[#A8B5A0] shadow-md flex items-center gap-3 transform -rotate-1">
                  <div className="w-10 h-10 rounded bg-[#FAF8F3] border border-[#E5D8C7] flex items-center justify-center text-[#D98768]">
                    <FileText size={20} />
                  </div>
                  <div className="text-left">
                    <p className="text-xs font-semibold text-[#34312D] truncate w-28">
                      annual_report.pdf
                    </p>
                    <p className="text-[10px] text-[#34312D]/60">
                      18.4 MB • PDF Document
                    </p>
                  </div>
                </div>

                <p className="text-xs text-[#465343] font-medium">
                  Dragging detected • Modifier key recognized
                </p>
              </div>
            </div>
          )}

          {/* Step 2 Visual */}
          {activeStep === 2 && (
            <div className="w-full max-w-lg space-y-6 text-center animate-fadeIn">
              <div className="flex items-center justify-center gap-2 text-xs font-mono text-[#D98768] font-semibold">
                <Sparkles size={14} />
                <span>Radial Action Bloom (Contextual to PDF)</span>
              </div>

              <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 p-4 rounded-xl bg-[#F3EEE4] border border-[#E5D8C7]">
                <div className="p-3 rounded-lg bg-[#D98768] text-[#FAF8F3] text-left shadow-xs">
                  <span className="text-[10px] uppercase font-mono block opacity-85">Action 1</span>
                  <span className="text-xs font-bold block">Compress PDF</span>
                  <span className="text-[10px] opacity-80 block">Reduce 60-80%</span>
                </div>
                <div className="p-3 rounded-lg bg-[#FFFFFF] border border-[#E5D8C7] text-left hover:border-[#465343]">
                  <span className="text-[10px] uppercase font-mono text-[#465343] block">Action 2</span>
                  <span className="text-xs font-bold text-[#34312D] block">Merge Pages</span>
                  <span className="text-[10px] text-[#34312D]/60 block">With other files</span>
                </div>
                <div className="p-3 rounded-lg bg-[#FFFFFF] border border-[#E5D8C7] text-left hover:border-[#465343]">
                  <span className="text-[10px] uppercase font-mono text-[#465343] block">Action 3</span>
                  <span className="text-xs font-bold text-[#34312D] block">Split / Extract</span>
                  <span className="text-[10px] text-[#34312D]/60 block">Page selection</span>
                </div>
                <div className="p-3 rounded-lg bg-[#FFFFFF] border border-[#E5D8C7] text-left hover:border-[#465343]">
                  <span className="text-[10px] uppercase font-mono text-[#465343] block">Action 4</span>
                  <span className="text-xs font-bold text-[#34312D] block">Export PNGs</span>
                  <span className="text-[10px] text-[#34312D]/60 block">300 DPI raster</span>
                </div>
                <div className="p-3 rounded-lg bg-[#FFFFFF] border border-[#E5D8C7] text-left hover:border-[#465343]">
                  <span className="text-[10px] uppercase font-mono text-[#465343] block">Action 5</span>
                  <span className="text-xs font-bold text-[#34312D] block">Rotate Pages</span>
                  <span className="text-[10px] text-[#34312D]/60 block">90° / 180° / 270°</span>
                </div>
                <div className="p-3 rounded-lg bg-[#FFFFFF] border border-[#E5D8C7] text-left hover:border-[#465343]">
                  <span className="text-[10px] uppercase font-mono text-[#465343] block">Action 6</span>
                  <span className="text-xs font-bold text-[#34312D] block">Strip Metadata</span>
                  <span className="text-[10px] text-[#34312D]/60 block">Author & dates</span>
                </div>
              </div>
            </div>
          )}

          {/* Step 3 Visual */}
          {activeStep === 3 && (
            <div className="w-full max-w-lg space-y-6 text-center animate-fadeIn">
              <div className="flex items-center justify-center gap-2 text-xs font-mono text-[#465343] font-semibold">
                <CheckCircle2 size={16} className="text-[#D98768]" />
                <span>Output Validated & Committed to Disk</span>
              </div>

              <div className="p-6 rounded-xl bg-[#FFFFFF] border border-[#A8B5A0] shadow-sm flex flex-col items-center space-y-3">
                <div className="w-12 h-12 rounded-full bg-[#FAF8F3] border border-[#A8B5A0] flex items-center justify-center text-[#465343]">
                  <Zap size={22} className="stroke-[2.2]" />
                </div>
                <div>
                  <h4 className="font-serif text-sm font-bold text-[#34312D]">
                    annual_report_optimized.pdf
                  </h4>
                  <p className="text-xs text-[#465343] font-medium mt-0.5">
                    Size reduced from 18.4 MB → 3.8 MB (-79%)
                  </p>
                </div>
                <div className="text-[11px] text-[#34312D]/70 bg-[#F3EEE4] px-3 py-1.5 rounded-md border border-[#E5D8C7]">
                  Saved directly in ~/Documents • Revealed in Finder
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Autoplay toggle / reduced motion info */}
        <div className="mt-4 flex items-center justify-between text-xs text-[#465343]">
          <span>Click any step above to inspect each phase of the gesture workflow.</span>
          <button
            type="button"
            onClick={() => setIsAutoPlaying(!isAutoPlaying)}
            className="inline-flex items-center gap-1.5 hover:text-[#D98768] transition-colors"
          >
            <RefreshCw size={12} className={isAutoPlaying ? "animate-spin" : ""} />
            <span>{isAutoPlaying ? "Pause Auto-Advance" : "Resume Auto-Advance"}</span>
          </button>
        </div>
      </div>
    </section>
  );
}
