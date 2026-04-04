export interface User {
  id: string;
  email: string;
  username: string | null;
  avatar_url: string | null;
  plan: "free" | "premium";
  storage_used_bytes: number;
  created_at: string;
}

export interface TokenResponse {
  access_token: string;
  refresh_token: string;
  token_type: string;
  expires_in: number;
  user: User;
}

export interface UserCreate {
  email: string;
  password: string;
  username?: string;
}

export interface UserLogin {
  email: string;
  password: string;
}
