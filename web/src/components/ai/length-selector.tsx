"use client";

import { GENERATION_LENGTHS } from "@/lib/utils/constants";
import { cn } from "@/lib/utils";

interface LengthSelectorProps {
  value: string;
  onChange: (value: string) => void;
}

export function LengthSelector({ value, onChange }: LengthSelectorProps) {
  return (
    <div className="space-y-2">
      <label className="text-sm font-medium">長さ</label>
      <div className="flex gap-2">
        {GENERATION_LENGTHS.map((len) => (
          <button
            key={len.value}
            type="button"
            onClick={() => onChange(len.value)}
            className={cn(
              "flex-1 px-3 py-1.5 rounded-md text-sm border transition-colors",
              value === len.value
                ? "bg-primary text-primary-foreground border-primary"
                : "bg-card border-border hover:bg-accent"
            )}
          >
            {len.label}
          </button>
        ))}
      </div>
    </div>
  );
}
