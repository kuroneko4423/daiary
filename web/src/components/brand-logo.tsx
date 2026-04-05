"use client";

import { cn } from "@/lib/utils";

interface BrandLogoProps {
  size?: "sm" | "md" | "lg";
  showTagline?: boolean;
  variant?: "light" | "dark" | "auto";
}

const sizeConfig = {
  sm: { logo: "text-2xl", tagline: "text-[0.55rem]", gap: "mt-1", spacing: "tracking-[0.18rem]" },
  md: { logo: "text-4xl", tagline: "text-[0.65rem]", gap: "mt-1.5", spacing: "tracking-[0.22rem]" },
  lg: { logo: "text-5xl", tagline: "text-sm", gap: "mt-2", spacing: "tracking-[0.25rem]" },
};

export function BrandLogo({ size = "md", showTagline = true, variant = "auto" }: BrandLogoProps) {
  const config = sizeConfig[size];

  const textColorClass =
    variant === "dark"
      ? "text-[#f5efe8]"
      : variant === "light"
        ? "text-[#2d2420]"
        : "text-[#2d2420] dark:text-[#f5efe8]";

  const taglineColorClass =
    variant === "dark"
      ? "text-[#c4956a]/60"
      : variant === "light"
        ? "text-[#9a9590]"
        : "text-[#9a9590] dark:text-[#c4956a]/60";

  return (
    <div className="text-center select-none">
      <div
        className={cn(config.logo, textColorClass, "leading-tight")}
        style={{ fontFamily: "var(--font-playfair), Georgia, serif" }}
      >
        <span className="font-normal">d</span>
        <span className="font-bold italic text-[#c4956a]">AI</span>
        <span className="font-normal">ary</span>
      </div>
      {showTagline && (
        <div
          className={cn(config.tagline, config.gap, config.spacing, taglineColorClass, "font-light")}
          style={{ fontFamily: "var(--font-noto-sans-jp), sans-serif" }}
        >
          写真に、言葉を添えて。
        </div>
      )}
    </div>
  );
}
