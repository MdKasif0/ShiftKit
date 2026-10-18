import React from "react";

interface LogoProps {
  className?: string;
  size?: number;
}

export function ShiftKitLogo({ className = "", size = 32 }: LogoProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 48 48"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      className={className}
      aria-label="ShiftKit Logo"
      role="img"
    >
      {/* Outer subtle ring */}
      <circle cx="24" cy="24" r="22" stroke="#E5D8C7" strokeWidth="1.5" strokeDasharray="3 3" />
      
      {/* Background circular surface */}
      <circle cx="24" cy="24" r="20" fill="#F3EEE4" />
      
      {/* Radial action petals / segments */}
      {/* Top segment - Terracotta */}
      <path
        d="M24 7C29.5 7 34.5 9.5 37.8 13.5L29 20C27.7 18.5 25.9 17.5 24 17.5V7Z"
        fill="#D98768"
      />
      {/* Bottom Right - Deep Olive */}
      <path
        d="M40.5 24C40.5 29.5 38 34.5 34 37.8L27.5 29C29 27.7 30 25.9 30 24H40.5Z"
        fill="#465343"
      />
      {/* Bottom Left - Muted Sage */}
      <path
        d="M24 41C18.5 41 13.5 38.5 10.2 34.5L19 28C20.3 29.5 22.1 30.5 24 30.5V41Z"
        fill="#A8B5A0"
      />
      {/* Top Left - Warm Peach */}
      <path
        d="M7.5 24C7.5 18.5 10 13.5 14 10.2L20.5 19C19 20.3 18 22.1 18 24H7.5Z"
        fill="#F5D5C2"
      />

      {/* Center hub */}
      <circle cx="24" cy="24" r="9.5" fill="#FAF8F3" stroke="#E5D8C7" strokeWidth="1.5" />
      
      {/* Shift glyph: up arrow with base */}
      <path
        d="M24 18.5L27.5 22.5H25.5V26H22.5V22.5H20.5L24 18.5Z"
        fill="#34312D"
      />
      <rect x="22.5" y="27.5" width="3" height="1.2" rx="0.6" fill="#34312D" />
    </svg>
  );
}
