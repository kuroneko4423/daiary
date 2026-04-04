"use client";

import { useCallback, useState } from "react";
import { useDropzone } from "react-dropzone";
import { Upload, X, Loader2, CheckCircle2, AlertCircle } from "lucide-react";
import { useUploadPhoto } from "@/lib/hooks/use-photos";
import { Button } from "@/components/ui/button";
import { MAX_FILE_SIZE } from "@/lib/utils/constants";
import { formatFileSize } from "@/lib/utils/format";
import { toast } from "sonner";

interface UploadItem {
  file: File;
  status: "pending" | "uploading" | "done" | "error";
  preview: string;
  error?: string;
}

export function PhotoUploadZone() {
  const [items, setItems] = useState<UploadItem[]>([]);
  const uploadPhoto = useUploadPhoto();

  const onDrop = useCallback(
    (acceptedFiles: File[]) => {
      const newItems: UploadItem[] = acceptedFiles.map((file) => ({
        file,
        status: "pending" as const,
        preview: URL.createObjectURL(file),
      }));
      setItems((prev) => [...prev, ...newItems]);

      // Upload each file
      newItems.forEach((item) => {
        setItems((prev) =>
          prev.map((i) =>
            i.file === item.file ? { ...i, status: "uploading" } : i
          )
        );

        uploadPhoto.mutate(
          { file: item.file },
          {
            onSuccess: () => {
              setItems((prev) =>
                prev.map((i) =>
                  i.file === item.file ? { ...i, status: "done" } : i
                )
              );
              toast.success(`${item.file.name} をアップロードしました`);
            },
            onError: (error) => {
              setItems((prev) =>
                prev.map((i) =>
                  i.file === item.file
                    ? { ...i, status: "error", error: String(error) }
                    : i
                )
              );
              toast.error(`${item.file.name} のアップロードに失敗しました`);
            },
          }
        );
      });
    },
    [uploadPhoto]
  );

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: {
      "image/jpeg": [".jpg", ".jpeg"],
      "image/png": [".png"],
      "image/webp": [".webp"],
      "image/heic": [".heic"],
    },
    maxSize: MAX_FILE_SIZE,
    onDropRejected: (rejections) => {
      rejections.forEach((rejection) => {
        const error = rejection.errors[0];
        if (error?.code === "file-too-large") {
          toast.error(`${rejection.file.name} は10MBを超えています`);
        } else if (error?.code === "file-invalid-type") {
          toast.error(`${rejection.file.name} はサポートされていない形式です`);
        }
      });
    },
  });

  const removeItem = (file: File) => {
    setItems((prev) => {
      const item = prev.find((i) => i.file === file);
      if (item) URL.revokeObjectURL(item.preview);
      return prev.filter((i) => i.file !== file);
    });
  };

  return (
    <div className="space-y-6">
      <div
        {...getRootProps()}
        className={`border-2 border-dashed rounded-xl p-12 text-center cursor-pointer transition-colors ${
          isDragActive
            ? "border-primary bg-primary/5"
            : "border-muted-foreground/25 hover:border-primary/50"
        }`}
      >
        <input {...getInputProps()} />
        <Upload className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
        <p className="text-lg font-medium">
          {isDragActive ? "ここにドロップ" : "写真をドラッグ&ドロップ"}
        </p>
        <p className="text-sm text-muted-foreground mt-1">
          またはクリックしてファイルを選択
        </p>
        <p className="text-xs text-muted-foreground mt-3">
          JPEG, PNG, WebP, HEIC（最大10MB）
        </p>
      </div>

      {items.length > 0 && (
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <h3 className="text-sm font-medium">
              アップロード ({items.filter((i) => i.status === "done").length}/
              {items.length})
            </h3>
            {items.every((i) => i.status === "done" || i.status === "error") && (
              <Button
                variant="ghost"
                size="sm"
                onClick={() => {
                  items.forEach((i) => URL.revokeObjectURL(i.preview));
                  setItems([]);
                }}
              >
                クリア
              </Button>
            )}
          </div>
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
            {items.map((item, idx) => (
              <div key={idx} className="relative aspect-square rounded-lg overflow-hidden group">
                <img
                  src={item.preview}
                  alt={item.file.name}
                  className="w-full h-full object-cover"
                />
                <div className="absolute inset-0 bg-black/40 flex items-center justify-center">
                  {item.status === "uploading" && (
                    <Loader2 className="h-6 w-6 text-white animate-spin" />
                  )}
                  {item.status === "done" && (
                    <CheckCircle2 className="h-6 w-6 text-green-400" />
                  )}
                  {item.status === "error" && (
                    <AlertCircle className="h-6 w-6 text-red-400" />
                  )}
                </div>
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    removeItem(item.file);
                  }}
                  className="absolute top-1 right-1 p-1 rounded-full bg-black/50 text-white opacity-0 group-hover:opacity-100 transition-opacity"
                >
                  <X className="h-3 w-3" />
                </button>
                <div className="absolute bottom-0 left-0 right-0 p-1.5 bg-black/50 text-white text-xs truncate">
                  {item.file.name} ({formatFileSize(item.file.size)})
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
