"use client";

import React, { useState } from "react";
import {
  FileImage,
  Scissors,
  Film,
  Layers,
  ShieldCheck,
  ListOrdered,
  RotateCw,
  Play,
  Pause,
  Plus,
  Check,
  Sliders,
  Folder,
  X,
  FileText,
  MousePointer,
  MapPin,
  Camera,
  Calendar,
  User,
  ArrowRight,
} from "lucide-react";

export function EditorialFeatures() {
  const [activeCropAspect, setActiveCropAspect] = useState<"1:1" | "4:3" | "16:9" | "Custom">("Custom");
  const [isPlayingTrim, setIsPlayingTrim] = useState<boolean>(false);
  const [activePdfPage, setActivePdfPage] = useState<number>(2);

  const cropReadouts = {
    "1:1": "1024 × 1024",
    "4:3": "1280 × 960",
    "16:9": "1280 × 720",
    "Custom": "1280 × 1024",
  };

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
              Engineered Capabilities
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
        <div className="space-y-8">
          {/* ------------------------------------------------------- */}
          {/* TREATMENT A: PRIMARY FEATURE SHOWCASE (CONVERSION)      */}
          {/* ------------------------------------------------------- */}
          <div className="p-6 sm:p-8 lg:p-10 rounded-2xl sm:rounded-3xl bg-[#F3EEE4] border border-[#E5D8C7] shadow-sm">
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
                      className="px-2.5 py-1 rounded bg-[#FFFFFF] border border-[#E5D8C7] text-[#34312D] font-medium shadow-2xs"
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
                  <div className="p-4 sm:p-6 flex flex-col sm:flex-row items-center justify-between gap-4 relative">
                    {/* Source File Card */}
                    <div className="w-full sm:w-[130px] p-3 rounded-xl bg-[#FFFFFF] border border-[#E5D8C7] shadow-2xs space-y-2 text-center shrink-0">
                      <div className="w-full h-18 rounded-lg overflow-hidden border border-[#E5D8C7] relative">
                        <img
                          src="/mountain_sample.jpg"
                          alt="Source Photo"
                          className="w-full h-full object-cover"
                        />
                        <div className="absolute bottom-1 right-1 w-4 h-4 rounded-full bg-[#34312D] text-[#FAF8F3] flex items-center justify-center">
                          <MousePointer size={9} className="fill-current" />
                        </div>
                      </div>
                      <div>
                        <p className="text-xs font-bold text-[#34312D] truncate">photo.png</p>
                        <p className="text-[10px] text-[#898177]">2.4 MB • PNG</p>
                      </div>
                    </div>

                    {/* Connector Arrow 1 */}
                    <div className="hidden sm:flex items-center text-[#D98768]">
                      <svg width="28" height="12" viewBox="0 0 28 12" fill="none">
                        <path
                          d="M0 6H24M24 6L19 1M24 6L19 11"
                          stroke="currentColor"
                          strokeWidth="1.5"
                          strokeDasharray="3 3"
                        />
                      </svg>
                    </div>

                    {/* Center: Radial HUD Bloom */}
                    <div className="relative w-[150px] h-[150px] shrink-0">
                      <svg viewBox="0 0 160 160" className="w-full h-full drop-shadow-2xs">
                        <circle cx="80" cy="80" r="76" fill="none" stroke="#E5D8C7" strokeWidth="1" strokeDasharray="3 3" />
                        
                        {/* 6 Segments */}
                        {/* 1. Convert (Active - Top) */}
                        <path
                          d="M 60 25 L 50 5 A 76 76 0 0 1 110 5 L 100 25 A 56 56 0 0 0 60 25 Z"
                          fill="#D98768"
                          stroke="#C47456"
                          strokeWidth="1.5"
                        />
                        <text x="80" y="16" textAnchor="middle" fill="#FAF8F3" fontSize="8" fontWeight="bold">
                          Convert
                        </text>

                        {/* 2. Compress (Top Right) */}
                        <path
                          d="M 103 27 L 115 8 A 76 76 0 0 1 154 48 L 135 60 A 56 56 0 0 0 103 27 Z"
                          fill="#FFFFFF"
                          stroke="#E5D8C7"
                          strokeWidth="1"
                        />
                        <text x="127" y="38" textAnchor="middle" fill="#34312D" fontSize="7.5" fontWeight="600">
                          Compress
                        </text>

                        {/* 3. Crop (Bottom Right) */}
                        <path
                          d="M 135 66 L 155 80 A 76 76 0 0 1 135 133 L 118 116 A 56 56 0 0 0 135 66 Z"
                          fill="#FFFFFF"
                          stroke="#E5D8C7"
                          strokeWidth="1"
                        />
                        <text x="135" y="103" textAnchor="middle" fill="#34312D" fontSize="7.5" fontWeight="600">
                          Crop
                        </text>

                        {/* 4. Merge (Bottom) */}
                        <path
                          d="M 112 120 L 126 142 A 76 76 0 0 1 34 142 L 48 120 A 56 56 0 0 0 112 120 Z"
                          fill="#FFFFFF"
                          stroke="#E5D8C7"
                          strokeWidth="1"
                        />
                        <text x="80" y="136" textAnchor="middle" fill="#34312D" fontSize="7.5" fontWeight="600">
                          Merge
                        </text>

                        {/* 5. Edit (Bottom Left) */}
                        <path
                          d="M 44 116 L 25 133 A 76 76 0 0 1 5 80 L 25 66 A 56 56 0 0 0 44 116 Z"
                          fill="#FFFFFF"
                          stroke="#E5D8C7"
                          strokeWidth="1"
                        />
                        <text x="25" y="103" textAnchor="middle" fill="#34312D" fontSize="7.5" fontWeight="600">
                          Edit
                        </text>

                        {/* 6. Extract (Top Left) */}
                        <path
                          d="M 27 60 L 6 48 A 76 76 0 0 1 45 8 L 57 27 A 56 56 0 0 0 27 60 Z"
                          fill="#FFFFFF"
                          stroke="#E5D8C7"
                          strokeWidth="1"
                        />
                        <text x="33" y="38" textAnchor="middle" fill="#34312D" fontSize="7.5" fontWeight="600">
                          Extract
                        </text>

                        {/* Center Hub */}
                        <circle cx="80" cy="80" r="26" fill="#FAF8F3" stroke="#E5D8C7" strokeWidth="1.5" />
                      </svg>

                      {/* Center Hub Content */}
                      <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none text-center">
                        <div className="w-5 h-5 rounded overflow-hidden border border-[#E5D8C7] mb-0.5">
                          <img src="/photo_thumb.jpg" alt="Center Hub" className="w-full h-full object-cover" />
                        </div>
                        <span className="text-[7.5px] font-mono font-bold text-[#34312D]">photo.png</span>
                      </div>
                    </div>

                    {/* Connector Arrow 2 */}
                    <div className="hidden sm:flex items-center text-[#D98768]">
                      <svg width="28" height="12" viewBox="0 0 28 12" fill="none">
                        <path
                          d="M0 6H24M24 6L19 1M24 6L19 11"
                          stroke="currentColor"
                          strokeWidth="1.5"
                          strokeDasharray="3 3"
                        />
                      </svg>
                    </div>

                    {/* Output File Card */}
                    <div className="w-full sm:w-[130px] p-3 rounded-xl bg-[#FFFFFF] border-2 border-[#465343]/50 shadow-2xs space-y-2 text-center shrink-0">
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
                      </div>
                      <div className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-[#E8EFE5] text-[9.5px] font-mono font-bold text-[#465343]">
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
                  <div className="flex items-center gap-1 text-xs font-mono">
                    {(["1:1", "4:3", "16:9", "Custom"] as const).map((aspect) => (
                      <button
                        key={aspect}
                        type="button"
                        onClick={() => setActiveCropAspect(aspect)}
                        className={`px-2 py-1 rounded-md transition-colors cursor-pointer text-[11px] font-medium ${
                          activeCropAspect === aspect
                            ? "bg-[#D98768] text-[#FAF8F3] font-bold shadow-2xs"
                            : "bg-[#F3EEE4] text-[#34312D] hover:bg-[#E5D8C7]"
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
                  Crop images to exact dimensions with live measurements, flexible framing, and convenient aspect-ratio presets.
                </p>
              </div>

              {/* Miniature Crop Window Preview */}
              <div className="rounded-xl bg-[#FAF8F3] border border-[#E5D8C7] overflow-hidden shadow-2xs">
                <div className="px-3 py-1.5 bg-[#F3EEE4] border-b border-[#E5D8C7] flex items-center justify-between">
                  <div className="flex items-center gap-1">
                    <span className="w-2 h-2 rounded-full bg-[#E58871]" />
                    <span className="w-2 h-2 rounded-full bg-[#E6BF68]" />
                    <span className="w-2 h-2 rounded-full bg-[#8EA87D]" />
                  </div>
                  <span className="text-[10px] font-mono text-[#898177]">
                    {cropReadouts[activeCropAspect]}
                  </span>
                </div>

                {/* Crop Canvas with Framed Guides */}
                <div className="relative w-full h-[180px] sm:h-[200px] overflow-hidden bg-[#34312D]">
                  <img
                    src="/mountain_sample.jpg"
                    alt="Crop Canvas"
                    className="w-full h-full object-cover"
                  />

                  {/* Darkened Outer Masks */}
                  <div className="absolute inset-0 bg-black/40 pointer-events-none" />

                  {/* Active Crop Box */}
                  <div
                    className={`absolute border-2 border-[#D98768] shadow-md transition-all duration-300 pointer-events-none ${
                      activeCropAspect === "1:1"
                        ? "top-3 bottom-3 left-1/2 -translate-x-1/2 w-[154px]"
                        : activeCropAspect === "4:3"
                        ? "top-3 bottom-3 left-1/2 -translate-x-1/2 w-[210px]"
                        : activeCropAspect === "16:9"
                        ? "top-6 bottom-6 left-6 right-6"
                        : "top-4 bottom-4 left-8 right-8"
                    }`}
                  >
                    {/* Clear inside window revealing bright photo */}
                    <div className="absolute -inset-[2px] overflow-hidden">
                      {/* Rule of Thirds Grid Lines */}
                      <div className="absolute inset-0 grid grid-cols-3 grid-rows-3 pointer-events-none">
                        <div className="border-r border-b border-white/30" />
                        <div className="border-r border-b border-white/30" />
                        <div className="border-b border-white/30" />
                        <div className="border-r border-b border-white/30" />
                        <div className="border-r border-b border-white/30" />
                        <div className="border-b border-white/30" />
                        <div className="border-r border-white/30" />
                        <div className="border-r border-white/30" />
                        <div />
                      </div>
                    </div>

                    {/* Terracotta Corner Drag Handles */}
                    <span className="absolute -top-1.5 -left-1.5 w-3 h-3 bg-[#D98768] border border-white rounded-xs" />
                    <span className="absolute -top-1.5 -right-1.5 w-3 h-3 bg-[#D98768] border border-white rounded-xs" />
                    <span className="absolute -bottom-1.5 -left-1.5 w-3 h-3 bg-[#D98768] border border-white rounded-xs" />
                    <span className="absolute -bottom-1.5 -right-1.5 w-3 h-3 bg-[#D98768] border border-white rounded-xs" />

                    {/* Dimension Readout Badge */}
                    <div className="absolute -bottom-7 left-1/2 -translate-x-1/2 px-2 py-0.5 rounded bg-[#34312D]/90 text-[#FAF8F3] text-[9.5px] font-mono font-bold shadow-xs">
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
                  <span className="text-[10px] font-mono text-[#D98768] font-bold bg-[#FAF8F3] px-2 py-1 rounded border border-[#E5D8C7]">
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
                    className="w-8 h-8 rounded-full bg-[#FFFFFF] border border-[#E5D8C7] hover:border-[#D98768] flex items-center justify-center text-[#34312D] shrink-0 cursor-pointer shadow-2xs transition-colors"
                    aria-label={isPlayingTrim ? "Pause preview" : "Play preview"}
                  >
                    {isPlayingTrim ? (
                      <Pause size={12} className="text-[#D98768]" />
                    ) : (
                      <Play size={12} className="ml-0.5 text-[#34312D]" />
                    )}
                  </button>

                  {/* Horizontal Timeline Bar with 8 Video Frame Slices */}
                  <div className="flex-grow relative h-12 rounded-lg overflow-hidden border border-[#E5D8C7] bg-[#34312D]">
                    <div className="grid grid-cols-8 h-full divide-x divide-[#34312D]/40">
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
                        <span className="absolute -top-1 -left-[3px] w-2 h-2 bg-white rotate-45 rounded-2xs" />
                      </div>
                    </div>
                  </div>
                </div>

                {/* Timeline Timestamps */}
                <div className="flex items-center justify-between text-[11px] font-mono text-[#898177]">
                  <span>00:00</span>
                  <span className="px-2 py-0.5 rounded bg-[#FFFFFF] border border-[#E5D8C7] text-[#D98768] font-bold">
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
                    <div className="w-full h-14 rounded overflow-hidden bg-[#FAF8F3] mb-1">
                      <img src="/photo_thumb.jpg" alt="P1" className="w-full h-full object-cover" />
                    </div>
                    <span className="block text-center text-[9px] font-mono font-bold text-[#898177]">1</span>
                  </div>

                  {/* Page 2 (Active Selected) */}
                  <div
                    onClick={() => setActivePdfPage(2)}
                    className={`flex-1 p-1 rounded-lg bg-[#FFFFFF] border cursor-pointer transition-all ${
                      activePdfPage === 2 ? "border-[#D98768] ring-1 ring-[#D98768] shadow-2xs" : "border-[#E5D8C7]"
                    }`}
                  >
                    <div className="w-full h-14 rounded border border-[#E5D8C7] bg-[#FAF8F3] p-1 flex flex-col justify-between mb-1">
                      <div className="space-y-1">
                        <div className="w-3/4 h-1 bg-[#D98768]/60 rounded-full" />
                        <div className="w-full h-1 bg-[#E5D8C7] rounded-full" />
                        <div className="w-5/6 h-1 bg-[#E5D8C7] rounded-full" />
                      </div>
                      <div className="w-1/2 h-1 bg-[#E5D8C7] rounded-full" />
                    </div>
                    <span className="block text-center text-[9px] font-mono font-bold text-[#D98768]">2</span>
                  </div>

                  {/* Page 3 */}
                  <div
                    onClick={() => setActivePdfPage(3)}
                    className={`flex-1 p-1 rounded-lg bg-[#FFFFFF] border cursor-pointer transition-all ${
                      activePdfPage === 3 ? "border-[#D98768] ring-1 ring-[#D98768]" : "border-[#E5D8C7]"
                    }`}
                  >
                    <div className="w-full h-14 rounded overflow-hidden bg-[#FAF8F3] mb-1">
                      <img src="/mountain_sample.jpg" alt="P3" className="w-full h-full object-cover" />
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
                    <div className="w-full h-14 rounded border border-[#E5D8C7] bg-[#FAF8F3] p-1 flex flex-col justify-between mb-1">
                      <div className="space-y-1">
                        <div className="w-full h-1 bg-[#E5D8C7] rounded-full" />
                        <div className="w-2/3 h-1 bg-[#E5D8C7] rounded-full" />
                      </div>
                      <div className="w-1/2 h-1 bg-[#E5D8C7] rounded-full" />
                    </div>
                    <span className="block text-center text-[9px] font-mono font-bold text-[#898177]">4</span>
                  </div>

                  {/* Add Page Slot */}
                  <div className="flex-1 p-1 rounded-lg border-2 border-dashed border-[#E5D8C7] hover:border-[#D98768] transition-colors flex flex-col items-center justify-center h-20 text-[#898177] hover:text-[#D98768] cursor-pointer">
                    <Plus size={14} />
                    <span className="text-[7.5px] font-mono uppercase mt-1">Add</span>
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
                  <div className="col-span-5 space-y-1">
                    <span className="text-[9px] font-mono uppercase font-bold text-[#898177] block mb-1">
                      Before
                    </span>
                    <div className="flex items-center gap-1 text-[#34312D] truncate">
                      <MapPin size={10} className="text-[#D98768] shrink-0" />
                      <span className="truncate">San Francisco</span>
                    </div>
                    <div className="flex items-center gap-1 text-[#34312D] truncate">
                      <Camera size={10} className="text-[#D98768] shrink-0" />
                      <span className="truncate">iPhone 15 Pro</span>
                    </div>
                    <div className="flex items-center gap-1 text-[#34312D] truncate">
                      <Calendar size={10} className="text-[#D98768] shrink-0" />
                      <span className="truncate">Oct 14, 2024</span>
                    </div>
                    <div className="flex items-center gap-1 text-[#34312D] truncate">
                      <User size={10} className="text-[#D98768] shrink-0" />
                      <span className="truncate">John Appleseed</span>
                    </div>
                  </div>

                  {/* Divider Arrow */}
                  <div className="col-span-1 flex items-center justify-center text-[#D98768]">
                    <ArrowRight size={12} />
                  </div>

                  {/* After Column */}
                  <div className="col-span-5 space-y-1">
                    <span className="text-[9px] font-mono uppercase font-bold text-[#465343] block mb-1">
                      After
                    </span>
                    <div className="text-[#898177] font-mono">— Scrubbed</div>
                    <div className="text-[#898177] font-mono">— Scrubbed</div>
                    <div className="text-[#898177] font-mono">— Scrubbed</div>
                    <div className="text-[#898177] font-mono">— Scrubbed</div>
                  </div>
                </div>

                <div className="pt-1 border-t border-[#E5D8C7]/60 flex items-center justify-between text-[10px] font-mono text-[#465343]">
                  <span>EXIF & XMP</span>
                  <span className="font-bold">✓ 4 tags removed</span>
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
              <div className="p-2.5 rounded-xl bg-[#FAF8F3] border border-[#E5D8C7] space-y-1.5 text-xs">
                {/* Row 1: Converting */}
                <div className="p-1.5 rounded-lg bg-[#FFFFFF] border border-[#E5D8C7] flex items-center justify-between gap-2">
                  <div className="flex items-center gap-1.5 truncate">
                    <FileImage size={13} className="text-[#D98768] shrink-0" />
                    <span className="font-medium text-[#34312D] text-[11px] truncate">vacation.jpg</span>
                  </div>
                  <div className="flex items-center gap-1.5 shrink-0">
                    <div className="w-14 h-1.5 rounded-full bg-[#E5D8C7] overflow-hidden">
                      <div className="w-[78%] h-full bg-[#D98768] rounded-full" />
                    </div>
                    <span className="font-mono text-[9px] text-[#898177]">78%</span>
                  </div>
                </div>

                {/* Row 2: Trimming */}
                <div className="p-1.5 rounded-lg bg-[#FFFFFF] border border-[#E5D8C7] flex items-center justify-between gap-2">
                  <div className="flex items-center gap-1.5 truncate">
                    <Film size={13} className="text-[#465343] shrink-0" />
                    <span className="font-medium text-[#34312D] text-[11px] truncate">interview.mov</span>
                  </div>
                  <div className="flex items-center gap-1.5 shrink-0">
                    <div className="w-14 h-1.5 rounded-full bg-[#E5D8C7] overflow-hidden">
                      <div className="w-[42%] h-full bg-[#D98768] rounded-full" />
                    </div>
                    <span className="font-mono text-[9px] text-[#898177]">42%</span>
                  </div>
                </div>

                {/* Row 3: Complete */}
                <div className="p-1.5 rounded-lg bg-[#FFFFFF] border border-[#E5D8C7] flex items-center justify-between gap-2">
                  <div className="flex items-center gap-1.5 truncate">
                    <FileText size={13} className="text-[#898177] shrink-0" />
                    <span className="font-medium text-[#34312D] text-[11px] truncate">report.pdf</span>
                  </div>
                  <div className="flex items-center gap-1.5 shrink-0">
                    <div className="w-14 h-1.5 rounded-full bg-[#A8B5A0] overflow-hidden">
                      <div className="w-full h-full bg-[#465343] rounded-full" />
                    </div>
                    <Check size={11} className="text-[#465343]" strokeWidth={3} />
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
