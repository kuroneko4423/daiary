"use client";

import { useState } from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { usePhotos } from "@/lib/hooks/use-photos";
import { useAddPhotosToAlbum } from "@/lib/hooks/use-albums";
import { PhotoGrid } from "@/components/photos/photo-grid";
import { Loader2 } from "lucide-react";
import { toast } from "sonner";

interface PhotoPickerDialogProps {
  albumId: string;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function PhotoPickerDialog({
  albumId,
  open,
  onOpenChange,
}: PhotoPickerDialogProps) {
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const photosQuery = usePhotos({ limit: 100 });
  const addPhotos = useAddPhotosToAlbum();

  const photos = photosQuery.data?.pages?.flat() || [];

  const handleSelect = (photoId: string) => {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(photoId)) next.delete(photoId);
      else next.add(photoId);
      return next;
    });
  };

  const handleAdd = () => {
    if (selectedIds.size === 0) return;
    addPhotos.mutate(
      { albumId, data: { photo_ids: Array.from(selectedIds) } },
      {
        onSuccess: (data) => {
          toast.success(`${data.added}枚の写真を追加しました`);
          setSelectedIds(new Set());
          onOpenChange(false);
        },
        onError: () => {
          toast.error("写真の追加に失敗しました");
        },
      }
    );
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-3xl max-h-[80vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>写真を追加</DialogTitle>
        </DialogHeader>
        <PhotoGrid
          photos={photos}
          isLoading={photosQuery.isLoading}
          selectedIds={selectedIds}
          selectionMode={true}
          onSelect={handleSelect}
        />
        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            キャンセル
          </Button>
          <Button
            onClick={handleAdd}
            disabled={selectedIds.size === 0 || addPhotos.isPending}
          >
            {addPhotos.isPending && (
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
            )}
            {selectedIds.size}枚を追加
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
