"use client";

import { Heart } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useUpdatePhoto } from "@/lib/hooks/use-photos";
import { cn } from "@/lib/utils";

interface FavoriteButtonProps {
  photoId: string;
  isFavorite: boolean;
  size?: "sm" | "default";
}

export function FavoriteButton({ photoId, isFavorite, size = "default" }: FavoriteButtonProps) {
  const updatePhoto = useUpdatePhoto();

  const handleToggle = () => {
    updatePhoto.mutate({
      photoId,
      data: { is_favorite: !isFavorite },
    });
  };

  return (
    <Button
      variant="ghost"
      size={size === "sm" ? "sm" : "default"}
      onClick={handleToggle}
      disabled={updatePhoto.isPending}
    >
      <Heart
        className={cn(
          size === "sm" ? "h-4 w-4" : "h-5 w-5",
          isFavorite && "fill-red-500 text-red-500"
        )}
      />
    </Button>
  );
}
