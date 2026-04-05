import Link from "next/link";
import { Card, CardContent, CardDescription, CardFooter, CardHeader } from "@/components/ui/card";
import { SignupForm } from "@/components/auth/signup-form";
import { BrandLogo } from "@/components/brand-logo";

export default function SignupPage() {
  return (
    <Card>
      <CardHeader className="text-center">
        <div className="flex justify-center mb-2">
          <BrandLogo size="sm" showTagline={false} />
        </div>
        <CardDescription>新しいアカウントを作成</CardDescription>
      </CardHeader>
      <CardContent>
        <SignupForm />
      </CardContent>
      <CardFooter className="text-sm text-center">
        <div className="text-muted-foreground w-full">
          すでにアカウントをお持ちの方は{" "}
          <Link href="/login" className="text-primary hover:underline">
            ログイン
          </Link>
        </div>
      </CardFooter>
    </Card>
  );
}
