"use client";

import { useAuthStore } from "@/lib/stores/auth-store";
import { deleteAccount } from "@/lib/api/auth";
import { ProfileSection } from "@/components/settings/profile-section";
import { AiDefaultsSection } from "@/components/settings/ai-defaults-section";
import { ThemeToggle } from "@/components/settings/theme-toggle";
import { SubscriptionCard } from "@/components/settings/subscription-card";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Separator } from "@/components/ui/separator";
import { Button } from "@/components/ui/button";
import { LogOut, Trash2 } from "lucide-react";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import { useState } from "react";

export default function SettingsPage() {
  const { logout } = useAuthStore();
  const router = useRouter();
  const [deleting, setDeleting] = useState(false);

  const handleLogout = () => {
    logout();
    router.push("/login");
  };

  const handleDeleteAccount = async () => {
    if (
      !confirm(
        "本当にアカウントを削除しますか？この操作は取り消せません。すべてのデータが削除されます。"
      )
    )
      return;

    setDeleting(true);
    try {
      await deleteAccount();
      logout();
      toast.success("アカウントを削除しました");
      router.push("/login");
    } catch {
      toast.error("アカウントの削除に失敗しました");
    } finally {
      setDeleting(false);
    }
  };

  return (
    <div className="space-y-6 max-w-2xl">
      <h1 className="text-2xl font-bold">設定</h1>

      <Card>
        <CardHeader>
          <CardTitle className="text-sm">プロフィール</CardTitle>
        </CardHeader>
        <CardContent>
          <ProfileSection />
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="text-sm">外観</CardTitle>
        </CardHeader>
        <CardContent>
          <ThemeToggle />
        </CardContent>
      </Card>

      <Card>
        <CardContent className="pt-6">
          <AiDefaultsSection />
        </CardContent>
      </Card>

      <SubscriptionCard />

      <Card>
        <CardContent className="pt-6 space-y-4">
          <Button
            variant="outline"
            className="w-full"
            onClick={handleLogout}
          >
            <LogOut className="mr-2 h-4 w-4" />
            ログアウト
          </Button>
          <Separator />
          <Button
            variant="destructive"
            className="w-full"
            onClick={handleDeleteAccount}
            disabled={deleting}
          >
            <Trash2 className="mr-2 h-4 w-4" />
            アカウントを削除
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
