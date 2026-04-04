"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import * as aiApi from "@/lib/api/ai";
import type { HashtagRequest, CaptionRequest } from "@/lib/types/ai";

export function useGenerateHashtags() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: HashtagRequest) => aiApi.generateHashtags(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["ai", "usage"] });
    },
  });
}

export function useGenerateCaption() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: CaptionRequest) => aiApi.generateCaption(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["ai", "usage"] });
    },
  });
}

export function useUsage() {
  return useQuery({
    queryKey: ["ai", "usage"],
    queryFn: aiApi.getUsage,
  });
}
