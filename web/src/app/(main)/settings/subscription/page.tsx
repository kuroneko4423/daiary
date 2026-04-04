"use client";

import { useQuery } from "@tanstack/react-query";
import { getSubscription } from "@/lib/api/payments";
import { useUsage } from "@/lib/hooks/use-ai";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";
import { ArrowLeft, Crown, Sparkles, HardDrive, Shield, Zap } from "lucide-react";
import Link from "next/link";

export default function SubscriptionPage() {
  const { data: subscription } = useQuery({
    queryKey: ["subscription"],
    queryFn: getSubscription,
  });
  const { data: usage } = useUsage();

  const isPremium = subscription?.plan === "premium" && subscription?.is_active;

  return (
    <div className="space-y-6 max-w-2xl">
      <Link
        href="/settings"
        className="inline-flex items-center text-sm text-muted-foreground hover:text-foreground"
      >
        <ArrowLeft className="mr-1 h-4 w-4" />
        設定
      </Link>

      <h1 className="text-2xl font-bold">サブスクリプション</h1>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Crown className="h-5 w-5" />
            現在のプラン
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          <div className="flex items-center justify-between">
            <span>プラン</span>
            <Badge variant={isPremium ? "default" : "secondary"}>
              {isPremium ? "Premium" : "Free"}
            </Badge>
          </div>
          {usage && (
            <div className="flex items-center justify-between text-sm text-muted-foreground">
              <span>本日のAI生成</span>
              <span>
                {usage.used} / {usage.is_premium ? "無制限" : usage.limit}
              </span>
            </div>
          )}
          {subscription?.expires_at && (
            <div className="flex items-center justify-between text-sm text-muted-foreground">
              <span>有効期限</span>
              <span>
                {new Date(subscription.expires_at).toLocaleDateString("ja-JP")}
              </span>
            </div>
          )}
        </CardContent>
      </Card>

      {!isPremium && (
        <Card>
          <CardHeader>
            <CardTitle>Premium プラン</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-3">
              {[
                { icon: Sparkles, text: "AI生成が無制限" },
                { icon: HardDrive, text: "50GBストレージ" },
                { icon: Shield, text: "広告なし" },
                { icon: Zap, text: "優先サポート" },
              ].map(({ icon: Icon, text }) => (
                <div key={text} className="flex items-center gap-3">
                  <Icon className="h-5 w-5 text-primary" />
                  <span className="text-sm">{text}</span>
                </div>
              ))}
            </div>
            <Separator />
            <p className="text-sm text-muted-foreground">
              Premiumプランへのアップグレードは、iOS/Androidのモバイルアプリからお申し込みいただけます。
            </p>
            <Button disabled className="w-full">
              モバイルアプリからアップグレード
            </Button>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
