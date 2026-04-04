export interface Photo {
  id: string;
  user_id: string;
  storage_path: string;
  thumbnail_path: string | null;
  original_filename: string | null;
  file_size: number | null;
  width: number | null;
  height: number | null;
  exif_data: Record<string, unknown>;
  ai_tags: string[];
  is_favorite: boolean;
  url: string | null;
  created_at: string;
}

export interface PhotoListParams {
  offset?: number;
  limit?: number;
  favorites_only?: boolean;
  include_deleted?: boolean;
}

export interface PhotoSearchParams {
  q: string;
  offset?: number;
  limit?: number;
}

export interface PhotoUpdate {
  is_favorite?: boolean;
}
