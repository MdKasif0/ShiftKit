"use client";

import React, { useState, useEffect, useRef, useCallback } from "react";
import {
  MousePointer,
  Sparkles,
  FileText,
  Play,
  Pause,
  Folder,
  Eye,
  Zap,
  Sliders,
  Scissors,
  Layers,
  RotateCw,
  ShieldCheck,
  ArrowRight,
  Lightbulb,
  Check,
} from "lucide-react";

interface StepData {
  num: number;
  title: string;
  description: string;
  phaseLabel: string;
}

const STEPS: StepData[] = [
  {
    num: 1,
    title: "Hold Shift & Drag",
    description:
      "Start dragging any supported file from Finder while holding the Shift key.",
    phaseLabel: "Gesture Trigger",
  },
  {
    num: 2,
    title: "Radial Menu Appears",
    description:
      "A circular menu presents the actions available for your selected file.",
    phaseLabel: "Radial Bloom",
  },
  {
    num: 3,
    title: "Your File, Transformed",
    description:
      "The finished file is saved locally to your chosen destination.",
    phaseLabel: "Verified Output",
  },
];

interface RadialAction {
  id: string;
  name: string;
  shortLabel: string;
  icon: React.ComponentType<{ size?: number; className?: string }>;
  tag: string;
  description: string;
  metrics: string;
  presets: string[];
}

const RADIAL_ACTIONS: RadialAction[] = [
  {
    id: "compress",
    name: "Compress PDF",
    shortLabel: "Compress",
    icon: Sliders,
    tag: "Recommended",
    description: "Vector-preserving compression reducing file size up to 80%",
    metrics: "18.4 MB → 3.8 MB (-79%)",
    presets: ["Balanced (-79%)", "High Quality (-45%)", "Maximum (-88%)"],
  },
  {
    id: "convert",
    name: "Convert Document",
    shortLabel: "Convert",
    icon: RotateCw,
    tag: "Multi-Format",
    description: "Rasterize pages to PNG, WebP, or extract text structure",
    metrics: "24 Pages → Multi-page export",
    presets: ["PNG (300 DPI)", "WebP", "JPEG (Print)", "Plain Text"],
  },
  {
    id: "crop",
    name: "Crop / Trim Bounds",
    shortLabel: "Crop",
    icon: Scissors,
    tag: "Geometry",
    description: "Trim white margins or frame pages to exact aspect ratios",
    metrics: "24 pages framed to 4:3",
    presets: ["Trim White Borders", "4:3 Document", "16:9 Slide", "Custom"],
  },
  {
    id: "extract",
    name: "Extract Pages",
    shortLabel: "Extract",
    icon: Layers,
    tag: "Split",
    description: "Pull specific page ranges or extract embedded images",
    metrics: "Pages 1–5 → separate PDF",
    presets: ["Pages 1–5 only", "Odd / Even Sheets", "Extract All Images"],
  },
  {
    id: "merge",
    name: "Merge Documents",
    shortLabel: "Merge",
    icon: Folder,
    tag: "Combine",
    description: "Combine with additional dropped files sequentially",
    metrics: "+ Queue ready for drop",
    presets: ["Append to End", "Prepend to Front", "Interleave Pages"],
  },
  {
    id: "sanitize",
    name: "Sanitize Metadata",
    shortLabel: "Sanitize",
    icon: ShieldCheck,
    tag: "Privacy",
    description: "Scrub author names, creation timestamps, and hidden tags",
    metrics: "8 metadata fields scrubbed",
    presets: ["Strip All Tags", "Preserve Title only", "Flatten Annotations"],
  },
];

