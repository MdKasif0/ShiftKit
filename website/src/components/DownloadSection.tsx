"use client";

import React, { useState } from "react";
import Link from "next/link";
import Image from "next/image";
import {
  Download,
  Terminal,
  Copy,
  Check,
  ExternalLink,
  ShieldCheck,
  Package,
  HardDrive,
  Cpu,
  Laptop,
  ChevronDown,
  Info,
  ArrowRight,
} from "lucide-react";

export function DownloadSection() {
  const dmgUrl =
    process.env.NEXT_PUBLIC_SHIFTKIT_DMG_URL || "/downloads/ShiftKit-1.0.0.dmg";
  const [copiedClone, setCopiedClone] = useState(false);
  const [copiedChecksum, setCopiedChecksum] = useState(false);
  const [showInstallGuide, setShowInstallGuide] = useState(false);

  const cloneCommand = "git clone https://github.com/MdKasif0/ShiftKit.git";
  const verifiedSha256 =
    "255ca0aa221002447bb4f1c13f1107ddada8a5a6201707f8094549ffcff03e10";

  const copyToClipboard = async (
    text: string,
    type: "clone" | "checksum"
  ) => {
    try {
      if (typeof navigator !== "undefined" && navigator.clipboard && window.isSecureContext) {
        await navigator.clipboard.writeText(text);
      } else if (typeof document !== "undefined") {
        const textArea = document.createElement("textarea");
        textArea.value = text;
        textArea.style.position = "fixed";
        textArea.style.left = "-999999px";
        textArea.style.top = "-999999px";
        document.body.appendChild(textArea);
        textArea.focus();
        textArea.select();
        document.execCommand("copy");
        textArea.remove();
      }

      if (type === "clone") {
        setCopiedClone(true);
        setTimeout(() => setCopiedClone(false), 2000);
      } else {
        setCopiedChecksum(true);
        setTimeout(() => setCopiedChecksum(false), 2000);
      }
    } catch (err) {
      console.error("Failed to copy to clipboard:", err);
    }
  };

  return (
    <section
      id="download"
      aria-label="Download ShiftKit"
      className="py-16 md:py-24 bg-[#FAF8F3] scroll-mt-20 border-t border-[#E5D8C7]"
    >
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Main Release Card */}
        <div className="p-6 sm:p-10 md:p-12 rounded-3xl bg-[#F3EEE4] border border-[#E5D8C7] shadow-xs text-center relative overflow-hidden">
          {/* Subtle Ambient Decorative Gradient Arc */}
          <div
            className="absolute -top-32 left-1/2 -translate-x-1/2 w-96 h-96 rounded-full bg-[#FAF8F3]/70 blur-3xl pointer-events-none"
            aria-hidden="true"
          />

          <div className="relative z-10 max-w-2xl mx-auto">
            {/* App Icon Frame */}
            <div className="w-20 h-20 sm:w-22 sm:h-22 rounded-2xl bg-[#FAF8F3] border border-[#E5D8C7] p-2 shadow-2xs mx-auto mb-4 flex items-center justify-center transition-transform duration-200 hover:scale-[1.02]">
              <Image
                src="/app-icon.png"
                alt="ShiftKit App Icon"
                width={76}
                height={76}
                className="w-full h-full object-contain"
                priority
              />
            </div>

            {/* Official Release Badge */}
            <div className="inline-flex items-center gap-1.5 px-3 py-0.5 rounded-full bg-[#FAF8F3] border border-[#E5D8C7] shadow-2xs mb-4">
              <span className="w-1.5 h-1.5 rounded-full bg-[#D98768]" />
              <span className="text-[11px] font-mono font-bold uppercase tracking-wider text-[#D98768]">
                OFFICIAL RELEASE · v1.0.0
              </span>
            </div>

            {/* Headline */}
            <h2 className="font-serif text-3xl sm:text-4xl md:text-5xl font-bold tracking-tight text-[#34312D]">
              Get ShiftKit for Mac
            </h2>

            {/* Description */}
            <p className="text-sm sm:text-base text-[#34312D]/80 leading-relaxed mt-2.5 max-w-xl mx-auto">
              Accelerate your everyday file workflow with circular radial actions.
              100% native and local on-device processing.
            </p>

            {/* Primary Download Action */}
            <div className="pt-6 sm:pt-7 flex flex-col items-center justify-center space-y-3">
              <a
                href={dmgUrl}
                download="ShiftKit-1.0.0.dmg"
                className="inline-flex items-center justify-center gap-2.5 px-8 sm:px-10 py-3.5 sm:py-4 rounded-xl text-base font-semibold bg-[#D98768] hover:bg-[#c97556] text-[#FFFFFF] shadow-2xs hover:shadow-xs transition-all transform hover:-translate-y-0.5 active:translate-y-0 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#D98768] cursor-pointer"
              >
                <Download size={19} className="stroke-[2.2]" />
                <span>Download ShiftKit 1.0.0</span>
              </a>

              {/* Sub-label under CTA */}
              <div className="flex items-center gap-2 text-xs font-mono text-[#465343]">
                <span>DMG Installer</span>
                <span className="text-[#898177]">·</span>
                <span>5.2 MB</span>
                <span className="text-[#898177]">·</span>
                <span>macOS 14.0+</span>
              </div>
            </div>

            {/* Secondary Actions */}
            <div className="flex flex-wrap items-center justify-center gap-2.5 pt-3">
              <Link
                href="https://github.com/MdKasif0/ShiftKit"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl bg-[#FAF8F3] hover:bg-[#EAE3D6] border border-[#E5D8C7] text-xs font-mono font-bold text-[#34312D] transition-colors cursor-pointer"
              >
                <svg
                  width="13"
                  height="13"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                  aria-hidden="true"
                >
                  <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z" />
                </svg>
                <span>View Source on GitHub</span>
                <ExternalLink size={12} className="text-[#898177]" />
              </Link>

              <Link
                href="https://github.com/MdKasif0/ShiftKit/releases"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl bg-[#FAF8F3] hover:bg-[#EAE3D6] border border-[#E5D8C7] text-xs font-mono font-bold text-[#34312D] transition-colors cursor-pointer"
              >
                <span>Release Notes</span>
                <ArrowRight size={12} className="text-[#898177]" />
              </Link>
            </div>
          </div>

          {/* ========================================================= */}
          {/* LEVEL 2: VERIFIED SPECIFICATIONS GRID                     */}
          {/* ========================================================= */}
          <div className="mt-8 pt-8 border-t border-[#E5D8C7] grid grid-cols-2 md:grid-cols-4 gap-3 sm:gap-4 text-left">
            {/* Version */}
            <div className="p-3.5 sm:p-4 rounded-2xl bg-[#FAF8F3] border border-[#E5D8C7] flex flex-col justify-between space-y-2">
              <div className="flex items-center justify-between text-[#465343]">
                <span className="text-[10px] font-mono font-bold uppercase tracking-wider">
                  Version
                </span>
                <Package size={14} className="text-[#D98768]" />
              </div>
              <div>
                <span className="font-serif text-base sm:text-lg font-bold text-[#34312D] block">
                  1.0.0
                </span>
                <span className="text-[11px] font-mono text-[#898177]">
                  Production Build
                </span>
              </div>
            </div>

            {/* File Size */}
            <div className="p-3.5 sm:p-4 rounded-2xl bg-[#FAF8F3] border border-[#E5D8C7] flex flex-col justify-between space-y-2">
              <div className="flex items-center justify-between text-[#465343]">
                <span className="text-[10px] font-mono font-bold uppercase tracking-wider">
                  File Size
                </span>
                <HardDrive size={14} className="text-[#D98768]" />
              </div>
              <div>
                <span className="font-serif text-base sm:text-lg font-bold text-[#34312D] block">
                  5.2 MB
                </span>
                <span className="text-[11px] font-mono text-[#898177]">
                  Apple Disk Image (.dmg)
                </span>
              </div>
            </div>

            {/* Architecture */}
            <div className="p-3.5 sm:p-4 rounded-2xl bg-[#FAF8F3] border border-[#E5D8C7] flex flex-col justify-between space-y-2">
              <div className="flex items-center justify-between text-[#465343]">
                <span className="text-[10px] font-mono font-bold uppercase tracking-wider">
                  Architecture
                </span>
                <Cpu size={14} className="text-[#D98768]" />
              </div>
              <div>
                <span className="font-serif text-base sm:text-lg font-bold text-[#34312D] block">
                  Universal Mac
                </span>
                <span className="text-[11px] font-mono text-[#898177]">
                  Apple Silicon & Intel
                </span>
              </div>
            </div>

            {/* Requires */}
            <div className="p-3.5 sm:p-4 rounded-2xl bg-[#FAF8F3] border border-[#E5D8C7] flex flex-col justify-between space-y-2">
              <div className="flex items-center justify-between text-[#465343]">
                <span className="text-[10px] font-mono font-bold uppercase tracking-wider">
                  Requires
                </span>
                <Laptop size={14} className="text-[#D98768]" />
              </div>
              <div>
                <span className="font-serif text-base sm:text-lg font-bold text-[#34312D] block">
                  macOS 14.0+
                </span>
                <span className="text-[11px] font-mono text-[#898177]">
                  Sonoma & Sequoia
                </span>
              </div>
            </div>
          </div>

          {/* ========================================================= */}
          {/* LEVEL 3: DEVELOPER CLI & CHECKSUM VERIFICATION            */}
          {/* ========================================================= */}
          <div className="mt-5 space-y-2.5">
            {/* Git Clone Row */}
            <div className="p-2.5 sm:p-3 rounded-2xl bg-[#FAF8F3] border border-[#E5D8C7] flex flex-col sm:flex-row sm:items-center justify-between gap-2 text-left font-mono text-xs">
              <div className="flex items-center gap-2.5 min-w-0 flex-1">
                <div className="w-6 h-6 rounded-lg bg-[#F3EEE4] border border-[#E5D8C7] text-[#465343] flex items-center justify-center shrink-0">
                  <Terminal size={12} />
                </div>
                <span className="text-[#898177] text-[11px] shrink-0 font-bold">
                  Source code:
                </span>
                <code className="text-[#34312D] text-[11px] truncate select-all">
                  {cloneCommand}
                </code>
              </div>

              <button
                type="button"
                onClick={() => copyToClipboard(cloneCommand, "clone")}
                className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-[#F3EEE4] hover:bg-[#EAE3D6] border border-[#E5D8C7] text-[11px] font-mono font-bold text-[#34312D] transition-colors cursor-pointer shrink-0 self-end sm:self-auto focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-[#D98768]"
                aria-label="Copy Git clone command"
              >
                {copiedClone ? (
                  <>
                    <Check size={12} className="text-[#465343]" />
                    <span className="text-[#465343]">Copied!</span>
                  </>
                ) : (
                  <>
                    <Copy size={12} className="text-[#898177]" />
                    <span>Copy</span>
                  </>
                )}
              </button>
            </div>

            {/* SHA-256 Row */}
            <div className="p-2.5 sm:p-3 rounded-2xl bg-[#FAF8F3] border border-[#E5D8C7] flex flex-col sm:flex-row sm:items-center justify-between gap-2 text-left font-mono text-xs">
              <div className="flex items-center gap-2.5 min-w-0 flex-1">
                <div className="w-6 h-6 rounded-lg bg-[#FAF2ED] border border-[#D98768]/30 text-[#D98768] flex items-center justify-center shrink-0">
                  <ShieldCheck size={13} />
                </div>
                <span className="text-[#898177] text-[11px] shrink-0 font-bold">
                  SHA-256:
                </span>
                <code
                  className="text-[#34312D] text-[11px] truncate select-all"
                  title={verifiedSha256}
                >
                  {verifiedSha256}
                </code>
              </div>

              <button
                type="button"
                onClick={() => copyToClipboard(verifiedSha256, "checksum")}
                className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-[#F3EEE4] hover:bg-[#EAE3D6] border border-[#E5D8C7] text-[11px] font-mono font-bold text-[#34312D] transition-colors cursor-pointer shrink-0 self-end sm:self-auto focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-[#D98768]"
                aria-label="Copy SHA-256 Checksum"
              >
                {copiedChecksum ? (
                  <>
                    <Check size={12} className="text-[#465343]" />
                    <span className="text-[#465343]">Copied!</span>
                  </>
                ) : (
                  <>
                    <Copy size={12} className="text-[#898177]" />
                    <span>Copy</span>
                  </>
                )}
              </button>
            </div>
          </div>

          {/* ========================================================= */}
          {/* LEVEL 4: INSTALLATION & GATEKEEPER GUIDANCE (EXPANDABLE)  */}
          {/* ========================================================= */}
          <div className="mt-5 text-left">
            <button
              type="button"
              onClick={() => setShowInstallGuide(!showInstallGuide)}
              aria-expanded={showInstallGuide}
              aria-controls="installation-guide-panel"
              className="w-full p-3 rounded-2xl bg-[#FAF8F3] border border-[#E5D8C7] flex items-center justify-between text-xs font-mono font-bold text-[#34312D] hover:bg-[#F3EEE4] transition-colors cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#D98768]"
            >
              <div className="flex items-center gap-2">
                <Info size={14} className="text-[#D98768]" />
                <span>Installation Guidance & macOS Gatekeeper Notice</span>
              </div>
              <ChevronDown
                size={14}
                className={`text-[#898177] transform transition-transform duration-200 ${
                  showInstallGuide ? "rotate-180" : ""
                }`}
              />
            </button>

            {showInstallGuide && (
              <div
                id="installation-guide-panel"
                className="mt-2 p-4 sm:p-5 rounded-2xl bg-[#FAF8F3] border border-[#E5D8C7] text-xs text-[#34312D]/85 leading-relaxed space-y-3"
              >
                <div className="grid grid-cols-1 md:grid-cols-3 gap-3 pt-1">
                  <div className="p-3 rounded-xl bg-[#F3EEE4] border border-[#E5D8C7] space-y-1">
                    <span className="font-mono font-bold text-[10px] text-[#D98768] uppercase tracking-wider block">
                      Step 1 · Disk Image
                    </span>
                    <p className="font-medium text-[#34312D]">
                      Open the downloaded <code className="font-mono text-[11px] bg-[#FAF8F3] px-1 py-0.5 rounded">.dmg</code> file and drag <strong className="text-[#34312D]">ShiftKit.app</strong> into your Applications folder.
                    </p>
                  </div>

                  <div className="p-3 rounded-xl bg-[#F3EEE4] border border-[#E5D8C7] space-y-1">
                    <span className="font-mono font-bold text-[10px] text-[#D98768] uppercase tracking-wider block">
                      Step 2 · Accessibility
                    </span>
                    <p className="font-medium text-[#34312D]">
                      On first launch, grant Accessibility permission in System Settings. This enables ShiftKit to detect when the Shift key is held while dragging files.
                    </p>
                  </div>

                  <div className="p-3 rounded-xl bg-[#F3EEE4] border border-[#E5D8C7] space-y-1">
                    <span className="font-mono font-bold text-[10px] text-[#D98768] uppercase tracking-wider block">
                      Step 3 · Gatekeeper
                    </span>
                    <p className="font-medium text-[#34312D]">
                      If macOS shows an unverified developer dialog, right-click (Control-click) <strong className="text-[#34312D]">ShiftKit.app</strong> and click <strong className="text-[#34312D]">Open</strong> to bypass Gatekeeper.
                    </p>
                  </div>
                </div>

                <p className="text-[11px] font-mono text-[#898177] pt-1">
                  100% on-device processing. No background daemon, no cloud telemetry, no account required.
                </p>
              </div>
            )}
          </div>
        </div>
      </div>
    </section>
  );
}
