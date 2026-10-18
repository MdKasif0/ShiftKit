"use client";

import React, { useState } from "react";
import {
  Laptop,
  WifiOff,
  Folder,
  HardDrive,
  FileText,
  CheckCircle2,
  Trash2,
  Clock,
  CloudOff,
  Settings,
  ShieldCheck,
  Check,
  ArrowRight,
  Sparkles,
} from "lucide-react";

export function PrivacySection() {
  const [activeTab, setActiveTab] = useState<number>(0);

  return (
    <section
      id="privacy"
      aria-label="Privacy First Architecture"
      className="py-16 md:py-24 bg-[#FAF8F3] scroll-mt-24 border-t border-[#E5D8C7]"
    >
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* ========================================================= */}
        {/* SECTION HEADER                                            */}
        {/* ========================================================= */}
        <div className="max-w-2xl mx-auto text-center space-y-2.5 mb-12 sm:mb-16">
          <div className="inline-flex items-center gap-1.5 px-3 py-0.5 rounded-full bg-[#FAF8F3] border border-[#E5D8C7] shadow-2xs">
            <span className="w-1.5 h-1.5 rounded-full bg-[#D98768]" />
            <span className="text-[11px] font-mono font-bold uppercase tracking-widest text-[#D98768]">
              PRIVACY FIRST ARCHITECTURE
            </span>
          </div>

          <h2 className="font-serif text-3xl sm:text-4xl md:text-5xl font-bold tracking-tight text-[#34312D]">
            Your files stay yours.
          </h2>

          <p className="text-sm sm:text-base text-[#34312D]/80 leading-relaxed max-w-xl mx-auto">
            Most online conversion tools upload your confidential documents to an unknown cloud server. ShiftKit runs locally on your Mac, keeping your private data strictly in your hands.
          </p>
        </div>

        {/* ========================================================= */}
        {/* PRIMARY SHOWCASE: LOCAL BY DESIGN                         */}
        {/* ========================================================= */}
        <div className="rounded-3xl bg-[#FAF8F3] border border-[#E5D8C7] shadow-xs p-6 sm:p-8 lg:p-10 mb-6 sm:mb-8 transition-all">
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 lg:gap-12 items-center">
            {/* Left Column: Context & Verified Privacy Principles */}
            <div className="lg:col-span-5 space-y-6">
              <div className="space-y-2.5">
                <span className="text-[11px] font-mono font-bold uppercase tracking-wider text-[#D98768]">
                  LOCAL BY DESIGN
                </span>
                <h3 className="font-serif text-2xl sm:text-3xl font-bold text-[#34312D] leading-snug">
                  Your files don’t need a trip to the cloud.
                </h3>
                <p className="text-xs sm:text-sm text-[#34312D]/80 leading-relaxed">
                  Supported operations run directly on your Mac, keeping file contents on your device throughout the entire processing workflow.
                </p>
              </div>

              {/* 3 Verified Privacy Characteristic Rows */}
              <div className="space-y-3.5 pt-1">
                {/* Row 1: Local Processing */}
                <div className="flex items-start gap-3.5">
                  <div className="w-9 h-9 rounded-xl bg-[#FAF2ED] border border-[#E5D8C7] flex items-center justify-center text-[#D98768] shrink-0 mt-0.5 shadow-2xs">
                    <Laptop size={17} />
                  </div>
                  <div>
                    <div className="font-serif text-sm font-bold text-[#34312D]">
                      Local processing
                    </div>
                    <div className="text-xs text-[#898177]">
                      File operations run on your Mac.
                    </div>
                  </div>
                </div>

                {/* Row 2: No Remote Upload */}
                <div className="flex items-start gap-3.5">
                  <div className="w-9 h-9 rounded-xl bg-[#FAF2ED] border border-[#E5D8C7] flex items-center justify-center text-[#D98768] shrink-0 mt-0.5 shadow-2xs">
                    <WifiOff size={17} />
                  </div>
                  <div>
                    <div className="font-serif text-sm font-bold text-[#34312D]">
                      No remote conversion upload
                    </div>
                    <div className="text-xs text-[#898177]">
                      Your file contents never leave your device.
                    </div>
                  </div>
                </div>

                {/* Row 3: Local Destination */}
                <div className="flex items-start gap-3.5">
                  <div className="w-9 h-9 rounded-xl bg-[#FAF2ED] border border-[#E5D8C7] flex items-center justify-center text-[#D98768] shrink-0 mt-0.5 shadow-2xs">
                    <Folder size={17} />
                  </div>
                  <div>
                    <div className="font-serif text-sm font-bold text-[#34312D]">
                      Local output destination
                    </div>
                    <div className="text-xs text-[#898177]">
                      Results are saved to your chosen location.
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Right Column: macOS Window Local-Processing Visualization */}
            <div className="lg:col-span-7">
              <div className="rounded-2xl sm:rounded-3xl bg-[#FAF8F3] border border-[#E5D8C7] shadow-sm overflow-hidden">
                {/* Window Header */}
                <div className="px-4 py-2.5 bg-[#F3EEE4] border-b border-[#E5D8C7] flex items-center justify-between">
                  <div className="flex items-center gap-1.5">
                    <span className="w-2.5 h-2.5 rounded-full bg-[#E58871] border border-[#D4745D]" />
                    <span className="w-2.5 h-2.5 rounded-full bg-[#E6BF68] border border-[#D1A94F]" />
                    <span className="w-2.5 h-2.5 rounded-full bg-[#8EA87D] border border-[#7B966A]" />
                  </div>

                  <div className="font-mono text-xs font-bold text-[#465343] tracking-tight">
                    ShiftKit — Local Processing
                  </div>

                  <div className="w-10" />
                </div>

                {/* Window Canvas: Source -> Local Processing Engine -> Verified Output */}
                <div className="p-5 sm:p-7 bg-[#FAF8F3] flex flex-col items-center justify-center">
                  <div className="w-full flex flex-col sm:flex-row items-center justify-between gap-3 sm:gap-2">
                    {/* 1. Source File Card */}
                    <div className="w-full sm:w-36 p-3 rounded-2xl bg-[#FFFFFF] border border-[#E5D8C7] shadow-2xs space-y-2 text-center shrink-0">
                      <div className="w-full h-20 rounded-xl overflow-hidden border border-[#E5D8C7] bg-[#F3EEE4]">
                        <img
                          src="/mountain_sample.jpg"
                          alt="Local Source File"
                          className="w-full h-full object-cover"
                        />
                      </div>
                      <div>
                        <div className="font-mono text-xs font-bold text-[#34312D]">
                          photo.png
                        </div>
                        <div className="text-[10px] text-[#898177]">
                          PNG image
                        </div>
                      </div>
                    </div>

                    {/* Directional Connector 1: Dots + Arrowhead */}
                    <div className="flex items-center justify-center text-[#D98768] py-1 sm:py-0">
                      <span className="text-xs tracking-widest font-bold">••••➔</span>
                    </div>

                    {/* 2. Center Processing Engine Card */}
                    <div className="w-full sm:w-44 p-3.5 rounded-2xl bg-[#FFFFFF] border border-[#E5D8C7] shadow-2xs text-center space-y-2 shrink-0">
                      {/* ShiftKit Radial Logo Icon */}
                      <div className="w-8 h-8 rounded-full bg-[#FAF2ED] border border-[#D98768]/40 mx-auto flex items-center justify-center text-[#D98768] shadow-2xs">
                        <HardDrive size={15} />
                      </div>

                      <div className="space-y-0.5">
                        <div className="font-serif text-xs font-bold text-[#34312D]">
                          Processing
                        </div>
                        <div className="text-[10px] text-[#898177]">
                          on this Mac
                        </div>
                      </div>

                      {/* Terracotta Local Progress Bar */}
                      <div className="w-full h-1.5 rounded-full bg-[#F3EEE4] overflow-hidden">
                        <div className="w-3/5 h-full bg-[#D98768] rounded-full animate-pulse" />
                      </div>

                      <div className="space-y-0.5 text-[9.5px]">
                        <div className="text-[#898177]">Running locally...</div>
                        <div className="text-[#D98768] font-medium">
                          Your files stay on your device.
                        </div>
                      </div>
                    </div>

                    {/* Directional Connector 2: Dots + Arrowhead */}
                    <div className="flex items-center justify-center text-[#D98768] py-1 sm:py-0">
                      <span className="text-xs tracking-widest font-bold">••••➔</span>
                    </div>

                    {/* 3. Output File Card */}
                    <div className="w-full sm:w-36 flex flex-col items-center space-y-2 shrink-0">
                      <div className="w-full p-3 rounded-2xl bg-[#FFFFFF] border border-[#E5D8C7] shadow-2xs space-y-2 text-center relative">
                        <div className="w-full h-20 rounded-xl overflow-hidden border border-[#E5D8C7] bg-[#F3EEE4] relative">
                          <img
                            src="/mountain_sample.jpg"
                            alt="Output File"
                            className="w-full h-full object-cover"
                          />
                          {/* Green Verification Checkmark Badge */}
                          <div className="absolute top-1 right-1 w-5 h-5 rounded-full bg-[#8EA87D] text-[#FFFFFF] flex items-center justify-center shadow-xs">
                            <Check size={12} strokeWidth={3} />
                          </div>
                        </div>
                        <div>
                          <div className="font-mono text-xs font-bold text-[#34312D]">
                            photo.webp
                          </div>
                          <div className="text-[10px] text-[#898177]">
                            WebP image
                          </div>
                        </div>
                      </div>

                      {/* Saved Locally Pill */}
                      <div className="px-2.5 py-0.5 rounded-md bg-[#F3EEE4] border border-[#E5D8C7] text-[10px] font-mono text-[#465343] font-medium">
                        Saved locally
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* ========================================================= */}
        {/* 4 SUPPORTING PRIVACY PRINCIPLE CARDS                      */}
        {/* ========================================================= */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 sm:gap-6">
          {/* Card 1: On-Device Processing */}
          <div className="p-5 sm:p-6 rounded-2xl bg-[#FAF8F3] border border-[#E5D8C7] shadow-2xs flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 transition-all hover:border-[#D98768]/60">
            <div className="flex items-start gap-3.5">
              <div className="w-10 h-10 rounded-xl bg-[#FAF2ED] border border-[#E5D8C7] flex items-center justify-center text-[#D98768] shrink-0 mt-0.5">
                <Laptop size={18} />
              </div>
              <div className="space-y-1">
                <h4 className="font-serif text-base font-bold text-[#34312D]">
                  On-Device Processing
                </h4>
                <p className="text-xs text-[#34312D]/75 leading-relaxed max-w-xs">
                  Image encoding, video trimming, and PDF merging run directly on your Mac.
                </p>
              </div>
            </div>

            {/* Visual Widget: [📄] •••➔ [💻] */}
            <div className="w-full sm:w-auto self-end sm:self-center p-2.5 rounded-xl bg-[#FFFFFF] border border-[#E5D8C7] shadow-2xs flex items-center justify-center gap-2.5 text-xs font-mono shrink-0">
              <div className="w-7 h-7 rounded-lg bg-[#FAF2ED] text-[#D98768] flex items-center justify-center">
                <FileText size={14} />
              </div>
              <span className="text-[#D98768] font-bold text-[11px]">••••➔</span>
              <div className="w-7 h-7 rounded-lg bg-[#F3EEE4] text-[#465343] flex items-center justify-center">
                <Laptop size={14} />
              </div>
            </div>
          </div>

          {/* Card 2: File Contents Stay Local */}
          <div className="p-5 sm:p-6 rounded-2xl bg-[#FAF8F3] border border-[#E5D8C7] shadow-2xs flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 transition-all hover:border-[#D98768]/60">
            <div className="flex items-start gap-3.5">
              <div className="w-10 h-10 rounded-xl bg-[#FAF2ED] border border-[#E5D8C7] flex items-center justify-center text-[#D98768] shrink-0 mt-0.5">
                <WifiOff size={18} />
              </div>
              <div className="space-y-1">
                <h4 className="font-serif text-base font-bold text-[#34312D]">
                  File Contents Stay Local
                </h4>
                <p className="text-xs text-[#34312D]/75 leading-relaxed max-w-xs">
                  Your documents and media are processed without uploading to any remote server.
                </p>
              </div>
            </div>

            {/* Visual Widget: [📄] •••➔ [☁️⃠] */}
            <div className="w-full sm:w-auto self-end sm:self-center p-2.5 rounded-xl bg-[#FFFFFF] border border-[#E5D8C7] shadow-2xs flex items-center justify-center gap-2.5 text-xs font-mono shrink-0">
              <div className="w-7 h-7 rounded-lg bg-[#FAF2ED] text-[#D98768] flex items-center justify-center">
                <FileText size={14} />
              </div>
              <span className="text-[#D98768] font-bold text-[11px]">••••➔</span>
              <div className="w-7 h-7 rounded-lg bg-[#FAF2ED] text-[#D98768] flex items-center justify-center">
                <CloudOff size={14} />
              </div>
            </div>
          </div>

          {/* Card 3: Temporary Working Files */}
          <div className="p-5 sm:p-6 rounded-2xl bg-[#FAF8F3] border border-[#E5D8C7] shadow-2xs flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 transition-all hover:border-[#D98768]/60">
            <div className="flex items-start gap-3.5">
              <div className="w-10 h-10 rounded-xl bg-[#FAF2ED] border border-[#E5D8C7] flex items-center justify-center text-[#D98768] shrink-0 mt-0.5">
                <Trash2 size={18} />
              </div>
              <div className="space-y-1">
                <h4 className="font-serif text-base font-bold text-[#34312D]">
                  Temporary Working Files
                </h4>
                <p className="text-xs text-[#34312D]/75 leading-relaxed max-w-xs">
                  Temporary files are stored in your user cache directory and cleaned up after processing.
                </p>
              </div>
            </div>

            {/* Visual Widget: Lifecycle [📄] -> [⚙️] -> [🗑️] */}
            <div className="w-full sm:w-auto self-end sm:self-center p-2 rounded-xl bg-[#FFFFFF] border border-[#E5D8C7] shadow-2xs flex items-center justify-center gap-2 text-[10px] font-mono shrink-0">
              <div className="flex flex-col items-center">
                <div className="w-6 h-6 rounded-md bg-[#FAF2ED] text-[#D98768] flex items-center justify-center">
                  <FileText size={12} />
                </div>
                <span className="text-[9px] text-[#898177] mt-0.5">Temporary files</span>
              </div>
              <span className="text-[#898177] text-[10px]">➔</span>
              <div className="flex flex-col items-center">
                <div className="w-6 h-6 rounded-md bg-[#F3EEE4] text-[#34312D] flex items-center justify-center">
                  <Settings size={12} />
                </div>
                <span className="text-[9px] text-[#898177] mt-0.5">Processing</span>
              </div>
              <span className="text-[#898177] text-[10px]">➔</span>
              <div className="flex flex-col items-center">
                <div className="w-6 h-6 rounded-md bg-[#FAF2ED] text-[#D98768] flex items-center justify-center">
                  <Trash2 size={12} />
                </div>
                <span className="text-[9px] text-[#898177] mt-0.5">Cleanup</span>
              </div>
            </div>
          </div>

          {/* Card 4: Local Operation History */}
          <div className="p-5 sm:p-6 rounded-2xl bg-[#FAF8F3] border border-[#E5D8C7] shadow-2xs flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 transition-all hover:border-[#D98768]/60">
            <div className="flex items-start gap-3.5">
              <div className="w-10 h-10 rounded-xl bg-[#FAF2ED] border border-[#E5D8C7] flex items-center justify-center text-[#D98768] shrink-0 mt-0.5">
                <Clock size={18} />
              </div>
              <div className="space-y-1">
                <h4 className="font-serif text-base font-bold text-[#34312D]">
                  Local Operation History
                </h4>
                <p className="text-xs text-[#34312D]/75 leading-relaxed max-w-xs">
                  Recent operations are saved locally in a simple JSON file on your Mac for quick access.
                </p>
              </div>
            </div>

            {/* Visual Widget: 2-Row Recent History Log */}
            <div className="w-full sm:w-48 p-2.5 rounded-xl bg-[#FFFFFF] border border-[#E5D8C7] shadow-2xs space-y-1.5 text-[10px] font-mono shrink-0">
              {/* History Row 1 */}
              <div className="flex items-center justify-between gap-1.5">
                <div className="flex items-center gap-1.5 overflow-hidden">
                  <div className="w-5 h-5 rounded overflow-hidden border border-[#E5D8C7] shrink-0">
                    <img
                      src="/mountain_sample.jpg"
                      alt="History Item 1"
                      className="w-full h-full object-cover"
                    />
                  </div>
                  <div className="truncate">
                    <span className="font-bold text-[#34312D]">photo.webp</span>
                    <span className="text-[#898177] block text-[9px]">Image Convert</span>
                  </div>
                </div>
                <span className="text-[#898177] text-[9px] shrink-0">Today, 9:41 AM</span>
              </div>

              {/* History Row 2 */}
              <div className="flex items-center justify-between gap-1.5 pt-1 border-t border-[#F3EEE4]">
                <div className="flex items-center gap-1.5 overflow-hidden">
                  <div className="w-5 h-5 rounded bg-[#FAF2ED] text-[#D98768] flex items-center justify-center border border-[#E5D8C7] shrink-0">
                    <FileText size={10} />
                  </div>
                  <div className="truncate">
                    <span className="font-bold text-[#34312D]">report.pdf</span>
                    <span className="text-[#898177] block text-[9px]">PDF Merge</span>
                  </div>
                </div>
                <span className="text-[#898177] text-[9px] shrink-0">Today, 9:12 AM</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
