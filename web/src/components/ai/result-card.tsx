"use client";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Copy, Check } from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";

interface HashtagResultProps {
  type: "hashtags";
  hashtags: string[];
}

interface CaptionResultProps {
  type: "caption";
  caption: string;
}

type ResultCardProps = HashtagResultProps | CaptionResultProps;

export function ResultCard(props: ResultCardProps) {
  const [copied, setCopied] = useState(false);

  const handleCopy = () => {
    const text =
      props.type === "hashtags"
        ? props.hashtags.map((h) => `#${h}`).join(" ")
        : props.caption;

    navigator.clipboard.writeText(text);
    setCopied(true);
    toast.success("コピーしました");
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <Card>
      <CardHeader className="pb-2">
        <div className="flex items-center justify-between">
          <CardTitle className="text-sm">
            {props.type === "hashtags" ? "ハッシュタグ" : "キャプション"}
          </CardTitle>
          <Button variant="ghost" size="sm" onClick={handleCopy}>
            {copied ? (
              <Check className="h-4 w-4 text-green-500" />
            ) : (
              <Copy className="h-4 w-4" />
            )}
          </Button>
        </div>
      </CardHeader>
      <CardContent>
        {props.type === "hashtags" ? (
          <div className="flex flex-wrap gap-1.5">
            {props.hashtags.map((tag, i) => (
              <Badge key={i} variant="secondary">
                #{tag}
              </Badge>
            ))}
          </div>
        ) : (
          <p className="text-sm whitespace-pre-wrap">{props.caption}</p>
        )}
      </CardContent>
    </Card>
  );
}
