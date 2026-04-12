# dAIary セットアップ・デプロイ・リリースガイド

> バージョン: 1.0
> 最終更新: 2026-03-13

## 目次

1. [前提条件](#1-前提条件)
2. [環境変数の設定](#2-環境変数の設定)
3. [ローカル開発環境のセットアップ](#3-ローカル開発環境のセットアップ)
4. [テストとリント](#4-テストとリント)
5. [CI/CD パイプライン](#5-cicd-パイプライン)
6. [デプロイメント](#6-デプロイメント)
7. [モバイルアプリのリリース](#7-モバイルアプリのリリース)
8. [トラブルシューティング](#8-トラブルシューティング)
9. [コマンドリファレンス](#9-コマンドリファレンス)

---

## 1. 前提条件

### 必要ツール

| ツール | バージョン | 用途 |
|--------|-----------|------|
| Flutter SDK | 3.x（Dart SDK ^3.8.1） | モバイルアプリ開発 |
| Python | 3.12 以上 | バックエンド開発 |
| Docker Desktop | 最新安定版 | ローカルDB・バックエンド起動 |
| Node.js | 18 以上 | Supabase CLI（npx）実行 |
| Git | 最新安定版 | バージョン管理 |
| Android Studio | 最新安定版 | Android ビルド・エミュレータ |
| Xcode | 最新安定版（macOS のみ） | iOS ビルド・シミュレータ |

### バージョン確認

```bash
flutter --version
python --version
docker --version
node --version
git --version
```

---

## 2. 環境変数の設定

### バックエンド（`backend/.env`）

`backend/.env.example` を `backend/.env` にコピーして値を設定する。

```bash
cp backend/.env.example backend/.env
```

| 変数名 | 説明 | 取得元 |
|--------|------|--------|
| `SUPABASE_URL` | Supabase プロジェクト URL | Supabase ダッシュボード > Settings > API |
| `SUPABASE_KEY` | Supabase anon（公開）キー | 同上 |
| `SUPABASE_SERVICE_KEY` | Supabase service_role キー（RLS バイパス） | 同上 |
| `GEMINI_API_KEY` | Google Gemini API キー | [Google AI Studio](https://aistudio.google.com/) |
| `APP_ENV` | 実行環境（`development` / `production`） | — |
| `APP_DEBUG` | デバッグモード（`true` / `false`） | — |
| `SECRET_KEY` | JWT 署名用シークレットキー | `openssl rand -hex 32` で生成 |
| `CORS_ORIGINS` | 許可するオリジン | 開発: `http://localhost:3000` |

### モバイル（`apps/online/.env`）

`apps/online/.env.example` を `apps/online/.env` にコピーして値を設定する。

```bash
cp apps/online/.env.example apps/online/.env
```

| 変数名 | 説明 | 取得元 |
|--------|------|--------|
| `SUPABASE_URL` | Supabase プロジェクト URL | Supabase ダッシュボード |
| `SUPABASE_ANON_KEY` | Supabase anon（公開）キー | 同上 |
| `API_BASE_URL` | バックエンド API のベース URL | 開発: `http://localhost:8000/api/v1` |
| `ADMOB_ANDROID_APP_ID` | AdMob Android アプリ ID | [Google AdMob](https://admob.google.com/) |
| `ADMOB_IOS_APP_ID` | AdMob iOS アプリ ID | 同上 |

### 環境別の設定値

| 変数 | 開発環境 | 本番環境 |
|------|---------|---------|
| `APP_ENV` | `development` | `production` |
| `APP_DEBUG` | `true` | `false` |
| `API_BASE_URL` | `http://localhost:8000/api/v1` | `https://<本番ドメイン>/api/v1` |
| `CORS_ORIGINS` | `http://localhost:3000` | `https://<本番ドメイン>` |
| `SECRET_KEY` | 任意の文字列 | 強力なランダム文字列 |

---

## 3. ローカル開発環境のセットアップ

### 3.1 依存関係のインストール

```bash
make setup
```

これにより以下が実行される:
- `cd apps/online && flutter pub get` — Flutter パッケージ取得
- `cd backend && pip install -r requirements.txt` — Python パッケージインストール

### 3.2 コード生成（Flutter）

freezed / json_serializable のコード生成を実行する。

```bash
cd apps/online && dart run build_runner build --delete-conflicting-outputs
```

### 3.3 Docker でローカル環境を起動

```bash
make docker-up
```

以下のサービスが起動する:

| サービス | ポート | 説明 |
|---------|-------|------|
| backend | 8000 | FastAPI サーバー |
| db | 5432 | PostgreSQL 15（ユーザー: `postgres`、パスワード: `postgres`、DB: `daiary`） |

停止する場合:

```bash
make docker-down
```

### 3.4 Supabase ローカル環境（オプション）

Supabase CLI を使ったローカル開発も可能。

```bash
npx supabase start
```

| サービス | ポート |
|---------|-------|
| API | 54321 |
| DB | 54322 |
| Studio（管理画面） | 54323 |

### 3.5 データベースマイグレーション

```bash
make db-migrate    # マイグレーション適用
make db-seed       # シードデータ投入
```

リセットが必要な場合（開発環境のみ）:

```bash
make db-reset      # DB を完全リセット
```

### 3.6 サービスの起動（Docker なしの場合）

```bash
# バックエンド（ホットリロード付き）
make backend-run

# モバイルアプリ
make mobile-run
```

### 3.7 動作確認

1. バックエンドが起動していることを確認: `http://localhost:8000/docs`（Swagger UI）
2. モバイルアプリがバックエンドに接続できることを確認

---

## 4. テストとリント

### バックエンド

```bash
make backend-test       # 全テスト実行（pytest -v）
make backend-lint       # リント実行（ruff check .）
```

個別テストの実行:

```bash
cd backend && pytest tests/test_auth.py -v            # ファイル単位
cd backend && pytest tests/test_auth.py::test_name    # テスト関数単位
```

Ruff 設定: Python 3.12 対象、行長 88、ルール E/F/I/N/W/UP（`pyproject.toml`）

### モバイル

```bash
make mobile-test        # 全テスト実行（flutter test）
make mobile-lint        # 静的解析（flutter analyze）
```

---

## 5. CI/CD パイプライン

GitHub Actions で 3 つのワークフローが自動実行される。

### backend-ci.yml

- **トリガー**: `backend/**` への push / PR
- **環境**: ubuntu-latest, Python 3.12
- **ステップ**: 依存関係インストール → Ruff リント → pytest テスト

### mobile-ci.yml

- **トリガー**: `apps/**`, `packages/**` への push / PR
- **環境**: ubuntu-latest, Flutter 3.x（stable）
- **ステップ**: 依存関係インストール → flutter analyze → flutter test

### db-migration.yml

- **トリガー**: `supabase/**` への push / PR
- **ステップ**: SQL ファイルの存在・内容バリデーション

> パスベースのトリガーにより、関係のないファイル変更では CI が実行されない。

---

## 6. デプロイメント

### 6.1 Supabase 本番環境

1. [Supabase ダッシュボード](https://supabase.com/dashboard) で新規プロジェクトを作成
2. Settings > API から以下を取得:
   - `SUPABASE_URL`
   - `SUPABASE_KEY`（anon key）
   - `SUPABASE_SERVICE_KEY`（service_role key）
3. マイグレーションを本番に適用:

```bash
npx supabase db push --db-url "postgresql://postgres:<パスワード>@db.<project-ref>.supabase.co:5432/postgres"
```

4. Storage で `photos` バケットを作成（RLS ポリシーはマイグレーション `005_create_storage.sql` で自動設定）
5. Authentication の設定（メール認証の有効化など）

### 6.2 バックエンドデプロイ

#### Docker イメージのビルド

```bash
docker build -t daiary-backend ./backend
```

#### 本番環境変数

```
APP_ENV=production
APP_DEBUG=false
SECRET_KEY=<強力なランダム文字列>
CORS_ORIGINS=https://<本番ドメイン>
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_KEY=<本番 anon key>
SUPABASE_SERVICE_KEY=<本番 service_role key>
GEMINI_API_KEY=<本番 Gemini API key>
```

#### デプロイ先の選択肢

| プラットフォーム | 特徴 |
|----------------|------|
| Google Cloud Run | コンテナベース、スケーラブル、従量課金 |
| Fly.io | シンプルなデプロイ、グローバルエッジ |
| Railway | Git 連携で自動デプロイ |
| AWS ECS / Fargate | エンタープライズ向け |
| Render | Dockerfile からの自動ビルド |

いずれの場合も、Docker イメージを使用し、ポート 8000 を公開する。本番では `--reload` フラグは使用しない（Dockerfile の CMD には含まれていない）。

### 6.3 データベースマイグレーション

マイグレーションファイル（`supabase/migrations/`）:

| ファイル | 内容 |
|---------|------|
| `001_create_users.sql` | users テーブル、プラン enum、RLS |
| `002_create_photos.sql` | photos テーブル、EXIF、ソフトデリート |
| `003_create_albums.sql` | albums テーブル、共有トークン |
| `004_create_ai_generations.sql` | AI 生成結果テーブル |
| `005_create_storage.sql` | Storage バケット、10MB 制限、MIME 制限 |

#### 新規マイグレーションの追加

```bash
npx supabase migration new <マイグレーション名>
# supabase/migrations/ に新しい SQL ファイルが作成される
```

ファイルを編集後、`make db-migrate` で適用。

---

## 7. モバイルアプリのリリース

### 7.1 共通準備

1. **バージョン更新**: `apps/online/pubspec.yaml` の `version` を更新

```yaml
version: 1.0.1+2    # major.minor.patch+buildNumber
```

2. **本番環境変数の設定**: `apps/online/.env` の `API_BASE_URL` を本番 URL に変更
3. **コード生成の実行**:

```bash
cd apps/online && dart run build_runner build --delete-conflicting-outputs
```

### 7.2 Android リリース

#### キーストアの作成（初回のみ）

```bash
keytool -genkey -v -keystore ~/daiary-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias daiary
```

#### 署名設定

`apps/online/android/key.properties` を作成:

```properties
storePassword=<パスワード>
keyPassword=<パスワード>
keyAlias=daiary
storeFile=<キーストアのパス>
```

> 注意: 現在 `build.gradle.kts` は debug 署名を使用しています。リリース前に署名設定の更新が必要です。

#### ビルド

```bash
make mobile-build-apk
```

出力: `apps/online/build/app/outputs/flutter-apk/app-release.apk`

#### Google Play Console への提出

1. [Google Play Console](https://play.google.com/console) でアプリを作成（パッケージ名: `com.daiary.app`）
2. 内部テスト → クローズドテスト → オープンテスト → 本番の順にリリース
3. APK または App Bundle をアップロード

### 7.3 iOS リリース

> macOS + Xcode が必要です。

#### ビルド

```bash
make mobile-build-ios
```

#### Xcode での設定

1. `apps/online/ios/Runner.xcworkspace` を Xcode で開く
2. Signing & Capabilities で Apple Developer アカウントを設定
3. Bundle Identifier、バージョン、ビルド番号を確認
4. Archive を作成し、App Store Connect にアップロード

#### App Store Connect への提出

1. [App Store Connect](https://appstoreconnect.apple.com/) でアプリを作成
2. TestFlight で内部テスト → 外部テスト → App Store 審査提出

### 7.4 バージョニング

| 対象 | ファイル | 形式 | 現在値 |
|------|---------|------|--------|
| モバイル | `apps/online/pubspec.yaml` | `major.minor.patch+buildNumber` | `1.0.0+1` |
| バックエンド | `backend/pyproject.toml` | `major.minor.patch` | `1.0.0` |

リリース時は両方のバージョンを更新し、Git タグ（例: `v1.0.1`）を付与することを推奨。

---

## 8. トラブルシューティング

| 問題 | 解決方法 |
|------|---------|
| Flutter ビルドエラー | `cd apps/online && flutter clean` → `flutter pub get` → 再ビルド |
| コード生成の不整合 | `dart run build_runner build --delete-conflicting-outputs` を再実行 |
| Docker ポート競合 | `docker compose down` で既存コンテナを停止後、再起動 |
| Supabase 接続エラー | `.env` の `SUPABASE_URL` と `SUPABASE_KEY` が正しいか確認 |
| CORS エラー | `CORS_ORIGINS` にクライアントのオリジンが含まれているか確認 |
| Python パッケージエラー | `pip install -r requirements.txt` を再実行 |
| DB マイグレーション失敗 | SQL 構文を確認。開発環境なら `make db-reset` でリセット可能 |
| 全般的なクリーンアップ | `make clean`（Flutter clean + Python キャッシュ削除） |

---

## 9. コマンドリファレンス

| コマンド | 説明 |
|---------|------|
| `make setup` | 全依存関係インストール（Flutter + Python） |
| `make mobile-run` | Flutter アプリ実行 |
| `make mobile-test` | Flutter テスト実行 |
| `make mobile-lint` | Flutter 静的解析 |
| `make mobile-build-apk` | Android APK ビルド（リリース） |
| `make mobile-build-ios` | iOS ビルド（リリース） |
| `make backend-run` | バックエンド開発サーバー起動（ポート 8000、ホットリロード） |
| `make backend-test` | バックエンドテスト実行（pytest） |
| `make backend-lint` | バックエンドリント（Ruff） |
| `make db-migrate` | データベースマイグレーション適用 |
| `make db-reset` | データベースリセット（開発環境のみ） |
| `make db-seed` | シードデータ投入 |
| `make docker-up` | Docker コンテナ起動（バックエンド + PostgreSQL） |
| `make docker-down` | Docker コンテナ停止 |
| `make clean` | ビルド成果物・キャッシュ削除 |
