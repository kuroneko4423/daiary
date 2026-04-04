"use client";

import { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Separator } from "@/components/ui/separator";
import { StyleSelector } from "./style-selector";
import { LanguageSelector } from "./language-selector";
import { LengthSelector } from "./length-selector";
import { UsageBadge } from "./usage-badge";
import { ResultCard } from "./result-card";
import { useGenerateHashtags, useGenerateCaption } from "@/lib/hooks/use-ai";
import { useSettingsStore } from "@/lib/stores/settings-store";
import { Loader2, Hash, MessageSquare, X } from "lucide-react";
import { toast } from "sonner";

interface AiGeneratePanelProps {
  photoId: string;
  onClose?: () => void;
}

export function AiGeneratePanel({ photoId, onClose }: AiGeneratePanelProps) {
  const settings = useSettingsStore();

  const [style, setStyle] = useState(settings.defaultStyle);
  const [language, setLanguage] = useState(settings.defaultLanguage);
  const [length, setLength] = useState(settings.defaultLength);
  const [customPrompt, setCustomPrompt] = useState("");

  const [hashtags, setHashtags] = useState<string[] | null>(null);
  const [caption, setCaption] = useState<string | null>(null);

  const generateHashtags = useGenerateHashtags();
  const generateCaption = useGenerateCaption();

  const handleGenerateHashtags = () => {
    generateHashtags.mutate(
      {
        photo_id: photoId,
        language,
        count: 15,
        usage: "instagram",
      },
      {
        onSuccess: (data) => {
          setHashtags(data.hashtags);
        },
        onError: (error) => {
          const message =
            (error as { response?: { status?: number } })?.response?.status === 429
              ? "本日のAI生成回数の上限に達しました"
              : "ハッシュタグの生成に失敗しました";
          toast.error(message);
        },
      }
    );
  };

  const handleGenerateCaption = () => {
    generateCaption.mutate(
      {
        photo_id: photoId,
        language,
        style,
        length,
        custom_prompt: style === "custom" ? customPrompt : undefined,
      },
      {
        onSuccess: (data) => {
          setCaption(data.caption);
        },
        onError: (error) => {
          const message =
            (error as { response?: { status?: number } })?.response?.status === 429
              ? "本日のAI生成回数の上限に達しました"
              : "キャプションの生成に失敗しました";
          toast.error(message);
        },
      }
    );
  };

  return (
    <Card>
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <CardTitle className="text-lg">AI生成</CardTitle>
          <div className="flex items-center gap-2">
            <UsageBadge />
            {onClose && (
              <Button variant="ghost" size="sm" onClick={onClose}>
                <X className="h-4 w-4" />
              </Button>
            )}
          </div>
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        <StyleSelector value={style} onChange={setStyle} />

        {style === "custom" && (
          <div className="space-y-2">
            <label className="text-sm font-medium">カスタムプロンプト</label>
            <Textarea
              placeholder="生成の指示を入力..."
              value={customPrompt}
              onChange={(e) => setCustomPrompt(e.target.value)}
              rows={3}
            />
          </div>
        )}

        <LanguageSelector value={language} onChange={setLanguage} />
        <LengthSelector value={length} onChange={setLength} />

        <Separator />

        <div className="flex gap-2">
          <Button
            onClick={handleGenerateHashtags}
            disabled={generateHashtags.isPending}
            className="flex-1"
            variant="outline"
          >
            {generateHashtags.isPending ? (
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
            ) : (
              <Hash className="mr-2 h-4 w-4" />
            )}
            ハッシュタグ
          </Button>
          <Button
            onClick={handleGenerateCaption}
            disabled={generateCaption.isPending}
            className="flex-1"
          >
            {generateCaption.isPending ? (
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
            ) : (
              <MessageSquare className="mr-2 h-4 w-4" />
            )}
            キャプション
          </Button>
        </div>

        {hashtags && <ResultCard type="hashtags" hashtags={hashtags} />}
        {caption && <ResultCard type="caption" caption={caption} />}
      </CardContent>
    </Card>
  );
}
