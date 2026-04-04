import Link from "next/link";
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { PasswordResetForm } from "@/components/auth/password-reset-form";

export default function PasswordResetPage() {
  return (
    <Card>
      <CardHeader className="text-center">
        <CardTitle className="text-2xl">パスワードリセット</CardTitle>
        <CardDescription>
          登録したメールアドレスを入力してください
        </CardDescription>
      </CardHeader>
      <CardContent>
        <PasswordResetForm />
      </CardContent>
      <CardFooter className="text-sm text-center">
        <div className="text-muted-foreground w-full">
          <Link href="/login" className="text-primary hover:underline">
            ログインに戻る
          </Link>
        </div>
      </CardFooter>
    </Card>
  );
}
