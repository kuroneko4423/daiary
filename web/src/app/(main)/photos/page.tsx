"use client";

import { useState, useMemo } from "react";
import { usePhotos, useSearchPhotos, useDeletePhoto, useUpdatePhoto } from "@/lib/hooks/use-photos";
import { PhotoGrid } from "@/components/photos/photo-grid";
import { Button } from "@/components/ui/button";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Heart, Trash2, X, Loader2 } from "lucide-react";
import { useSearchParams } from "next/navigation";
import { toast } from "sonner";

export default function PhotosPage() {
  const searchParams = useSearchParams();
  const searchQuery = searchParams.get("q") || "";

  const [favoritesOnly, setFavoritesOnly] = useState(false);
  const [selectionMode, setSelectionMode] = useState(false);
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());

  const photosQuery = usePhotos({
    favorites_only: favoritesOnly,
    limit: 40,
  });

  const searchResults = useSearchPhotos({
    q: searchQuery,
    limit: 40,
  });

  const deletePhoto = useDeletePhoto();
  const updatePhoto = useUpdatePhoto();

  const isSearching = !!searchQuery;
  const activeQuery = isSearching ? searchResults : photosQuery;
  const photos = useMemo(() => {
    if (isSearching) return searchResults.data || [];
    return photosQuery.data?.pages?.flat() || [];
  }, [isSearching, searchResults.data, photosQuery.data]);

  const handleSelect = (photoId: string) => {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(photoId)) next.delete(photoId);
      else next.add(photoId);
      return next;
    });
  };

  const handleBulkDelete = async () => {
    if (!confirm(`${selectedIds.size}枚の写真を削除しますか？`)) return;
    for (const id of selectedIds) {
      deletePhoto.mutate(id);
    }
    setSelectedIds(new Set());
    setSelectionMode(false);
    toast.success("写真を削除しました");
  };

  const handleBulkFavorite = async () => {
    for (const id of selectedIds) {
      updatePhoto.mutate({ photoId: id, data: { is_favorite: true } });
    }
    setSelectedIds(new Set());
    setSelectionMode(false);
    toast.success("お気に入りに追加しました");
  };

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">
          {isSearching ? `「${searchQuery}」の検索結果` : "写真"}
        </h1>
        <div className="flex items-center gap-2">
          {selectionMode ? (
            <>
              <span className="text-sm text-muted-foreground">
                {selectedIds.size}枚選択中
              </span>
              <Button
                variant="outline"
                size="sm"
                onClick={handleBulkFavorite}
                disabled={selectedIds.size === 0}
              >
                <Heart className="h-4 w-4" />
              </Button>
              <Button
                variant="outline"
                size="sm"
                onClick={handleBulkDelete}
                disabled={selectedIds.size === 0}
                className="text-destructive"
              >
                <Trash2 className="h-4 w-4" />
              </Button>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => {
                  setSelectionMode(false);
                  setSelectedIds(new Set());
                }}
              >
                <X className="h-4 w-4" />
              </Button>
            </>
          ) : (
            <>
              {!isSearching && (
                <Tabs
                  value={favoritesOnly ? "favorites" : "all"}
                  onValueChange={(v) => setFavoritesOnly(v === "favorites")}
                >
                  <TabsList>
                    <TabsTrigger value="all">すべて</TabsTrigger>
                    <TabsTrigger value="favorites">お気に入り</TabsTrigger>
                  </TabsList>
                </Tabs>
              )}
              <Button
                variant="outline"
                size="sm"
                onClick={() => setSelectionMode(true)}
              >
                選択
              </Button>
            </>
          )}
        </div>
      </div>

      <PhotoGrid
        photos={photos}
        isLoading={activeQuery.isLoading}
        selectedIds={selectedIds}
        selectionMode={selectionMode}
        onSelect={handleSelect}
      />

      {!isSearching && photosQuery.hasNextPage && (
        <div className="flex justify-center pt-4">
          <Button
            variant="outline"
            onClick={() => photosQuery.fetchNextPage()}
            disabled={photosQuery.isFetchingNextPage}
          >
            {photosQuery.isFetchingNextPage && (
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
            )}
            もっと読み込む
          </Button>
        </div>
      )}
    </div>
  );
}
