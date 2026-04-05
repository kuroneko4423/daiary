"use client";

import { useAuthStore } from "@/lib/stores/auth-store";
import { useRouter } from "next/navigation";
import { useEffect } from "react";
import { SplashScreen } from "@/components/splash-screen";

export default function Home() {
  const { isAuthenticated } = useAuthStore();
  const router = useRouter();

  useEffect(() => {
    if (isAuthenticated) {
      router.replace("/photos");
    } else {
      router.replace("/login");
    }
  }, [isAuthenticated, router]);

  return <SplashScreen />;
}
