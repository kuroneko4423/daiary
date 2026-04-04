"use client";

import { useSettingsStore } from "@/lib/stores/settings-store";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { GENERATION_STYLES, LANGUAGES, GENERATION_LENGTHS } from "@/lib/utils/constants";

export function AiDefaultsSection() {
  const { defaultLanguage, defaultStyle, defaultLength, setDefaultLanguage, setDefaultStyle, setDefaultLength } =
    useSettingsStore();

  return (
    <div className="space-y-4">
      <h3 className="text-sm font-medium">AI生成のデフォルト設定</h3>

      <div className="flex items-center justify-between">
        <Label>デフォルト言語</Label>
        <Select value={defaultLanguage} onValueChange={(v) => v && setDefaultLanguage(v)}>
          <SelectTrigger className="w-40">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            {LANGUAGES.map((lang) => (
              <SelectItem key={lang.value} value={lang.value}>
                {lang.label}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div className="flex items-center justify-between">
        <Label>デフォルトスタイル</Label>
        <Select value={defaultStyle} onValueChange={(v) => v && setDefaultStyle(v)}>
          <SelectTrigger className="w-40">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            {GENERATION_STYLES.map((style) => (
              <SelectItem key={style.value} value={style.value}>
                {style.label}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div className="flex items-center justify-between">
        <Label>デフォルト長さ</Label>
        <Select value={defaultLength} onValueChange={(v) => v && setDefaultLength(v)}>
          <SelectTrigger className="w-40">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            {GENERATION_LENGTHS.map((len) => (
              <SelectItem key={len.value} value={len.value}>
                {len.label}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>
    </div>
  );
}
