"use client";

import type { Photo } from "@/lib/types/photo";
import { FavoriteButton } from "./favorite-button";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { Trash2, Sparkles, Info } from "lucide-react";
import { useDeletePhoto } from "@/lib/hooks/use-photos";
import { useRouter } from "next/navigation";
import { formatFileSize, formatDateTime } from "@/lib/utils/format";
import { toast } from "sonner";
import { useState } from "react";

interface PhotoDetailViewProps {
  photo: Photo;
  onGenerateAI?: () => void;
}

export function PhotoDetailView({ photo, onGenerateAI }: PhotoDetailViewProps) {
  const deletePhoto = useDeletePhoto();
  const router = useRouter();
  const [showInfo, setShowInfo] = useState(false);

  const handleDelete = () => {
    if (!confirm("この写真を削除しますか？")) return;
    deletePhoto.mutate(photo.id, {
      onSuccess: () => {
        toast.success("写真を削除しました");
        router.push("/photos");
      },
      onError: () => {
        toast.error("削除に失敗しました");
      },
    });
  };

  return (
    <div className="space-y-4">
      <div className="relative rounded-lg overflow-hidden bg-muted">
        {photo.url ? (
          <img
            src={photo.url}
            alt={photo.original_filename || "写真"}
            className="w-full max-h-[70vh] object-contain mx-auto"
          />
        ) : (
          <div className="w-full h-64 flex items-center justify-center text-muted-foreground">
            画像を読み込めません
          </div>
        )}
      </div>

      <div className="flex items-center gap-2">
        <FavoriteButton photoId={photo.id} isFavorite={photo.is_favorite} />
        <Button variant="outline" onClick={onGenerateAI}>
          <Sparkles className="mr-2 h-4 w-4" />
          AI生成
        </Button>
        <Button variant="outline" onClick={() => setShowInfo(!showInfo)}>
          <Info className="mr-2 h-4 w-4" />
          詳細
        </Button>
        <div className="flex-1" />
        <Button
          variant="ghost"
          className="text-destructive"
          onClick={handleDelete}
          disabled={deletePhoto.isPending}
        >
          <Trash2 className="mr-2 h-4 w-4" />
          削除
        </Button>
      </div>

      {photo.ai_tags.length > 0 && (
        <div className="flex flex-wrap gap-1.5">
          {photo.ai_tags.map((tag, i) => (
            <Badge key={i} variant="secondary">
              {tag}
            </Badge>
          ))}
        </div>
      )}

      {showInfo && (
        <div className="rounded-lg border p-4 space-y-2 text-sm">
          <h3 className="font-medium">ファイル情報</h3>
          <Separator />
          <div className="grid grid-cols-2 gap-2 text-muted-foreground">
            {photo.original_filename && (
              <>
                <span>ファイル名</span>
                <span>{photo.original_filename}</span>
              </>
            )}
            {photo.file_size && (
              <>
                <span>サイズ</span>
                <span>{formatFileSize(photo.file_size)}</span>
              </>
            )}
            {photo.width && photo.height && (
              <>
                <span>解像度</span>
                <span>
                  {photo.width} x {photo.height}
                </span>
              </>
            )}
            <span>撮影日</span>
            <span>{formatDateTime(photo.created_at)}</span>
          </div>
          {photo.exif_data && Object.keys(photo.exif_data).length > 0 && (
            <>
              <Separator />
              <h4 className="font-medium">EXIF データ</h4>
              <div className="grid grid-cols-2 gap-2 text-muted-foreground">
                {Object.entries(photo.exif_data).map(([key, value]) => (
                  <div key={key} className="contents">
                    <span>{key}</span>
                    <span>{String(value)}</span>
                  </div>
                ))}
              </div>
            </>
          )}
        </div>
      )}
    </div>
  );
}