export function InteractiveDemo() {
  const [activeStep, setActiveStep] = useState<number>(1);
  const [isAutoPlaying, setIsAutoPlaying] = useState<boolean>(true);
  const [selectedActionId, setSelectedActionId] = useState<string>("compress");
  const autoPlayTimerRef = useRef<NodeJS.Timeout | null>(null);

  const selectedAction =
    RADIAL_ACTIONS.find((a) => a.id === selectedActionId) || RADIAL_ACTIONS[0];

  const STEP_DURATION = 6000;

  const clearTimer = useCallback(() => {
    if (autoPlayTimerRef.current) {
      clearInterval(autoPlayTimerRef.current);
      autoPlayTimerRef.current = null;
    }
  }, []);

  useEffect(() => {
    if (typeof window !== "undefined") {
      const mediaQuery = window.matchMedia("(prefers-reduced-motion: reduce)");
      if (mediaQuery.matches) {
        setIsAutoPlaying(false);
        return;
      }
    }

    if (!isAutoPlaying) {
      clearTimer();
      return;
    }

    clearTimer();
    autoPlayTimerRef.current = setInterval(() => {
      setActiveStep((prev) => (prev % 3) + 1);
    }, STEP_DURATION);

    return () => clearTimer();
  }, [isAutoPlaying, clearTimer]);

  const handleStepSelect = (stepNum: number) => {
    setIsAutoPlaying(false);
    clearTimer();
    setActiveStep(stepNum);
  };

  const toggleAutoPlay = () => {
    if (isAutoPlaying) {
      setIsAutoPlaying(false);
      clearTimer();
    } else {
      setIsAutoPlaying(true);
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent, currentStep: number) => {
    if (e.key === "ArrowRight") {
      e.preventDefault();
      const next = currentStep === 3 ? 1 : currentStep + 1;
      handleStepSelect(next);
    } else if (e.key === "ArrowLeft") {
      e.preventDefault();
      const prev = currentStep === 1 ? 3 : currentStep - 1;
      handleStepSelect(prev);
    }
  };

  return (
    <section
      id="interactive-flow"
      aria-label="ShiftKit Interactive Workflow"
      className="relative py-12 md:py-18 bg-[#F3EEE4] border-y border-[#E5D8C7] overflow-hidden"
    >
      <div id="interactive-demo" className="absolute -top-20" aria-hidden="true" />

      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* ========================================================= */}
        {/* SECTION HEADER                                            */}
        {/* ========================================================= */}
        <div className="text-center max-w-2xl mx-auto mb-6 md:mb-8">
          <div className="inline-flex items-center gap-1.5 px-3 py-0.5 rounded-full bg-[#FAF8F3] border border-[#E5D8C7] mb-2.5 shadow-2xs">
            <span className="w-1.5 h-1.5 rounded-full bg-[#D98768]" />
            <span className="text-[11px] font-mono font-bold uppercase tracking-widest text-[#D98768]">
              Interactive Product Flow
            </span>
          </div>

          <h2 className="font-serif text-3xl sm:text-4xl font-bold tracking-tight text-[#34312D] mb-2">
            Three steps. Zero friction.
          </h2>

          <p className="text-xs sm:text-sm text-[#34312D]/80 leading-relaxed max-w-lg mx-auto">
            Experience how seamlessly ShiftKit fits into your daily macOS workflow
            without breaking your focus.
          </p>
        </div>

        {/* ========================================================= */}
        {/* 3-STEP SELECTOR SEQUENCE                                  */}
        {/* ========================================================= */}
        <div className="relative mb-5" role="tablist" aria-label="Workflow Steps">
          {/* Subtle Progress Track behind cards (Desktop) */}
          <div className="hidden md:block absolute top-[24px] left-[15%] right-[15%] h-[2px] bg-[#E5D8C7] -z-0">
            <div
              className="h-full bg-[#D98768] transition-all duration-500 ease-out"
              style={{
                width: activeStep === 1 ? "0%" : activeStep === 2 ? "50%" : "100%",
              }}
            />
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-3 relative z-10">
            {STEPS.map((s) => {
              const isActive = activeStep === s.num;
              const isPast = activeStep > s.num;

              return (
                <button
                  key={s.num}
                  type="button"
                  role="tab"
                  id={`tab-step-${s.num}`}
                  aria-selected={isActive}
                  aria-controls={`panel-step-${s.num}`}
                  tabIndex={isActive ? 0 : -1}
                  onClick={() => handleStepSelect(s.num)}
                  onKeyDown={(e) => handleKeyDown(e, s.num)}
                  className={`group relative p-3.5 sm:p-4 rounded-xl text-left transition-all duration-200 cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#D98768] ${
                    isActive
                      ? "bg-[#FAF8F3] border-2 border-[#D98768] shadow-[0_4px_16px_rgba(217,135,104,0.12)] -translate-y-0.5"
                      : "bg-[#FFFFFF] border border-[#E5D8C7] hover:border-[#A8B5A0] hover:bg-[#FAF8F3]/60"
                  }`}
                >
                  <div className="flex items-center justify-between mb-2">
                    <div className="flex items-center gap-2">
                      <span
                        className={`w-6 h-6 rounded-full flex items-center justify-center text-[11px] font-mono font-bold transition-colors ${
                          isActive
                            ? "bg-[#D98768] text-[#FAF8F3] shadow-xs"
                            : isPast
                            ? "bg-[#465343] text-[#FAF8F3]"
                            : "bg-[#F3EEE4] text-[#465343] border border-[#E5D8C7]"
                        }`}
                      >
                        {isPast ? <Check size={12} strokeWidth={3} /> : `0${s.num}`}
                      </span>

                      <span
                        className={`text-[9.5px] font-mono uppercase tracking-wider font-semibold ${
                          isActive ? "text-[#D98768]" : "text-[#898177]"
                        }`}
                      >
                        {s.phaseLabel}
                      </span>
                    </div>

                    {isActive ? (
                      <span className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded-full bg-[#FAF8F3] border border-[#D98768]/40 text-[9.5px] font-mono font-bold text-[#D98768]">
                        <span className="w-1.5 h-1.5 rounded-full bg-[#D98768] animate-pulse" />
                        ACTIVE
                      </span>
                    ) : (
                      <span className="text-[10.5px] font-mono text-[#898177] group-hover:text-[#465343] transition-colors">
                        Step {s.num}
                      </span>
                    )}
                  </div>

                  <h3
                    className={`font-serif text-sm sm:text-base font-bold mb-1 transition-colors ${
                      isActive ? "text-[#34312D]" : "text-[#34312D]/90"
                    }`}
                  >
                    {s.title}
                  </h3>

                  <p className="text-[11px] sm:text-xs text-[#34312D]/75 leading-relaxed line-clamp-2">
                    {s.description}
                  </p>
                </button>
              );
            })}
          </div>
        </div>

        {/* ========================================================= */}
        {/* PRODUCT DEMONSTRATION WINDOW PANEL (MAIN STAGE)           */}
        {/* ========================================================= */}
        <div
          id={`panel-step-${activeStep}`}
          role="tabpanel"
          aria-labelledby={`tab-step-${activeStep}`}
          className="rounded-2xl bg-[#FAF8F3] border border-[#E5D8C7] shadow-[0_10px_30px_rgba(52,49,45,0.06)] overflow-hidden transition-all duration-300"
        >
          {/* macOS App Window Header Bar */}
          <div className="px-4 sm:px-5 py-2.5 bg-[#F3EEE4]/90 border-b border-[#E5D8C7] flex items-center justify-between">
            <div className="flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 rounded-full bg-[#E58871] border border-[#D2735B]" />
              <span className="w-2.5 h-2.5 rounded-full bg-[#E6BF68] border border-[#CDA750]" />
              <span className="w-2.5 h-2.5 rounded-full bg-[#8EA87D] border border-[#7A9569]" />
              <span className="ml-2 text-[11px] font-mono text-[#898177] hidden sm:inline">
                ShiftKit • Interactive Preview
              </span>
            </div>

            <div className="flex items-center gap-1.5 text-[10.5px] font-mono font-medium">
              <span
                className={`px-1.5 py-0.5 rounded ${
                  activeStep === 1
                    ? "bg-[#D98768] text-[#FAF8F3] font-bold"
                    : "text-[#898177]"
                }`}
              >
                1. Drag
              </span>
              <span className="text-[#898177]">•</span>
              <span
                className={`px-1.5 py-0.5 rounded ${
                  activeStep === 2
                    ? "bg-[#D98768] text-[#FAF8F3] font-bold"
                    : "text-[#898177]"
                }`}
              >
                2. Radial Action
              </span>
              <span className="text-[#898177]">•</span>
              <span
                className={`px-1.5 py-0.5 rounded ${
                  activeStep === 3
                    ? "bg-[#D98768] text-[#FAF8F3] font-bold"
                    : "text-[#898177]"
                }`}
              >
                3. Result
              </span>
            </div>
          </div>

          {/* Demonstration Canvas Body */}
          <div className="p-4 sm:p-6 min-h-[360px] md:min-h-[380px] flex items-center justify-center relative">
            {/* Ambient Petal Rings in Background */}
            <svg
              className="absolute inset-0 w-full h-full pointer-events-none opacity-20"
              viewBox="0 0 900 380"
              fill="none"
            >
              <circle
                cx="450"
                cy="190"
                r="140"
                stroke="#E5D8C7"
                strokeWidth="1"
                strokeDasharray="4 6"
              />
              <circle cx="450" cy="190" r="230" stroke="#E5D8C7" strokeWidth="1" />
            </svg>

            {/* ------------------------------------------------------- */}
            {/* STEP 1: HOLD SHIFT & DRAG                               */}
            {/* ------------------------------------------------------- */}
            {activeStep === 1 && (
              <div className="w-full max-w-4xl grid grid-cols-1 lg:grid-cols-12 gap-5 items-center">
                {/* Left Column: Finder Window View (7 cols) */}
                <div className="lg:col-span-7 rounded-xl bg-[#FFFFFF] border border-[#E5D8C7] shadow-xs overflow-hidden">
                  <div className="px-3.5 py-2 bg-[#FAF8F3] border-b border-[#E5D8C7] flex items-center justify-between text-xs text-[#898177]">
                    <div className="flex items-center gap-1.5">
                      <Folder size={13} className="text-[#465343]" />
                      <span className="font-semibold text-[#34312D]">Documents</span>
                    </div>
                    <span className="font-mono text-[10px]">3 items</span>
                  </div>

                  <div className="grid grid-cols-12 divide-x divide-[#E5D8C7]">
                    {/* Finder Sidebar */}
                    <div className="col-span-4 p-2.5 bg-[#FAF8F3]/60 hidden sm:block text-[10.5px] space-y-1">
                      <div className="text-[9px] font-mono uppercase font-bold text-[#898177] px-1.5 py-0.5">
                        Favorites
                      </div>
                      <div className="px-1.5 py-0.5 rounded text-[#898177]">Recents</div>
                      <div className="px-1.5 py-0.5 rounded bg-[#E5D8C7]/60 font-semibold text-[#34312D]">
                        Desktop
                      </div>
                      <div className="px-1.5 py-0.5 rounded text-[#898177]">Documents</div>
                      <div className="px-1.5 py-0.5 rounded text-[#898177]">Downloads</div>
                    </div>

                    {/* Finder File Table */}
                    <div className="col-span-12 sm:col-span-8 p-2.5 space-y-1.5">
                      <div className="p-2 rounded-lg bg-[#F5D5C2]/40 border-2 border-dashed border-[#D98768] flex items-center justify-between shadow-2xs">
                        <div className="flex items-center gap-2">
                          <div className="w-7 h-7 rounded bg-[#FAF8F3] border border-[#E5D8C7] flex items-center justify-center text-[#D98768] shadow-2xs">
                            <FileText size={15} />
                          </div>
                          <div>
                            <p className="text-xs font-bold text-[#34312D]">
                              annual_report.pdf
                            </p>
                            <p className="text-[9.5px] text-[#465343] font-medium">
                              18.4 MB • PDF Document
                            </p>
                          </div>
                        </div>
                        <span className="px-1.5 py-0.5 rounded text-[9.5px] font-mono font-bold bg-[#D98768] text-[#FAF8F3]">
                          Selected
                        </span>
                      </div>

                      <div className="p-2 rounded bg-[#FAF8F3]/70 border border-[#E5D8C7]/60 flex items-center justify-between opacity-75">
                        <div className="flex items-center gap-2">
                          <div className="w-6 h-6 rounded bg-[#F3EEE4] flex items-center justify-center text-[#465343]">
                            <FileText size={13} />
                          </div>
                          <div>
                            <p className="text-[11px] font-medium text-[#34312D]">
                              quarterly_budget.xlsx
                            </p>
                            <p className="text-[9px] text-[#898177]">2.4 MB • Spreadsheet</p>
                          </div>
                        </div>
                        <span className="text-[9.5px] font-mono text-[#898177]">Ready</span>
                      </div>

                      <div className="p-2 rounded bg-[#FAF8F3]/70 border border-[#E5D8C7]/60 flex items-center justify-between opacity-75">
                        <div className="flex items-center gap-2">
                          <div className="w-6 h-6 rounded bg-[#F3EEE4] flex items-center justify-center text-[#465343]">
                            <FileText size={13} />
                          </div>
                          <div>
                            <p className="text-[11px] font-medium text-[#34312D]">
                              hero_keynote.key
                            </p>
                            <p className="text-[9px] text-[#898177]">14.2 MB • Presentation</p>
                          </div>
                        </div>
                        <span className="text-[9.5px] font-mono text-[#898177]">Ready</span>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Right Column: Active Drag & Radial Target Zone (5 cols) */}
                <div className="lg:col-span-5 flex flex-col items-center justify-center space-y-3">
                  <div className="relative w-full max-w-xs">
                    {/* Tactile Shift Key Indicator */}
                    <div className="mb-2.5 flex items-center justify-center gap-2">
                      <div className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-[#F3EEE4] border-b-2 border-r-2 border-[#D9C8B5] shadow-xs">
                        <kbd className="px-1.5 py-0.5 rounded bg-[#FAF8F3] border border-[#E5D8C7] text-[11px] font-mono font-bold text-[#34312D] shadow-2xs">
                          ⇧ Shift
                        </kbd>
                        <span className="text-[10px] font-mono font-bold text-[#D98768] uppercase tracking-wider">
                          Key Held
                        </span>
                      </div>
                      <span className="text-[11px] text-[#898177] font-mono">+ Drag</span>
                    </div>

                    {/* Dropping Canvas Card */}
                    <div className="p-4 rounded-xl bg-[#FFFFFF] border-2 border-dashed border-[#D98768] shadow-sm text-center relative overflow-hidden">
                      <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-lg bg-[#FAF8F3] border border-[#D98768] shadow-sm mb-2.5 transform -rotate-1">
                        <FileText size={15} className="text-[#D98768]" />
                        <span className="text-xs font-bold text-[#34312D]">
                          annual_report.pdf
                        </span>
                        <div className="w-4.5 h-4.5 rounded-full bg-[#D98768] text-[#FAF8F3] flex items-center justify-center">
                          <MousePointer size={10} className="fill-current" />
                        </div>
                      </div>

                      <div className="space-y-0.5">
                        <p className="font-serif text-sm font-bold text-[#34312D]">
                          Drop into Gesture Zone
                        </p>
                        <p className="text-[11px] text-[#465343] leading-relaxed">
                          Releasing with Shift held summons the radial action canvas instantly.
                        </p>
                      </div>

                      <div className="mt-2.5 inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-[#E8EFE5] border border-[#A8B5A0] text-[9.5px] font-mono font-bold text-[#465343]">
                        <Check size={11} strokeWidth={2.5} />
                        Modifier recognized • Ready for Bloom
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* ------------------------------------------------------- */}
            {/* STEP 2: RADIAL MENU BLOOMS                              */}
            {/* ------------------------------------------------------- */}
            {activeStep === 2 && (
              <div className="w-full max-w-4xl grid grid-cols-1 lg:grid-cols-12 gap-5 items-center">
                {/* Left Side: Dragged Context Summary (3 cols) */}
                <div className="lg:col-span-3 space-y-2.5 hidden lg:block">
                  <div className="p-3.5 rounded-xl bg-[#FFFFFF] border border-[#E5D8C7] shadow-xs space-y-2.5">
                    <div className="flex items-center gap-1.5 text-[11px] font-mono font-bold text-[#D98768]">
                      <Sparkles size={12} />
                      <span>Contextual HUD</span>
                    </div>

                    <div className="flex items-center gap-2 pt-1 border-t border-[#E5D8C7]/60">
                      <div className="w-8 h-8 rounded bg-[#FAF8F3] border border-[#E5D8C7] flex items-center justify-center text-[#D98768]">
                        <FileText size={16} />
                      </div>
                      <div>
                        <p className="text-xs font-bold text-[#34312D]">annual_report.pdf</p>
                        <p className="text-[9.5px] text-[#465343]">18.4 MB • 24 Pages</p>
                      </div>
                    </div>

                    <p className="text-[10.5px] text-[#898177] leading-relaxed">
                      ShiftKit inspected the file header and revealed 6 dedicated PDF operations.
                    </p>

                    <div className="inline-flex items-center gap-1 text-[9.5px] font-mono text-[#465343] bg-[#F3EEE4] px-2 py-0.5 rounded">
                      <span>Click segment to preview</span>
                    </div>
                  </div>
                </div>

                {/* Center: The Precision Circular Radial HUD (5 cols) */}
                <div className="lg:col-span-5 flex flex-col items-center justify-center">
                  <div className="relative w-[260px] h-[260px] sm:w-[280px] sm:h-[280px]">
                    <svg
                      viewBox="0 0 320 320"
                      className="w-full h-full drop-shadow-sm select-none"
                    >
                      <circle
                        cx="160"
                        cy="160"
                        r="154"
                        fill="none"
                        stroke="#E5D8C7"
                        strokeWidth="1"
                        strokeDasharray="4 4"
                      />

                      {RADIAL_ACTIONS.map((action, index) => {
                        const angles = [-90, -30, 30, 90, 150, 210];
                        const centerDeg = angles[index];
                        const halfSpan = (27.5 * Math.PI) / 180;
                        const midRad = (centerDeg * Math.PI) / 180;

                        const R = 150;
                        const r = 58;
                        const cx = 160;
                        const cy = 160;

                        const a1 = midRad - halfSpan;
                        const a2 = midRad + halfSpan;

                        const x1 = cx + r * Math.cos(a1);
                        const y1 = cy + r * Math.sin(a1);
                        const x2 = cx + R * Math.cos(a1);
                        const y2 = cy + R * Math.sin(a1);
                        const x3 = cx + R * Math.cos(a2);
                        const y3 = cy + R * Math.sin(a2);
                        const x4 = cx + r * Math.cos(a2);
                        const y4 = cy + r * Math.sin(a2);

                        const pathData = `M ${x1.toFixed(1)} ${y1.toFixed(1)} L ${x2.toFixed(1)} ${y2.toFixed(1)} A ${R} ${R} 0 0 1 ${x3.toFixed(1)} ${y3.toFixed(1)} L ${x4.toFixed(1)} ${y4.toFixed(1)} A ${r} ${r} 0 0 0 ${x1.toFixed(1)} ${y1.toFixed(1)} Z`;

                        const isSelected = selectedActionId === action.id;
                        const midR = (R + r) / 2;
                        const labelX = cx + midR * Math.cos(midRad);
                        const labelY = cy + midR * Math.sin(midRad);

                        return (
                          <g
                            key={action.id}
                            className="cursor-pointer transition-all duration-150"
                            onClick={() => setSelectedActionId(action.id)}
                          >
                            <path
                              d={pathData}
                              fill={isSelected ? "#D98768" : "#FFFFFF"}
                              stroke={isSelected ? "#C47456" : "#E5D8C7"}
                              strokeWidth={isSelected ? "2" : "1.2"}
                              className="hover:fill-[#F3EEE4] transition-colors"
                            />
                            <text
                              x={labelX}
                              y={labelY + (centerDeg === 90 ? 4 : 0)}
                              textAnchor="middle"
                              dominantBaseline="central"
                              fill={isSelected ? "#FAF8F3" : "#34312D"}
                              fontSize="11"
                              fontFamily="system-ui, -apple-system, sans-serif"
                              fontWeight={isSelected ? "700" : "600"}
                              className="pointer-events-none select-none tracking-tight"
                            >
                              {action.shortLabel}
                            </text>
                          </g>
                        );
                      })}

                      <circle
                        cx="160"
                        cy="160"
                        r="52"
                        fill="#FAF8F3"
                        stroke="#E5D8C7"
                        strokeWidth="2"
                      />
                    </svg>

                    <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none text-center">
                      <div className="w-6 h-6 rounded bg-[#FFFFFF] border border-[#E5D8C7] flex items-center justify-center text-[#D98768] mb-0.5 shadow-2xs">
                        <FileText size={13} />
                      </div>
                      <p className="text-[9.5px] font-bold text-[#34312D] leading-tight">
                        annual_report
                      </p>
                      <p className="text-[8.5px] font-mono text-[#898177]">18.4 MB • PDF</p>
                    </div>
                  </div>

                  <p className="text-[11px] text-[#465343] font-medium mt-2 text-center">
                    Tap any action segment to inspect parameters
                  </p>
                </div>

                {/* Right Side: Live Action Inspector Card (4 cols) */}
                <div className="lg:col-span-4">
                  <div className="p-3.5 sm:p-4 rounded-xl bg-[#FFFFFF] border-2 border-[#D98768]/60 shadow-xs space-y-2.5">
                    <div className="flex items-center justify-between pb-2 border-b border-[#E5D8C7]">
                      <div className="flex items-center gap-1.5">
                        <div className="w-7 h-7 rounded bg-[#FAF8F3] border border-[#E5D8C7] flex items-center justify-center text-[#D98768]">
                          {React.createElement(selectedAction.icon, { size: 15 })}
                        </div>
                        <div>
                          <h4 className="font-serif text-xs sm:text-sm font-bold text-[#34312D]">
                            {selectedAction.name}
                          </h4>
                          <span className="text-[9.5px] font-mono text-[#898177]">
                            {selectedAction.tag} Operation
                          </span>
                        </div>
                      </div>
                      <span className="px-1.5 py-0.5 rounded text-[9px] font-mono font-bold bg-[#E8EFE5] text-[#465343] border border-[#A8B5A0]">
                        Active
                      </span>
                    </div>

                    <p className="text-[11px] text-[#34312D]/80 leading-relaxed">
                      {selectedAction.description}
                    </p>

                    <div className="space-y-1">
                      <span className="text-[9.5px] font-mono uppercase text-[#898177] font-bold">
                        Presets & Quality:
                      </span>
                      <div className="grid grid-cols-1 gap-1">
                        {selectedAction.presets.map((preset, idx) => (
                          <div
                            key={preset}
                            className={`px-2.5 py-1 rounded text-[11px] font-medium flex items-center justify-between ${
                              idx === 0
                                ? "bg-[#FAF8F3] border border-[#D98768] text-[#34312D] font-bold"
                                : "bg-[#FAF8F3]/60 border border-[#E5D8C7] text-[#898177]"
                            }`}
                          >
                            <span>{preset}</span>
                            {idx === 0 && (
                              <Check size={11} className="text-[#D98768]" strokeWidth={3} />
                            )}
                          </div>
                        ))}
                      </div>
                    </div>

                    <div className="p-2 rounded-lg bg-[#FAF8F3] border border-[#E5D8C7] flex items-center justify-between">
                      <span className="text-[10.5px] text-[#465343] font-medium">Estimated Output:</span>
                      <span className="text-[11px] font-mono font-bold text-[#D98768]">
                        {selectedAction.metrics}
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* ------------------------------------------------------- */}
            {/* STEP 3: YOUR FILE, TRANSFORMED                          */}
            {/* ------------------------------------------------------- */}
            {activeStep === 3 && (
              <div className="w-full max-w-4xl grid grid-cols-1 md:grid-cols-12 gap-4 items-center">
                {/* Source File Card (5 cols) */}
                <div className="md:col-span-5 p-4 rounded-xl bg-[#FFFFFF] border border-[#E5D8C7] shadow-xs space-y-2.5">
                  <div className="flex items-center justify-between">
                    <span className="px-2 py-0.5 rounded text-[9.5px] font-mono font-bold uppercase bg-[#F3EEE4] text-[#898177] border border-[#E5D8C7]">
                      Original Source
                    </span>
                    <span className="text-[11px] font-mono text-[#898177]">Finder Input</span>
                  </div>

                  <div className="flex items-center gap-2.5 py-1">
                    <div className="w-10 h-10 rounded-lg bg-[#FAF8F3] border border-[#E5D8C7] flex items-center justify-center text-[#898177]">
                      <FileText size={20} />
                    </div>
                    <div>
                      <h4 className="font-serif text-sm font-bold text-[#34312D]">
                        annual_report.pdf
                      </h4>
                      <p className="text-[11px] font-mono text-[#898177]">18.4 MB • 24 Pages</p>
                    </div>
                  </div>

                  <div className="pt-2 border-t border-[#E5D8C7]/70 text-[10.5px] text-[#898177] space-y-0.5">
                    <div className="flex justify-between">
                      <span>Source:</span>
                      <span className="font-mono text-[#34312D]">~/Desktop/</span>
                    </div>
                    <div className="flex justify-between">
                      <span>Original State:</span>
                      <span>Unmodified on Disk</span>
                    </div>
                  </div>
                </div>

                {/* Central Pipeline Telemetry (2 cols) */}
                <div className="md:col-span-2 flex flex-col items-center justify-center space-y-1.5 py-1">
                  <div className="w-8 h-8 rounded-full bg-[#E8EFE5] border border-[#A8B5A0] flex items-center justify-center text-[#465343] shadow-xs">
                    <Zap size={15} strokeWidth={2.4} />
                  </div>
                  <div className="text-center space-y-0.5">
                    <span className="text-[10.5px] font-mono font-bold text-[#465343] block">
                      0.28s
                    </span>
                    <span className="text-[8.5px] font-mono uppercase text-[#898177] block">
                      Apple Media Engine
                    </span>
                  </div>
                  <ArrowRight size={14} className="text-[#D98768] hidden md:block" />
                </div>

                {/* Transformed Output Card (5 cols) */}
                <div className="md:col-span-5 p-4 rounded-xl bg-[#FFFFFF] border-2 border-[#465343]/50 shadow-sm space-y-2.5 relative overflow-hidden">
                  <div className="flex items-center justify-between">
                    <span className="px-2 py-0.5 rounded text-[9.5px] font-mono font-bold uppercase bg-[#E8EFE5] text-[#465343] border border-[#A8B5A0]">
                      Optimized Output
                    </span>
                    <span className="px-2 py-0.5 rounded text-[9.5px] font-mono font-bold bg-[#D98768] text-[#FAF8F3]">
                      -79% Size Reduced
                    </span>
                  </div>

                  <div className="flex items-center gap-2.5 py-1">
                    <div className="w-10 h-10 rounded-lg bg-[#FAF8F3] border border-[#A8B5A0] flex items-center justify-center text-[#465343] relative shadow-2xs">
                      <FileText size={20} />
                      <div className="absolute -bottom-1 -right-1 w-3.5 h-3.5 rounded-full bg-[#465343] text-[#FAF8F3] flex items-center justify-center">
                        <Check size={9} strokeWidth={3} />
                      </div>
                    </div>
                    <div>
                      <h4 className="font-serif text-sm font-bold text-[#34312D]">
                        annual_report_compressed.pdf
                      </h4>
                      <p className="text-[11px] font-mono font-bold text-[#465343]">
                        3.8 MB <span className="text-[#898177] font-normal">(was 18.4 MB)</span>
                      </p>
                    </div>
                  </div>

                  <div className="pt-2 border-t border-[#E5D8C7]/70 space-y-2">
                    <div className="flex items-center justify-between text-[10.5px]">
                      <span className="text-[#898177]">Committed to:</span>
                      <span className="font-mono text-[#465343] font-medium truncate max-w-[170px]">
                        ~/Documents/annual_report_compressed.pdf
                      </span>
                    </div>

                    <div className="grid grid-cols-2 gap-1.5 pt-0.5">
                      <button
                        type="button"
                        className="px-2 py-1.5 rounded-lg bg-[#FAF8F3] border border-[#E5D8C7] hover:border-[#465343] text-[10.5px] font-medium text-[#34312D] flex items-center justify-center gap-1 transition-colors cursor-pointer"
                      >
                        <Folder size={11} className="text-[#465343]" />
                        <span>Reveal in Finder</span>
                      </button>
                      <button
                        type="button"
                        className="px-2 py-1.5 rounded-lg bg-[#FAF8F3] border border-[#E5D8C7] hover:border-[#465343] text-[10.5px] font-medium text-[#34312D] flex items-center justify-center gap-1 transition-colors cursor-pointer"
                      >
                        <Eye size={11} className="text-[#465343]" />
                        <span>Quick Look</span>
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            )}
          </div>

          {/* ======================================================= */}
          {/* WINDOW FOOTER UTILITY BAR                                */}
          {/* ======================================================= */}
          <div className="px-4 sm:px-5 py-2.5 bg-[#F3EEE4]/90 border-t border-[#E5D8C7] flex flex-col sm:flex-row items-center justify-between gap-2.5 text-xs text-[#465343]">
            <div className="flex items-center gap-1.5 text-center sm:text-left">
              <Lightbulb size={13} className="text-[#D98768] shrink-0" />
              <span className="text-[11px] sm:text-xs">
                {activeStep === 1 &&
                  "Hold Shift before or during the drag action to wake ShiftKit."}
                {activeStep === 2 &&
                  "Click any radial segment above to inspect options and parameters."}
                {activeStep === 3 &&
                  "100% on-device processing. Output is committed to disk in milliseconds."}
              </span>
            </div>

            <div className="flex items-center gap-2.5 shrink-0">
              <div className="flex items-center gap-1">
                {[1, 2, 3].map((dot) => (
                  <span
                    key={dot}
                    className={`h-1.5 rounded-full transition-all duration-300 ${
                      activeStep === dot
                        ? "bg-[#D98768] w-3.5"
                        : "bg-[#E5D8C7] w-1.5"
                    }`}
                  />
                ))}
              </div>

              <button
                type="button"
                onClick={toggleAutoPlay}
                className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-[#FAF8F3] border border-[#E5D8C7] hover:border-[#D98768] hover:text-[#D98768] transition-colors font-mono text-[10.5px] font-medium cursor-pointer shadow-2xs"
                aria-label={isAutoPlaying ? "Pause preview auto-advance" : "Resume preview auto-advance"}
              >
                {isAutoPlaying ? (
                  <>
                    <Pause size={11} className="text-[#D98768]" />
                    <span>Pause Preview</span>
                  </>
                ) : (
                  <>
                    <Play size={11} className="text-[#465343]" />
                    <span>Resume Auto-Advance</span>
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
