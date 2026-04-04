"use client";

import { use, useState } from "react";
import { useAlbum, useDeleteAlbum, useRemovePhotoFromAlbum } from "@/lib/hooks/use-albums";
import { PhotoGrid } from "@/components/photos/photo-grid";
import { PhotoPickerDialog } from "@/components/albums/photo-picker-dialog";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { ArrowLeft, Plus, Trash2 } from "lucide-react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { toast } from "sonner";

export default function AlbumDetailPage({
  params,
}: {
  params: Promise<{ albumId: string }>;
}) {
  const { albumId } = use(params);
  const { data: album, isLoading } = useAlbum(albumId);
  const deleteAlbum = useDeleteAlbum();
  const removePhoto = useRemovePhotoFromAlbum();
  const router = useRouter();
  const [pickerOpen, setPickerOpen] = useState(false);
  const [selectionMode, setSelectionMode] = useState(false);
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());

  const handleDeleteAlbum = () => {
    if (!confirm("このアルバムを削除しますか？写真は削除されません。")) return;
    deleteAlbum.mutate(albumId, {
      onSuccess: () => {
        toast.success("アルバムを削除しました");
        router.push("/albums");
      },
    });
  };

  const handleSelect = (photoId: string) => {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(photoId)) next.delete(photoId);
      else next.add(photoId);
      return next;
    });
  };

  const handleRemoveSelected = () => {
    if (!confirm(`${selectedIds.size}枚の写真をアルバムから削除しますか？`)) return;
    for (const photoId of selectedIds) {
      removePhoto.mutate({ albumId, photoId });
    }
    setSelectedIds(new Set());
    setSelectionMode(false);
    toast.success("写真を削除しました");
  };

  if (isLoading) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-8 w-48" />
        <div className="grid grid-cols-3 gap-3">
          {Array.from({ length: 6 }).map((_, i) => (
            <Skeleton key={i} className="aspect-square rounded-lg" />
          ))}
        </div>
      </div>
    );
  }

  if (!album) {
    return (
      <div className="text-center py-20 text-muted-foreground">
        <p>アルバムが見つかりません</p>
        <Link href="/albums" className="mt-4 inline-block">
          <Button variant="outline">アルバム一覧に戻る</Button>
        </Link>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <Link
        href="/albums"
        className="inline-flex items-center text-sm text-muted-foreground hover:text-foreground transition-colors"
      >
        <ArrowLeft className="mr-1 h-4 w-4" />
        アルバム一覧
      </Link>

      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">{album.name}</h1>
          <p className="text-sm text-muted-foreground">{album.photo_count}枚</p>
        </div>
        <div className="flex items-center gap-2">
          {selectionMode ? (
            <>
              <Button
                variant="outline"
                size="sm"
                onClick={handleRemoveSelected}
                disabled={selectedIds.size === 0}
                className="text-destructive"
              >
                <Trash2 className="mr-1 h-4 w-4" />
                削除 ({selectedIds.size})
              </Button>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => {
                  setSelectionMode(false);
                  setSelectedIds(new Set());
                }}
              >
                キャンセル
              </Button>
            </>
          ) : (
            <>
              <Button variant="outline" size="sm" onClick={() => setPickerOpen(true)}>
                <Plus className="mr-1 h-4 w-4" />
                写真を追加
              </Button>
              <Button
                variant="outline"
                size="sm"
                onClick={() => setSelectionMode(true)}
              >
                選択
              </Button>
              <Button
                variant="ghost"
                size="sm"
                className="text-destructive"
                onClick={handleDeleteAlbum}
              >
                <Trash2 className="h-4 w-4" />
              </Button>
            </>
          )}
        </div>
      </div>

      <PhotoGrid
        photos={album.photos || []}
        selectedIds={selectedIds}
        selectionMode={selectionMode}
        onSelect={handleSelect}
      />

      <PhotoPickerDialog
        albumId={albumId}
        open={pickerOpen}
        onOpenChange={setPickerOpen}
      />
    </div>
  );
}
