import Link from "next/link";
import { Card, CardContent, CardDescription, CardFooter, CardHeader } from "@/components/ui/card";
import { LoginForm } from "@/components/auth/login-form";
import { BrandLogo } from "@/components/brand-logo";

export default function LoginPage() {
  return (
    <Card>
      <CardHeader className="text-center">
        <div className="flex justify-center mb-2">
          <BrandLogo size="sm" showTagline={false} />
        </div>
        <CardDescription>アカウントにログイン</CardDescription>
      </CardHeader>
      <CardContent>
        <LoginForm />
      </CardContent>
      <CardFooter className="flex flex-col gap-2 text-sm text-center">
        <Link
          href="/password-reset"
          className="text-muted-foreground hover:text-primary transition-colors"
        >
          パスワードを忘れた場合
        </Link>
        <div className="text-muted-foreground">
          アカウントをお持ちでない方は{" "}
          <Link href="/signup" className="text-primary hover:underline">
            新規登録
          </Link>
        </div>
      </CardFooter>
    </Card>
  );
}
