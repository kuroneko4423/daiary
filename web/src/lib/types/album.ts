import type { Photo } from "./photo";

export interface Album {
  id: string;
  user_id: string;
  name: string;
  cover_photo_id: string | null;
  is_public: boolean;
  share_token: string | null;
  photo_count: number;
  created_at: string;
  updated_at: string;
}

export interface AlbumDetail extends Album {
  photos: Photo[];
}

export interface AlbumCreate {
  name: string;
  cover_photo_id?: string;
  is_public?: boolean;
}

export interface AlbumUpdate {
  name?: string;
  cover_photo_id?: string;
  is_public?: boolean;
}

export interface AlbumAddPhotos {
  photo_ids: string[];
}
