"use client";

import { useAuthStore } from "@/lib/stores/auth-store";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { formatFileSize } from "@/lib/utils/format";

export function ProfileSection() {
  const { user } = useAuthStore();

  if (!user) return null;

  const initials = user.username
    ? user.username.slice(0, 2).toUpperCase()
    : user.email.slice(0, 2).toUpperCase();

  return (
    <div className="flex items-center gap-4">
      <Avatar className="h-16 w-16">
        <AvatarFallback className="text-lg">{initials}</AvatarFallback>
      </Avatar>
      <div className="space-y-1">
        <div className="flex items-center gap-2">
          <h2 className="text-lg font-medium">{user.username || "ユーザー"}</h2>
          <Badge variant={user.plan === "premium" ? "default" : "secondary"}>
            {user.plan === "premium" ? "Premium" : "Free"}
          </Badge>
        </div>
        <p className="text-sm text-muted-foreground">{user.email}</p>
        <p className="text-xs text-muted-foreground">
          ストレージ使用量: {formatFileSize(user.storage_used_bytes)}
        </p>
      </div>
    </div>
  );
}
