import React from "react";
import Link from "next/link";
import { Navbar } from "@/components/Navbar";
import { Footer } from "@/components/Footer";
import { ShieldCheck, ArrowLeft, HardDrive, WifiOff, Trash2, Database } from "lucide-react";

export const metadata = {
  title: "Privacy Policy — ShiftKit",
  description: "ShiftKit privacy architecture and local data retention policy.",
};

export default function PrivacyPage() {
  return (
    <div className="min-h-screen bg-[#FAF8F3] text-[#34312D] flex flex-col justify-between">
      <Navbar />

      <main className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-16 md:py-24 space-y-12">
        <Link
          href="/"
          className="inline-flex items-center gap-1.5 text-xs font-mono font-medium text-[#465343] hover:text-[#D98768] transition-colors"
        >
          <ArrowLeft size={14} />
          <span>Back to Home</span>
        </Link>

        <div className="space-y-4 border-b border-[#E5D8C7] pb-8">
          <span className="text-xs font-mono font-bold uppercase tracking-wider text-[#D98768]">
            Trust & Transparency
          </span>
          <h1 className="font-serif text-3xl sm:text-4xl md:text-5xl font-bold tracking-tight text-[#34312D]">
            Privacy Policy
          </h1>
          <p className="text-sm text-[#34312D]/75">
            Last updated: October 2026 • ShiftKit 1.0.0
          </p>
        </div>

        <div className="prose prose-neutral max-w-none space-y-8 text-sm sm:text-base leading-relaxed text-[#34312D]/85">
          <section className="space-y-3">
            <h2 className="font-serif text-xl sm:text-2xl font-bold text-[#34312D]">
              1. Local-First Architecture
            </h2>
            <p>
              ShiftKit is engineered from the ground up as a native, local-first utility for macOS. Unlike cloud-based file conversion websites, ShiftKit executes all image processing, video/audio transcoding, PDF manipulation, and metadata inspections strictly on your Mac computer.
            </p>
            <p>
              At no point are your file contents, documents, images, audio, or video streams transmitted to any remote conversion server or third-party cloud infrastructure.
            </p>
          </section>

          <section className="space-y-3">
            <h2 className="font-serif text-xl sm:text-2xl font-bold text-[#34312D]">
              2. Temporary Files and Disk Artifacts
            </h2>
            <p>
              During certain intensive operations (such as multi-pass video trimming or PDF vector compilation), ShiftKit creates temporary atomic working files in your Mac’s standard user cache directory.
            </p>
            <p>
              These temporary files are committed to their final destination upon successful output validation, or deleted immediately if an operation fails or is cancelled by the user. You can also purge all cached temporary files at any time by clicking <strong>Purge Temporary Files</strong> in ShiftKit Settings.
            </p>
          </section>

          <section className="space-y-3">
            <h2 className="font-serif text-xl sm:text-2xl font-bold text-[#34312D]">
              3. Operational History and Local Retention
            </h2>
            <p>
              ShiftKit maintains a concise history log saved locally on your Mac at:
              <br />
              <code className="font-mono text-xs bg-[#F3EEE4] px-2 py-1 rounded text-[#465343] block my-2">
                ~/Library/Application Support/com.shiftkit.mac/history.json
              </code>
              This log stores only:
            </p>
            <ul className="list-disc pl-5 space-y-1.5 text-xs sm:text-sm">
              <li>Original filename and target format</li>
              <li>Timestamp of conversion</li>
              <li>Outcome status (Completed, Failed, or Cancelled)</li>
              <li>File size and destination path on your Mac</li>
            </ul>
            <p>
              ShiftKit never stores complete file contents, images, text payloads, or sensitive document metadata in this history. You can clear this log at any time with the <strong>Clear History</strong> button.
            </p>
          </section>

          <section className="space-y-3">
            <h2 className="font-serif text-xl sm:text-2xl font-bold text-[#34312D]">
              4. System Permissions
            </h2>
            <p>
              ShiftKit requests Accessibility permissions in macOS System Settings solely to monitor the physical <strong>Shift</strong> key modifier during file dragging gestures. ShiftKit does not monitor keystrokes outside of drag operations and does not log your typing.
            </p>
          </section>

          <section className="space-y-3">
            <h2 className="font-serif text-xl sm:text-2xl font-bold text-[#34312D]">
              5. Analytics and Telemetry
            </h2>
            <p>
              The ShiftKit application does not include any third-party tracking libraries, behavioral advertising analytics, or user profiling. If optional local diagnostics are viewed in Settings, they show only system tool versions (such as local FFmpeg availability), never your personal files.
            </p>
          </section>

          <section className="space-y-3">
            <h2 className="font-serif text-xl sm:text-2xl font-bold text-[#34312D]">
              6. Open Source Verification
            </h2>
            <p>
              The complete Swift and AppKit source code for ShiftKit is openly available for audit and verification at:
              <br />
              <Link
                href="https://github.com/MdKasif0/ShiftKit"
                target="_blank"
                rel="noopener noreferrer"
                className="text-[#D98768] font-mono hover:underline"
              >
                https://github.com/MdKasif0/ShiftKit
              </Link>
            </p>
          </section>
        </div>
      </main>

      <Footer />
    </div>
  );
}
