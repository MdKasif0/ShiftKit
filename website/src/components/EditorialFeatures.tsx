"use client";

import React from "react";
import {
  FileImage,
  Scissors,
  Film,
  Layers,
  ShieldAlert,
  ListOrdered,
  Sparkles,
  ArrowRight,
  Check
} from "lucide-react";

export function EditorialFeatures() {
  return (
    <section id="features" className="py-20 md:py-28 bg-[#FAF8F3]">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Section Header */}
        <div className="max-w-2xl mb-16 space-y-3">
          <span className="text-xs font-mono font-bold uppercase tracking-wider text-[#D98768]">
            Engineered Capabilities
          </span>
          <h2 className="font-serif text-3xl sm:text-4xl md:text-5xl font-bold tracking-tight text-[#34312D] leading-tight">
            Every essential file tool. <br />
            Built natively for your Mac.
          </h2>
          <p className="text-[#34312D]/80 text-base sm:text-lg leading-relaxed">
            No browser upload bars. No subscriptions. No bloated Electron containers. ShiftKit executes purely using Apple native frameworks and dedicated local media engines.
          </p>
        </div>

        {/* Editorial Layout: Mixed Asymmetric Blocks */}
        <div className="space-y-8">
          {/* Feature 1: Wide Hero Card - Universal Conversion */}
          <div className="p-8 sm:p-10 rounded-2xl bg-[#F3EEE4] border border-[#E5D8C7] shadow-sm">
            <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-center">
              <div className="lg:col-span-7 space-y-4">
                <div className="inline-flex items-center gap-2 px-3 py-1 rounded-md bg-[#FAF8F3] border border-[#E5D8C7] text-xs font-mono font-semibold text-[#465343]">
                  <FileImage size={14} className="text-[#D98768]" />
                  IMAGE & DOCUMENT ROUTING
                </div>
                <h3 className="font-serif text-2xl sm:text-3xl font-bold text-[#34312D]">
                  Universal local conversion without format friction.
                </h3>
                <p className="text-sm sm:text-base text-[#34312D]/80 leading-relaxed">
                  Instantly convert between modern web standards and high-fidelity print formats. ShiftKit automatically checks your Mac hardware encoders for hardware acceleration on Apple Silicon.
                </p>
                <div className="pt-2 flex flex-wrap gap-2 text-xs font-mono">
                  {["WebP", "PNG", "JPEG", "HEIC", "TIFF", "BMP", "GIF", "AVIF", "PDF"].map((fmt) => (
                    <span
                      key={fmt}
                      className="px-2.5 py-1 rounded bg-[#FFFFFF] border border-[#E5D8C7] text-[#34312D] font-medium shadow-2xs"
                    >
                      .{fmt.toLowerCase()}
                    </span>
                  ))}
                </div>
              </div>

              {/* Graphical Spec Column */}
              <div className="lg:col-span-5 p-5 rounded-xl bg-[#FAF8F3] border border-[#E5D8C7] space-y-3">
                <div className="text-xs font-mono font-bold text-[#465343] pb-2 border-b border-[#E5D8C7]">
                  VERIFIED LOCAL ENGINES
                </div>
                <div className="space-y-2 text-xs text-[#34312D]">
                  <div className="flex justify-between items-center py-1">
                    <span className="font-medium">Core Graphics & ImageIO</span>
                    <span className="text-[#D98768] font-mono text-[11px]">Native Apple</span>
                  </div>
                  <div className="flex justify-between items-center py-1">
                    <span className="font-medium">PDFKit Framework</span>
                    <span className="text-[#D98768] font-mono text-[11px]">Vector-Accurate</span>
                  </div>
                  <div className="flex justify-between items-center py-1">
                    <span className="font-medium">AVFoundation Pipeline</span>
                    <span className="text-[#D98768] font-mono text-[11px]">ProRes & HEVC</span>
                  </div>
                  <div className="flex justify-between items-center py-1">
                    <span className="font-medium">Local FFmpeg Integration</span>
                    <span className="text-[#D98768] font-mono text-[11px]">Universal Media</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Two-Column Mid Row */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            {/* Feature 2: Dedicated Visual Crop */}
            <div className="p-8 rounded-2xl bg-[#FFFFFF] border border-[#E5D8C7] shadow-xs flex flex-col justify-between space-y-6">
              <div className="space-y-3">
                <div className="w-10 h-10 rounded-lg bg-[#F3EEE4] border border-[#E5D8C7] flex items-center justify-center text-[#465343]">
                  <Scissors size={20} />
                </div>
                <h3 className="font-serif text-xl sm:text-2xl font-bold text-[#34312D]">
                  Visual Crop Studio with Aspect Lock.
                </h3>
                <p className="text-sm text-[#34312D]/80 leading-relaxed">
                  Crop images to exact dimensions before saving. Choose from 1:1 square for avatars, 16:9 widescreen, 4:3 document ratio, or freeform framing with live pixel readouts.
                </p>
              </div>

              <div className="p-4 rounded-xl bg-[#FAF8F3] border border-[#E5D8C7] space-y-2 text-xs">
                <div className="flex items-center justify-between text-[#465343] font-mono">
                  <span>PRESETS INCLUDED</span>
                  <span className="text-[#D98768]">1:1 • 4:3 • 16:9 • Custom</span>
                </div>
                <div className="w-full h-2 rounded-full bg-[#E5D8C7] overflow-hidden">
                  <div className="w-3/4 h-full bg-[#D98768] rounded-full"></div>
                </div>
              </div>
            </div>

            {/* Feature 3: Video & Audio Trimmer */}
            <div className="p-8 rounded-2xl bg-[#FFFFFF] border border-[#E5D8C7] shadow-xs flex flex-col justify-between space-y-6">
              <div className="space-y-3">
                <div className="w-10 h-10 rounded-lg bg-[#F3EEE4] border border-[#E5D8C7] flex items-center justify-center text-[#465343]">
                  <Film size={20} />
                </div>
                <h3 className="font-serif text-xl sm:text-2xl font-bold text-[#34312D]">
                  Frame-Accurate Video & Audio Trimming.
                </h3>
                <p className="text-sm text-[#34312D]/80 leading-relaxed">
                  Trim unwanted seconds from screen recordings, podcasts, and video clips without launching heavy editing suites. Snaps to keyframes for lossless output speed.
                </p>
              </div>

              <div className="p-4 rounded-xl bg-[#FAF8F3] border border-[#E5D8C7] space-y-2 text-xs">
                <div className="flex items-center justify-between text-[#465343] font-mono">
                  <span>SUPPORTED FORMATS</span>
                  <span className="text-[#D98768]">MP4 • MOV • WebM • MP3 • WAV</span>
                </div>
                <div className="flex items-center gap-1.5 text-[11px] text-[#34312D]/70">
                  <Check size={13} className="text-[#D98768]" />
                  <span>Sub-millisecond timeline geometry calculation</span>
                </div>
              </div>
            </div>
          </div>

          {/* Three-Column Bottom Row */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {/* Feature 4: PDF Merge & Assembly */}
            <div className="p-7 rounded-2xl bg-[#F3EEE4] border border-[#E5D8C7] shadow-2xs space-y-3">
              <div className="w-9 h-9 rounded-lg bg-[#FAF8F3] border border-[#E5D8C7] flex items-center justify-center text-[#D98768]">
                <Layers size={18} />
              </div>
              <h3 className="font-serif text-lg font-bold text-[#34312D]">
                PDF Page Studio
              </h3>
              <p className="text-xs text-[#34312D]/80 leading-relaxed">
                Merge multiple PDFs, convert loose photos into multi-page documents, reorder thumbnails, rotate orientation, or extract selected pages.
              </p>
            </div>

            {/* Feature 5: Privacy Metadata Cleaning */}
            <div className="p-7 rounded-2xl bg-[#F3EEE4] border border-[#E5D8C7] shadow-2xs space-y-3">
              <div className="w-9 h-9 rounded-lg bg-[#FAF8F3] border border-[#E5D8C7] flex items-center justify-center text-[#465343]">
                <ShieldAlert size={18} />
              </div>
              <h3 className="font-serif text-lg font-bold text-[#34312D]">
                Metadata Sanitizer
              </h3>
              <p className="text-xs text-[#34312D]/80 leading-relaxed">
                Scrub GPS coordinates, camera serial numbers, lens info, audio ID3 tags, and PDF authors before sharing files with clients or publishing online.
              </p>
            </div>

            {/* Feature 6: Concurrency Batch Queue */}
            <div className="p-7 rounded-2xl bg-[#F3EEE4] border border-[#E5D8C7] shadow-2xs space-y-3">
              <div className="w-9 h-9 rounded-lg bg-[#FAF8F3] border border-[#E5D8C7] flex items-center justify-center text-[#D98768]">
                <ListOrdered size={18} />
              </div>
              <h3 className="font-serif text-lg font-bold text-[#34312D]">
                Batch Queue Studio
              </h3>
              <p className="text-xs text-[#34312D]/80 leading-relaxed">
                Drop 50 files at once. ShiftKit throttles concurrency dynamically (1–8 parallel workers) to prevent CPU heating, with live progress bars and individual item retry.
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
