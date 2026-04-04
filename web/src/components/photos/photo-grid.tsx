"use client";

import type { Photo } from "@/lib/types/photo";
import { PhotoCard } from "./photo-card";
import { Skeleton } from "@/components/ui/skeleton";

interface PhotoGridProps {
  photos: Photo[];
  isLoading?: boolean;
  selectedIds?: Set<string>;
  selectionMode?: boolean;
  onSelect?: (photoId: string) => void;
}

export function PhotoGrid({
  photos,
  isLoading,
  selectedIds,
  selectionMode,
  onSelect,
}: PhotoGridProps) {
  if (isLoading) {
    return (
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-3">
        {Array.from({ length: 12 }).map((_, i) => (
          <Skeleton key={i} className="aspect-square rounded-lg" />
        ))}
      </div>
    );
  }

  if (photos.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-20 text-muted-foreground">
        <p className="text-lg">写真がありません</p>
        <p className="text-sm mt-1">写真をアップロードして始めましょう</p>
      </div>
    );
  }

  return (
    <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-3">
      {photos.map((photo) => (
        <PhotoCard
          key={photo.id}
          photo={photo}
          selected={selectedIds?.has(photo.id)}
          selectionMode={selectionMode}
          onSelect={onSelect}
        />
      ))}
    </div>
  );
}
