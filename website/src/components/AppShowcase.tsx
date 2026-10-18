"use client";

import React, { useState } from "react";
import {
  Compass,
  Scissors,
  Film,
  Layers,
  ListFilter,
  Check,
  Pause,
  Play,
  RotateCcw,
  Sparkles
} from "lucide-react";

export function AppShowcase() {
  const [activeTab, setActiveTab] = useState<"radial" | "crop" | "trim" | "merge" | "queue">("radial");

  const tabs = [
    { id: "radial", label: "Radial Action HUD", icon: Compass },
    { id: "crop", label: "Visual Crop Studio", icon: Scissors },
    { id: "trim", label: "Timeline Video Trimmer", icon: Film },
    { id: "merge", label: "Multi-File Merge Studio", icon: Layers },
    { id: "queue", label: "Job Queue & History", icon: ListFilter },
  ] as const;

  return (
    <section id="showcase" className="py-20 md:py-28 bg-[#FAF8F3]">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Section Header */}
        <div className="text-center max-w-2xl mx-auto space-y-3 mb-12">
          <span className="text-xs font-mono font-bold uppercase tracking-wider text-[#D98768]">
            Interface Showcase
          </span>
          <h2 className="font-serif text-3xl sm:text-4xl font-bold tracking-tight text-[#34312D]">
            Designed for macOS. Handcrafted in Swift.
          </h2>
          <p className="text-sm sm:text-base text-[#34312D]/80 leading-relaxed">
            Every pixel adheres to Apple human interface guidelines, elevated with warm editorial surfaces and crisp typography.
          </p>
        </div>

        {/* Tab Navigation */}
        <div className="flex flex-wrap items-center justify-center gap-2 mb-10">
          {tabs.map((tab) => {
            const Icon = tab.icon;
            const isSelected = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                type="button"
                onClick={() => setActiveTab(tab.id)}
                className={`inline-flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-semibold transition-all cursor-pointer ${
                  isSelected
                    ? "bg-[#D98768] text-[#FAF8F3] shadow-xs"
                    : "bg-[#F3EEE4] text-[#34312D] hover:bg-[#E5D8C7] border border-[#E5D8C7]"
                }`}
              >
                <Icon size={14} />
                <span>{tab.label}</span>
              </button>
            );
          })}
        </div>

        {/* Simulated macOS Window Presentation */}
        <div className="max-w-4xl mx-auto rounded-2xl bg-[#F3EEE4] border border-[#E5D8C7] shadow-lg p-4 sm:p-6">
          {/* Window Header */}
          <div className="flex items-center justify-between pb-4 mb-4 border-b border-[#E5D8C7] text-xs text-[#34312D]/70">
            <div className="flex items-center gap-2">
              <span className="w-3 h-3 rounded-full bg-[#E5D8C7]"></span>
              <span className="w-3 h-3 rounded-full bg-[#E5D8C7]"></span>
              <span className="w-3 h-3 rounded-full bg-[#E5D8C7]"></span>
            </div>
            <div className="font-serif font-bold text-[#465343]">
              {activeTab === "radial" && "ShiftKit Radial Overlay — photo.png"}
              {activeTab === "crop" && "ShiftKit Crop Studio — avatar.heic"}
              {activeTab === "trim" && "ShiftKit Video Trimmer — screencast.mov"}
              {activeTab === "merge" && "ShiftKit Multi-File Merge Studio"}
              {activeTab === "queue" && "ShiftKit Job Queue & Local History"}
            </div>
            <div className="text-[11px] font-mono text-[#D98768]">
              Native Cocoa
            </div>
          </div>

          {/* Window Content Body */}
          <div className="min-h-[380px] bg-[#FAF8F3] rounded-xl border border-[#E5D8C7] p-6 flex flex-col justify-center items-center">
            {/* View 1: Radial Menu */}
            {activeTab === "radial" && (
              <div className="text-center space-y-4 max-w-md animate-fadeIn">
                <div className="w-56 h-56 mx-auto rounded-full bg-[#F3EEE4] border-2 border-[#E5D8C7] relative flex items-center justify-center shadow-md">
                  {/* Petal icons */}
                  <div className="absolute top-3 px-3 py-1 bg-[#D98768] text-[#FAF8F3] rounded text-[11px] font-bold shadow-2xs">
                    To WebP
                  </div>
                  <div className="absolute right-3 top-14 px-2 py-0.5 bg-[#FFFFFF] border border-[#E5D8C7] rounded text-[10px] font-medium">
                    Compress
                  </div>
                  <div className="absolute right-5 bottom-8 px-2 py-0.5 bg-[#FFFFFF] border border-[#E5D8C7] rounded text-[10px] font-medium">
                    Crop
                  </div>
                  <div className="absolute left-5 bottom-8 px-2 py-0.5 bg-[#FFFFFF] border border-[#E5D8C7] rounded text-[10px] font-medium">
                    To PDF
                  </div>
                  <div className="absolute left-3 top-14 px-2 py-0.5 bg-[#FFFFFF] border border-[#E5D8C7] rounded text-[10px] font-medium">
                    EXIF Clean
                  </div>
                  <div className="w-16 h-16 rounded-full bg-[#FAF8F3] border border-[#E5D8C7] flex flex-col items-center justify-center">
                    <span className="text-[9px] font-mono text-[#D98768] font-bold">SHIFT</span>
                    <span className="text-[10px] font-bold text-[#34312D]">Menu</span>
                  </div>
                </div>
                <div>
                  <h4 className="font-serif text-lg font-bold text-[#34312D]">Context-Aware Radial Blooming</h4>
                  <p className="text-xs text-[#34312D]/75">
                    Appears directly at the cursor when you drag while holding Shift. Dismisses automatically if you release or drop outside.
                  </p>
                </div>
              </div>
            )}

            {/* View 2: Crop Studio */}
            {activeTab === "crop" && (
              <div className="w-full max-w-lg space-y-4 animate-fadeIn">
                <div className="p-4 rounded-xl bg-[#F3EEE4] border border-[#E5D8C7] flex flex-col items-center justify-center min-h-[220px] relative">
                  <div className="w-44 h-44 rounded border-2 border-dashed border-[#D98768] bg-[#FAF8F3]/60 flex flex-col items-center justify-center p-3 text-center">
                    <Scissors size={24} className="text-[#D98768] mb-1" />
                    <span className="text-xs font-mono font-bold text-[#34312D]">1:1 Square (1080 × 1080)</span>
                    <span className="text-[10px] text-[#465343]">Drag handles to reframe</span>
                  </div>
                </div>
                <div className="flex items-center justify-between text-xs font-mono text-[#465343] pt-1">
                  <span className="flex items-center gap-2">
                    <button className="px-2.5 py-1 rounded bg-[#D98768] text-[#FAF8F3] font-bold">1:1</button>
                    <button className="px-2.5 py-1 rounded bg-[#FFFFFF] border border-[#E5D8C7]">4:3</button>
                    <button className="px-2.5 py-1 rounded bg-[#FFFFFF] border border-[#E5D8C7]">16:9</button>
                  </span>
                  <span>Target: WebP @ 92%</span>
                </div>
              </div>
            )}

            {/* View 3: Video Trimmer */}
            {activeTab === "trim" && (
              <div className="w-full max-w-lg space-y-4 animate-fadeIn">
                <div className="p-4 rounded-xl bg-[#34312D] text-[#FAF8F3] min-h-[170px] flex flex-col items-center justify-center relative rounded-lg">
                  <Film size={36} className="text-[#E5D8C7] mb-2 opacity-60" />
                  <span className="text-xs font-mono text-[#FAF8F3]">screencast_demo.mov</span>
                  <span className="text-[11px] text-[#A8B5A0]">00:04.250 – 00:18.900 (Duration: 14.65s)</span>
                </div>
                <div className="p-3 rounded-lg bg-[#F3EEE4] border border-[#E5D8C7] space-y-2">
                  <div className="flex items-center justify-between text-[11px] font-mono text-[#34312D]">
                    <span>Trim In: 00:04.250</span>
                    <span className="text-[#D98768] font-bold">Lossless Snapping</span>
                    <span>Trim Out: 00:18.900</span>
                  </div>
                  <div className="w-full h-3 rounded bg-[#E5D8C7] relative">
                    <div className="absolute left-[20%] right-[30%] h-full bg-[#D98768] rounded"></div>
                  </div>
                </div>
              </div>
            )}

            {/* View 4: Merge Studio */}
            {activeTab === "merge" && (
              <div className="w-full max-w-lg space-y-3 animate-fadeIn text-xs">
                <div className="flex items-center justify-between pb-2 border-b border-[#E5D8C7]">
                  <span className="font-bold font-serif text-sm text-[#34312D]">Items to Combine (3 Files)</span>
                  <span className="font-mono text-[#D98768] font-bold">Mode: Merge to PDF</span>
                </div>
                <div className="space-y-2">
                  <div className="p-2.5 rounded-lg bg-[#FFFFFF] border border-[#E5D8C7] flex items-center justify-between">
                    <span>1. contract_cover.pdf (1 page)</span>
                    <span className="text-[#465343] font-mono text-[11px]">240 KB</span>
                  </div>
                  <div className="p-2.5 rounded-lg bg-[#FFFFFF] border border-[#E5D8C7] flex items-center justify-between">
                    <span>2. signature_page.png (Embedded Page)</span>
                    <span className="text-[#465343] font-mono text-[11px]">1.2 MB</span>
                  </div>
                  <div className="p-2.5 rounded-lg bg-[#FFFFFF] border border-[#E5D8C7] flex items-center justify-between">
                    <span>3. appendix_terms.pdf (4 pages)</span>
                    <span className="text-[#465343] font-mono text-[11px]">680 KB</span>
                  </div>
                </div>
                <div className="pt-2 flex justify-end">
                  <span className="px-3.5 py-1.5 rounded-md bg-[#D98768] text-[#FAF8F3] font-semibold text-xs shadow-2xs">
                    Combine All into Single PDF
                  </span>
                </div>
              </div>
            )}

            {/* View 5: Job Queue */}
            {activeTab === "queue" && (
              <div className="w-full max-w-lg space-y-3 animate-fadeIn text-xs">
                <div className="flex items-center justify-between pb-2 border-b border-[#E5D8C7]">
                  <span className="font-bold font-serif text-sm text-[#34312D]">Active & Recent Operations</span>
                  <span className="font-mono text-[#465343]">Workers: 2 active</span>
                </div>
                <div className="space-y-2">
                  <div className="p-3 rounded-lg bg-[#FFFFFF] border border-[#A8B5A0] space-y-1.5 shadow-2xs">
                    <div className="flex items-center justify-between font-medium text-[#34312D]">
                      <span>product_shoot.tiff → To WebP</span>
                      <span className="text-[#D98768] font-mono text-[11px] font-bold">82% (Encoding)</span>
                    </div>
                    <div className="w-full h-1.5 rounded-full bg-[#F3EEE4] overflow-hidden">
                      <div className="w-[82%] h-full bg-[#D98768] rounded-full"></div>
                    </div>
                  </div>
                  <div className="p-3 rounded-lg bg-[#FFFFFF] border border-[#E5D8C7] flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <Check size={14} className="text-[#465343]" />
                      <span className="text-[#34312D]">podcast_ep12.wav → MP3 (320 kbps)</span>
                    </div>
                    <span className="text-[11px] font-mono text-[#465343]">Completed (0.8s)</span>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </section>
  );
}
