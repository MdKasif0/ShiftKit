"use client";

import React, { useState } from "react";
import Link from "next/link";
import {
  Laptop,
  FileText,
  WifiOff,
  Folder,
  Layers,
  Download,
  ShieldCheck,
  Sparkles,
  ChevronDown,
  ArrowRight,
  ExternalLink,
} from "lucide-react";

export function FAQ() {
  const [openIndex, setOpenIndex] = useState<number | null>(0);
  const [selectedCategory, setSelectedCategory] = useState<string>("All");

  const categories = ["All", "Getting Started", "File Operations", "Privacy & Security"] as const;

  const faqs = [
    {
      id: "macos-availability",
      category: "Getting Started",
      icon: Laptop,
      q: "Is ShiftKit available for macOS?",
      a: "Yes. ShiftKit is built specifically for macOS 14.0 (Sonoma) and macOS 15 (Sequoia). It is compiled as a Universal Binary supporting both Apple Silicon (M1/M2/M3/M4) and 64-bit Intel Mac computers.",
      highlight: "Universal Binary · macOS 14 & 15",
    },
    {
      id: "supported-formats",
      category: "File Operations",
      icon: FileText,
      q: "Which formats does ShiftKit support?",
      a: "ShiftKit supports image workflows (PNG, JPEG, WebP, HEIC, TIFF, BMP, GIF, AVIF), document formats (PDF creation, compression, extraction, and merging), audio formats (MP3, WAV, AAC, M4A), and video conversions (MP4, MOV, WebM).",
      highlight: "Images, PDFs, Audio & Video",
    },
    {
      id: "privacy-uploads",
      category: "Privacy & Security",
      icon: WifiOff,
      q: "Are files uploaded to a server?",
      a: "No. ShiftKit is a local-first desktop application. Every conversion, crop, trim, and metadata inspection executes entirely on your Mac using native Apple frameworks and local engines. Your files never leave your device.",
      highlight: "100% On-Device · Zero Cloud Uploads",
    },
    {
      id: "save-locations",
      category: "File Operations",
      icon: Folder,
      q: "Where are converted files saved?",
      a: "By default, ShiftKit saves converted files beside your original files or into a dedicated ShiftKit Output folder. You can configure this in Settings under Output, or choose \"Ask every time\" to prompt for a custom location.",
      highlight: "Beside Source or Custom Folder",
    },
    {
      id: "batch-processing",
      category: "File Operations",
      icon: Layers,
      q: "Can I process multiple files?",
      a: "Yes. When you drag multiple files, ShiftKit launches the Multi-File Studio. You can choose to merge compatible files into a single multi-page PDF or batch convert each file with automatic queue throttling and per-item progress.",
      highlight: "Multi-Page Merge & Batch FIFO",
    },
    {
      id: "installation",
      category: "Getting Started",
      icon: Download,
      q: "How do I install ShiftKit?",
      a: "Download the ShiftKit disk image (.dmg), open it, and drag ShiftKit.app into your Applications folder. On first launch, grant Accessibility permissions in System Settings so ShiftKit can recognize when the Shift key is held during drag gestures.",
      highlight: "Standard DMG Drag-and-Drop",
    },
    {
      id: "gatekeeper-warnings",
      category: "Privacy & Security",
      icon: ShieldCheck,
      q: "What happens if macOS displays a security warning?",
      a: "If macOS displays a warning that the developer cannot be verified (Gatekeeper), right-click (or Control-click) ShiftKit.app in your Applications folder and select \"Open\", then click \"Open\" in the confirmation dialog. Once an official Developer ID certificate is applied to release builds, this warning will not appear.",
      highlight: "Gatekeeper Right-Click Open",
    },
    {
      id: "pricing-license",
      category: "Getting Started",
      icon: Sparkles,
      q: "Is ShiftKit free?",
      a: "ShiftKit is currently provided as an open-source evaluation build. The complete source code is public on GitHub under an open-source license. Commercial licensing and optional App Store editions may be introduced in the future.",
      highlight: "Open Source Evaluation Build",
    },
  ];

  // Filter FAQs based on selected category
  const filteredFaqs =
    selectedCategory === "All"
      ? faqs
      : faqs.filter((faq) => faq.category === selectedCategory);

  const toggleItem = (idx: number) => {
    setOpenIndex(openIndex === idx ? null : idx);
  };

  return (
    <section
      id="faq"
      aria-label="Frequently Asked Questions"
      className="py-16 md:py-24 bg-[#FAF8F3] scroll-mt-24 border-t border-[#E5D8C7]"
    >
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* ========================================================= */}
        {/* SECTION HEADER                                            */}
        {/* ========================================================= */}
        <div className="text-center max-w-2xl mx-auto space-y-2.5 mb-10 sm:mb-12">
          <div className="inline-flex items-center gap-1.5 px-3 py-0.5 rounded-full bg-[#FAF8F3] border border-[#E5D8C7] shadow-2xs">
            <span className="w-1.5 h-1.5 rounded-full bg-[#D98768]" />
            <span className="text-[11px] font-mono font-bold uppercase tracking-widest text-[#D98768]">
              FREQUENTLY ASKED QUESTIONS
            </span>
          </div>

          <h2 className="font-serif text-3xl sm:text-4xl md:text-5xl font-bold tracking-tight text-[#34312D]">
            Everything you need to know.
          </h2>

          <p className="text-sm sm:text-base text-[#34312D]/80 leading-relaxed max-w-xl mx-auto">
            Clear, honest answers about privacy, formats, and desktop integration.
          </p>
        </div>

        {/* ========================================================= */}
        {/* CATEGORY FILTER TABS                                      */}
        {/* ========================================================= */}
        <div className="flex items-center justify-center gap-1.5 sm:gap-2 mb-8 overflow-x-auto pb-2 no-scrollbar select-none">
          {categories.map((cat) => {
            const isSelected = selectedCategory === cat;
            return (
              <button
                key={cat}
                type="button"
                onClick={() => {
                  setSelectedCategory(cat);
                  // Reset open item when switching category
                  setOpenIndex(0);
                }}
                className={`px-3 py-1.5 rounded-xl text-xs font-mono font-bold transition-all cursor-pointer shrink-0 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#D98768] ${
                  isSelected
                    ? "bg-[#D98768] text-[#FFFFFF] shadow-2xs"
                    : "bg-[#F3EEE4] text-[#34312D] hover:bg-[#EAE3D6] border border-[#E5D8C7]"
                }`}
              >
                {cat}
              </button>
            );
          })}
        </div>

        {/* ========================================================= */}
        {/* UNIFIED ACCORDION PANEL                                   */}
        {/* ========================================================= */}
        <div className="rounded-2xl sm:rounded-3xl bg-[#FAF8F3] border border-[#E5D8C7] shadow-xs overflow-hidden divide-y divide-[#E5D8C7]">
          {filteredFaqs.map((item, idx) => {
            const isOpen = openIndex === idx;
            const IconComp = item.icon;

            return (
              <div
                key={item.id}
                className={`transition-colors duration-150 ${
                  isOpen ? "bg-[#FAF2ED]/40" : "hover:bg-[#F3EEE4]/40"
                }`}
              >
                {/* Accordion Trigger Button */}
                <button
                  type="button"
                  id={`faq-trigger-${item.id}`}
                  aria-expanded={isOpen}
                  aria-controls={`faq-answer-${item.id}`}
                  onClick={() => toggleItem(idx)}
                  className="w-full p-4 sm:p-5 text-left flex items-center justify-between gap-3.5 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#D98768] cursor-pointer group"
                >
                  <div className="flex items-center gap-3.5 min-w-0">
                    {/* Left Icon Badge */}
                    <div
                      className={`w-9 h-9 rounded-xl flex items-center justify-center shrink-0 border transition-colors ${
                        isOpen
                          ? "bg-[#FAF2ED] text-[#D98768] border-[#D98768]/40 shadow-2xs"
                          : "bg-[#F3EEE4] text-[#465343] border-[#E5D8C7] group-hover:border-[#D98768]/30"
                      }`}
                    >
                      <IconComp size={16} />
                    </div>

                    {/* Question Title */}
                    <div className="min-w-0">
                      <span className="font-serif text-base sm:text-lg font-bold text-[#34312D] group-hover:text-[#465343] transition-colors block">
                        {item.q}
                      </span>
                    </div>
                  </div>

                  {/* Disclosure Chevron */}
                  <div
                    className={`w-7 h-7 rounded-lg flex items-center justify-center shrink-0 transition-all duration-200 ${
                      isOpen
                        ? "text-[#D98768]"
                        : "text-[#898177] group-hover:text-[#34312D]"
                    }`}
                  >
                    <ChevronDown
                      size={18}
                      className={`transform transition-transform duration-200 ${
                        isOpen ? "rotate-180" : ""
                      }`}
                    />
                  </div>
                </button>

                {/* Expanded Answer Body */}
                {isOpen && (
                  <div
                    id={`faq-answer-${item.id}`}
                    role="region"
                    aria-labelledby={`faq-trigger-${item.id}`}
                    className="px-4 sm:px-5 pb-5 pt-2 text-xs sm:text-sm text-[#34312D]/85 leading-relaxed border-t border-[#E5D8C7]/40 animate-fadeIn"
                  >
                    <div className="pl-0 sm:pl-12.5 max-w-2xl space-y-2">
                      <p>{item.a}</p>

                      {/* Highlight metadata chip */}
                      <div className="pt-1 flex items-center gap-2">
                        <span className="text-[10px] font-mono font-bold px-2 py-0.5 rounded bg-[#F3EEE4] border border-[#E5D8C7] text-[#465343]">
                          {item.highlight}
                        </span>
                      </div>
                    </div>
                  </div>
                )}
              </div>
            );
          })}
        </div>

        {/* ========================================================= */}
        {/* CLOSING REASSURANCE FOOTER                                */}
        {/* ========================================================= */}
        <div className="mt-10 sm:mt-12 p-4 sm:p-5 rounded-2xl bg-[#F3EEE4] border border-[#E5D8C7] flex flex-col sm:flex-row items-center justify-between gap-3 text-xs">
          <div className="text-center sm:text-left text-[#34312D]/85">
            <span className="font-bold font-serif text-sm text-[#34312D] block">
              Still have a question?
            </span>
            <span>
              Explore the full open-source codebase on GitHub or download ShiftKit to experience the workflow.
            </span>
          </div>

          <div className="flex items-center gap-2.5 shrink-0">
            <a
              href="https://github.com/MdKasif0/ShiftKit"
              target="_blank"
              rel="noopener noreferrer"
              className="px-3 py-1.5 rounded-xl bg-[#FFFFFF] border border-[#E5D8C7] text-[#34312D] hover:bg-[#FAF8F3] font-mono font-bold text-[11px] flex items-center gap-1.5 transition-colors cursor-pointer"
            >
              <span>GitHub</span>
              <ExternalLink size={12} />
            </a>

            <Link
              href="#download"
              className="px-3.5 py-1.5 rounded-xl bg-[#D98768] text-[#FFFFFF] font-mono font-bold text-[11px] flex items-center gap-1.5 shadow-2xs hover:bg-[#C47456] transition-colors cursor-pointer"
            >
              <span>Get ShiftKit</span>
              <ArrowRight size={12} />
            </Link>
          </div>
        </div>
      </div>
    </section>
  );
}
