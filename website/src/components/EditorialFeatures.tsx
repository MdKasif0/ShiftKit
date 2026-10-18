"use client";

import React, { useState } from "react";
import {
  FileImage,
  Scissors,
  Film,
  Layers,
  ShieldCheck,
  ListOrdered,
  Play,
  Pause,
  Plus,
  Check,
  X,
  FileText,
  MapPin,
  Camera,
  Calendar,
  User,
  ArrowRight,
  RefreshCw,
  FolderArchive,
  Copy,
  Edit3,
} from "lucide-react";

export function EditorialFeatures() {
  const [activeCropAspect, setActiveCropAspect] = useState<"1:1" | "4:3" | "16:9" | "Custom">("1:1");
  const [isPlayingTrim, setIsPlayingTrim] = useState<boolean>(false);
  const [activePdfPage, setActivePdfPage] = useState<number>(2);

  const cropReadouts = {
    "1:1": "1024 × 1024",
    "4:3": "1280 × 960",
    "16:9": "1280 × 720",
    "Custom": "1280 × 1024",
  };

  // Mathematical helper to generate perfectly smooth donut sectors for the Radial Menu
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

  // Radial menu definitions: 6 equal 60° sectors with 3° gaps
  const radialSegments = [
    {
      name: "Convert",
      icon: RefreshCw,
      centerAngle: -90,
      active: true,
      fill: "#D98768",
      stroke: "#C47456",
      textColor: "#FAF8F3",
      iconColor: "#FAF8F3",
    },
    {
      name: "Compress",
      icon: Layers,
      centerAngle: -30,
      active: false,
      fill: "#FFFFFF",
      stroke: "#E5D8C7",
      textColor: "#34312D",
      iconColor: "#898177",
    },
    {
      name: "Extract",
      icon: FolderArchive,
      centerAngle: 30,
      active: false,
      fill: "#FFFFFF",
      stroke: "#E5D8C7",
      textColor: "#34312D",
      iconColor: "#898177",
    },
    {
      name: "Merge",
      icon: Copy,
      centerAngle: 90,
      active: false,
      fill: "#FFFFFF",
      stroke: "#E5D8C7",
      textColor: "#34312D",
      iconColor: "#898177",
    },
    {
      name: "Edit",
      icon: Edit3,
      centerAngle: 150,
      active: false,
      fill: "#FFFFFF",
      stroke: "#E5D8C7",
      textColor: "#34312D",
      iconColor: "#898177",
    },
    {
      name: "Crop",
      icon: Scissors,
      centerAngle: 210,
      active: false,
      fill: "#FFFFFF",
      stroke: "#E5D8C7",
      textColor: "#34312D",
      iconColor: "#898177",
    },
  ];

  return (
    <section id="features" aria-label="ShiftKit Features" className="py-16 md:py-24 bg-[#FAF8F3]">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* ========================================================= */}
        {/* SECTION HEADER                                            */}
        {/* ========================================================= */}
        <div className="max-w-2xl mb-12 sm:mb-16 space-y-3">
          <div className="inline-flex items-center gap-1.5 px-3 py-0.5 rounded-full bg-[#FAF8F3] border border-[#E5D8C7] shadow-2xs">
            <span className="w-1.5 h-1.5 rounded-full bg-[#D98768]" />
            <span className="text-[11px] font-mono font-bold uppercase tracking-widest text-[#D98768]">
              ENGINEERED CAPABILITIES
            </span>
          </div>

          <h2 className="font-serif text-3xl sm:text-4xl md:text-5xl font-bold tracking-tight text-[#34312D] leading-[1.15]">
            Every essential file tool. <br />
            Built natively for your Mac.
          </h2>

          <p className="text-[#34312D]/80 text-sm sm:text-base leading-relaxed">
            No browser upload bars. No subscriptions. No bloated Electron containers.
            ShiftKit executes purely using Apple native frameworks and dedicated local media engines.
          </p>
        </div>

        {/* ========================================================= */}
        {/* ASYMMETRIC SYSTEM: TREATMENT A, B, C                      */}
        {/* ========================================================= */}
        <div className="space-y-6 sm:space-y-8">
          {/* ------------------------------------------------------- */}
          {/* TREATMENT A: PRIMARY FEATURE SHOWCASE (CONVERSION)      */}
          {/* ------------------------------------------------------- */}
          <div className="p-6 sm:p-8 lg:p-10 rounded-2xl sm:rounded-3xl bg-[#F3EEE4] border border-[#E5D8C7] shadow-xs">
            <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-center">
              {/* Left Column: Product Narrative */}
              <div className="lg:col-span-5 space-y-4">
                <div className="inline-flex items-center gap-2 px-3 py-1 rounded-md bg-[#FAF8F3] border border-[#E5D8C7] text-xs font-mono font-semibold text-[#465343]">
                  <FileImage size={14} className="text-[#D98768]" />
                  IMAGE & DOCUMENT ROUTING
                </div>

                <h3 className="font-serif text-2xl sm:text-3xl font-bold text-[#34312D] leading-tight">
                  Convert files without the usual friction.
                </h3>

                <p className="text-sm text-[#34312D]/80 leading-relaxed">
                  Convert supported images and documents into the formats you need, directly on your Mac.
                  No extra apps, no exporting elsewhere, just select and go.
                </p>

                {/* Supported Format Chips */}
                <div className="pt-2 flex flex-wrap gap-2 text-xs font-mono">
                  {[".webp", ".png", ".jpeg", ".heic", ".tiff", ".pdf"].map((fmt) => (
                    <span
                      key={fmt}
                      className="px-2.5 py-1 rounded-md bg-[#FFFFFF] border border-[#E5D8C7] text-[#34312D] font-medium shadow-2xs hover:border-[#D98768]/60 transition-colors"
                    >
                      {fmt}
                    </span>
                  ))}
                </div>

                {/* Local Engine Footnote */}
                <p className="text-[11px] text-[#898177] pt-1">
                  Accelerated by Apple Silicon hardware encoders & native ImageIO.
                </p>
              </div>

              {/* Right Column: Miniature Visual Conversion Workflow Preview */}
              <div className="lg:col-span-7">
                <div className="rounded-2xl bg-[#FAF8F3] border border-[#E5D8C7] shadow-sm overflow-hidden">
                  {/* macOS Window Header */}
                  <div className="px-4 py-2 bg-[#F3EEE4] border-b border-[#E5D8C7] flex items-center justify-between">
                    <div className="flex items-center gap-1.5">
                      <span className="w-2.5 h-2.5 rounded-full bg-[#E58871] border border-[#D2735B]" />
                      <span className="w-2.5 h-2.5 rounded-full bg-[#E6BF68] border border-[#CDA750]" />
                      <span className="w-2.5 h-2.5 rounded-full bg-[#8EA87D] border border-[#7A9569]" />
                      <span className="ml-2 text-[11px] font-mono text-[#898177]">
                        ShiftKit • Convert File
                      </span>
                    </div>
                  </div>

                  {/* Visual Conversion Canvas */}
                  <div className="p-4 sm:p-6 flex flex-col md:flex-row items-center justify-between gap-3 sm:gap-4 relative overflow-x-auto">
                    {/* Source File Card */}
                    <div className="w-[130px] p-3 rounded-xl bg-[#FFFFFF] border border-[#E5D8C7] shadow-2xs space-y-2 text-center shrink-0 relative group">
                      <div className="w-full h-18 rounded-lg overflow-hidden border border-[#E5D8C7] relative">
                        <img
                          src="/mountain_sample.jpg"
                          alt="Source Photo"
                          className="w-full h-full object-cover"
                        />
                      </div>
                      <div>
                        <p className="text-xs font-bold text-[#34312D] truncate">photo.png</p>
                        <p className="text-[10px] text-[#898177]">2.4 MB • PNG</p>
                        <span className="inline-block px-1.5 py-0.5 rounded text-[9px] font-medium bg-[#FAF8F3] border border-[#E5D8C7] text-[#898177] mt-1">
                          Image
                        </span>
                      </div>
                      {/* macOS Mouse Cursor hovering */}
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

                    {/* Connector Arrow 1 */}
                    <div className="hidden md:flex items-center text-[#D98768] shrink-0">
                      <svg width="32" height="12" viewBox="0 0 32 12" fill="none">
                        <path
                          d="M0 6H26M26 6L20 1M26 6L20 11"
                          stroke="currentColor"
                          strokeWidth="1.5"
                          strokeDasharray="3 3"
                        />
                      </svg>
                    </div>

                    {/* Center: Radial Action Menu HUD */}
                    <div className="relative w-[180px] h-[180px] shrink-0 flex items-center justify-center">
                      <svg viewBox="0 0 200 200" className="w-full h-full drop-shadow-sm select-none">
                        {/* Outer Guide Ring */}
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
                        {radialSegments.map((seg) => {
                          const halfSpan = 27; // 54° arc with 6° separator gap
                          const startAngle = seg.centerAngle - halfSpan;
                          const endAngle = seg.centerAngle + halfSpan;
                          const pathData = createDonutSegment(100, 100, 48, 92, startAngle, endAngle);

                          // Position for label and icon
                          const iconPos = polarToCartesian(100, 100, 75, seg.centerAngle);
                          const textPos = polarToCartesian(100, 100, 62, seg.centerAngle);

                          const IconComponent = seg.icon;

                          return (
                            <g key={seg.name} className="transition-all duration-200">
                              <path
                                d={pathData}
                                fill={seg.fill}
                                stroke={seg.stroke}
                                strokeWidth={seg.active ? "1.5" : "1"}
                              />
                              {/* Segment Label */}
                              <text
                                x={textPos.x}
                                y={textPos.y + 3}
                                textAnchor="middle"
                                fill={seg.textColor}
                                fontSize="9"
                                fontWeight={seg.active ? "bold" : "600"}
                                fontFamily="system-ui, -apple-system, sans-serif"
                              >
                                {seg.name}
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
                            src="/photo_thumb.jpg"
                            alt="Center Thumbnail"
                            className="w-full h-full object-cover"
                          />
                        </div>
                        <span className="text-[9px] font-mono font-bold text-[#34312D]">PNG</span>
                      </div>
                    </div>

                    {/* Connector Arrow 2 */}
                    <div className="hidden md:flex items-center text-[#D98768] shrink-0">
                      <svg width="32" height="12" viewBox="0 0 32 12" fill="none">
                        <path
                          d="M0 6H26M26 6L20 1M26 6L20 11"
                          stroke="currentColor"
                          strokeWidth="1.5"
                          strokeDasharray="3 3"
                        />
                      </svg>
                    </div>

                    {/* Output File Card */}
                    <div className="w-[130px] p-3 rounded-xl bg-[#FFFFFF] border-2 border-[#A8B5A0] shadow-2xs space-y-2 text-center shrink-0">
                      <div className="w-full h-18 rounded-lg overflow-hidden border border-[#A8B5A0] relative">
                        <img
                          src="/mountain_sample.jpg"
                          alt="Converted WebP"
                          className="w-full h-full object-cover"
                        />
                      </div>
                      <div>
                        <p className="text-xs font-bold text-[#34312D] truncate">photo.webp</p>
                        <p className="text-[10px] font-mono text-[#465343] font-semibold">1.1 MB • WEBP</p>
                        <span className="inline-block px-1.5 py-0.5 rounded text-[9px] font-medium bg-[#FAF8F3] border border-[#E5D8C7] text-[#898177] mt-1">
                          Image
                        </span>
                      </div>
                      <div className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-[#E8EFE5] text-[9.5px] font-mono font-bold text-[#465343] border border-[#A8B5A0]/40">
                        <Check size={10} strokeWidth={3} />
                        Saved locally
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* ------------------------------------------------------- */}
          {/* TREATMENT B: MAJOR EDITING TOOLS (2 COLUMNS)             */}
          {/* ------------------------------------------------------- */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 sm:gap-8">
            {/* Feature B1: Visual Crop Studio */}
            <div className="p-6 sm:p-8 rounded-2xl sm:rounded-3xl bg-[#FFFFFF] border border-[#E5D8C7] shadow-xs flex flex-col justify-between space-y-6">
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <div className="w-10 h-10 rounded-xl bg-[#F3EEE4] border border-[#E5D8C7] flex items-center justify-center text-[#465343]">
                    <Scissors size={20} />
                  </div>
                  {/* Aspect Ratio Buttons */}
                  <div className="flex items-center gap-1.5 text-xs font-mono">
                    {(["1:1", "4:3", "16:9", "Custom"] as const).map((aspect) => (
                      <button
                        key={aspect}
                        type="button"
                        onClick={() => setActiveCropAspect(aspect)}
                        className={`px-2.5 py-1 rounded-md transition-all cursor-pointer text-[11px] font-medium ${
                          activeCropAspect === aspect
                            ? "bg-[#D98768] text-[#FAF8F3] font-bold shadow-2xs border border-[#C47456]"
                            : "bg-[#F3EEE4] text-[#34312D] border border-[#E5D8C7] hover:bg-[#E5D8C7]"
                        }`}
                      >
                        {aspect}
                      </button>
                    ))}
                  </div>
                </div>

                <h3 className="font-serif text-xl sm:text-2xl font-bold text-[#34312D]">
                  Visual Crop Studio with Aspect Lock.
                </h3>

                <p className="text-xs sm:text-sm text-[#34312D]/80 leading-relaxed">
                  Crop images to exact dimensions before saving. Choose from 1:1 square, 16:9 widescreen, 4:3 document ratio, or freeform framing with live pixel readouts.
                </p>
              </div>

              {/* Miniature Crop Window Preview */}
              <div className="rounded-xl bg-[#FAF8F3] border border-[#E5D8C7] overflow-hidden shadow-2xs">
                <div className="px-3 py-1.5 bg-[#F3EEE4] border-b border-[#E5D8C7] flex items-center justify-between">
                  <div className="flex items-center gap-1.5">
                    <span className="w-2.5 h-2.5 rounded-full bg-[#E58871]" />
                    <span className="w-2.5 h-2.5 rounded-full bg-[#E6BF68]" />
                    <span className="w-2.5 h-2.5 rounded-full bg-[#8EA87D]" />
                  </div>
                </div>

                {/* Crop Canvas with Framed Guides */}
                <div className="relative w-full h-[190px] sm:h-[210px] overflow-hidden bg-[#34312D]">
                  <img
                    src="/mountain_sample.jpg"
                    alt="Crop Canvas"
                    className="w-full h-full object-cover"
                  />

                  {/* Darkened Outer Mask */}
                  <div className="absolute inset-0 bg-black/45 pointer-events-none" />

                  {/* Active Crop Box */}
                  <div
                    className={`absolute border-2 border-[#D98768] shadow-md transition-all duration-300 pointer-events-none ${
                      activeCropAspect === "1:1"
                        ? "top-3 bottom-3 left-1/2 -translate-x-1/2 w-[164px]"
                        : activeCropAspect === "4:3"
                        ? "top-3 bottom-3 left-1/2 -translate-x-1/2 w-[220px]"
                        : activeCropAspect === "16:9"
                        ? "top-7 bottom-7 left-6 right-6"
                        : "top-4 bottom-4 left-6 right-6"
                    }`}
                  >
                    {/* Clear Inner Cutout with Rule of Thirds Grid */}
                    <div className="absolute -inset-[2px] overflow-hidden">
                      <div className="absolute inset-0 grid grid-cols-3 grid-rows-3 pointer-events-none">
                        <div className="border-r border-b border-white/35" />
                        <div className="border-r border-b border-white/35" />
                        <div className="border-b border-white/35" />
                        <div className="border-r border-b border-white/35" />
                        <div className="border-r border-b border-white/35" />
                        <div className="border-b border-white/35" />
                        <div className="border-r border-b border-white/35" />
                        <div className="border-r border-b border-white/35" />
                        <div />
                      </div>
                    </div>

                    {/* Terracotta Corner Drag Handles */}
                    <span className="absolute -top-1.5 -left-1.5 w-3 h-3 bg-[#D98768] border border-white rounded-xs shadow-xs" />
                    <span className="absolute -top-1.5 -right-1.5 w-3 h-3 bg-[#D98768] border border-white rounded-xs shadow-xs" />
                    <span className="absolute -bottom-1.5 -left-1.5 w-3 h-3 bg-[#D98768] border border-white rounded-xs shadow-xs" />
                    <span className="absolute -bottom-1.5 -right-1.5 w-3 h-3 bg-[#D98768] border border-white rounded-xs shadow-xs" />

                    {/* Midpoint Edge Handles */}
                    <span className="absolute top-1/2 -translate-y-1/2 -left-1.5 w-2.5 h-3 bg-[#D98768] border border-white rounded-xs" />
                    <span className="absolute top-1/2 -translate-y-1/2 -right-1.5 w-2.5 h-3 bg-[#D98768] border border-white rounded-xs" />
                    <span className="absolute -top-1.5 left-1/2 -translate-x-1/2 w-3 h-2.5 bg-[#D98768] border border-white rounded-xs" />
                    <span className="absolute -bottom-1.5 left-1/2 -translate-x-1/2 w-3 h-2.5 bg-[#D98768] border border-white rounded-xs" />

                    {/* Dimension Readout Badge inside the crop frame */}
                    <div className="absolute bottom-2 left-1/2 -translate-x-1/2 px-2.5 py-0.5 rounded-full bg-[#1A1817]/90 text-[#FAF8F3] text-[10px] font-mono font-bold shadow-sm backdrop-blur-xs border border-white/10">
                      {cropReadouts[activeCropAspect]}
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Feature B2: Video & Audio Trimming */}
            <div className="p-6 sm:p-8 rounded-2xl sm:rounded-3xl bg-[#FFFFFF] border border-[#E5D8C7] shadow-xs flex flex-col justify-between space-y-6">
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <div className="w-10 h-10 rounded-xl bg-[#F3EEE4] border border-[#E5D8C7] flex items-center justify-center text-[#465343]">
                    <Film size={20} />
                  </div>
                  <span className="text-[10px] font-mono text-[#D98768] font-bold bg-[#FAF8F3] px-2.5 py-1 rounded-full border border-[#E5D8C7]">
                    MP4 • MOV • WebM • MP3 • WAV
                  </span>
                </div>

                <h3 className="font-serif text-xl sm:text-2xl font-bold text-[#34312D]">
                  Frame-Accurate Video & Audio Trimming.
                </h3>

                <p className="text-xs sm:text-sm text-[#34312D]/80 leading-relaxed">
                  Trim unwanted seconds from screen recordings, podcasts, and video clips without launching heavy editing suites. Snaps to keyframes for precise control.
                </p>
              </div>

              {/* Miniature Filmstrip Timeline Scrubber */}
              <div className="p-4 rounded-xl bg-[#FAF8F3] border border-[#E5D8C7] space-y-3 shadow-2xs">
                {/* Filmstrip Track */}
                <div className="flex items-center gap-3">
                  {/* Play Button */}
                  <button
                    type="button"
                    onClick={() => setIsPlayingTrim(!isPlayingTrim)}
                    className="w-9 h-9 rounded-full bg-[#FFFFFF] border border-[#E5D8C7] hover:border-[#D98768] flex items-center justify-center text-[#34312D] shrink-0 cursor-pointer shadow-2xs transition-colors"
                    aria-label={isPlayingTrim ? "Pause preview" : "Play preview"}
                  >
                    {isPlayingTrim ? (
                      <Pause size={13} className="text-[#D98768]" />
                    ) : (
                      <Play size={13} className="ml-0.5 text-[#34312D]" />
                    )}
                  </button>

                  {/* Horizontal Timeline Bar with 8 Video Frame Slices */}
                  <div className="flex-grow relative h-12 rounded-lg overflow-hidden border border-[#E5D8C7] bg-[#34312D]">
                    <div className="grid grid-cols-8 h-full divide-x divide-[#34312D]/50">
                      {[0, 1, 2, 3, 4, 5, 6, 7].map((i) => (
                        <div key={i} className="relative h-full overflow-hidden">
                          <img
                            src="/mountain_sample.jpg"
                            alt={`Frame ${i}`}
                            className="w-full h-full object-cover filter brightness-95"
                          />
                          {/* Dimming outside frames */}
                          {(i === 0 || i === 7) && (
                            <div className="absolute inset-0 bg-black/60" />
                          )}
                        </div>
                      ))}
                    </div>

                    {/* Active Selected Region Overlay */}
                    <div className="absolute inset-y-0 left-[12.5%] right-[12.5%] border-y-2 border-[#D98768] pointer-events-none">
                      {/* Left Handle */}
                      <div className="absolute top-0 bottom-0 -left-1 w-2.5 bg-[#D98768] rounded-l-xs flex items-center justify-center shadow-xs">
                        <div className="w-[1.5px] h-4 bg-white/80" />
                      </div>
                      {/* Right Handle */}
                      <div className="absolute top-0 bottom-0 -right-1 w-2.5 bg-[#D98768] rounded-r-xs flex items-center justify-center shadow-xs">
                        <div className="w-[1.5px] h-4 bg-white/80" />
                      </div>
                      {/* Playhead Needle */}
                      <div className="absolute top-0 bottom-0 left-[45%] w-[2px] bg-white shadow-xs">
                        <span className="absolute -top-1 -left-[3px] w-2 h-2 bg-white rotate-45 rounded-2xs shadow-xs" />
                      </div>
                    </div>
                  </div>
                </div>

                {/* Timeline Timestamps */}
                <div className="flex items-center justify-between text-[11px] font-mono text-[#898177]">
                  <span>00:00</span>
                  <span className="px-2.5 py-0.5 rounded-full bg-[#FFFFFF] border border-[#E5D8C7] text-[#D98768] font-bold shadow-2xs">
                    00:08.4 — 00:32.1
                  </span>
                  <span>01:12</span>
                </div>
              </div>
            </div>
          </div>

          {/* ------------------------------------------------------- */}
          {/* TREATMENT C: SUPPORTING UTILITIES (3 COLUMNS)            */}
          {/* ------------------------------------------------------- */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 sm:gap-8">
            {/* Feature C1: PDF Page Studio */}
            <div className="p-6 rounded-2xl sm:rounded-3xl bg-[#FFFFFF] border border-[#E5D8C7] shadow-xs flex flex-col justify-between space-y-5">
              <div className="space-y-2.5">
                <div className="w-9 h-9 rounded-xl bg-[#F3EEE4] border border-[#E5D8C7] flex items-center justify-center text-[#D98768]">
                  <Layers size={18} />
                </div>
                <h3 className="font-serif text-lg sm:text-xl font-bold text-[#34312D]">
                  PDF Page Studio
                </h3>
                <p className="text-xs text-[#34312D]/80 leading-relaxed">
                  Merge multiple PDFs, convert photos into multi-page documents, reorder thumbnails, rotate pages, or extract selected pages.
                </p>
              </div>

              {/* Visual Preview: Multi-Page Thumbnail Sorter */}
              <div className="p-3 rounded-xl bg-[#FAF8F3] border border-[#E5D8C7] space-y-2">
                <div className="flex items-center justify-between gap-1.5">
                  {/* Page 1 */}
                  <div
                    onClick={() => setActivePdfPage(1)}
                    className={`flex-1 p-1 rounded-lg bg-[#FFFFFF] border cursor-pointer transition-all ${
                      activePdfPage === 1 ? "border-[#D98768] ring-1 ring-[#D98768]" : "border-[#E5D8C7]"
                    }`}
                  >
                    <div className="w-full h-14 rounded overflow-hidden bg-[#FAF8F3] mb-1 border border-[#E5D8C7]/50">
                      <img src="/mountain_sample.jpg" alt="P1" className="w-full h-full object-cover" />
                    </div>
                    <span className="block text-center text-[9px] font-mono font-bold text-[#898177]">1</span>
                  </div>

                  {/* Page 2 (Active Selected) */}
                  <div
                    onClick={() => setActivePdfPage(2)}
                    className={`flex-1 p-1 rounded-lg bg-[#FAF8F3] border-2 cursor-pointer transition-all ${
                      activePdfPage === 2
                        ? "border-[#D98768] bg-[#FDF6F0] shadow-2xs"
                        : "border-[#E5D8C7]"
                    }`}
                  >
                    <div className="w-full h-14 rounded border border-[#D98768]/40 bg-[#FFFFFF] p-1 flex flex-col justify-between mb-1">
                      <div className="space-y-1">
                        <div className="w-3/4 h-1 bg-[#D98768]/70 rounded-full" />
                        <div className="w-full h-1 bg-[#E5D8C7] rounded-full" />
                        <div className="w-5/6 h-1 bg-[#E5D8C7] rounded-full" />
                      </div>
                      <div className="w-1/2 h-1 bg-[#E5D8C7] rounded-full" />
                    </div>
                    <span className="block text-center text-[9px] font-mono font-bold text-[#D98768]">2</span>
                  </div>

                  {/* Page 3: Plant Thumbnail */}
                  <div
                    onClick={() => setActivePdfPage(3)}
                    className={`flex-1 p-1 rounded-lg bg-[#FFFFFF] border cursor-pointer transition-all ${
                      activePdfPage === 3 ? "border-[#D98768] ring-1 ring-[#D98768]" : "border-[#E5D8C7]"
                    }`}
                  >
                    <div className="w-full h-14 rounded overflow-hidden bg-[#FAF8F3] mb-1 border border-[#E5D8C7]/50">
                      <img src="/plant_thumb.jpg" alt="P3" className="w-full h-full object-cover" />
                    </div>
                    <span className="block text-center text-[9px] font-mono font-bold text-[#898177]">3</span>
                  </div>

                  {/* Page 4 */}
                  <div
                    onClick={() => setActivePdfPage(4)}
                    className={`flex-1 p-1 rounded-lg bg-[#FFFFFF] border cursor-pointer transition-all ${
                      activePdfPage === 4 ? "border-[#D98768] ring-1 ring-[#D98768]" : "border-[#E5D8C7]"
                    }`}
                  >
                    <div className="w-full h-14 rounded border border-[#E5D8C7] bg-[#FFFFFF] p-1 flex flex-col justify-between mb-1">
                      <div className="space-y-1">
                        <div className="w-full h-1 bg-[#E5D8C7] rounded-full" />
                        <div className="w-2/3 h-1 bg-[#E5D8C7] rounded-full" />
                      </div>
                      <div className="w-1/2 h-1 bg-[#E5D8C7] rounded-full" />
                    </div>
                    <span className="block text-center text-[9px] font-mono font-bold text-[#898177]">4</span>
                  </div>

                  {/* Add Page Slot */}
                  <div className="flex-1 p-1 rounded-lg border-2 border-dashed border-[#E5D8C7] hover:border-[#D98768] transition-colors flex flex-col items-center justify-center h-20 text-[#898177] hover:text-[#D98768] cursor-pointer bg-[#FFFFFF]">
                    <Plus size={14} />
                    <span className="text-[7.5px] font-mono uppercase mt-1">Add Pages</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Feature C2: Metadata Sanitizer */}
            <div className="p-6 rounded-2xl sm:rounded-3xl bg-[#FFFFFF] border border-[#E5D8C7] shadow-xs flex flex-col justify-between space-y-5">
              <div className="space-y-2.5">
                <div className="w-9 h-9 rounded-xl bg-[#F3EEE4] border border-[#E5D8C7] flex items-center justify-center text-[#465343]">
                  <ShieldCheck size={18} />
                </div>
                <h3 className="font-serif text-lg sm:text-xl font-bold text-[#34312D]">
                  Metadata Sanitizer
                </h3>
                <p className="text-xs text-[#34312D]/80 leading-relaxed">
                  Scrub GPS coordinates, camera serial numbers, lens info, audio ID3 tags, and PDF authors before sharing files with clients or publishing online.
                </p>
              </div>

              {/* Visual Preview: Before & After Sanitization Table */}
              <div className="p-3 rounded-xl bg-[#FAF8F3] border border-[#E5D8C7] space-y-2">
                <div className="grid grid-cols-11 items-center gap-1 text-[10.5px]">
                  {/* Before Column */}
                  <div className="col-span-5 space-y-1.5">
                    <span className="text-[9px] font-mono uppercase font-bold text-[#898177] block mb-1">
                      Before
                    </span>
                    <div className="flex items-center gap-1.5 text-[#34312D] truncate">
                      <MapPin size={11} className="text-[#898177] shrink-0" />
                      <span className="text-[9px] text-[#898177]">Location</span>
                      <span className="text-[9px] font-medium text-[#34312D] truncate ml-auto">San Francisco, CA</span>
                    </div>
                    <div className="flex items-center gap-1.5 text-[#34312D] truncate">
                      <Camera size={11} className="text-[#898177] shrink-0" />
                      <span className="text-[9px] text-[#898177]">Camera</span>
                      <span className="text-[9px] font-medium text-[#34312D] truncate ml-auto">iPhone 15 Pro</span>
                    </div>
                    <div className="flex items-center gap-1.5 text-[#34312D] truncate">
                      <Calendar size={11} className="text-[#898177] shrink-0" />
                      <span className="text-[9px] text-[#898177]">Capture Date</span>
                      <span className="text-[9px] font-medium text-[#34312D] truncate ml-auto">Oct 14, 2024</span>
                    </div>
                    <div className="flex items-center gap-1.5 text-[#34312D] truncate">
                      <User size={11} className="text-[#898177] shrink-0" />
                      <span className="text-[9px] text-[#898177]">Author</span>
                      <span className="text-[9px] font-medium text-[#34312D] truncate ml-auto">John Appleseed</span>
                    </div>
                  </div>

                  {/* Divider Arrow */}
                  <div className="col-span-1 flex items-center justify-center text-[#898177]">
                    <ArrowRight size={13} />
                  </div>

                  {/* After Column */}
                  <div className="col-span-5 space-y-1.5">
                    <span className="text-[9px] font-mono uppercase font-bold text-[#465343] block mb-1">
                      After
                    </span>
                    <div className="flex items-center gap-1.5 text-[#898177]">
                      <MapPin size={11} className="text-[#898177] shrink-0" />
                      <span className="text-[9px] text-[#898177]">Location</span>
                      <span className="text-[9px] font-mono text-[#898177] ml-auto">—</span>
                    </div>
                    <div className="flex items-center gap-1.5 text-[#898177]">
                      <Camera size={11} className="text-[#898177] shrink-0" />
                      <span className="text-[9px] text-[#898177]">Camera</span>
                      <span className="text-[9px] font-mono text-[#898177] ml-auto">—</span>
                    </div>
                    <div className="flex items-center gap-1.5 text-[#898177]">
                      <Calendar size={11} className="text-[#898177] shrink-0" />
                      <span className="text-[9px] text-[#898177]">Capture Date</span>
                      <span className="text-[9px] font-mono text-[#898177] ml-auto">—</span>
                    </div>
                    <div className="flex items-center gap-1.5 text-[#898177]">
                      <User size={11} className="text-[#898177] shrink-0" />
                      <span className="text-[9px] text-[#898177]">Author</span>
                      <span className="text-[9px] font-mono text-[#898177] ml-auto">—</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Feature C3: Batch Queue Studio */}
            <div className="p-6 rounded-2xl sm:rounded-3xl bg-[#FFFFFF] border border-[#E5D8C7] shadow-xs flex flex-col justify-between space-y-5">
              <div className="space-y-2.5">
                <div className="w-9 h-9 rounded-xl bg-[#F3EEE4] border border-[#E5D8C7] flex items-center justify-center text-[#D98768]">
                  <ListOrdered size={18} />
                </div>
                <h3 className="font-serif text-lg sm:text-xl font-bold text-[#34312D]">
                  Batch Queue Studio
                </h3>
                <p className="text-xs text-[#34312D]/80 leading-relaxed">
                  Drop multiple files at once. ShiftKit throttles concurrency dynamically to prevent CPU heating, with live progress bars and individual item retry.
                </p>
              </div>

              {/* Visual Preview: Miniature Concurrent Queue */}
              <div className="p-2.5 rounded-xl bg-[#FAF8F3] border border-[#E5D8C7] space-y-2 text-xs">
                {/* Row 1: Converting */}
                <div className="p-2 rounded-lg bg-[#FFFFFF] border border-[#E5D8C7] flex items-center justify-between gap-2 shadow-2xs">
                  <div className="flex items-center gap-2 truncate">
                    <FileImage size={14} className="text-[#D98768] shrink-0" />
                    <div className="truncate">
                      <span className="font-semibold text-[#34312D] text-[11px] block truncate">vacation.jpg</span>
                    </div>
                  </div>
                  <span className="text-[10px] text-[#898177] shrink-0">Convert to WebP</span>
                  <div className="flex items-center gap-1.5 shrink-0">
                    <div className="w-12 h-1.5 rounded-full bg-[#E5D8C7] overflow-hidden">
                      <div className="w-[78%] h-full bg-[#D98768] rounded-full" />
                    </div>
                    <span className="font-mono text-[9px] text-[#898177]">78%</span>
                    <button type="button" className="text-[#898177] hover:text-[#34312D] cursor-pointer">
                      <X size={10} />
                    </button>
                  </div>
                </div>

                {/* Row 2: Trimming */}
                <div className="p-2 rounded-lg bg-[#FFFFFF] border border-[#E5D8C7] flex items-center justify-between gap-2 shadow-2xs">
                  <div className="flex items-center gap-2 truncate">
                    <Film size={14} className="text-[#465343] shrink-0" />
                    <div className="truncate">
                      <span className="font-semibold text-[#34312D] text-[11px] block truncate">interview.mov</span>
                    </div>
                  </div>
                  <span className="text-[10px] text-[#898177] shrink-0">Trim Video</span>
                  <div className="flex items-center gap-1.5 shrink-0">
                    <div className="w-12 h-1.5 rounded-full bg-[#E5D8C7] overflow-hidden">
                      <div className="w-[42%] h-full bg-[#D98768] rounded-full" />
                    </div>
                    <span className="font-mono text-[9px] text-[#898177]">42%</span>
                    <button type="button" className="text-[#898177] hover:text-[#34312D] cursor-pointer">
                      <X size={10} />
                    </button>
                  </div>
                </div>

                {/* Row 3: Complete */}
                <div className="p-2 rounded-lg bg-[#FFFFFF] border border-[#E5D8C7] flex items-center justify-between gap-2 shadow-2xs">
                  <div className="flex items-center gap-2 truncate">
                    <FileText size={14} className="text-[#898177] shrink-0" />
                    <div className="truncate">
                      <span className="font-semibold text-[#34312D] text-[11px] block truncate">report.pdf</span>
                    </div>
                  </div>
                  <span className="text-[10px] text-[#898177] shrink-0">Compress PDF</span>
                  <div className="flex items-center gap-1.5 shrink-0">
                    <div className="w-12 h-1.5 rounded-full bg-[#A8B5A0] overflow-hidden">
                      <div className="w-full h-full bg-[#465343] rounded-full" />
                    </div>
                    <span className="w-3 flex justify-center text-[#465343]">
                      <Check size={11} strokeWidth={3} />
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
