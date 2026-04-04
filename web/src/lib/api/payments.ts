import type { SubscriptionResponse } from "@/lib/types/payment";
import apiClient from "./client";

export async function getSubscription(): Promise<SubscriptionResponse> {
  const response = await apiClient.get<SubscriptionResponse>(
    "/payments/subscription"
  );
  return response.data;
}
