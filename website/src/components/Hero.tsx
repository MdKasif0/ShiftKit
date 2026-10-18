"use client";

import React, { useState } from "react";
import Link from "next/link";
import Image from "next/image";
import {
  Download,
  Play,
  Check,
  FileImage,
  Crop,
  Layers,
  Sliders,
  FileText,
  Shrink,
  Sparkles,
  Clock,
  HardDrive,
  Folder,
  ArrowDownCircle,
  Film,
} from "lucide-react";

interface ActionItem {
  id: string;
  name: string;
  label: string;
  outputName: string;
  outputMeta: string;
  outputBadge: string;
  description: string;
  icon: React.ComponentType<{ size?: number; className?: string }>;
  startAngle: number;
  endAngle: number;
}

const ACTIONS: ActionItem[] = [
  {
    id: "convert",
    name: "Convert",
    label: "CONVERT",
    outputName: "photo.webp",
    outputMeta: "1.1 MB • WEBP",
    outputBadge: "54% smaller",
    description: "Lossless CoreGraphics WebP encoding • 12ms",
    icon: Sparkles,
    startAngle: -120,
    endAngle: -60,
  },
  {
    id: "crop",
    name: "Crop",
    label: "CROP",
    outputName: "photo_1x1.png",
    outputMeta: "1.3 MB • PNG",
    outputBadge: "Square 1:1",
    description: "Center-weighted smart crop (1080 × 1080)",
    icon: Crop,
    startAngle: -60,
    endAngle: 0,
  },
  {
    id: "merge",
    name: "Merge",
    label: "MERGE",
    outputName: "portfolio.pdf",
    outputMeta: "2.6 MB • PDF",
    outputBadge: "Combined Document",
    description: "Native PDFKit pipeline • Zero recompression",
    icon: Layers,
    startAngle: 0,
    endAngle: 60,
  },
  {
    id: "edit",
    name: "Edit",
    label: "EDIT",
    outputName: "photo_clean.png",
    outputMeta: "2.4 MB • PNG",
    outputBadge: "EXIF Scrubbed",
    description: "Stripped camera GPS, serials & metadata",
    icon: Sliders,
    startAngle: 60,
    endAngle: 120,
  },
  {
    id: "extract",
    name: "Extract",
    label: "EXTRACT",
    outputName: "palette.json",
    outputMeta: "8 KB • JSON",
    outputBadge: "6 Dominant Colors",
    description: "Color palette extracted locally in memory",
    icon: FileText,
    startAngle: 120,
    endAngle: 180,
  },
  {
    id: "compress",
    name: "Compress",
    label: "COMPRESS",
    outputName: "photo.min.png",
    outputMeta: "820 KB • PNG",
    outputBadge: "66% smaller",
    description: "Pngquant on-device compression • 45ms",
    icon: Shrink,
    startAngle: 180,
    endAngle: 240,
  },
];

// SVG Annular Sector Path Generator
function getSectorPath(
  cx: number,
  cy: number,
  innerR: number,
  outerR: number,
  startAngleDeg: number,
  endAngleDeg: number,
  gapDeg: number = 3
): string {
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const start = toRad(startAngleDeg + gapDeg / 2);
  const end = toRad(endAngleDeg - gapDeg / 2);

  const x1 = (cx + outerR * Math.cos(start)).toFixed(2);
  const y1 = (cy + outerR * Math.sin(start)).toFixed(2);
  const x2 = (cx + outerR * Math.cos(end)).toFixed(2);
  const y2 = (cy + outerR * Math.sin(end)).toFixed(2);

  const x3 = (cx + innerR * Math.cos(end)).toFixed(2);
  const y3 = (cy + innerR * Math.sin(end)).toFixed(2);
  const x4 = (cx + innerR * Math.cos(start)).toFixed(2);
  const y4 = (cy + innerR * Math.sin(start)).toFixed(2);

  const largeArc = endAngleDeg - startAngleDeg > 180 ? 1 : 0;
  return `M ${x1} ${y1} A ${outerR} ${outerR} 0 ${largeArc} 1 ${x2} ${y2} L ${x3} ${y3} A ${innerR} ${innerR} 0 ${largeArc} 0 ${x4} ${y4} Z`;
}

