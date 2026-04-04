"use client";

import type { Album } from "@/lib/types/album";
import { Card, CardContent } from "@/components/ui/card";
import { FolderOpen } from "lucide-react";
import Link from "next/link";

interface AlbumCardProps {
  album: Album;
}

export function AlbumCard({ album }: AlbumCardProps) {
  return (
    <Link href={`/albums/${album.id}`}>
      <Card className="overflow-hidden hover:shadow-md transition-shadow cursor-pointer group">
        <div className="aspect-square bg-muted flex items-center justify-center">
          <FolderOpen className="h-12 w-12 text-muted-foreground group-hover:text-primary transition-colors" />
        </div>
        <CardContent className="p-3">
          <h3 className="font-medium truncate">{album.name}</h3>
          <p className="text-xs text-muted-foreground mt-0.5">
            {album.photo_count}枚
          </p>
        </CardContent>
      </Card>
    </Link>
  );
}
