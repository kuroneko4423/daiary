import type { TokenResponse, UserCreate, UserLogin } from "@/lib/types/user";
import apiClient from "./client";

export async function login(data: UserLogin): Promise<TokenResponse> {
  const response = await apiClient.post<TokenResponse>("/auth/login", data);
  return response.data;
}

export async function signup(data: UserCreate): Promise<TokenResponse> {
  const response = await apiClient.post<TokenResponse>("/auth/signup", data);
  return response.data;
}

export async function refreshToken(refresh_token: string): Promise<TokenResponse> {
  const response = await apiClient.post<TokenResponse>("/auth/refresh", {
    refresh_token,
  });
  return response.data;
}

export async function resetPassword(email: string): Promise<void> {
  await apiClient.post("/auth/password-reset", { email });
}

export async function deleteAccount(): Promise<void> {
  await apiClient.delete("/auth/account");
}
