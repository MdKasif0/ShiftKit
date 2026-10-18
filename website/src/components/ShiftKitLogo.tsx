import React from "react";
import Image from "next/image";

interface LogoProps {
  className?: string;
  size?: number;
}

export function ShiftKitLogo({ className = "", size = 32 }: LogoProps) {
  return (
    <div
      className={`relative inline-block shrink-0 ${className}`}
      style={{ width: size, height: size }}
    >
      <Image
        src="/logo.png"
        alt="ShiftKit Logo"
        width={size}
        height={size}
        className="w-full h-full object-contain drop-shadow-xs"
        priority
      />
    </div>
  );
}
