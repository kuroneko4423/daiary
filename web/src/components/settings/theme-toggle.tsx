"use client";

import { useTheme } from "next-themes";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Label } from "@/components/ui/label";

export function ThemeToggle() {
  const { theme, setTheme } = useTheme();

  return (
    <div className="flex items-center justify-between">
      <Label>テーマ</Label>
      <Select value={theme} onValueChange={(v) => v && setTheme(v)}>
        <SelectTrigger className="w-40">
          <SelectValue />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="light">ライト</SelectItem>
          <SelectItem value="dark">ダーク</SelectItem>
          <SelectItem value="system">システム</SelectItem>
        </SelectContent>
      </Select>
    </div>
  );
}
