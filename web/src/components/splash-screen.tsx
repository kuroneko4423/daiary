"use client";

import { BrandLogo } from "./brand-logo";

export function SplashScreen() {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center animate-fade-in">
      {/* Light background */}
      <div
        className="absolute inset-0 dark:hidden"
        style={{
          background: "linear-gradient(180deg, #f5efe8 0%, #ebe3d8 100%)",
        }}
      >
        {/* Warm glow - top right */}
        <div
          className="absolute -top-10 -right-10 w-40 h-40 sm:w-60 sm:h-60 rounded-full"
          style={{
            background: "radial-gradient(circle, rgba(232,168,124,0.1) 0%, transparent 70%)",
          }}
        />
      </div>

      {/* Dark background */}
      <div
        className="absolute inset-0 hidden dark:block"
        style={{
          background: "linear-gradient(180deg, #1a1714 0%, #2d2420 100%)",
        }}
      >
        {/* Gold glow - bottom left */}
        <div
          className="absolute -bottom-10 -left-10 w-40 h-40 sm:w-60 sm:h-60 rounded-full"
          style={{
            background: "radial-gradient(circle, rgba(196,149,106,0.06) 0%, transparent 70%)",
          }}
        />
      </div>

      {/* Logo */}
      <div className="relative z-10">
        <BrandLogo size="lg" />
      </div>
    </div>
  );
}
