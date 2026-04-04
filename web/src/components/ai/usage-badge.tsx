"use client";

import { useUsage } from "@/lib/hooks/use-ai";
import { Badge } from "@/components/ui/badge";
import { Sparkles } from "lucide-react";

export function UsageBadge() {
  const { data: usage } = useUsage();

  if (!usage) return null;

  return (
    <Badge variant={usage.remaining > 0 ? "secondary" : "destructive"} className="gap-1">
      <Sparkles className="h-3 w-3" />
      {usage.is_premium
        ? "無制限"
        : `残り ${usage.remaining}/${usage.limit} 回`}
    </Badge>
  );
}
