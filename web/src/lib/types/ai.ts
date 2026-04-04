export interface HashtagRequest {
  photo_id: string;
  language?: string;
  count?: number;
  usage?: string;
}

export interface HashtagResponse {
  hashtags: string[];
  generation_id: string;
}

export interface CaptionRequest {
  photo_id: string;
  language?: string;
  style?: string;
  length?: string;
  custom_prompt?: string;
}

export interface CaptionResponse {
  caption: string;
  generation_id: string;
}

export interface UsageResponse {
  used: number;
  limit: number;
  remaining: number;
  is_premium: boolean;
}
