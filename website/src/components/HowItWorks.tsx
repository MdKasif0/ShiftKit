"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  FileText,
  Compass,
  Cpu,
  CheckCircle2,
  Play,
  Pause,
  RefreshCw,
  FolderArchive,
  Copy,
  Edit3,
  Scissors,
  Layers,
  ChevronDown,
  Info,
  Check,
  MousePointer,
  Sparkles,
  Zap,
} from "lucide-react";

export function HowItWorks() {
  const [activeStep, setActiveStep] = useState<number>(2);
  const [selectedAction, setSelectedAction] = useState<string>("Convert");
  const [selectedFormat, setSelectedFormat] = useState<string>("WEBP");
  const [isPlaying, setIsPlaying] = useState<boolean>(true);
  const autoAdvanceTimerRef = useRef<NodeJS.Timeout | null>(null);

  const steps = [
    {
      id: 1,
      num: "01",
      icon: FileText,
      title: "Hold Shift & Drag",
      subtitle: "Select one or more files",
      description:
        "Select files in Finder and hold Shift while dragging. ShiftKit detects the gesture securely via macOS Accessibility APIs.",
      statusText: "Hold Shift and drag a file to begin",
    },
    {
      id: 2,
      num: "02",
      icon: Compass,
      title: "Choose an Action",
      subtitle: "Open the radial canvas",
      description:
        "A circular menu blooms right at your cursor, inspecting file headers to present high-impact actions for that exact format.",
      statusText: "Choose an action to continue",
    },
    {
      id: 3,
      num: "03",
      icon: Cpu,
      title: "Process Locally",
      subtitle: "Runs natively on your Mac",
      description:
        "Execution happens on your Mac's CPU and Apple Silicon media engines with zero network requests and strict memory safety.",
      statusText: "Processing locally using native macOS engines...",
    },
    {
      id: 4,
      num: "04",
      icon: CheckCircle2,
      title: "Get the Result",
      subtitle: "Verified output on disk",
      description:
        "ShiftKit verifies that the resulting file exists, is intact, and readable before revealing it in Finder.",
      statusText: "File verified and saved to destination",
    },
  ];

  // Auto-advance workflow preview unless paused by user
  useEffect(() => {
    if (!isPlaying) {
      if (autoAdvanceTimerRef.current) {
        clearInterval(autoAdvanceTimerRef.current);
        autoAdvanceTimerRef.current = null;
      }
      return;
    }

    autoAdvanceTimerRef.current = setInterval(() => {
      setActiveStep((prev) => (prev % 4) + 1);
    }, 4500);

    return () => {
      if (autoAdvanceTimerRef.current) {
        clearInterval(autoAdvanceTimerRef.current);
        autoAdvanceTimerRef.current = null;
      }
    };
  }, [isPlaying]);

  const handleStepClick = (stepId: number) => {
    setActiveStep(stepId);
  };

  const togglePlay = () => {
    setIsPlaying((prev) => !prev);
  };

  // Mathematical helper for SVG donut segments
  const polarToCartesian = (cx: number, cy: number, r: number, angleDeg: number) => {
    const rad = (angleDeg * Math.PI) / 180;
    return {
      x: cx + r * Math.cos(rad),
      y: cy + r * Math.sin(rad),
    };
  };

  const createDonutSegment = (
    cx: number,
    cy: number,
    rIn: number,
    rOut: number,
    startAngleDeg: number,
    endAngleDeg: number
  ) => {
    const p1 = polarToCartesian(cx, cy, rOut, startAngleDeg);
    const p2 = polarToCartesian(cx, cy, rOut, endAngleDeg);
    const p3 = polarToCartesian(cx, cy, rIn, endAngleDeg);
    const p4 = polarToCartesian(cx, cy, rIn, startAngleDeg);
    const largeArcFlag = endAngleDeg - startAngleDeg <= 180 ? 0 : 1;

    return `M ${p1.x} ${p1.y} A ${rOut} ${rOut} 0 ${largeArcFlag} 1 ${p2.x} ${p2.y} L ${p3.x} ${p3.y} A ${rIn} ${rIn} 0 ${largeArcFlag} 0 ${p4.x} ${p4.y} Z`;
  };

  // Radial menu definitions matching ShiftKit native capabilities
  const radialActions = [
    { name: "Convert", icon: RefreshCw, centerAngle: -90 },
    { name: "Compress", icon: Layers, centerAngle: -30 },
    { name: "Crop", icon: Scissors, centerAngle: 30 },
    { name: "Merge", icon: Copy, centerAngle: 90 },
    { name: "Edit", icon: Edit3, centerAngle: 150 },
    { name: "Extract", icon: FolderArchive, centerAngle: 210 },
  ];

  return (
    <section id="how-it-works" aria-label="How ShiftKit Works" className="py-16 md:py-24 bg-[#FAF8F3] scroll-mt-20">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* ========================================================= */}
        {/* SECTION HEADER                                            */}
        {/* ========================================================= */}
        <div className="max-w-2xl mx-auto text-center space-y-3 mb-12 sm:mb-16">
          <div className="inline-flex items-center gap-1.5 px-3 py-0.5 rounded-full bg-[#FAF8F3] border border-[#E5D8C7] shadow-2xs">
            <span className="w-1.5 h-1.5 rounded-full bg-[#D98768]" />
            <span className="text-[11px] font-mono font-bold uppercase tracking-widest text-[#D98768]">
              UNDER THE HOOD
            </span>
          </div>

          <h2 className="font-serif text-3xl sm:text-4xl md:text-5xl font-bold tracking-tight text-[#34312D] leading-[1.15]">
            Engineered for pure speed and focus.
          </h2>

          <p className="text-[#34312D]/80 text-sm sm:text-base leading-relaxed max-w-xl mx-auto">
            Designed from day one to feel like a native part of macOS. No web wrappers, no background daemons hogging battery, and zero cloud dependencies.
          </p>
        </div>

        {/* ========================================================= */}
        {/* 4-STAGE CONNECTED PROGRESSION SELECTOR                     */}
        {/* ========================================================= */}
        <div className="relative mb-8 sm:mb-10">
          {/* Subtle Connecting Line behind the cards (Desktop) */}
          <div className="hidden lg:block absolute top-1/2 left-12 right-12 -translate-y-1/2 h-[1px] bg-[#E5D8C7] z-0" />

          {/* Cards Grid */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 relative z-10">
            {steps.map((step, idx) => {
              const Icon = step.icon;
              const isActive = activeStep === step.id;

              return (
                <div key={step.id} className="relative flex items-center">
                  <button
                    type="button"
                    onClick={() => handleStepClick(step.id)}
                    className={`w-full p-4 rounded-xl sm:rounded-2xl border text-left transition-all duration-200 cursor-pointer flex items-center gap-3.5 ${
                      isActive
                        ? "bg-[#FAF2ED] border-[#D98768] shadow-sm ring-1 ring-[#D98768]/30"
                        : "bg-[#FFFFFF] border-[#E5D8C7] hover:border-[#D98768]/60 shadow-2xs"
                    }`}
                    aria-label={`Stage ${step.num}: ${step.title}`}
                    aria-current={isActive ? "step" : undefined}
                  >
                    {/* Icon Badge */}
                    <div
                      className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 transition-colors ${
                        isActive
                          ? "bg-[#F5D5C2] text-[#D98768]"
                          : "bg-[#F3EEE4] text-[#465343]"
                      }`}
                    >
                      <Icon size={18} />
                    </div>

                    {/* Content */}
                    <div className="min-w-0 flex-1">
                      <span className="font-mono text-[11px] font-bold text-[#D98768] block">
                        {step.num}
                      </span>
                      <h3 className="font-serif text-sm sm:text-base font-bold text-[#34312D] truncate">
                        {step.title}
                      </h3>
                      <p className="text-[11px] text-[#898177] truncate">
                        {step.subtitle}
                      </p>
                    </div>
                  </button>

                  {/* Connecting Node on horizontal line between cards */}
                  {idx < steps.length - 1 && (
                    <div className="hidden lg:flex absolute -right-2 top-1/2 -translate-y-1/2 w-4 h-4 rounded-full bg-[#FAF8F3] border border-[#E5D8C7] items-center justify-center z-20 pointer-events-none">
                      <span
                        className={`w-1.5 h-1.5 rounded-full transition-colors ${
                          activeStep > step.id ? "bg-[#D98768]" : "bg-[#E5D8C7]"
                        }`}
                      />
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>

        {/* ========================================================= */}
        {/* LARGE INTERACTIVE MACOS PRODUCT DEMONSTRATION WINDOW      */}
        {/* ========================================================= */}
        <div className="rounded-2xl sm:rounded-3xl bg-[#FAF8F3] border border-[#E5D8C7] shadow-sm overflow-hidden">
          {/* Window Header */}
          <div className="px-4 py-2.5 bg-[#F3EEE4] border-b border-[#E5D8C7] flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="w-2.5 h-2.5 rounded-full bg-[#E58871] border border-[#D2735B]" />
              <span className="w-2.5 h-2.5 rounded-full bg-[#E6BF68] border border-[#CDA750]" />
              <span className="w-2.5 h-2.5 rounded-full bg-[#8EA87D] border border-[#7A9569]" />
              <span className="ml-2 text-xs font-mono text-[#898177]">
                ShiftKit • Workflow Preview
              </span>
            </div>

            <div className="flex items-center gap-2">
              <span className="text-[11px] font-mono text-[#898177] hidden sm:inline">
                Stage {activeStep} of 4
              </span>
            </div>
          </div>

          {/* Interactive Workspace Canvas */}
          <div className="p-6 sm:p-10 lg:p-12 relative min-h-[420px] flex items-center justify-center">
            {/* ----------------------------------------------------- */}
            {/* STAGE 1: HOLD SHIFT WHILE DRAGGING                    */}
            {/* ----------------------------------------------------- */}
            {activeStep === 1 && (
              <div className="w-full max-w-xl flex flex-col items-center justify-center space-y-8 animate-fadeIn">
                <div className="flex flex-col sm:flex-row items-center justify-center gap-8 w-full">
                  {/* File Card in Drag State */}
                  <div className="relative group">
                    <div className="w-48 p-4 rounded-2xl bg-[#FFFFFF] border-2 border-[#D98768] shadow-md space-y-3 text-center transform -rotate-2 transition-transform">
                      <div className="w-full h-28 rounded-xl overflow-hidden border border-[#E5D8C7]">
                        <img
                          src="/mountain_sample.jpg"
                          alt="Dragging Photo"
                          className="w-full h-full object-cover"
                        />
                      </div>
                      <div>
                        <p className="text-sm font-bold text-[#34312D]">photo.png</p>
                        <p className="text-xs text-[#898177]">PNG image • 2.4 MB</p>
                      </div>
                    </div>

                    {/* Mouse Cursor */}
                    <div className="absolute -bottom-3 -right-2 pointer-events-none drop-shadow-md">
                      <svg width="26" height="26" viewBox="0 0 24 24" fill="none">
                        <path
                          d="M3 3L10.07 20.97L12.58 13.58L19.97 11.07L3 3Z"
                          fill="#1A1817"
                          stroke="#FFFFFF"
                          strokeWidth="1.5"
                          strokeLinejoin="round"
                        />
                      </svg>
                    </div>
                  </div>

                  {/* Drop Target Gesture Guide */}
                  <div className="flex flex-col items-center space-y-4 text-center">
                    {/* Realistic 3D Tactile Shift Key */}
                    <div className="flex items-center gap-2 px-4 py-2.5 rounded-xl border border-[#D4C8B8] border-b-[3px] border-b-[#B8A894] bg-gradient-to-b from-[#FFFFFF] to-[#EFEAE1] shadow-xs ring-2 ring-[#D98768]/20">
                      <span className="text-sm font-bold text-[#D98768]">⇧</span>
                      <span className="text-xs font-mono font-bold text-[#34312D] tracking-wide">
                        Shift
                      </span>
                    </div>

                    <p className="text-xs text-[#898177] max-w-[200px] leading-relaxed">
                      Hold Shift while dragging any file from Finder to activate the radial menu.
                    </p>
                  </div>
                </div>

                <div className="px-4 py-2 rounded-full bg-[#FAF2ED] border border-[#E5D8C7] text-xs font-mono text-[#D98768] flex items-center gap-2 shadow-2xs">
                  <span className="w-2 h-2 rounded-full bg-[#D98768] animate-ping" />
                  Gesture detected: Preparing radial menu bloom...
                </div>
              </div>
            )}

            {/* ----------------------------------------------------- */}
            {/* STAGE 2: CHOOSE FROM RADIAL CANVAS (HERO SCREENSHOT)   */}
            {/* ----------------------------------------------------- */}
            {activeStep === 2 && (
              <div className="w-full grid grid-cols-1 lg:grid-cols-12 gap-8 items-center animate-fadeIn">
                {/* Left Column: Dragged File & Shift Key */}
                <div className="lg:col-span-4 flex flex-col items-center lg:items-start space-y-4">
                  {/* File Card */}
                  <div className="w-44 p-3.5 rounded-2xl bg-[#FFFFFF] border border-[#E5D8C7] shadow-xs space-y-2.5 text-center relative">
                    <div className="w-full h-24 rounded-xl overflow-hidden border border-[#E5D8C7]">
                      <img
                        src="/mountain_sample.jpg"
                        alt="Selected Photo"
                        className="w-full h-full object-cover"
                      />
                    </div>
                    <div>
                      <p className="text-xs font-bold text-[#34312D]">photo.png</p>
                      <p className="text-[11px] text-[#898177]">PNG image • 2.4 MB</p>
                    </div>

                    {/* Mouse Pointer */}
                    <div className="absolute -bottom-2 -right-2 pointer-events-none drop-shadow-md">
                      <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
                        <path
                          d="M3 3L10.07 20.97L12.58 13.58L19.97 11.07L3 3Z"
                          fill="#1A1817"
                          stroke="#FFFFFF"
                          strokeWidth="1.5"
                          strokeLinejoin="round"
                        />
                      </svg>
                    </div>
                  </div>

                  {/* 3D Tactile macOS Shift Key Indicator */}
                  <div className="flex items-center gap-3 pt-1">
                    <div className="px-3 py-1.5 rounded-lg border border-[#D4C8B8] border-b-2 border-b-[#B8A894] bg-gradient-to-b from-[#FFFFFF] to-[#EFEAE1] shadow-2xs flex items-center gap-1.5 text-xs font-mono font-bold text-[#34312D]">
                      <span>⇧</span>
                      <span>Shift</span>
                    </div>
                    <span className="text-[11px] text-[#898177]">
                      Hold Shift and drag a file
                    </span>
                  </div>
                </div>

                {/* Center Column: The Defining Radial Menu HUD */}
                <div className="lg:col-span-4 flex items-center justify-center relative">
                  <div className="relative w-[210px] h-[210px] shrink-0 flex items-center justify-center select-none">
                    <svg viewBox="0 0 200 200" className="w-full h-full drop-shadow-sm">
                      {/* Outer Guide */}
                      <circle
                        cx="100"
                        cy="100"
                        r="96"
                        fill="none"
                        stroke="#E5D8C7"
                        strokeWidth="1"
                        strokeDasharray="3 3"
                      />

                      {/* 6 Radial Segments */}
                      {radialActions.map((action) => {
                        const isSelected = selectedAction === action.name;
                        const halfSpan = 27; // 54° sector with 6° gaps
                        const startAngle = action.centerAngle - halfSpan;
                        const endAngle = action.centerAngle + halfSpan;
                        const pathData = createDonutSegment(100, 100, 48, 92, startAngle, endAngle);

                        const textPos = polarToCartesian(100, 100, 68, action.centerAngle);
                        const iconPos = polarToCartesian(100, 100, 80, action.centerAngle);

                        return (
                          <g
                            key={action.name}
                            onClick={() => setSelectedAction(action.name)}
                            className="cursor-pointer transition-all duration-200"
                          >
                            <path
                              d={pathData}
                              fill={isSelected ? "#D98768" : "#FFFFFF"}
                              stroke={isSelected ? "#C47456" : "#E5D8C7"}
                              strokeWidth={isSelected ? "1.5" : "1"}
                              className="hover:opacity-90"
                            />
                            {/* Segment Label */}
                            <text
                              x={textPos.x}
                              y={textPos.y + 3}
                              textAnchor="middle"
                              fill={isSelected ? "#FAF8F3" : "#34312D"}
                              fontSize="9.5"
                              fontWeight={isSelected ? "bold" : "600"}
                              fontFamily="system-ui, -apple-system, sans-serif"
                            >
                              {action.name}
                            </text>
                          </g>
                        );
                      })}

                      {/* Center Hub Outer Ring */}
                      <circle
                        cx="100"
                        cy="100"
                        r="44"
                        fill="#FAF8F3"
                        stroke="#E5D8C7"
                        strokeWidth="1.5"
                      />
                    </svg>

                    {/* Center Hub Content */}
                    <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none text-center">
                      <div className="w-8 h-8 rounded-md overflow-hidden border border-[#E5D8C7] mb-0.5 shadow-2xs">
                        <img
                          src="/mountain_sample.jpg"
                          alt="Center Hub"
                          className="w-full h-full object-cover"
                        />
                      </div>
                      <span className="text-[9px] font-mono font-bold text-[#34312D]">photo.png</span>
                    </div>
                  </div>
                </div>

                {/* Right Column: Dynamic Action Config Popover & Output Preview */}
                <div className="lg:col-span-4 flex flex-col space-y-4">
                  {/* Action Configuration Card */}
                  <div className="p-4 rounded-2xl bg-[#FFFFFF] border border-[#E5D8C7] shadow-xs space-y-3">
                    <div className="flex items-center gap-2">
                      <div className="w-7 h-7 rounded-lg bg-[#FAF2ED] text-[#D98768] flex items-center justify-center">
                        <FileText size={15} />
                      </div>
                      <div>
                        <h4 className="text-xs font-bold text-[#34312D]">Convert image</h4>
                        <p className="text-[11px] text-[#898177]">Choose an output format.</p>
                      </div>
                    </div>

                    {/* Output Format Options */}
                    <div className="flex items-center gap-1.5 pt-1">
                      {["PNG", "WEBP", "JPEG"].map((fmt) => (
                        <button
                          key={fmt}
                          type="button"
                          onClick={() => setSelectedFormat(fmt)}
                          className={`px-3 py-1 rounded-md text-xs font-mono font-semibold transition-all cursor-pointer ${
                            selectedFormat === fmt
                              ? "bg-[#D98768] text-[#FAF8F3] shadow-2xs"
                              : "bg-[#FAF8F3] text-[#34312D] border border-[#E5D8C7] hover:bg-[#E5D8C7]"
                          }`}
                        >
                          {fmt}
                        </button>
                      ))}
                      <div className="w-6 h-6 rounded-md bg-[#FAF8F3] border border-[#E5D8C7] flex items-center justify-center text-[#898177]">
                        <ChevronDown size={12} />
                      </div>
                    </div>
                  </div>

                  {/* Output Preview Card */}
                  <div className="p-3 rounded-xl bg-[#FFFFFF] border border-[#E5D8C7] shadow-2xs flex items-center justify-between gap-3">
                    <div className="flex items-center gap-2.5">
                      <div className="w-10 h-8 rounded-lg overflow-hidden border border-[#E5D8C7]">
                        <img
                          src="/mountain_sample.jpg"
                          alt="WebP Output"
                          className="w-full h-full object-cover"
                        />
                      </div>
                      <div>
                        <p className="text-xs font-bold text-[#34312D]">photo.webp</p>
                        <p className="text-[10px] text-[#898177]">WEBP image</p>
                      </div>
                    </div>
                    <div className="w-5 h-5 rounded-full bg-[#465343] text-white flex items-center justify-center">
                      <Check size={11} strokeWidth={3} />
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* ----------------------------------------------------- */}
            {/* STAGE 3: ASYNCHRONOUS LOCAL PROCESSING                */}
            {/* ----------------------------------------------------- */}
            {activeStep === 3 && (
              <div className="w-full max-w-xl flex flex-col items-center justify-center space-y-6 animate-fadeIn">
                <div className="w-full p-6 sm:p-8 rounded-2xl bg-[#FFFFFF] border border-[#E5D8C7] shadow-xs space-y-6">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-xl bg-[#FAF2ED] text-[#D98768] flex items-center justify-center">
                        <Cpu size={20} />
                      </div>
                      <div>
                        <h4 className="font-serif text-base font-bold text-[#34312D]">
                          Local Media Engine
                        </h4>
                        <p className="text-xs text-[#898177]">Executing on Apple Silicon</p>
                      </div>
                    </div>
                    <span className="px-2.5 py-1 rounded-md bg-[#E8EFE5] text-[#465343] text-xs font-mono font-bold">
                      Zero Cloud Upload
                    </span>
                  </div>

                  {/* Progress Representation */}
                  <div className="space-y-2">
                    <div className="flex justify-between text-xs font-mono">
                      <span className="text-[#34312D] font-medium">Converting photo.png → photo.webp</span>
                      <span className="text-[#D98768] font-bold">74%</span>
                    </div>
                    <div className="w-full h-2 rounded-full bg-[#E5D8C7] overflow-hidden">
                      <div className="w-[74%] h-full bg-[#D98768] rounded-full transition-all duration-300" />
                    </div>
                  </div>

                  {/* Implementation Metadata */}
                  <div className="grid grid-cols-3 gap-2 pt-2 border-t border-[#E5D8C7]/60 text-center text-[11px] font-mono text-[#898177]">
                    <div className="p-2 rounded bg-[#FAF8F3] border border-[#E5D8C7]/50">
                      <span className="block font-bold text-[#34312D]">ImageIO</span>
                      <span>Native Decoder</span>
                    </div>
                    <div className="p-2 rounded bg-[#FAF8F3] border border-[#E5D8C7]/50">
                      <span className="block font-bold text-[#34312D]">CoreGraphics</span>
                      <span>Pixel Buffer</span>
                    </div>
                    <div className="p-2 rounded bg-[#FAF8F3] border border-[#E5D8C7]/50">
                      <span className="block font-bold text-[#465343]">Throttled</span>
                      <span>Low CPU Temp</span>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* ----------------------------------------------------- */}
            {/* STAGE 4: VERIFIED OUTPUT ON DISK                      */}
            {/* ----------------------------------------------------- */}
            {activeStep === 4 && (
              <div className="w-full max-w-xl flex flex-col items-center justify-center space-y-6 animate-fadeIn">
                <div className="w-full p-6 sm:p-8 rounded-2xl bg-[#FFFFFF] border border-[#E5D8C7] shadow-xs space-y-6">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-xl bg-[#E8EFE5] text-[#465343] flex items-center justify-center">
                        <CheckCircle2 size={20} />
                      </div>
                      <div>
                        <h4 className="font-serif text-base font-bold text-[#34312D]">
                          Verified Output on Disk
                        </h4>
                        <p className="text-xs text-[#898177]">Byte integrity verified · Finder ready</p>
                      </div>
                    </div>
                    <span className="px-2.5 py-1 rounded-full bg-[#E8EFE5] text-[#465343] text-xs font-mono font-bold flex items-center gap-1">
                      <Check size={12} strokeWidth={3} />
                      Saved
                    </span>
                  </div>

                  {/* Before / After Comparison */}
                  <div className="grid grid-cols-2 gap-4">
                    <div className="p-3 rounded-xl bg-[#FAF8F3] border border-[#E5D8C7] space-y-2 text-center">
                      <span className="text-[10px] font-mono uppercase text-[#898177] font-bold block">
                        Source
                      </span>
                      <div className="w-full h-16 rounded-lg overflow-hidden border border-[#E5D8C7]">
                        <img src="/mountain_sample.jpg" alt="Source" className="w-full h-full object-cover" />
                      </div>
                      <p className="text-xs font-bold text-[#34312D]">photo.png</p>
                      <p className="text-[10px] font-mono text-[#898177]">2.4 MB</p>
                    </div>

                    <div className="p-3 rounded-xl bg-[#FAF8F3] border-2 border-[#A8B5A0] space-y-2 text-center">
                      <span className="text-[10px] font-mono uppercase text-[#465343] font-bold block">
                        Output (54% Smaller)
                      </span>
                      <div className="w-full h-16 rounded-lg overflow-hidden border border-[#A8B5A0]">
                        <img src="/mountain_sample.jpg" alt="Result" className="w-full h-full object-cover" />
                      </div>
                      <p className="text-xs font-bold text-[#34312D]">photo.webp</p>
                      <p className="text-[10px] font-mono text-[#465343] font-semibold">1.1 MB</p>
                    </div>
                  </div>
                </div>
              </div>
            )}
          </div>

          {/* Window Footer Bar with Contextual Info & Auto-Advance Control */}
          <div className="px-4 sm:px-6 py-3 bg-[#F3EEE4] border-t border-[#E5D8C7] flex flex-col sm:flex-row items-center justify-between gap-3 text-xs">
            {/* Status Information */}
            <div className="flex items-center gap-2 text-[#34312D]/80">
              <Info size={14} className="text-[#D98768] shrink-0" />
              <span className="font-mono text-[11px] sm:text-xs">
                {steps.find((s) => s.id === activeStep)?.statusText}
              </span>
            </div>

            {/* Play/Pause Control */}
            <button
              type="button"
              onClick={togglePlay}
              className="px-3 py-1 rounded-md bg-[#FAF8F3] border border-[#E5D8C7] hover:border-[#D98768] text-[#34312D] text-[11px] font-mono flex items-center gap-1.5 transition-colors cursor-pointer shadow-2xs"
              aria-label={isPlaying ? "Pause auto-advance" : "Resume auto-advance"}
            >
              {isPlaying ? (
                <>
                  <Pause size={11} className="text-[#D98768]" />
                  <span>Pause preview</span>
                </>
              ) : (
                <>
                  <Play size={11} className="text-[#D98768]" />
                  <span>Resume preview</span>
                </>
              )}
            </button>
          </div>
        </div>

        {/* Secondary Technology Affirmation Strip */}
        <div className="mt-8 pt-6 border-t border-[#E5D8C7]/50 flex flex-wrap items-center justify-center gap-4 sm:gap-8 text-xs font-mono text-[#898177]">
          <span className="flex items-center gap-1.5">
            <span className="w-1.5 h-1.5 rounded-full bg-[#465343]" />
            Native Swift & SwiftUI
          </span>
          <span className="flex items-center gap-1.5">
            <span className="w-1.5 h-1.5 rounded-full bg-[#465343]" />
            Local Apple Silicon Engines
          </span>
          <span className="flex items-center gap-1.5">
            <span className="w-1.5 h-1.5 rounded-full bg-[#465343]" />
            Zero Background Daemons
          </span>
          <span className="flex items-center gap-1.5">
            <span className="w-1.5 h-1.5 rounded-full bg-[#465343]" />
            100% On-Device Privacy
          </span>
        </div>
      </div>
    </section>
  );
}
