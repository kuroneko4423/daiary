# CLAUDE.md

このファイルは、Claude Code (claude.ai/code) がこのリポジトリのコードを扱う際のガイダンスを提供します。

## プロジェクト概要

dAIary - 写真撮影とAIによるコンテンツ生成（Google Gemini APIを使ったハッシュタグ・キャプション生成）を組み合わせた、SNS投稿向けモバイルフォトダイアリーアプリ。Flutter モバイルアプリ、Next.js Webアプリ、FastAPI バックエンドのモノレポ構成で、データベース・認証・ストレージに Supabase を使用。

## よく使うコマンド

### セットアップ

```bash
make setup              # 全依存関係のインストール（Flutter + Python + Node.js）
```

### バックエンド（FastAPI, Python 3.12+）

```bash
make backend-run        # 開発サーバー起動（uvicorn, ポート8000, 自動リロード）
make backend-test       # テスト実行（pytest -v）
make backend-lint       # リント（ruff check .）
cd backend && pytest tests/test_auth.py -v          # 単一テストファイル実行
cd backend && pytest tests/test_auth.py::test_name  # 単一テスト実行
```

### モバイル（Flutter, Dart SDK ^3.8.1）

```bash
make mobile-run         # Flutterアプリ実行
make mobile-test        # Flutterテスト実行
make mobile-lint        # 静的解析（flutter analyze）
cd mobile && dart run build_runner build --delete-conflicting-outputs  # コード生成（freezed/json_serializable）
```

### Web（Next.js, Node.js 20+）

```bash
make web-dev            # 開発サーバー起動（next dev, ポート3000）
make web-build          # プロダクションビルド
make web-lint           # リント（eslint）
make web-test           # テスト実行
```

### データベース（Supabase）

```bash
make db-migrate         # マイグレーション適用（npx supabase db push）
make db-reset           # データベースリセット
```

### Docker

```bash
make docker-up          # バックエンド + Web + postgres 起動（ポート 8000, 3000, 5432）
make docker-down        # コンテナ停止
```

## アーキテクチャ

### マルチプラットフォーム構成

- **Flutter モバイルアプリ**（iOS/Android）→ REST API → **FastAPI バックエンド**（Python）→ **Supabase**（PostgreSQL + Auth + Storage）+ **Google Gemini API**
- **Next.js Webアプリ**（ブラウザ）→ REST API → **FastAPI バックエンド**（同上）

### バックエンド（`backend/`）

レイヤードアーキテクチャ: APIルート（`api/v1/`）→ サービス（`services/`）→ Supabaseクライアント（`config/database.py`）

- **依存性注入**: FastAPI `Depends` による実装 — `get_current_user`（JWT認証）、`get_supabase`（anonクライアント、RLS適用）、`get_admin_supabase`（サービスロール、RLSバイパス）、`get_settings_dep`
- **ミドルウェアチェーン**: RequestLoggingMiddleware → CORSMiddleware → HTTPBearer JWT認証（エンドポイント単位）
- **設定管理**: pydantic-settings + `.env` ファイル（`config/settings.py`）、シングルトン `settings` インスタンス
- **テスト**: pytest-asyncio + `httpx.AsyncClient` + ASGIトランスポート。認証は `app.dependency_overrides[get_current_user]` でモック。Supabaseは `MagicMock` チェーンパターンでモック（`tests/conftest.py` 参照）
- **Ruff設定**: target py312, line-length 88, ルール E/F/I/N/W/UP（`pyproject.toml`）

### モバイル（`mobile/`）

Riverpod状態管理を用いたフィーチャーベースのクリーンアーキテクチャ。

- **フィーチャー構成**: `features/<name>/{data, domain, presentation}` — 各フィーチャーにエンティティ、リポジトリ（インターフェース + 実装）、データソース、プロバイダー（StateNotifier）、画面、ウィジェットを配置
- **フィーチャー一覧**: auth, camera, ai_generate, album, settings
- **状態管理**: flutter_riverpod v2 + StateNotifier パターン
- **ナビゲーション**: go_router + 認証ガードリダイレクト、ShellRoute によるボトムナビ（カメラ/写真/アルバム/設定）
- **サービス**（フィーチャー横断）: `api_client.dart`（Dio）、`supabase_service.dart`、`admob_service.dart`、`purchase_service.dart`、`share_service.dart`
- **コード生成**: freezed + json_serializable（イミュータブルモデル用）、`build_runner` が必要

### Web（`web/`）

Next.js 14+ (App Router) + TypeScript + Tailwind CSS + shadcn/ui。

- **ディレクトリ構成**: `app/(auth)/` — 認証ページ、`app/(main)/` — メイン機能（写真/アルバム/アップロード/設定）
- **状態管理**: TanStack Query（サーバーステート）+ Zustand（認証・設定のクライアントステート、localStorage永続化）
- **APIクライアント**: Axios + JWT自動付与インターセプター + 401時自動トークンリフレッシュ（`lib/api/client.ts`）
- **コンポーネント構成**: `components/{photos,albums,ai,auth,settings,layout}/` — 機能別にグループ化
- **認証**: Bearer JWT トークン、localStorage に保存、AuthProvider でルートガード
- **モバイル版との差異**: カメラ撮影→ファイルアップロード（D&D）、AdMob広告なし、課金はステータス表示のみ

### 主要データフロー

- **認証**: モバイル → FastAPI → Supabase Auth → JWT発行 → flutter_secure_storage に保存 → Bearer トークンとして送信
- **写真アップロード**: multipart/form-data → FastAPI でバリデーション（JPEG/PNG/WebP/HEIC, 最大10MB）→ Supabase Storage（`{user_id}/photos/`）→ メタデータを `photos` テーブルに保存 → 署名付きURLを返却
- **AI生成**: JWT + 使用回数チェック（Free: 10回/日, Premium: 無制限）→ Storage から写真取得 → Gemini API → 結果を `ai_generations` テーブルに保存

### 環境変数

- バックエンド: `backend/.env.example` を `backend/.env` にコピー（Supabase URL/キー、Gemini APIキー、SECRET_KEY、CORS_ORIGINS）
- モバイル: `mobile/.env.example` を `mobile/.env` にコピー（Supabase URL/anonキー、APIベースURL、AdMobアプリID）
- Web: `web/.env.example` を `web/.env.local` にコピー（APIベースURL）

## 言語

プロジェクトドキュメントは日本語で記述。コードとAPIは英語で記述。
