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
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { useCreateAlbum } from "@/lib/hooks/use-albums";
import { Loader2 } from "lucide-react";
import { toast } from "sonner";

interface AlbumCreateDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function AlbumCreateDialog({ open, onOpenChange }: AlbumCreateDialogProps) {
  const [name, setName] = useState("");
  const [isPublic, setIsPublic] = useState(false);
  const createAlbum = useCreateAlbum();

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;

    createAlbum.mutate(
      { name: name.trim(), is_public: isPublic },
      {
        onSuccess: () => {
          toast.success("アルバムを作成しました");
          setName("");
          setIsPublic(false);
          onOpenChange(false);
        },
        onError: () => {
          toast.error("アルバムの作成に失敗しました");
        },
      }
    );
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>新しいアルバム</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="album-name">アルバム名</Label>
            <Input
              id="album-name"
              placeholder="アルバム名を入力"
              value={name}
              onChange={(e) => setName(e.target.value)}
              required
              autoFocus
            />
          </div>
          <div className="flex items-center justify-between">
            <Label htmlFor="album-public">公開する</Label>
            <Switch
              id="album-public"
              checked={isPublic}
              onCheckedChange={setIsPublic}
            />
          </div>
          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={() => onOpenChange(false)}
            >
              キャンセル
            </Button>
            <Button type="submit" disabled={createAlbum.isPending || !name.trim()}>
              {createAlbum.isPending && (
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              )}
              作成
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
