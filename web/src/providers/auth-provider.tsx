"use client";

import { useAuthStore } from "@/lib/stores/auth-store";
import { useRouter, usePathname } from "next/navigation";
import { useEffect, useSyncExternalStore } from "react";
import { SplashScreen } from "@/components/splash-screen";

const PUBLIC_PATHS = ["/login", "/signup", "/password-reset"];

const subscribe = () => () => {};
const getSnapshot = () => true;
const getServerSnapshot = () => false;

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const { isAuthenticated } = useAuthStore();
  const router = useRouter();
  const pathname = usePathname();
  const mounted = useSyncExternalStore(subscribe, getSnapshot, getServerSnapshot);

  useEffect(() => {
    if (!mounted) return;

    const isPublicPath = PUBLIC_PATHS.includes(pathname);

    if (!isAuthenticated && !isPublicPath) {
      router.replace("/login");
    } else if (isAuthenticated && isPublicPath) {
      router.replace("/photos");
    }
  }, [isAuthenticated, pathname, router, mounted]);

  if (!mounted) {
    return <SplashScreen />;
  }

  return <>{children}</>;
}
