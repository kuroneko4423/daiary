import type {
  CaptionRequest,
  CaptionResponse,
  HashtagRequest,
  HashtagResponse,
  UsageResponse,
} from "@/lib/types/ai";
import apiClient from "./client";

export async function generateHashtags(
  data: HashtagRequest
): Promise<HashtagResponse> {
  const response = await apiClient.post<HashtagResponse>("/ai/hashtags", data);
  return response.data;
}

export async function generateCaption(
  data: CaptionRequest
): Promise<CaptionResponse> {
  const response = await apiClient.post<CaptionResponse>("/ai/caption", data);
  return response.data;
}

export async function getUsage(): Promise<UsageResponse> {
  const response = await apiClient.get<UsageResponse>("/ai/usage");
  return response.data;
}
