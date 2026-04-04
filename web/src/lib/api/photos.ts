import type { Photo, PhotoListParams, PhotoSearchParams, PhotoUpdate } from "@/lib/types/photo";
import apiClient from "./client";

export async function getPhotos(params: PhotoListParams = {}): Promise<Photo[]> {
  const response = await apiClient.get<Photo[]>("/photos/", { params });
  return response.data;
}

export async function getPhoto(photoId: string): Promise<Photo> {
  const response = await apiClient.get<Photo>(`/photos/${photoId}`);
  return response.data;
}

export async function uploadPhoto(
  file: File,
  isFavorite: boolean = false
): Promise<Photo> {
  const formData = new FormData();
  formData.append("file", file);
  const response = await apiClient.post<Photo>(
    `/photos/upload?is_favorite=${isFavorite}`,
    formData,
    {
      headers: { "Content-Type": "multipart/form-data" },
    }
  );
  return response.data;
}

export async function updatePhoto(
  photoId: string,
  data: PhotoUpdate
): Promise<Photo> {
  const response = await apiClient.patch<Photo>(`/photos/${photoId}`, data);
  return response.data;
}

export async function deletePhoto(photoId: string): Promise<void> {
  await apiClient.delete(`/photos/${photoId}`);
}

export async function searchPhotos(params: PhotoSearchParams): Promise<Photo[]> {
  const response = await apiClient.get<Photo[]>("/photos/search/", { params });
  return response.data;
}
