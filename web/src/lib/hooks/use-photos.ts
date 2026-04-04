"use client";

import { useQuery, useMutation, useQueryClient, useInfiniteQuery } from "@tanstack/react-query";
import * as photosApi from "@/lib/api/photos";
import type { PhotoListParams, PhotoSearchParams, PhotoUpdate } from "@/lib/types/photo";

export function usePhotos(params: PhotoListParams = {}) {
  return useInfiniteQuery({
    queryKey: ["photos", params],
    queryFn: ({ pageParam = 0 }) =>
      photosApi.getPhotos({ ...params, offset: pageParam, limit: params.limit || 20 }),
    getNextPageParam: (lastPage, allPages) => {
      const limit = params.limit || 20;
      if (lastPage.length < limit) return undefined;
      return allPages.flat().length;
    },
    initialPageParam: 0,
  });
}

export function usePhoto(photoId: string) {
  return useQuery({
    queryKey: ["photos", photoId],
    queryFn: () => photosApi.getPhoto(photoId),
    enabled: !!photoId,
  });
}

export function useUploadPhoto() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ file, isFavorite }: { file: File; isFavorite?: boolean }) =>
      photosApi.uploadPhoto(file, isFavorite),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["photos"] });
    },
  });
}

export function useUpdatePhoto() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ photoId, data }: { photoId: string; data: PhotoUpdate }) =>
      photosApi.updatePhoto(photoId, data),
    onSuccess: (_, { photoId }) => {
      queryClient.invalidateQueries({ queryKey: ["photos"] });
      queryClient.invalidateQueries({ queryKey: ["photos", photoId] });
    },
  });
}

export function useDeletePhoto() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (photoId: string) => photosApi.deletePhoto(photoId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["photos"] });
    },
  });
}

export function useSearchPhotos(params: PhotoSearchParams) {
  return useQuery({
    queryKey: ["photos", "search", params],
    queryFn: () => photosApi.searchPhotos(params),
    enabled: !!params.q,
  });
}
