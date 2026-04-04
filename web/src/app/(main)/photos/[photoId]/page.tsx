"use client";

import { use, useState } from "react";
import { usePhoto } from "@/lib/hooks/use-photos";
import { PhotoDetailView } from "@/components/photos/photo-detail-view";
import { AiGeneratePanel } from "@/components/ai/ai-generate-panel";
import { Skeleton } from "@/components/ui/skeleton";
import { Button } from "@/components/ui/button";
import { ArrowLeft } from "lucide-react";
import Link from "next/link";

export default function PhotoDetailPage({
  params,
}: {
  params: Promise<{ photoId: string }>;
}) {
  const { photoId } = use(params);
  const { data: photo, isLoading, error } = usePhoto(photoId);
  const [showAI, setShowAI] = useState(false);

  if (isLoading) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-8 w-32" />
        <Skeleton className="w-full h-[60vh] rounded-lg" />
      </div>
    );
  }

  if (error || !photo) {
    return (
      <div className="flex flex-col items-center justify-center py-20 text-muted-foreground">
        <p>写真が見つかりません</p>
        <Link href="/photos" className="mt-4">
          <Button variant="outline">写真一覧に戻る</Button>
        </Link>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <Link
        href="/photos"
        className="inline-flex items-center text-sm text-muted-foreground hover:text-foreground transition-colors"
      >
        <ArrowLeft className="mr-1 h-4 w-4" />
        写真一覧
      </Link>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className={showAI ? "lg:col-span-2" : "lg:col-span-3"}>
          <PhotoDetailView
            photo={photo}
            onGenerateAI={() => setShowAI(!showAI)}
          />
        </div>
        {showAI && (
          <div className="lg:col-span-1">
            <AiGeneratePanel
              photoId={photo.id}
              onClose={() => setShowAI(false)}
            />
          </div>
        )}
      </div>
    </div>
  );
}
