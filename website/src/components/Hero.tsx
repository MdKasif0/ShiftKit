"use client";

import React, { useState } from "react";
import Link from "next/link";
import { Download, Play, ArrowRight, Sparkles, Check, FileImage, Scissors, Shrink, Layers, ShieldCheck } from "lucide-react";

export function Hero() {
  const [activeSegment, setActiveSegment] = useState<string>("convert");
  const [isHoveringMenu, setIsHoveringMenu] = useState(false);

  return (
    <section className="relative pt-12 pb-20 md:pt-20 md:pb-32 overflow-hidden">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Top Centered Header Content */}
        <div className="text-center max-w-3xl mx-auto space-y-6">
          {/* Tasteful Label */}
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#F3EEE4] border border-[#E5D8C7] text-xs font-semibold tracking-wider text-[#465343] uppercase shadow-2xs">
            <span className="w-1.5 h-1.5 rounded-full bg-[#D98768]"></span>
            MADE FOR macOS 14+
          </div>

          {/* Main Headline */}
          <h1 className="font-serif text-4xl sm:text-5xl md:text-6xl lg:text-7xl font-bold tracking-tight text-[#34312D] leading-[1.08]">
            Your files. <br className="hidden sm:inline" />
            <span className="text-[#465343]">One gesture.</span>
          </h1>

          {/* Supporting Text */}
          <p className="text-lg sm:text-xl text-[#34312D]/80 leading-relaxed font-sans max-w-2xl mx-auto">
            Convert and edit files without leaving your workflow. Hold <kbd className="px-2 py-0.5 text-xs font-mono font-bold bg-[#F3EEE4] border border-[#E5D8C7] rounded text-[#34312D] shadow-2xs">⇧ Shift</kbd>, drag a file, and choose what happens next.
          </p>

          {/* Action CTAs */}
          <div className="pt-2 flex flex-col sm:flex-row items-center justify-center gap-3.5">
            <Link
              href="#download"
              className="w-full sm:w-auto inline-flex items-center justify-center gap-2.5 px-6 py-3.5 rounded-lg text-sm font-semibold bg-[#D98768] hover:bg-[#c97556] text-[#FAF8F3] shadow-sm transition-all transform hover:-translate-y-0.5 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-[#D98768]"
            >
              <Download size={17} className="stroke-[2.2]" />
              <span>Download for Mac</span>
            </Link>
            <Link
              href="#interactive-demo"
              className="w-full sm:w-auto inline-flex items-center justify-center gap-2 px-6 py-3.5 rounded-lg text-sm font-medium bg-[#FFFFFF] hover:bg-[#F3EEE4] text-[#34312D] border border-[#E5D8C7] shadow-2xs transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#465343]"
            >
              <Play size={15} className="fill-[#465343] stroke-[#465343]" />
              <span>See how it works</span>
            </Link>
          </div>

          {/* Subtle reassurance metadata */}
          <div className="pt-3 flex flex-wrap items-center justify-center gap-y-2 gap-x-6 text-xs text-[#465343]/85 font-medium">
            <span className="flex items-center gap-1.5">
              <Check size={14} className="text-[#D98768] stroke-[2.5]" />
              100% on-device processing
            </span>
            <span className="flex items-center gap-1.5">
              <Check size={14} className="text-[#D98768] stroke-[2.5]" />
              Universal for Apple Silicon & Intel
            </span>
            <span className="flex items-center gap-1.5">
              <Check size={14} className="text-[#D98768] stroke-[2.5]" />
              No cloud conversion server
            </span>
          </div>
        </div>

        {/* Hero Product Visual Illustration */}
        <div className="mt-14 md:mt-20 max-w-4xl mx-auto">
          <div className="relative rounded-2xl bg-[#F3EEE4] border border-[#E5D8C7] p-4 sm:p-8 shadow-md">
            {/* macOS Window Title Bar */}
            <div className="flex items-center justify-between pb-4 mb-6 border-b border-[#E5D8C7]/70 text-xs text-[#34312D]/60">
              <div className="flex items-center gap-2">
                <span className="w-3 h-3 rounded-full bg-[#E5D8C7] border border-[#34312D]/10"></span>
                <span className="w-3 h-3 rounded-full bg-[#E5D8C7] border border-[#34312D]/10"></span>
                <span className="w-3 h-3 rounded-full bg-[#E5D8C7] border border-[#34312D]/10"></span>
              </div>
              <div className="font-medium tracking-wide text-[#465343]">
                ShiftKit Radial Action Canvas
              </div>
              <div className="text-[11px] font-mono text-[#D98768]">
                [⇧ Shift Active]
              </div>
            </div>

            {/* Interactive Transformation Stage */}
            <div className="grid grid-cols-1 md:grid-cols-12 gap-6 items-center py-4">
              {/* Left Column: Dragged File Token */}
              <div className="md:col-span-3 flex flex-col items-center md:items-start space-y-3">
                <span className="text-[11px] font-mono tracking-wider text-[#465343] uppercase">
                  1. Dragged From Finder
                </span>
                <div className="w-full max-w-[210px] p-4 rounded-xl bg-[#FFFFFF] border-2 border-dashed border-[#A8B5A0] shadow-2xs flex flex-col items-center text-center space-y-2">
                  <div className="w-12 h-12 rounded-lg bg-[#FAF8F3] border border-[#E5D8C7] flex items-center justify-center text-[#D98768]">
                    <FileImage size={24} />
                  </div>
                  <div>
                    <p className="font-medium text-xs text-[#34312D] truncate w-36">
                      hero_screenshot.png
                    </p>
                    <p className="text-[11px] text-[#34312D]/60">
                      4.8 MB • Portable Network Graphics
                    </p>
                  </div>
                  <span className="inline-block px-2 py-0.5 rounded text-[10px] font-medium bg-[#FAF8F3] text-[#465343] border border-[#E5D8C7]">
                    PNG Original
                  </span>
                </div>
              </div>

              {/* Center Column: ShiftKit Circular Radial Menu */}
              <div className="md:col-span-6 flex flex-col items-center justify-center py-4">
                <span className="text-[11px] font-mono tracking-wider text-[#465343] uppercase mb-4">
                  2. Circular Radial Action Menu
                </span>

                {/* The Radial Menu Widget */}
                <div
                  className="relative w-64 h-64 sm:w-72 sm:h-72 rounded-full bg-[#FAF8F3] border-2 border-[#E5D8C7] shadow-lg flex items-center justify-center"
                  onMouseEnter={() => setIsHoveringMenu(true)}
                  onMouseLeave={() => setIsHoveringMenu(false)}
                >
                  {/* Outer subtle guide rings */}
                  <div className="absolute inset-2 rounded-full border border-dashed border-[#E5D8C7]/80 pointer-events-none"></div>

                  {/* 5 Petal Segments arranged circularly */}
                  {/* Segment: Convert (Top) */}
                  <button
                    type="button"
                    onClick={() => setActiveSegment("convert")}
                    className={`absolute top-3 inset-x-0 mx-auto w-24 py-1.5 px-2 rounded-lg text-xs font-semibold flex flex-col items-center transition-all ${
                      activeSegment === "convert"
                        ? "bg-[#D98768] text-[#FAF8F3] shadow-xs scale-105"
                        : "bg-[#FFFFFF] text-[#34312D] border border-[#E5D8C7] hover:border-[#D98768]"
                    }`}
                  >
                    <Sparkles size={13} className="mb-0.5" />
                    <span>To WebP</span>
                  </button>

                  {/* Segment: Compress (Top Right) */}
                  <button
                    type="button"
                    onClick={() => setActiveSegment("compress")}
                    className={`absolute right-3 top-16 w-20 py-1.5 px-2 rounded-lg text-xs font-semibold flex flex-col items-center transition-all ${
                      activeSegment === "compress"
                        ? "bg-[#465343] text-[#FAF8F3] shadow-xs scale-105"
                        : "bg-[#FFFFFF] text-[#34312D] border border-[#E5D8C7] hover:border-[#465343]"
                    }`}
                  >
                    <Shrink size={13} className="mb-0.5" />
                    <span>Compress</span>
                  </button>

                  {/* Segment: Crop (Bottom Right) */}
                  <button
                    type="button"
                    onClick={() => setActiveSegment("crop")}
                    className={`absolute right-5 bottom-8 w-20 py-1.5 px-2 rounded-lg text-xs font-semibold flex flex-col items-center transition-all ${
                      activeSegment === "crop"
                        ? "bg-[#A8B5A0] text-[#34312D] shadow-xs scale-105"
                        : "bg-[#FFFFFF] text-[#34312D] border border-[#E5D8C7] hover:border-[#A8B5A0]"
                    }`}
                  >
                    <Scissors size={13} className="mb-0.5" />
                    <span>Crop</span>
                  </button>

                  {/* Segment: Merge (Bottom Left) */}
                  <button
                    type="button"
                    onClick={() => setActiveSegment("merge")}
                    className={`absolute left-5 bottom-8 w-20 py-1.5 px-2 rounded-lg text-xs font-semibold flex flex-col items-center transition-all ${
                      activeSegment === "merge"
                        ? "bg-[#D98768] text-[#FAF8F3] shadow-xs scale-105"
                        : "bg-[#FFFFFF] text-[#34312D] border border-[#E5D8C7] hover:border-[#D98768]"
                    }`}
                  >
                    <Layers size={13} className="mb-0.5" />
                    <span>To PDF</span>
                  </button>

                  {/* Segment: Metadata (Top Left) */}
                  <button
                    type="button"
                    onClick={() => setActiveSegment("meta")}
                    className={`absolute left-3 top-16 w-20 py-1.5 px-2 rounded-lg text-xs font-semibold flex flex-col items-center transition-all ${
                      activeSegment === "meta"
                        ? "bg-[#465343] text-[#FAF8F3] shadow-xs scale-105"
                        : "bg-[#FFFFFF] text-[#34312D] border border-[#E5D8C7] hover:border-[#465343]"
                    }`}
                  >
                    <ShieldCheck size={13} className="mb-0.5" />
                    <span>Scrub EXIF</span>
                  </button>

                  {/* Central Hub Button */}
                  <div className="w-20 h-20 rounded-full bg-[#FFFFFF] border-2 border-[#E5D8C7] shadow-xs flex flex-col items-center justify-center text-center p-2 z-10">
                    <span className="text-[10px] font-mono text-[#D98768] font-bold">
                      CLICK
                    </span>
                    <span className="text-[11px] font-bold text-[#34312D]">
                      Execute
                    </span>
                  </div>
                </div>

                <p className="mt-3 text-[11px] text-[#465343] font-medium text-center">
                  Hover or click segments to preview live action dispatch
                </p>
              </div>

              {/* Right Column: Local Validated Output Result */}
              <div className="md:col-span-3 flex flex-col items-center md:items-end space-y-3">
                <span className="text-[11px] font-mono tracking-wider text-[#D98768] uppercase font-bold">
                  3. Verified Local Output
                </span>
                <div className="w-full max-w-[210px] p-4 rounded-xl bg-[#FFFFFF] border border-[#A8B5A0] shadow-xs flex flex-col items-center text-center space-y-2">
                  <div className="w-12 h-12 rounded-lg bg-[#FAF8F3] border border-[#A8B5A0]/50 flex items-center justify-center text-[#465343]">
                    <Check size={22} className="stroke-[2.5]" />
                  </div>
                  <div>
                    <p className="font-semibold text-xs text-[#34312D] truncate w-36">
                      {activeSegment === "convert" && "hero_screenshot.webp"}
                      {activeSegment === "compress" && "hero_screenshot_min.png"}
                      {activeSegment === "crop" && "hero_screenshot_crop.png"}
                      {activeSegment === "merge" && "hero_screenshot.pdf"}
                      {activeSegment === "meta" && "hero_screenshot_clean.png"}
                    </p>
                    <p className="text-[11px] text-[#465343] font-medium">
                      {activeSegment === "convert" && "540 KB (89% reduced)"}
                      {activeSegment === "compress" && "1.6 MB (67% reduced)"}
                      {activeSegment === "crop" && "1200 × 1200 px (1:1)"}
                      {activeSegment === "merge" && "Single Page Document"}
                      {activeSegment === "meta" && "0 GPS / EXIF tags"}
                    </p>
                  </div>
                  <span className="inline-block px-2 py-0.5 rounded text-[10px] font-medium bg-[#F3EEE4] text-[#465343] border border-[#E5D8C7]">
                    Validated • On-Device
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
