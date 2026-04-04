"use client";

import { useState } from "react";
import { useAlbums } from "@/lib/hooks/use-albums";
import { AlbumGrid } from "@/components/albums/album-grid";
import { AlbumCreateDialog } from "@/components/albums/album-create-dialog";
import { Button } from "@/components/ui/button";
import { Plus } from "lucide-react";

export default function AlbumsPage() {
  const [createOpen, setCreateOpen] = useState(false);
  const { data: albums, isLoading } = useAlbums();

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">アルバム</h1>
        <Button onClick={() => setCreateOpen(true)}>
          <Plus className="mr-2 h-4 w-4" />
          新規作成
        </Button>
      </div>

      <AlbumGrid albums={albums || []} isLoading={isLoading} />
      <AlbumCreateDialog open={createOpen} onOpenChange={setCreateOpen} />
    </div>
  );
}
