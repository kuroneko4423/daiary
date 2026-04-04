import { PhotoUploadZone } from "@/components/photos/photo-upload-zone";

export default function UploadPage() {
  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-bold">写真をアップロード</h1>
      <PhotoUploadZone />
    </div>
  );
}