export function Hero() {
  const [activeActionId, setActiveActionId] = useState<string>("convert");
  const activeAction = ACTIONS.find((a) => a.id === activeActionId) || ACTIONS[0];

  const dmgUrl = process.env.NEXT_PUBLIC_SHIFTKIT_DMG_URL || "/downloads/ShiftKit-1.0.0.dmg";

  return (
    <section className="relative overflow-hidden bg-[#FAF8F3] pt-5 pb-16 sm:pt-7 sm:pb-20 md:pt-9 md:pb-28">
      {/* Editorial Desk Background Image */}
      <div
        className="absolute inset-0 bg-cover bg-bottom bg-no-repeat pointer-events-none opacity-90 sm:opacity-95"
        style={{ backgroundImage: "url('/hero-bg.jpg')" }}
        aria-hidden="true"
      >
        {/* Soft top gradient to blend smoothly into the sticky navbar */}
        <div className="absolute inset-x-0 top-0 h-28 bg-gradient-to-b from-[#FAF8F3] via-[#FAF8F3]/80 to-transparent" />
        {/* Soft bottom gradient to transition into the next content section */}
        <div className="absolute inset-x-0 bottom-0 h-32 bg-gradient-to-t from-[#FAF8F3] via-[#FAF8F3]/70 to-transparent" />
      </div>

      <div className="relative max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Top Header Group: Compact, Intentional Hierarchy */}
        <div className="text-center max-w-2xl mx-auto">
          {/* Compatibility Badge */}
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#F3EEE4] border border-[#E5D8C7] text-[11px] font-semibold tracking-wider text-[#465343] uppercase shadow-2xs mb-3">
            <span className="w-1.5 h-1.5 rounded-full bg-[#D98768] animate-pulse"></span>
            MADE FOR macOS 14+
          </div>

          {/* Refined Headline */}
          <h1 className="font-serif text-4xl sm:text-5xl md:text-6xl font-bold tracking-tight text-[#34312D] leading-[1.08] mb-3">
            Your files. <br className="hidden sm:inline" />
            <span className="text-[#465343]">One gesture.</span>
          </h1>

          {/* Supporting Text with Realistic Shift Key */}
          <p className="text-base sm:text-lg text-[#34312D]/85 leading-relaxed font-sans max-w-xl mx-auto mb-5">
            Convert and edit files without leaving your workflow. Hold{" "}
            <kbd className="inline-flex items-center px-2 py-0.5 mx-0.5 text-xs font-mono font-bold bg-[#F3EEE4] border border-[#E5D8C7] rounded-md text-[#34312D] shadow-[0_1px_2px_rgba(52,49,45,0.08),inset_0_1px_0_rgba(255,255,255,0.9)]">
              ⇧ Shift
            </kbd>
            , drag a file, and choose what happens next.
          </p>

          {/* Action CTAs */}
          <div className="flex flex-col sm:flex-row items-center justify-center gap-3 mb-4">
            <a
              href={dmgUrl}
              download
              className="w-full sm:w-auto inline-flex items-center justify-center gap-2 px-6 py-3 rounded-lg text-sm font-semibold bg-[#D98768] hover:bg-[#c97556] active:bg-[#b86445] text-[#FAF8F3] shadow-[0_2px_8px_rgba(217,135,104,0.3)] transition-all transform hover:-translate-y-0.5 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-[#D98768]"
            >
              <Download size={16} className="stroke-[2.2]" />
              <span>Download for Mac</span>
            </a>
            <Link
              href="#how-it-works"
              className="w-full sm:w-auto inline-flex items-center justify-center gap-2 px-5 py-3 rounded-lg text-sm font-medium bg-[#FFFFFF] hover:bg-[#F3EEE4] text-[#34312D] border border-[#E5D8C7] shadow-2xs transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#465343]"
            >
              <Play size={14} className="fill-[#465343] stroke-[#465343]" />
              <span>See how it works</span>
            </Link>
          </div>

          {/* Subtle Trust Indicators */}
          <div className="flex flex-wrap items-center justify-center gap-y-1.5 gap-x-5 text-xs text-[#465343]/90 font-medium mb-8">
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

        {/* Product Showcase Composition: Foreground Window with Finder Framing */}
        <div className="relative max-w-5xl mx-auto">
          {/* Subtle Finder Background Window: Left Sidebar (Desktop Only) */}
          <div
            className="hidden xl:block absolute -left-12 -bottom-2 w-52 h-[340px] rounded-xl bg-[#FAF8F3]/95 border border-[#E5D8C7] shadow-[0_12px_32px_rgba(52,49,45,0.08)] p-3 -z-10 transform -rotate-1 pointer-events-none select-none"
            aria-hidden="true"
          >
            <div className="flex items-center gap-1.5 mb-3 pb-2 border-b border-[#E5D8C7]/60">
              <span className="w-2.5 h-2.5 rounded-full bg-[#FF5F56]/80"></span>
              <span className="w-2.5 h-2.5 rounded-full bg-[#FFBD2E]/80"></span>
              <span className="w-2.5 h-2.5 rounded-full bg-[#27C93F]/80"></span>
              <span className="ml-2 text-[10px] font-medium text-[#898177]">Favorites</span>
            </div>
            <div className="space-y-1 text-[11px] text-[#34312D]/75">
              <div className="flex items-center gap-2 px-2 py-1 rounded text-[#34312D]/60">
                <Clock size={12} />
                <span>Recents</span>
              </div>
              <div className="flex items-center gap-2 px-2 py-1 rounded text-[#34312D]/60">
                <HardDrive size={12} />
                <span>Applications</span>
              </div>
              <div className="flex items-center gap-2 px-2 py-1 rounded bg-[#E5D8C7]/50 font-semibold text-[#465343]">
                <Folder size={12} />
                <span>Desktop</span>
              </div>
              <div className="flex items-center gap-2 px-2 py-1 rounded text-[#34312D]/60">
                <Folder size={12} />
                <span>Documents</span>
              </div>
              <div className="flex items-center gap-2 px-2 py-1 rounded text-[#34312D]/60">
                <ArrowDownCircle size={12} />
                <span>Downloads</span>
              </div>
              <div className="flex items-center gap-2 px-2 py-1 rounded text-[#34312D]/60">
                <FileImage size={12} />
                <span>Pictures</span>
              </div>
              <div className="flex items-center gap-2 px-2 py-1 rounded text-[#34312D]/60">
                <Film size={12} />
                <span>Movies</span>
              </div>
            </div>
          </div>

          {/* Subtle Finder Background Window: Right Files (Desktop Only) */}
          <div
            className="hidden xl:block absolute -right-12 -bottom-2 w-52 h-[340px] rounded-xl bg-[#FAF8F3]/95 border border-[#E5D8C7] shadow-[0_12px_32px_rgba(52,49,45,0.08)] p-3 -z-10 transform rotate-1 pointer-events-none select-none"
            aria-hidden="true"
          >
            <div className="flex items-center justify-between mb-3 pb-2 border-b border-[#E5D8C7]/60">
              <div className="flex items-center gap-1.5">
                <span className="w-2.5 h-2.5 rounded-full bg-[#FF5F56]/80"></span>
                <span className="w-2.5 h-2.5 rounded-full bg-[#FFBD2E]/80"></span>
                <span className="w-2.5 h-2.5 rounded-full bg-[#27C93F]/80"></span>
              </div>
              <span className="text-[10px] font-medium text-[#898177]">Desktop</span>
            </div>
            <div className="space-y-2.5 text-[11px]">
              <div className="p-2 rounded-lg bg-[#FFFFFF] border border-[#E5D8C7] flex items-center gap-2">
                <div className="w-8 h-8 rounded bg-[#FAF8F3] border border-[#E5D8C7] flex items-center justify-center shrink-0 overflow-hidden">
                  <Image
                    src="/mountain-sample.png"
                    alt="Vacation thumbnail"
                    width={32}
                    height={32}
                    className="w-full h-full object-cover"
                  />
                </div>
                <div className="truncate">
                  <p className="font-medium text-[#34312D] truncate">Vacation.jpg</p>
                  <p className="text-[10px] text-[#898177]">3.8 MB</p>
                </div>
              </div>
              <div className="p-2 rounded-lg bg-[#FFFFFF] border border-[#E5D8C7] flex items-center gap-2">
                <div className="w-8 h-8 rounded bg-[#FAF8F3] border border-[#E5D8C7] flex items-center justify-center text-[#D98768] shrink-0">
                  <FileText size={16} />
                </div>
                <div className="truncate">
                  <p className="font-medium text-[#34312D] truncate">Design.pdf</p>
                  <p className="text-[10px] text-[#898177]">1.2 MB</p>
                </div>
              </div>
              <div className="p-2 rounded-lg bg-[#FFFFFF] border border-[#E5D8C7] flex items-center gap-2">
                <div className="w-8 h-8 rounded bg-[#FAF8F3] border border-[#E5D8C7] flex items-center justify-center text-[#465343] shrink-0">
                  <Film size={16} />
                </div>
                <div className="truncate">
                  <p className="font-medium text-[#34312D] truncate">Clip.mp4</p>
                  <p className="text-[10px] text-[#898177]">18.4 MB</p>
                </div>
              </div>
            </div>
          </div>

          {/* Main Foreground Native macOS Application Window */}
          <div className="relative rounded-2xl bg-[#FDFBF7] border border-[#E5D8C7] shadow-[0_20px_50px_rgba(52,49,45,0.14),0_4px_12px_rgba(52,49,45,0.06)] p-4 sm:p-6 lg:p-7 backdrop-blur-xs">
            {/* macOS Window Title Bar */}
            <div className="flex items-center justify-between pb-3.5 mb-5 border-b border-[#E5D8C7]/80">
              <div className="flex items-center gap-2">
                <span className="w-3 h-3 rounded-full bg-[#FF5F56] border border-[#E0443E]"></span>
                <span className="w-3 h-3 rounded-full bg-[#FFBD2E] border border-[#DEA123]"></span>
                <span className="w-3 h-3 rounded-full bg-[#27C93F] border border-[#1AAB29]"></span>
              </div>
              <div className="text-xs font-medium tracking-wide text-[#34312D]/80">
                ShiftKit Radial Action Canvas
              </div>
              <div className="flex items-center gap-1.5 px-2 py-0.5 rounded bg-[#F5D5C2]/40 border border-[#D98768]/30 text-[11px] font-mono text-[#D98768] font-semibold">
                <span>[ ⇧ Shift Active ]</span>
              </div>
            </div>

            {/* Stage: 3 Connected Columns (Input File → Radial Menu → Output Result) */}
            <div className="grid grid-cols-1 md:grid-cols-12 gap-5 sm:gap-6 items-center">
              {/* Left Column: Input File Card with Mouse Pointer and Shift Key */}
              <div className="md:col-span-3 flex flex-col items-center md:items-start space-y-2.5">
                <span className="text-[10px] font-mono font-bold tracking-wider text-[#465343] uppercase">
                  1. Drag file with Shift
                </span>

                <div className="relative w-full max-w-[200px] p-3.5 rounded-xl bg-[#FFFFFF] border border-[#E5D8C7] shadow-sm flex flex-col items-center text-center space-y-2">
                  <div className="w-20 h-20 rounded-lg bg-[#FAF8F3] border border-[#E5D8C7] overflow-hidden flex items-center justify-center shadow-2xs">
                    <Image
                      src="/mountain-sample.png"
                      alt="Input photo thumbnail"
                      width={80}
                      height={80}
                      className="w-full h-full object-cover"
                    />
                  </div>
                  <div>
                    <p className="font-semibold text-xs text-[#34312D]">photo.png</p>
                    <p className="text-[11px] text-[#898177]">2.4 MB • PNG</p>
                  </div>

                  {/* macOS Cursor Drag Token Overlay */}
                  <div className="absolute -bottom-2 -right-2 flex items-center gap-1 bg-[#34312D] text-[#FAF8F3] pl-1.5 pr-2 py-1 rounded-md shadow-md text-[11px] font-medium border border-[#34312D]">
                    <svg
                      width="12"
                      height="12"
                      viewBox="0 0 24 24"
                      fill="white"
                      className="transform -rotate-12"
                    >
                      <path d="M3 3l7 18 3-7 7-3L3 3z" />
                    </svg>
                    <span className="bg-[#D98768] text-white text-[10px] font-bold px-1 py-0.2 rounded font-mono">
                      ⇧ Shift
                    </span>
                  </div>
                </div>
              </div>

              {/* Center Column: The Signature Radial Menu */}
              <div className="md:col-span-6 flex flex-col items-center justify-center">
                <span className="text-[10px] font-mono font-bold tracking-wider text-[#465343] uppercase mb-2">
                  2. Choose Action from Radial Menu
                </span>

                {/* Circular Radial Menu Widget with Exact Sector Geometry */}
                <div className="relative w-64 h-64 sm:w-72 sm:h-72 flex items-center justify-center select-none">
                  {/* Subtle outer guidance dashed circle */}
                  <div className="absolute inset-1 rounded-full border border-dashed border-[#E5D8C7] pointer-events-none" />

                  {/* SVG Pie Sectors */}
                  <svg
                    viewBox="0 0 300 300"
                    className="w-full h-full drop-shadow-[0_8px_20px_rgba(52,49,45,0.08)]"
                  >
                    {ACTIONS.map((action) => {
                      const isActive = activeActionId === action.id;
                      const pathData = getSectorPath(150, 150, 48, 126, action.startAngle, action.endAngle, 3);
                      return (
                        <path
                          key={action.id}
                          d={pathData}
                          onClick={() => setActiveActionId(action.id)}
                          onMouseEnter={() => setActiveActionId(action.id)}
                          className={`cursor-pointer transition-all duration-200 stroke-2 stroke-[#FAF8F3] ${
                            isActive
                              ? "fill-[#D98768] hover:fill-[#c97556]"
                              : "fill-[#F3EEE4] hover:fill-[#E5D8C7]"
                          }`}
                        />
                      );
                    })}
                  </svg>

                  {/* Sector Action Icons and Labels Placed over Centroids */}
                  {ACTIONS.map((action) => {
                    const isActive = activeActionId === action.id;
                    const Icon = action.icon;

                    // Centroid math: R = 86px, Angle = mid angle
                    const midAngle = (action.startAngle + action.endAngle) / 2;
                    const rad = (midAngle * Math.PI) / 180;
                    const cx = 50 + ((86 * Math.cos(rad)) / 300) * 100;
                    const cy = 50 + ((86 * Math.sin(rad)) / 300) * 100;

                    return (
                      <button
                        key={action.id}
                        type="button"
                        onClick={() => setActiveActionId(action.id)}
                        onMouseEnter={() => setActiveActionId(action.id)}
                        style={{ left: `${cx}%`, top: `${cy}%` }}
                        className={`absolute transform -translate-x-1/2 -translate-y-1/2 flex flex-col items-center justify-center pointer-events-auto transition-transform ${
                          isActive ? "scale-105" : "hover:scale-102"
                        }`}
                        aria-label={`Select ${action.name} action`}
                      >
                        <Icon
                          size={15}
                          className={isActive ? "text-white" : "text-[#34312D]"}
                        />
                        <span
                          className={`text-[9px] font-bold tracking-wider mt-0.5 uppercase ${
                            isActive ? "text-white" : "text-[#34312D]/85"
                          }`}
                        >
                          {action.label}
                        </span>
                      </button>
                    );
                  })}

                  {/* Central Hub Disc */}
                  <div className="absolute w-24 h-24 rounded-full bg-[#FFFFFF] border-2 border-[#E5D8C7] shadow-sm flex flex-col items-center justify-center p-1.5 pointer-events-none z-10 text-center">
                    <div className="w-7 h-7 rounded bg-[#FAF8F3] border border-[#E5D8C7] overflow-hidden mb-1 flex items-center justify-center">
                      <Image
                        src="/mountain-sample.png"
                        alt="Hub thumbnail"
                        width={28}
                        height={28}
                        className="w-full h-full object-cover"
                      />
                    </div>
                    <span className="text-[10px] font-semibold text-[#34312D] leading-none truncate max-w-[70px]">
                      photo.png
                    </span>
                    <span className="text-[8px] text-[#898177] mt-0.5 leading-none">
                      Image • 2.4 MB
                    </span>
                  </div>
                </div>

                <p className="mt-2 text-[11px] text-[#465343] font-medium text-center">
                  Click or hover any slice to simulate on-device action
                </p>
              </div>

              {/* Right Column: Verified Output Card */}
              <div className="md:col-span-3 flex flex-col items-center md:items-end space-y-2.5">
                <span className="text-[10px] font-mono font-bold tracking-wider text-[#D98768] uppercase">
                  3. Instant Verified Result
                </span>

                <div className="relative w-full max-w-[200px] p-3.5 rounded-xl bg-[#FFFFFF] border border-[#A8B5A0] shadow-sm flex flex-col items-center text-center space-y-2 transition-all duration-300">
                  {/* Top-Right Success Checkmark Pill */}
                  <div className="absolute -top-2.5 -right-2.5 w-6 h-6 rounded-full bg-[#465343] text-white flex items-center justify-center shadow-xs border-2 border-white">
                    <Check size={12} className="stroke-[3]" />
                  </div>

                  <div className="w-20 h-20 rounded-lg bg-[#FAF8F3] border border-[#E5D8C7] overflow-hidden flex items-center justify-center shadow-2xs">
                    <Image
                      src="/mountain-sample.png"
                      alt="Output result thumbnail"
                      width={80}
                      height={80}
                      className="w-full h-full object-cover"
                    />
                  </div>

                  <div>
                    <p className="font-semibold text-xs text-[#34312D]">
                      {activeAction.outputName}
                    </p>
                    <p className="text-[11px] text-[#465343] font-medium">
                      {activeAction.outputMeta}
                    </p>
                  </div>

                  <span className="inline-block px-2 py-0.5 rounded text-[10px] font-semibold bg-[#F3EEE4] text-[#465343] border border-[#E5D8C7]">
                    {activeAction.outputBadge}
                  </span>
                </div>
              </div>
            </div>

            {/* Bottom Status Feedback Bar */}
            <div className="mt-5 pt-3 border-t border-[#E5D8C7]/70 flex flex-col sm:flex-row items-center justify-between gap-2 text-xs text-[#898177]">
              <div className="flex items-center gap-2">
                <span className="w-2 h-2 rounded-full bg-[#465343]"></span>
                <span className="font-medium text-[#34312D]">
                  Action: <span className="text-[#D98768] font-semibold">{activeAction.name}</span>
                </span>
                <span className="hidden sm:inline text-[#E5D8C7]">•</span>
                <span className="text-[#465343] font-medium">{activeAction.description}</span>
              </div>
              <div className="font-mono text-[11px] text-[#898177]">
                Local Sandbox • Zero Uploads
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
