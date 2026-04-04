"use client";

import type { Photo } from "@/lib/types/photo";
import { Heart } from "lucide-react";
import { cn } from "@/lib/utils";
import Link from "next/link";

interface PhotoCardProps {
  photo: Photo;
  selected?: boolean;
  selectionMode?: boolean;
  onSelect?: (photoId: string) => void;
}

export function PhotoCard({
  photo,
  selected,
  selectionMode,
  onSelect,
}: PhotoCardProps) {
  const imageUrl = photo.url || "";

  if (selectionMode) {
    return (
      <div
        className={cn(
          "relative aspect-square rounded-lg overflow-hidden cursor-pointer border-2 transition-all",
          selected ? "border-primary ring-2 ring-primary/30" : "border-transparent"
        )}
        onClick={() => onSelect?.(photo.id)}
      >
        {imageUrl ? (
          <img
            src={imageUrl}
            alt={photo.original_filename || "写真"}
            className="w-full h-full object-cover"
          />
        ) : (
          <div className="w-full h-full bg-muted flex items-center justify-center text-muted-foreground text-xs">
            No image
          </div>
        )}
        {photo.is_favorite && (
          <Heart className="absolute top-2 right-2 h-4 w-4 fill-red-500 text-red-500" />
        )}
        {selected && (
          <div className="absolute inset-0 bg-primary/20 flex items-center justify-center">
            <div className="h-6 w-6 rounded-full bg-primary text-primary-foreground flex items-center justify-center text-xs">
              ✓
            </div>
          </div>
        )}
      </div>
    );
  }

  return (
    <Link
      href={`/photos/${photo.id}`}
      className="relative aspect-square rounded-lg overflow-hidden group block"
    >
      {imageUrl ? (
        <img
          src={imageUrl}
          alt={photo.original_filename || "写真"}
          className="w-full h-full object-cover transition-transform group-hover:scale-105"
        />
      ) : (
        <div className="w-full h-full bg-muted flex items-center justify-center text-muted-foreground text-xs">
          No image
        </div>
      )}
      {photo.is_favorite && (
        <Heart className="absolute top-2 right-2 h-4 w-4 fill-red-500 text-red-500" />
      )}
      <div className="absolute inset-0 bg-black/0 group-hover:bg-black/10 transition-colors" />
    </Link>
  );
}
