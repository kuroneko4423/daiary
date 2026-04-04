"use client";

import { useQuery } from "@tanstack/react-query";
import { getSubscription } from "@/lib/api/payments";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Crown } from "lucide-react";

export function SubscriptionCard() {
  const { data: subscription } = useQuery({
    queryKey: ["subscription"],
    queryFn: getSubscription,
  });

  if (!subscription) return null;

  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="text-sm flex items-center gap-2">
          <Crown className="h-4 w-4" />
          サブスクリプション
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-2">
        <div className="flex items-center justify-between">
          <span className="text-sm">プラン</span>
          <Badge variant={subscription.is_active ? "default" : "secondary"}>
            {subscription.plan === "premium" ? "Premium" : "Free"}
          </Badge>
        </div>
        {subscription.expires_at && (
          <div className="flex items-center justify-between text-sm text-muted-foreground">
            <span>有効期限</span>
            <span>{new Date(subscription.expires_at).toLocaleDateString("ja-JP")}</span>
          </div>
        )}
        {subscription.plan !== "premium" && (
          <p className="text-xs text-muted-foreground mt-2">
            Premiumプランへのアップグレードはモバイルアプリから行えます。
          </p>
        )}
      </CardContent>
    </Card>
  );
}
