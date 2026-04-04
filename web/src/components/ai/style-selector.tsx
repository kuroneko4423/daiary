"use client";

import { GENERATION_STYLES } from "@/lib/utils/constants";
import { cn } from "@/lib/utils";

interface StyleSelectorProps {
  value: string;
  onChange: (value: string) => void;
}

export function StyleSelector({ value, onChange }: StyleSelectorProps) {
  return (
    <div className="space-y-2">
      <label className="text-sm font-medium">スタイル</label>
      <div className="flex flex-wrap gap-2">
        {GENERATION_STYLES.map((style) => (
          <button
            key={style.value}
            type="button"
            onClick={() => onChange(style.value)}
            className={cn(
              "px-3 py-1.5 rounded-full text-sm border transition-colors",
              value === style.value
                ? "bg-primary text-primary-foreground border-primary"
                : "bg-card border-border hover:bg-accent"
            )}
          >
            {style.label}
          </button>
        ))}
      </div>
    </div>
  );
}
