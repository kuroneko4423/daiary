"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Upload, Image, FolderOpen, Settings, Camera } from "lucide-react";
import { cn } from "@/lib/utils";

const navItems = [
  { href: "/upload", label: "アップロード", icon: Upload },
  { href: "/photos", label: "写真", icon: Image },
  { href: "/albums", label: "アルバム", icon: FolderOpen },
  { href: "/settings", label: "設定", icon: Settings },
];

export function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="hidden md:flex flex-col w-60 border-r bg-card h-screen sticky top-0">
      <div className="flex items-center gap-2 px-6 py-5 border-b">
        <Camera className="h-6 w-6 text-primary" />
        <span className="text-lg font-semibold">dAIary</span>
      </div>
      <nav className="flex-1 px-3 py-4 space-y-1">
        {navItems.map((item) => {
          const isActive =
            pathname === item.href || pathname.startsWith(item.href + "/");
          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                "flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors",
                isActive
                  ? "bg-primary/10 text-primary"
                  : "text-muted-foreground hover:bg-accent hover:text-accent-foreground"
              )}
            >
              <item.icon className="h-5 w-5" />
              {item.label}
            </Link>
          );
        })}
      </nav>
    </aside>
  );
}
