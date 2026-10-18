import React from "react";
import { Navbar } from "@/components/Navbar";
import { Hero } from "@/components/Hero";
import { InteractiveDemo } from "@/components/InteractiveDemo";
import { EditorialFeatures } from "@/components/EditorialFeatures";
import { HowItWorks } from "@/components/HowItWorks";
import { AppShowcase } from "@/components/AppShowcase";
import { PrivacySection } from "@/components/PrivacySection";
import { SystemRequirements } from "@/components/SystemRequirements";
import { FAQ } from "@/components/FAQ";
import { DownloadSection } from "@/components/DownloadSection";
import { Footer } from "@/components/Footer";

export default function Home() {
  return (
    <div className="min-h-screen bg-[#FAF8F3] text-[#34312D] flex flex-col justify-between selection:bg-[#F5D5C2]">
      <Navbar />
      <main id="main-content" className="flex-grow">
        <Hero />
        <InteractiveDemo />
        <EditorialFeatures />
        <HowItWorks />
        <AppShowcase />
        <PrivacySection />
        <SystemRequirements />
        <FAQ />
        <DownloadSection />
      </main>
      <Footer />
    </div>
  );
}
