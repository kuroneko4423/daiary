import type {
  Album,
  AlbumAddPhotos,
  AlbumCreate,
  AlbumDetail,
  AlbumUpdate,
} from "@/lib/types/album";
import apiClient from "./client";

export async function getAlbums(): Promise<Album[]> {
  const response = await apiClient.get<Album[]>("/albums/");
  return response.data;
}

export async function getAlbum(albumId: string): Promise<AlbumDetail> {
  const response = await apiClient.get<AlbumDetail>(`/albums/${albumId}`);
  return response.data;
}

export async function createAlbum(data: AlbumCreate): Promise<Album> {
  const response = await apiClient.post<Album>("/albums/", data);
  return response.data;
}

export async function updateAlbum(
  albumId: string,
  data: AlbumUpdate
): Promise<Album> {
  const response = await apiClient.patch<Album>(`/albums/${albumId}`, data);
  return response.data;
}

export async function deleteAlbum(albumId: string): Promise<void> {
  await apiClient.delete(`/albums/${albumId}`);
}

export async function addPhotosToAlbum(
  albumId: string,
  data: AlbumAddPhotos
): Promise<{ added: number }> {
  const response = await apiClient.post<{ added: number }>(
    `/albums/${albumId}/photos`,
    data
  );
  return response.data;
}

export async function removePhotoFromAlbum(
  albumId: string,
  photoId: string
): Promise<void> {
  await apiClient.delete(`/albums/${albumId}/photos/${photoId}`);
}
