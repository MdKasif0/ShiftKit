"use client";

import React, { useState } from "react";
import {
  Compass,
  Scissors,
  Film,
  Layers,
  ListFilter,
  Check,
  CheckCircle2,
  Play,
  Pause,
  RotateCcw,
  RotateCw,
  Sparkles,
  FileText,
  Image as ImageIcon,
  ShieldCheck,
  GripVertical,
  ArrowUpDown,
  Download,
  Grid,
  Info,
  Clock,
  ChevronRight,
  HardDrive,
  Cpu,
  Sliders,
} from "lucide-react";

export function AppShowcase() {
  const [activeTab, setActiveTab] = useState<"radial" | "crop" | "trim" | "merge" | "queue">("radial");

  // State for Showcase 1: Radial Action HUD
  const [radialSelectedAction, setRadialSelectedAction] = useState<string>("To WebP");

  // State for Showcase 2: Visual Crop Studio
  const [cropPreset, setCropPreset] = useState<"1:1" | "4:3" | "16:9" | "free">("1:1");
  const [showCropGrid, setShowCropGrid] = useState<boolean>(true);
  const [cropRotation, setCropRotation] = useState<number>(0);

  // State for Showcase 3: Timeline Video Trimmer
  const [trimRange, setTrimRange] = useState<{ start: string; end: string; duration: string; leftPercent: number; rightPercent: number }>({
    start: "00:04.250",
    end: "00:18.900",
    duration: "14.65s",
    leftPercent: 18,
    rightPercent: 78,
  });
  const [isVideoPlaying, setIsVideoPlaying] = useState<boolean>(false);

  // State for Showcase 4: Multi-File Merge Studio
  const [mergeDocuments, setMergeDocuments] = useState([
    { id: "doc-1", name: "contract_cover.pdf", type: "PDF", pages: 1, size: "240 KB" },
    { id: "doc-2", name: "signature_page.png", type: "PNG", pages: 1, size: "1.2 MB" },
    { id: "doc-3", name: "appendix_terms.pdf", type: "PDF", pages: 4, size: "680 KB" },
  ]);
  const [flattenForms, setFlattenForms] = useState<boolean>(true);
  const [preserveBookmarks, setPreserveBookmarks] = useState<boolean>(true);

  // State for Showcase 5: Job Queue & History
  const [selectedJobId, setSelectedJobId] = useState<string>("job-1");

  const tabs = [
    { id: "radial", label: "Radial Action HUD", icon: Compass },
    { id: "crop", label: "Visual Crop Studio", icon: Scissors },
    { id: "trim", label: "Timeline Video Trimmer", icon: Film },
    { id: "merge", label: "Multi-File Merge Studio", icon: Layers },
    { id: "queue", label: "Job Queue & History", icon: ListFilter },
  ] as const;

  // Polar math helpers for Radial SVG Menu
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

  // Radial menu definitions matching the provided screenshot
  const radialMenuWedges = [
    {
      id: "webp",
      name: "To WebP",
      centerAngle: -90, // Top
      icon: ImageIcon,
      outputName: "photo.webp",
      outputMeta: "WebP image",
      badgeColor: "#D98768",
    },
    {
      id: "compress",
      name: "Compress",
      centerAngle: -18, // Upper Right
      icon: Layers,
      outputName: "photo_compressed.png",
      outputMeta: "PNG image · 1.4 MB (-42%)",
      badgeColor: "#A8B5A0",
    },
    {
      id: "crop",
      name: "Crop",
      centerAngle: 54, // Lower Right
      icon: Scissors,
      outputName: "photo_square.png",
      outputMeta: "PNG image · 1080 × 1080",
      badgeColor: "#D98768",
    },
    {
      id: "pdf",
      name: "To PDF",
      centerAngle: 126, // Lower Left
      icon: FileText,
      outputName: "photo.pdf",
      outputMeta: "PDF Document · 1.8 MB",
      badgeColor: "#D98768",
    },
    {
      id: "exif",
      name: "EXIF Clean",
      centerAngle: 198, // Upper Left
      icon: ShieldCheck,
      outputName: "photo_sanitized.png",
      outputMeta: "PNG image · Metadata Cleaned",
      badgeColor: "#465343",
    },
  ];

  // Helper to get active radial wedge data
  const currentRadialWedge =
    radialMenuWedges.find((w) => w.name === radialSelectedAction) || radialMenuWedges[0];

  // Move document up in merge studio
  const moveDocUp = (index: number) => {
    if (index === 0) return;
    setMergeDocuments((prev) => {
      const copy = [...prev];
      const temp = copy[index - 1];
      copy[index - 1] = copy[index];
      copy[index] = temp;
      return copy;
    });
  };

  // Move document down in merge studio
  const moveDocDown = (index: number) => {
    if (index === mergeDocuments.length - 1) return;
    setMergeDocuments((prev) => {
      const copy = [...prev];
      const temp = copy[index + 1];
      copy[index + 1] = copy[index];
      copy[index] = temp;
      return copy;
    });
  };

  // Job queue task data
  const queueTasks = [
    {
      id: "job-1",
      name: "product_shoot_raw.tiff → To WebP",
      status: "Processing (82%)",
      statusType: "active",
      progress: 82,
      time: "0.4s elapsed",
      engine: "CoreGraphics ImageIO · Apple Silicon",
      size: "14.2 MB → 1.8 MB (est)",
      destination: "~/Downloads/Exports",
    },
    {
      id: "job-2",
      name: "screencast_demo.mov → Trimmed",
      status: "Complete · 0.6s",
      statusType: "done",
      progress: 100,
      time: "Finished 2m ago",
      engine: "AVAssetExportSession · Lossless Stream Copy",
      size: "420 MB → 112 MB",
      destination: "~/Movies/ShiftKit",
    },
    {
      id: "job-3",
      name: "annual_report_2026.pdf → Compress",
      status: "Complete · 1.1s",
      statusType: "done",
      progress: 100,
      time: "Finished 5m ago",
      engine: "PDFKit Flate Optimizer",
      size: "18.4 MB → 6.2 MB (-66%)",
      destination: "~/Documents/Compressed",
    },
    {
      id: "job-4",
      name: "podcast_ep42_master.wav → To AAC 320k",
      status: "Queued (FIFO)",
      statusType: "queued",
      progress: 0,
      time: "In line · Next up",
      engine: "AudioToolbox Converter",
      size: "48.6 MB Source",
      destination: "~/Music/ShiftKit Exports",
    },
  ];

  const activeQueueJob = queueTasks.find((j) => j.id === selectedJobId) || queueTasks[0];

  return (
    <section
      id="showcase"
      aria-label="Interface Showcase"
      className="py-14 md:py-22 bg-[#FAF8F3] scroll-mt-24"
    >
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* ========================================================= */}
        {/* SECTION HEADER                                            */}
        {/* ========================================================= */}
        <div className="text-center max-w-2xl mx-auto space-y-2.5 mb-10 sm:mb-12">
          <div className="inline-flex items-center gap-1.5 px-3 py-0.5 rounded-full bg-[#FAF8F3] border border-[#E5D8C7] shadow-2xs">
            <span className="w-1.5 h-1.5 rounded-full bg-[#D98768]" />
            <span className="text-[11px] font-mono font-bold uppercase tracking-widest text-[#D98768]">
              INTERFACE SHOWCASE
            </span>
          </div>

          <h2 className="font-serif text-3xl sm:text-4xl md:text-5xl font-bold tracking-tight text-[#34312D]">
            Designed for macOS. Handcrafted in Swift.
          </h2>

          <p className="text-sm sm:text-base text-[#34312D]/80 leading-relaxed max-w-xl mx-auto">
            Every pixel adheres to Apple human interface guidelines, elevated with warm editorial surfaces and crisp typography.
          </p>
        </div>

        {/* ========================================================= */}
        {/* 5 SHOWCASE SELECTORS                                      */}
        {/* ========================================================= */}
        <div
          role="tablist"
          aria-label="ShiftKit Interface Capabilities"
          className="flex items-center justify-start sm:justify-center gap-2 overflow-x-auto pb-3 mb-8 sm:mb-10 no-scrollbar select-none"
        >
          {tabs.map((tab) => {
            const Icon = tab.icon;
            const isSelected = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                role="tab"
                id={`tab-${tab.id}`}
                aria-selected={isSelected}
                aria-controls={`panel-${tab.id}`}
                type="button"
                onClick={() => setActiveTab(tab.id)}
                className={`inline-flex items-center gap-2 px-3.5 py-2 rounded-xl text-xs sm:text-[13px] font-semibold transition-all shrink-0 cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#D98768] ${
                  isSelected
                    ? "bg-[#D98768] text-[#FFFFFF] shadow-sm ring-1 ring-[#D98768]"
                    : "bg-[#F3EEE4] text-[#34312D] hover:bg-[#EAE3D6] border border-[#E5D8C7]"
                }`}
              >
                <Icon size={14} className={isSelected ? "text-[#FFFFFF]" : "text-[#D98768]"} />
                <span>{tab.label}</span>
              </button>
            );
          })}
        </div>

        {/* ========================================================= */}
        {/* MACOS APPLICATION PREVIEW WINDOW CONTAINER                */}
        {/* ========================================================= */}
        <div
          id={`panel-${activeTab}`}
          role="tabpanel"
          aria-labelledby={`tab-${activeTab}`}
          className="max-w-5xl mx-auto rounded-2xl sm:rounded-3xl bg-[#FAF8F3] border border-[#E5D8C7] shadow-sm overflow-hidden transition-all duration-300"
        >
          {/* Authentic macOS Window Header */}
          <div className="px-4 sm:px-6 py-3 bg-[#F3EEE4] border-b border-[#E5D8C7] flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="w-3 h-3 rounded-full bg-[#E58871] border border-[#D4745D]" />
              <span className="w-3 h-3 rounded-full bg-[#E6BF68] border border-[#D1A94F]" />
              <span className="w-3 h-3 rounded-full bg-[#8EA87D] border border-[#7B966A]" />
            </div>

            {/* Window Center Title */}
            <div className="font-mono text-xs sm:text-[13px] font-bold text-[#465343] tracking-tight">
              {activeTab === "radial" && "ShiftKit Radial Overlay — photo.png"}
              {activeTab === "crop" && "ShiftKit Crop Studio — photo.png"}
              {activeTab === "trim" && "ShiftKit Video Trimmer — screencast_demo.mov"}
              {activeTab === "merge" && `ShiftKit Multi-File Merge Studio — ${mergeDocuments.length} Documents`}
              {activeTab === "queue" && "ShiftKit Job Queue & Local History — 4 Tasks"}
            </div>

            {/* Window Right Technology Badge */}
            <div className="hidden sm:flex items-center gap-1.5 px-2 py-0.5 rounded bg-[#FAF8F3] border border-[#E5D8C7] text-[10px] font-mono text-[#D98768] font-bold">
              <span>Native Cocoa</span>
            </div>
          </div>

          {/* Window Body Canvas */}
          <div className="p-5 sm:p-8 min-h-[360px] sm:min-h-[400px] flex flex-col justify-between relative bg-gradient-to-b from-[#FAF8F3] to-[#F7F3EA]/70">
            {/* ===================================================== */}
            {/* VIEW 1: RADIAL ACTION HUD (Visual Centerpiece)        */}
            {/* ===================================================== */}
            {activeTab === "radial" && (
              <div className="w-full flex flex-col justify-between flex-grow animate-fadeIn">
                {/* 3-Column Radial Preview (Source Card -> Radial Wheel -> Destination Card) */}
                <div className="w-full relative flex flex-col lg:flex-row items-center justify-between gap-6 lg:gap-8 my-auto">
                  {/* Left Column: Source File Card */}
                  <div className="w-full max-w-[210px] shrink-0 flex flex-col items-center lg:items-start space-y-2 z-10">
                    <div className="w-full p-3 rounded-2xl bg-[#FFFFFF] border border-[#E5D8C7] shadow-xs space-y-2 text-center">
                      <div className="w-full h-24 rounded-xl overflow-hidden border border-[#E5D8C7] bg-[#F3EEE4]">
                        <img
                          src="/mountain_sample.jpg"
                          alt="Source Preview"
                          className="w-full h-full object-cover"
                        />
                      </div>
                      <div className="space-y-0.5">
                        <div className="font-mono text-xs font-bold text-[#34312D]">photo.png</div>
                        <div className="text-[11px] text-[#898177]">PNG image · 2.4 MB</div>
                      </div>
                    </div>
                  </div>

                  {/* Desktop SVG Connector Line 1 (Source Card to Radial Menu) */}
                  <div className="hidden lg:flex items-center justify-center flex-1 z-0">
                    <div className="w-full flex items-center justify-center">
                      <div className="w-2 h-2 rounded-full border border-[#D98768] bg-[#FAF8F3]" />
                      <div className="flex-1 border-t border-dashed border-[#D98768]/60 mx-1" />
                    </div>
                  </div>

                  {/* Center Column: 5-Segment Circular Radial Menu Wheel */}
                  <div className="shrink-0 flex items-center justify-center relative z-10">
                    <div className="relative w-[230px] h-[230px] shrink-0 flex items-center justify-center select-none">
                      <svg viewBox="0 0 220 220" className="w-full h-full drop-shadow-sm">
                        {/* Outer Guidance Circle */}
                        <circle
                          cx="110"
                          cy="110"
                          r="106"
                          fill="none"
                          stroke="#E5D8C7"
                          strokeWidth="1"
                          strokeDasharray="3 3"
                        />

                        {/* 5 Radial Wedges */}
                        {radialMenuWedges.map((wedge) => {
                          const isSelected = radialSelectedAction === wedge.name;
                          // 72° per segment with 3° separator gaps
                          const halfSpan = 33;
                          const startAngle = wedge.centerAngle - halfSpan;
                          const endAngle = wedge.centerAngle + halfSpan;
                          const pathData = createDonutSegment(110, 110, 46, 102, startAngle, endAngle);
                          const IconComp = wedge.icon;

                          // Icon and text positions calculated via polar coordinates
                          const labelPos = polarToCartesian(110, 110, 74, wedge.centerAngle);

                          return (
                            <g
                              key={wedge.id}
                              onClick={() => setRadialSelectedAction(wedge.name)}
                              className="cursor-pointer transition-all duration-200"
                            >
                              <path
                                d={pathData}
                                fill={isSelected ? "#D98768" : "#FFFFFF"}
                                stroke={isSelected ? "#C47456" : "#E5D8C7"}
                                strokeWidth={isSelected ? "1.5" : "1"}
                                className="hover:opacity-90 transition-colors"
                              />

                              {/* Centered Icon and Label using foreignObject for crisp typography */}
                              <foreignObject
                                x={labelPos.x - 28}
                                y={labelPos.y - 18}
                                width="56"
                                height="36"
                                className="pointer-events-none"
                              >
                                <div className="w-full h-full flex flex-col items-center justify-center text-center">
                                  <IconComp
                                    size={13}
                                    className={isSelected ? "text-[#FFFFFF]" : "text-[#34312D]"}
                                  />
                                  <span
                                    className={`text-[9.5px] mt-0.5 whitespace-nowrap font-sans tracking-tight leading-none ${
                                      isSelected
                                        ? "text-[#FFFFFF] font-bold"
                                        : "text-[#34312D] font-semibold"
                                    }`}
                                  >
                                    {wedge.name}
                                  </span>
                                </div>
                              </foreignObject>
                            </g>
                          );
                        })}

                        {/* Center Hub Outer Ring */}
                        <circle
                          cx="110"
                          cy="110"
                          r="42"
                          fill="#FAF8F3"
                          stroke="#E5D8C7"
                          strokeWidth="1.5"
                        />
                      </svg>

                      {/* Center Hub Content with Thumbnail */}
                      <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none text-center">
                        <div className="w-8 h-8 rounded-full overflow-hidden border border-[#E5D8C7] mb-0.5 shadow-2xs">
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

                  {/* Desktop SVG Connector Line 2 (Radial Menu to Destination Card) */}
                  <div className="hidden lg:flex items-center justify-center flex-1 z-0">
                    <div className="w-full flex items-center justify-center">
                      <div className="flex-1 border-t border-dashed border-[#D98768]/60 mx-1" />
                      <div className="w-2 h-2 rounded-full border border-[#D98768] bg-[#FAF8F3]" />
                    </div>
                  </div>

                  {/* Right Column: Destination Output Card */}
                  <div className="w-full max-w-[210px] shrink-0 flex flex-col items-center lg:items-end space-y-2 z-10">
                    <div className="w-full p-3.5 rounded-2xl bg-[#FFFFFF] border border-[#E5D8C7] shadow-xs flex items-center gap-3">
                      <div className="w-10 h-10 rounded-xl bg-[#FAF2ED] border border-[#E5D8C7] flex items-center justify-center text-[#D98768] shrink-0">
                        <ImageIcon size={18} />
                      </div>
                      <div className="space-y-0.5 text-left overflow-hidden">
                        <div className="font-mono text-xs font-bold text-[#34312D] truncate">
                          {currentRadialWedge.outputName}
                        </div>
                        <div className="text-[11px] text-[#898177] truncate">
                          {currentRadialWedge.outputMeta}
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Editorial Description Beneath Interface */}
                <div className="text-center max-w-lg mx-auto pt-4 sm:pt-5 border-t border-[#E5D8C7]/50 mt-4 sm:mt-5 space-y-1">
                  <h4 className="font-serif text-lg sm:text-xl font-bold text-[#34312D]">
                    Context-aware radial actions
                  </h4>
                  <p className="text-xs sm:text-[13px] text-[#34312D]/80 leading-relaxed">
                    Appears directly at the cursor when you drag while holding Shift. Dismisses automatically if you release or drop outside.
                  </p>
                </div>
              </div>
            )}

            {/* ===================================================== */}
            {/* VIEW 2: VISUAL CROP STUDIO                            */}
            {/* ===================================================== */}
            {activeTab === "crop" && (
              <div className="w-full flex flex-col justify-between flex-grow animate-fadeIn">
                <div className="max-w-2xl mx-auto w-full space-y-4">
                  {/* Cropping Canvas Frame */}
                  <div className="w-full h-56 sm:h-64 rounded-2xl bg-[#34312D] border border-[#E5D8C7] relative overflow-hidden flex items-center justify-center shadow-inner">
                    {/* Background Image */}
                    <img
                      src="/mountain_sample.jpg"
                      alt="Crop Source"
                      className="w-full h-full object-cover opacity-50"
                      style={{
                        transform: `rotate(${cropRotation}deg)`,
                        transition: "transform 0.3s ease",
                      }}
                    />

                    {/* Dark Dimmed Overlay Outside Crop Region */}
                    <div className="absolute inset-0 bg-[#000000]/40 pointer-events-none" />

                    {/* Active Interactive Crop Boundary Rectangle */}
                    <div
                      className={`absolute border-2 border-[#D98768] shadow-lg transition-all duration-300 flex items-center justify-center overflow-hidden bg-transparent ${
                        cropPreset === "1:1"
                          ? "w-44 h-44"
                          : cropPreset === "4:3"
                          ? "w-60 h-44"
                          : cropPreset === "16:9"
                          ? "w-72 h-40"
                          : "w-52 h-48"
                      }`}
                    >
                      {/* Active Un-dimmed Clear Image Portion */}
                      <img
                        src="/mountain_sample.jpg"
                        alt="Crop Focus"
                        className="absolute w-[800px] h-[500px] max-w-none object-cover pointer-events-none"
                        style={{
                          transform: `rotate(${cropRotation}deg)`,
                          transition: "transform 0.3s ease",
                        }}
                      />

                      {/* Rule of Thirds Grid Overlay */}
                      {showCropGrid && (
                        <div className="absolute inset-0 grid grid-cols-3 grid-rows-3 pointer-events-none border border-[#D98768]/30">
                          <div className="border-r border-b border-[#D98768]/30" />
                          <div className="border-r border-b border-[#D98768]/30" />
                          <div className="border-b border-[#D98768]/30" />
                          <div className="border-r border-b border-[#D98768]/30" />
                          <div className="border-r border-b border-[#D98768]/30" />
                          <div className="border-b border-[#D98768]/30" />
                          <div className="border-r border-[#D98768]/30" />
                          <div className="border-r border-[#D98768]/30" />
                          <div />
                        </div>
                      )}

                      {/* Authentic 4 L-Corner Handles */}
                      <div className="absolute top-0 left-0 w-3.5 h-3.5 border-t-2 border-l-2 border-[#FFFFFF] shadow-xs" />
                      <div className="absolute top-0 right-0 w-3.5 h-3.5 border-t-2 border-r-2 border-[#FFFFFF] shadow-xs" />
                      <div className="absolute bottom-0 left-0 w-3.5 h-3.5 border-b-2 border-l-2 border-[#FFFFFF] shadow-xs" />
                      <div className="absolute bottom-0 right-0 w-3.5 h-3.5 border-b-2 border-r-2 border-[#FFFFFF] shadow-xs" />

                      {/* Edge Midpoint Pip Handles */}
                      <div className="absolute top-0 left-1/2 -translate-x-1/2 -translate-y-1/2 w-4 h-1 rounded bg-[#FFFFFF]" />
                      <div className="absolute bottom-0 left-1/2 -translate-x-1/2 translate-y-1/2 w-4 h-1 rounded bg-[#FFFFFF]" />
                      <div className="absolute left-0 top-1/2 -translate-y-1/2 -translate-x-1/2 w-1 h-4 rounded bg-[#FFFFFF]" />
                      <div className="absolute right-0 top-1/2 -translate-y-1/2 translate-x-1/2 w-1 h-4 rounded bg-[#FFFFFF]" />

                      {/* Dimension Readout Badge */}
                      <div className="absolute bottom-2 right-2 px-2 py-0.5 rounded bg-[#34312D]/85 backdrop-blur-xs text-[10px] font-mono text-[#FAF8F3] font-bold shadow-xs">
                        {cropPreset === "1:1" && "1080 × 1080 px"}
                        {cropPreset === "4:3" && "1440 × 1080 px"}
                        {cropPreset === "16:9" && "1920 × 1080 px"}
                        {cropPreset === "free" && "Custom Crop"}
                      </div>
                    </div>
                  </div>

                  {/* Crop Controls & Aspect Ratio Presets Bar */}
                  <div className="p-3 rounded-xl bg-[#F3EEE4] border border-[#E5D8C7] flex flex-wrap items-center justify-between gap-3 text-xs">
                    {/* Aspect Ratio Buttons */}
                    <div className="flex items-center gap-1.5">
                      <span className="text-[11px] font-mono text-[#898177] mr-1">Aspect:</span>
                      {(["1:1", "4:3", "16:9", "free"] as const).map((ratio) => (
                        <button
                          key={ratio}
                          type="button"
                          onClick={() => setCropPreset(ratio)}
                          className={`px-2.5 py-1 rounded-lg text-xs font-mono font-bold transition-colors cursor-pointer ${
                            cropPreset === ratio
                              ? "bg-[#D98768] text-[#FFFFFF] shadow-2xs"
                              : "bg-[#FFFFFF] border border-[#E5D8C7] text-[#34312D] hover:bg-[#FAF8F3]"
                          }`}
                        >
                          {ratio === "free" ? "Freeform" : ratio}
                        </button>
                      ))}
                    </div>

                    {/* Secondary Tool Toggles */}
                    <div className="flex items-center gap-2">
                      <button
                        type="button"
                        onClick={() => setShowCropGrid((prev) => !prev)}
                        className={`p-1.5 rounded-lg border transition-colors cursor-pointer ${
                          showCropGrid
                            ? "bg-[#D98768] text-[#FFFFFF] border-[#D98768]"
                            : "bg-[#FFFFFF] text-[#34312D] border-[#E5D8C7] hover:bg-[#FAF8F3]"
                        }`}
                        title="Toggle Rule-of-Thirds Grid"
                      >
                        <Grid size={13} />
                      </button>

                      <button
                        type="button"
                        onClick={() => setCropRotation((prev) => (prev + 90) % 360)}
                        className="p-1.5 rounded-lg bg-[#FFFFFF] border border-[#E5D8C7] text-[#34312D] hover:bg-[#FAF8F3] transition-colors cursor-pointer"
                        title="Rotate 90°"
                      >
                        <RotateCw size={13} />
                      </button>

                      <span className="text-[11px] font-mono text-[#465343] pl-2 border-l border-[#E5D8C7]">
                        Target: WebP @ 92%
                      </span>
                    </div>
                  </div>
                </div>

                {/* Editorial Description */}
                <div className="text-center max-w-lg mx-auto pt-4 sm:pt-5 border-t border-[#E5D8C7]/50 mt-4 sm:mt-5 space-y-1">
                  <h4 className="font-serif text-lg sm:text-xl font-bold text-[#34312D]">
                    Non-destructive canvas cropping
                  </h4>
                  <p className="text-xs sm:text-[13px] text-[#34312D]/80 leading-relaxed">
                    Frame images instantly with native aspect ratio snapping. Exports directly without altering your original source file on disk.
                  </p>
                </div>
              </div>
            )}

            {/* ===================================================== */}
            {/* VIEW 3: TIMELINE VIDEO TRIMMER                        */}
            {/* ===================================================== */}
            {activeTab === "trim" && (
              <div className="w-full flex flex-col justify-between flex-grow animate-fadeIn">
                <div className="max-w-2xl mx-auto w-full space-y-3.5">
                  {/* Video Preview Monitor Bezel */}
                  <div className="w-full h-44 sm:h-48 rounded-2xl bg-[#34312D] border border-[#2B2825] relative overflow-hidden flex flex-col justify-between p-3 shadow-inner">
                    <img
                      src="/mountain_sample.jpg"
                      alt="Video Monitor"
                      className="absolute inset-0 w-full h-full object-cover opacity-60"
                    />

                    {/* Top Monitor Info Strip */}
                    <div className="relative z-10 flex items-center justify-between text-[11px] font-mono text-[#FAF8F3]">
                      <span className="px-2 py-0.5 rounded bg-[#000000]/60 backdrop-blur-xs">
                        screencast_demo.mov
                      </span>
                      <span className="px-2 py-0.5 rounded bg-[#000000]/60 backdrop-blur-xs text-[#A8B5A0]">
                        4K 3840×2160 · 60fps · ProRes 422
                      </span>
                    </div>

                    {/* Play/Pause Button in Center */}
                    <div className="relative z-10 flex items-center justify-center">
                      <button
                        type="button"
                        onClick={() => setIsVideoPlaying((p) => !p)}
                        className="w-12 h-12 rounded-full bg-[#FAF8F3]/90 hover:bg-[#FFFFFF] text-[#34312D] flex items-center justify-center shadow-lg transition-transform hover:scale-105 cursor-pointer"
                      >
                        {isVideoPlaying ? <Pause size={18} /> : <Play size={18} className="ml-0.5" />}
                      </button>
                    </div>

                    {/* Bottom Playback Timecode Readout */}
                    <div className="relative z-10 flex items-center justify-between text-[11px] font-mono text-[#FAF8F3]">
                      <span className="px-2 py-0.5 rounded bg-[#000000]/60 backdrop-blur-xs">
                        {isVideoPlaying ? "00:12.300 / 00:24.000" : "00:08.400 / 00:24.000"}
                      </span>
                      <span className="px-2 py-0.5 rounded bg-[#D98768] text-[#FFFFFF] font-bold">
                        Duration: {trimRange.duration}
                      </span>
                    </div>
                  </div>

                  {/* Horizontal Timeline Strip with Filmstrip & Waveforms */}
                  <div className="p-3.5 rounded-xl bg-[#F3EEE4] border border-[#E5D8C7] space-y-2.5">
                    {/* Timecode Indicators */}
                    <div className="flex items-center justify-between text-[11px] font-mono text-[#34312D]">
                      <span className="font-bold text-[#D98768]">In: {trimRange.start}</span>
                      <span className="text-[10px] text-[#465343] px-2 py-0.5 rounded bg-[#FAF8F3] border border-[#E5D8C7]">
                        AVFoundation Keyframe Snapped
                      </span>
                      <span className="font-bold text-[#D98768]">Out: {trimRange.end}</span>
                    </div>

                    {/* Filmstrip Frame Track */}
                    <div className="relative w-full h-12 rounded-lg bg-[#34312D] overflow-hidden border border-[#E5D8C7] flex">
                      {/* 6 Miniature Thumbnails */}
                      {[0, 1, 2, 3, 4, 5].map((idx) => (
                        <div key={idx} className="flex-1 h-full border-r border-[#FAF8F3]/20 overflow-hidden opacity-75">
                          <img
                            src="/mountain_sample.jpg"
                            alt="Filmstrip"
                            className="w-full h-full object-cover filter brightness-90"
                          />
                        </div>
                      ))}

                      {/* Dimmed Outside Left */}
                      <div
                        className="absolute top-0 bottom-0 left-0 bg-[#000000]/60 pointer-events-none"
                        style={{ width: `${trimRange.leftPercent}%` }}
                      />

                      {/* Dimmed Outside Right */}
                      <div
                        className="absolute top-0 bottom-0 right-0 bg-[#000000]/60 pointer-events-none"
                        style={{ width: `${100 - trimRange.rightPercent}%` }}
                      />

                      {/* Selected Active Trim Zone in Terracotta */}
                      <div
                        className="absolute top-0 bottom-0 border-y-2 border-[#D98768] bg-[#D98768]/20"
                        style={{
                          left: `${trimRange.leftPercent}%`,
                          right: `${100 - trimRange.rightPercent}%`,
                        }}
                      >
                        {/* Left Trim Handle */}
                        <div className="absolute top-0 bottom-0 -left-1 w-3 bg-[#D98768] rounded-l flex items-center justify-center cursor-ew-resize">
                          <div className="w-0.5 h-4 bg-[#FFFFFF] rounded-full" />
                        </div>

                        {/* Scrubber Playhead Line */}
                        <div className="absolute top-0 bottom-0 left-1/3 w-0.5 bg-[#FFFFFF] shadow-xs">
                          <div className="w-2 h-2 rounded-full bg-[#FFFFFF] -translate-x-[3px] -translate-y-1 shadow-xs" />
                        </div>

                        {/* Right Trim Handle */}
                        <div className="absolute top-0 bottom-0 -right-1 w-3 bg-[#D98768] rounded-r flex items-center justify-center cursor-ew-resize">
                          <div className="w-0.5 h-4 bg-[#FFFFFF] rounded-full" />
                        </div>
                      </div>
                    </div>

                    {/* Clean SVG Audio Waveform Track */}
                    <div className="h-4 w-full flex items-center gap-[3px] px-1 opacity-80">
                      {[12, 24, 38, 16, 45, 60, 32, 50, 75, 82, 40, 68, 52, 34, 70, 90, 65, 45, 30, 22, 14, 28, 48, 62, 35, 20].map((h, i) => (
                        <div
                          key={i}
                          className="flex-1 rounded-full bg-[#8EA87D]"
                          style={{ height: `${h}%` }}
                        />
                      ))}
                    </div>

                    {/* Trim Presets */}
                    <div className="flex items-center justify-between pt-1">
                      <div className="flex items-center gap-1.5 text-xs font-mono">
                        <span className="text-[11px] text-[#898177]">Snippets:</span>
                        <button
                          type="button"
                          onClick={() =>
                            setTrimRange({
                              start: "00:00.000",
                              end: "00:06.200",
                              duration: "6.20s",
                              leftPercent: 0,
                              rightPercent: 26,
                            })
                          }
                          className="px-2 py-0.5 rounded bg-[#FFFFFF] border border-[#E5D8C7] text-[#34312D] hover:bg-[#FAF8F3] cursor-pointer"
                        >
                          Intro (6.2s)
                        </button>
                        <button
                          type="button"
                          onClick={() =>
                            setTrimRange({
                              start: "00:04.250",
                              end: "00:18.900",
                              duration: "14.65s",
                              leftPercent: 18,
                              rightPercent: 78,
                            })
                          }
                          className="px-2 py-0.5 rounded bg-[#D98768] text-[#FFFFFF] font-bold cursor-pointer"
                        >
                          Highlight (14.6s)
                        </button>
                      </div>

                      <span className="text-[11px] font-mono text-[#D98768] font-bold">
                        Lossless Stream Copy
                      </span>
                    </div>
                  </div>
                </div>

                {/* Editorial Description */}
                <div className="text-center max-w-lg mx-auto pt-4 sm:pt-5 border-t border-[#E5D8C7]/50 mt-4 sm:mt-5 space-y-1">
                  <h4 className="font-serif text-lg sm:text-xl font-bold text-[#34312D]">
                    Lossless stream copy trimmer
                  </h4>
                  <p className="text-xs sm:text-[13px] text-[#34312D]/80 leading-relaxed">
                    Snaps to native keyframes to extract sub-clips instantly without re-encoding, preserving native bitrate, color depth, and HDR metadata.
                  </p>
                </div>
              </div>
            )}

            {/* ===================================================== */}
            {/* VIEW 4: MULTI-FILE MERGE STUDIO                       */}
            {/* ===================================================== */}
            {activeTab === "merge" && (
              <div className="w-full flex flex-col justify-between flex-grow animate-fadeIn">
                <div className="max-w-2xl mx-auto w-full grid grid-cols-1 md:grid-cols-12 gap-4 items-center">
                  {/* Left Column: Source Document Items Stack */}
                  <div className="md:col-span-7 space-y-2.5">
                    <div className="flex items-center justify-between pb-1 text-xs">
                      <span className="font-serif font-bold text-sm text-[#34312D]">
                        Items to Combine ({mergeDocuments.length} Files)
                      </span>
                      <span className="text-[11px] font-mono text-[#D98768] font-bold">
                        Total: 6 Pages · 2.1 MB
                      </span>
                    </div>

                    {/* Document Row Items */}
                    <div className="space-y-2">
                      {mergeDocuments.map((doc, idx) => (
                        <div
                          key={doc.id}
                          className="p-3 rounded-xl bg-[#FFFFFF] border border-[#E5D8C7] shadow-2xs flex items-center justify-between text-xs transition-all hover:border-[#D98768]"
                        >
                          <div className="flex items-center gap-2.5 overflow-hidden">
                            <span className="text-[#898177]">
                              <GripVertical size={14} />
                            </span>
                            <div className="w-7 h-7 rounded-lg bg-[#FAF2ED] text-[#D98768] flex items-center justify-center shrink-0">
                              <FileText size={14} />
                            </div>
                            <div className="overflow-hidden">
                              <div className="font-mono font-bold text-[#34312D] truncate">
                                {idx + 1}. {doc.name}
                              </div>
                              <div className="text-[10px] text-[#898177]">
                                {doc.pages === 1 ? "1 Page" : `${doc.pages} Pages`} · {doc.size}
                              </div>
                            </div>
                          </div>

                          {/* Reorder Buttons */}
                          <div className="flex items-center gap-1 shrink-0">
                            <button
                              type="button"
                              onClick={() => moveDocUp(idx)}
                              disabled={idx === 0}
                              className="w-6 h-6 rounded bg-[#F3EEE4] hover:bg-[#E5D8C7] disabled:opacity-30 text-[#34312D] flex items-center justify-center text-[10px] font-bold cursor-pointer disabled:cursor-not-allowed"
                              title="Move Up"
                            >
                              ▲
                            </button>
                            <button
                              type="button"
                              onClick={() => moveDocDown(idx)}
                              disabled={idx === mergeDocuments.length - 1}
                              className="w-6 h-6 rounded bg-[#F3EEE4] hover:bg-[#E5D8C7] disabled:opacity-30 text-[#34312D] flex items-center justify-center text-[10px] font-bold cursor-pointer disabled:cursor-not-allowed"
                              title="Move Down"
                            >
                              ▼
                            </button>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>

                  {/* Flow Arrow & Target Result Card */}
                  <div className="md:col-span-5 flex flex-col items-center justify-center space-y-3 p-4 rounded-2xl bg-[#F3EEE4] border border-[#E5D8C7]">
                    <div className="w-8 h-8 rounded-full bg-[#FAF2ED] border border-[#D98768] text-[#D98768] flex items-center justify-center text-xs font-bold shadow-2xs">
                      +
                    </div>

                    <div className="w-full p-3.5 rounded-xl bg-[#FFFFFF] border border-[#E5D8C7] shadow-xs text-center space-y-2">
                      <div className="w-9 h-9 rounded-xl bg-[#FAF2ED] text-[#D98768] mx-auto flex items-center justify-center">
                        <Layers size={18} />
                      </div>
                      <div className="space-y-0.5">
                        <div className="font-mono text-xs font-bold text-[#34312D]">
                          combined_contract.pdf
                        </div>
                        <div className="text-[11px] text-[#465343] font-medium flex items-center justify-center gap-1">
                          <CheckCircle2 size={12} className="text-[#8EA87D]" />
                          <span>6 Pages · Single PDF</span>
                        </div>
                      </div>
                    </div>

                    {/* Settings Toggles */}
                    <div className="w-full space-y-1 text-[11px] font-mono text-[#34312D]">
                      <label className="flex items-center gap-2 cursor-pointer select-none">
                        <input
                          type="checkbox"
                          checked={flattenForms}
                          onChange={(e) => setFlattenForms(e.target.checked)}
                          className="rounded border-[#E5D8C7] text-[#D98768] focus:ring-[#D98768]"
                        />
                        <span>Flatten annotations & forms</span>
                      </label>
                      <label className="flex items-center gap-2 cursor-pointer select-none">
                        <input
                          type="checkbox"
                          checked={preserveBookmarks}
                          onChange={(e) => setPreserveBookmarks(e.target.checked)}
                          className="rounded border-[#E5D8C7] text-[#D98768] focus:ring-[#D98768]"
                        />
                        <span>Preserve vector outline text</span>
                      </label>
                    </div>
                  </div>
                </div>

                {/* Editorial Description */}
                <div className="text-center max-w-lg mx-auto pt-4 sm:pt-5 border-t border-[#E5D8C7]/50 mt-4 sm:mt-5 space-y-1">
                  <h4 className="font-serif text-lg sm:text-xl font-bold text-[#34312D]">
                    Multi-format document assembly
                  </h4>
                  <p className="text-xs sm:text-[13px] text-[#34312D]/80 leading-relaxed">
                    Combine mixed PDFs, high-res PNGs, and scans into a single publication-ready document with automatic page orientation normalization.
                  </p>
                </div>
              </div>
            )}

            {/* ===================================================== */}
            {/* VIEW 5: JOB QUEUE & HISTORY                           */}
            {/* ===================================================== */}
            {activeTab === "queue" && (
              <div className="w-full flex flex-col justify-between flex-grow animate-fadeIn">
                <div className="max-w-2xl mx-auto w-full space-y-3">
                  <div className="flex items-center justify-between pb-1 border-b border-[#E5D8C7] text-xs">
                    <span className="font-serif font-bold text-sm text-[#34312D]">
                      Active & Recent Operations
                    </span>
                    <span className="font-mono text-[#D98768] font-bold">
                      FIFO Runner · 2 Workers
                    </span>
                  </div>

                  {/* Task List */}
                  <div className="space-y-2">
                    {queueTasks.map((task) => {
                      const isSelected = selectedJobId === task.id;
                      return (
                        <div
                          key={task.id}
                          onClick={() => setSelectedJobId(task.id)}
                          className={`p-3 rounded-xl border transition-all cursor-pointer ${
                            isSelected
                              ? "bg-[#FFFFFF] border-[#D98768] shadow-xs ring-1 ring-[#D98768]/30"
                              : "bg-[#FFFFFF] border-[#E5D8C7] hover:border-[#D4C8B8]"
                          }`}
                        >
                          <div className="flex items-center justify-between text-xs mb-1.5">
                            <div className="flex items-center gap-2 overflow-hidden">
                              {task.statusType === "done" && (
                                <span className="w-4 h-4 rounded-full bg-[#FAF2ED] text-[#8EA87D] flex items-center justify-center shrink-0">
                                  <Check size={11} />
                                </span>
                              )}
                              {task.statusType === "active" && (
                                <span className="w-2 h-2 rounded-full bg-[#D98768] animate-ping shrink-0" />
                              )}
                              {task.statusType === "queued" && (
                                <span className="w-4 h-4 rounded-full bg-[#F3EEE4] text-[#898177] flex items-center justify-center shrink-0">
                                  <Clock size={11} />
                                </span>
                              )}
                              <span className="font-mono font-bold text-[#34312D] truncate">
                                {task.name}
                              </span>
                            </div>
                            <span
                              className={`text-[11px] font-mono font-bold shrink-0 ${
                                task.statusType === "done"
                                  ? "text-[#465343]"
                                  : task.statusType === "active"
                                  ? "text-[#D98768]"
                                  : "text-[#898177]"
                              }`}
                            >
                              {task.status}
                            </span>
                          </div>

                          {/* Progress bar for active task */}
                          {task.statusType === "active" && (
                            <div className="w-full h-1.5 rounded-full bg-[#F3EEE4] overflow-hidden my-1">
                              <div
                                className="h-full bg-[#D98768] rounded-full transition-all duration-300"
                                style={{ width: `${task.progress}%` }}
                              />
                            </div>
                          )}

                          <div className="flex items-center justify-between text-[10px] text-[#898177] font-mono pt-0.5">
                            <span>{task.engine}</span>
                            <span>{task.size}</span>
                          </div>
                        </div>
                      );
                    })}
                  </div>

                  {/* Selected Task Inspection Drawer */}
                  <div className="p-3 rounded-xl bg-[#F3EEE4] border border-[#E5D8C7] flex flex-wrap items-center justify-between gap-2 text-[11px] font-mono text-[#34312D]">
                    <div className="flex items-center gap-2">
                      <HardDrive size={13} className="text-[#D98768]" />
                      <span>Destination: {activeQueueJob.destination}</span>
                    </div>
                    <span className="text-[#465343] font-bold">100% Local · No Cloud</span>
                  </div>
                </div>

                {/* Editorial Description */}
                <div className="text-center max-w-lg mx-auto pt-4 sm:pt-5 border-t border-[#E5D8C7]/50 mt-4 sm:mt-5 space-y-1">
                  <h4 className="font-serif text-lg sm:text-xl font-bold text-[#34312D]">
                    Asynchronous background FIFO engine
                  </h4>
                  <p className="text-xs sm:text-[13px] text-[#34312D]/80 leading-relaxed">
                    Offloads heavy batch workloads to background threads with throttled memory allocation, ensuring your Mac never stutters or drops frames.
                  </p>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </section>
  );
}
