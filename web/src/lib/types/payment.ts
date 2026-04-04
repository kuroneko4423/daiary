export interface SubscriptionResponse {
  plan: string;
  is_active: boolean;
  expires_at: string | null;
  product_id: string | null;
}
