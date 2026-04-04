"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import * as albumsApi from "@/lib/api/albums";
import type { AlbumCreate, AlbumUpdate, AlbumAddPhotos } from "@/lib/types/album";

export function useAlbums() {
  return useQuery({
    queryKey: ["albums"],
    queryFn: albumsApi.getAlbums,
  });
}

export function useAlbum(albumId: string) {
  return useQuery({
    queryKey: ["albums", albumId],
    queryFn: () => albumsApi.getAlbum(albumId),
    enabled: !!albumId,
  });
}

export function useCreateAlbum() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: AlbumCreate) => albumsApi.createAlbum(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["albums"] });
    },
  });
}

export function useUpdateAlbum() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ albumId, data }: { albumId: string; data: AlbumUpdate }) =>
      albumsApi.updateAlbum(albumId, data),
    onSuccess: (_, { albumId }) => {
      queryClient.invalidateQueries({ queryKey: ["albums"] });
      queryClient.invalidateQueries({ queryKey: ["albums", albumId] });
    },
  });
}

export function useDeleteAlbum() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (albumId: string) => albumsApi.deleteAlbum(albumId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["albums"] });
    },
  });
}

export function useAddPhotosToAlbum() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ albumId, data }: { albumId: string; data: AlbumAddPhotos }) =>
      albumsApi.addPhotosToAlbum(albumId, data),
    onSuccess: (_, { albumId }) => {
      queryClient.invalidateQueries({ queryKey: ["albums", albumId] });
    },
  });
}

export function useRemovePhotoFromAlbum() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ albumId, photoId }: { albumId: string; photoId: string }) =>
      albumsApi.removePhotoFromAlbum(albumId, photoId),
    onSuccess: (_, { albumId }) => {
      queryClient.invalidateQueries({ queryKey: ["albums", albumId] });
    },
  });
}
