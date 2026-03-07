# アーキテクチャ設計書

## 1. システム全体構成

AI Photographer は、Flutter モバイルアプリ、FastAPI バックエンド、Supabase (PostgreSQL + Auth + Storage)、および Google Gemini API を組み合わせた 3 層アーキテクチャで構成されています。

```
┌─────────────────────┐
│   Flutter Mobile App │
│   (iOS / Android)    │
└─────────┬───────────┘
          │ HTTPS (REST API)
          ▼
┌─────────────────────┐     ┌──────────────────────┐
│  FastAPI Backend     │────▶│  Google Gemini API    │
│  (Python 3.12)       │     │  (AI生成)             │
└─────────┬───────────┘     └──────────────────────┘
          │ supabase-py
          ▼
┌─────────────────────────────────────────┐
│            Supabase                      │
│  ┌───────────┬───────────┬────────────┐ │
│  │PostgreSQL │  Auth     │  Storage   │ │
│  │  (DB)     │  (JWT)    │  (Photos)  │ │
│  └───────────┴───────────┴────────────┘ │
└─────────────────────────────────────────┘
```

### 各層の役割

| 層 | 役割 |
| --- | --- |
| **プレゼンテーション層** (Flutter) | ユーザーインターフェース、カメラ制御、状態管理、ナビゲーション |
| **アプリケーション層** (FastAPI) | ビジネスロジック、認証検証、AI生成オーケストレーション、決済処理 |
| **データ層** (Supabase) | データ永続化 (PostgreSQL)、ユーザー認証 (Auth)、写真ストレージ (Storage) |

---

## 2. モノレポ構成

プロジェクトはモノレポ構成を採用しており、モバイルアプリ・バックエンド・インフラ定義を単一リポジトリで管理しています。

```
ai-photographer/
├── mobile/              # Flutter モバイルアプリ (iOS / Android)
├── backend/             # FastAPI バックエンドAPI (Python 3.12)
├── supabase/            # DBマイグレーション・RLS ポリシー定義 (SQL)
├── docs/                # 共有ドキュメント (要件定義書、実装計画書、API仕様書等)
├── .github/workflows/   # CI/CD パイプライン (GitHub Actions)
├── docker-compose.yml   # ローカル開発用コンテナ定義
├── Makefile             # 開発用コマンド集
└── README.md            # プロジェクト概要
```

---

## 3. バックエンドアーキテクチャ

### 3.1 レイヤードアーキテクチャ

バックエンドは以下の層で構成されています。

```
API Routes (api/v1/)
    │
    ├── 認証検証 (middleware/auth.py)
    ├── リクエストバリデーション (schemas/)
    │
    ▼
Services (services/)
    │
    ├── ai_service.py       ... Gemini API との通信
    ├── storage_service.py  ... Supabase Storage 操作
    ├── payment_service.py  ... 決済処理
    │
    ▼
Supabase Client (config/database.py)
    │
    ▼
Supabase (PostgreSQL / Auth / Storage)
```

### 3.2 ミドルウェアチェーン

リクエストは以下の順序でミドルウェアを通過します。

```
リクエスト
  → RequestLoggingMiddleware  (リクエスト/レスポンスのログ記録、レイテンシ計測)
  → CORSMiddleware           (Cross-Origin Resource Sharing 設定)
  → HTTPBearer認証            (エンドポイント単位で JWT 検証)
  → ルートハンドラ
```

- **RequestLoggingMiddleware** (`middleware/logging.py`): 全リクエストのメソッド・パス・ステータスコード・処理時間をログ出力
- **CORSMiddleware**: `settings.CORS_ORIGINS` で指定されたオリジンからのリクエストを許可
- **JWT認証** (`middleware/auth.py`): `HTTPBearer` スキームでトークンを取得し、`supabase.auth.get_user()` で検証。`public.users` テーブルからプロフィール情報を付加

### 3.3 依存性注入パターン

FastAPI の `Depends` を活用し、以下の依存関係を注入しています。

| 依存関係 | 提供元 | 説明 |
| --- | --- | --- |
| `get_current_user` | `middleware/auth.py` | JWT 検証済みユーザー情報 (dict) |
| `get_supabase` | `api/deps.py` | Supabase クライアント (anon key、RLS 適用) |
| `get_admin_supabase` | `api/deps.py` | Supabase 管理クライアント (service role key、RLS バイパス) |
| `get_settings_dep` | `api/deps.py` | アプリケーション設定 (Settings) |

### 3.4 ディレクトリ構成

```
backend/
├── main.py                 # FastAPI アプリケーションエントリーポイント
├── config/
│   ├── settings.py         # 環境変数・設定管理 (pydantic-settings)
│   └── database.py         # Supabase クライアント生成 (anon / admin)
├── api/
│   ├── deps.py             # 共通の依存性注入ファクトリ
│   └── v1/
│       ├── router.py       # v1 ルーター集約 (prefix 定義)
│       ├── auth.py         # 認証エンドポイント (signup, login, refresh 等)
│       ├── photos.py       # 写真 CRUD エンドポイント
│       ├── albums.py       # アルバム CRUD エンドポイント
│       ├── ai_generate.py  # AI生成エンドポイント (hashtags, caption, usage)
│       └── payments.py     # 決済エンドポイント (verify-receipt, subscription 等)
├── schemas/
│   ├── user.py             # ユーザー関連 Pydantic モデル
│   ├── photo.py            # 写真関連 Pydantic モデル
│   ├── album.py            # アルバム関連 Pydantic モデル
│   ├── ai_generate.py      # AI生成関連 Pydantic モデル
│   └── payment.py          # 決済関連 Pydantic モデル
├── models/
│   ├── user.py             # ユーザードメインモデル (UserPlan enum 等)
│   ├── photo.py            # 写真ドメインモデル
│   ├── album.py            # アルバムドメインモデル
│   └── ai_generation.py    # AI生成ドメインモデル
├── middleware/
│   ├── auth.py             # JWT 認証ミドルウェア (get_current_user)
│   ├── logging.py          # リクエストログミドルウェア
│   └── rate_limit.py       # レート制限 (インメモリストア)
├── services/
│   ├── ai_service.py       # Google Gemini API クライアント
│   ├── storage_service.py  # Supabase Storage 操作
│   └── payment_service.py  # App Store / Play Store 決済処理
├── tests/                  # テストスイート
├── Dockerfile              # コンテナイメージ定義
├── requirements.txt        # Python パッケージ依存関係
└── pyproject.toml          # プロジェクトメタデータ
```

---

## 4. モバイルアーキテクチャ

### 4.1 アーキテクチャパターン

Feature-based ディレクトリ構成と Clean Architecture の原則を組み合わせています。各 feature は Data / Domain / Presentation の 3 層に分離されています。

```
features/
└── <feature_name>/
    ├── data/               # リポジトリ実装、データソース、DTO
    ├── domain/             # エンティティ、リポジトリインターフェース
    └── presentation/
        ├── providers/      # Riverpod プロバイダ (StateNotifier)
        ├── screens/        # 画面ウィジェット
        └── widgets/        # 再利用可能なUIコンポーネント
```

### 4.2 状態管理

**flutter_riverpod** (v2.6.1) を使用し、StateNotifier パターンで状態を管理しています。

- `ProviderScope` がアプリ全体を囲み、全プロバイダのスコープを提供
- 認証状態は `authStateProvider` で管理し、ルーティングのリダイレクト判定に利用
- 各 feature は独自の Provider / StateNotifierProvider を持つ

### 4.3 ナビゲーション

**go_router** (v14.8.1) を使用し、宣言的ルーティングを実装しています。

- **認証ガード**: `redirect` コールバックで認証状態を監視し、未認証ユーザーを `/login` にリダイレクト、認証済みユーザーを `/camera` にリダイレクト
- **ShellRoute**: ボトムナビゲーション (Camera / Photos / Albums / Settings) を `MainShell` ウィジェットで共有
- **ネストルーティング**: アルバム詳細 (`/albums/:id`) はアルバム一覧のサブルートとして定義

**ルート一覧**:

| パス | 画面 | 認証 |
| --- | --- | --- |
| `/login` | ログイン画面 | 不要 |
| `/signup` | サインアップ画面 | 不要 |
| `/camera` | カメラ画面 | 必要 |
| `/photos` | 写真一覧画面 | 必要 |
| `/photos/:id` | 写真詳細画面 | 必要 |
| `/albums` | アルバム一覧画面 | 必要 |
| `/albums/:id` | アルバム詳細画面 | 必要 |
| `/settings` | 設定画面 | 必要 |
| `/ai-generate` | AI生成画面 | 必要 |
| `/subscription` | サブスクリプション画面 | 必要 |

### 4.4 Feature 一覧

| Feature | 説明 |
| --- | --- |
| `auth` | ユーザー認証 (ログイン、サインアップ、認証状態管理) |
| `camera` | カメラ撮影、写真プレビュー |
| `ai_generate` | AI によるハッシュタグ・キャプション生成 |
| `album` | アルバム管理、写真一覧・詳細表示 |
| `settings` | アプリ設定、サブスクリプション管理 |

### 4.5 サービス層

feature 横断の共通サービスは `services/` ディレクトリに配置しています。

| サービス | ファイル | 説明 |
| --- | --- | --- |
| API クライアント | `api_client.dart` | Dio ベースの HTTP クライアント。バックエンド API との通信を担当 |
| Supabase サービス | `supabase_service.dart` | Supabase Flutter SDK の初期化と管理 |
| 広告サービス | `admob_service.dart` | Google Mobile Ads (AdMob) の管理 |
| 課金サービス | `purchase_service.dart` | アプリ内課金 (In-App Purchase) の管理 |
| 共有サービス | `share_service.dart` | 写真・コンテンツの外部共有機能 |

---

## 5. データフロー

### 5.1 認証フロー

```
User → Mobile App → Supabase Auth (signup/login)
                         │
                         ▼
                   JWT (access_token + refresh_token) 発行
                         │
                         ▼
          Mobile App がトークンをセキュアストレージに保存
                         │
                         ▼
          以降の API リクエストに Authorization: Bearer <token> を付与
                         │
                         ▼
              FastAPI Backend → supabase.auth.get_user(token) で検証
                         │
                         ▼
              public.users テーブルからプロフィール (plan, username 等) を取得
                         │
                         ▼
                   リクエスト処理を続行
```

1. ユーザーがモバイルアプリでメールアドレス・パスワードを入力
2. アプリが FastAPI バックエンドの `/api/v1/auth/signup` または `/api/v1/auth/login` を呼び出し
3. バックエンドが Supabase Auth に委譲してユーザー認証を実行
4. Supabase Auth が JWT (access_token / refresh_token) を発行
5. バックエンドが `TokenResponse` としてトークンとユーザー情報をアプリに返却
6. アプリがトークンをセキュアストレージに保存し、以降の API 呼び出しに使用
7. トークン期限切れ時は `/api/v1/auth/refresh` で新しいトークンを取得

### 5.2 写真アップロードフロー

```
Camera / Gallery
      │
      ▼
Mobile App (image_picker / camera)
      │ multipart/form-data
      ▼
FastAPI Backend (POST /api/v1/photos/upload)
      │
      ├── ファイル形式・サイズのバリデーション (JPEG/PNG/WebP/HEIC, 10MB上限)
      │
      ├── Supabase Storage にアップロード
      │     └── パス: {user_id}/photos/{filename}
      │
      ├── photos テーブルにレコード挿入
      │     └── storage_path, original_filename, file_size 等
      │
      ├── 署名付き URL を生成
      │
      └── PhotoResponse をモバイルアプリに返却
```

1. ユーザーがカメラで撮影またはギャラリーから写真を選択
2. モバイルアプリが `multipart/form-data` でバックエンドに送信
3. バックエンドがファイル形式 (JPEG, PNG, WebP, HEIC) とサイズ (10MB以下) を検証
4. Supabase Storage の `photos` バケットにユーザー ID をプレフィックスとしてアップロード
5. `photos` テーブルにメタデータレコードを挿入（失敗時はストレージからクリーンアップ）
6. 署名付き URL を生成して `PhotoResponse` を返却

### 5.3 AI生成フロー

```
User が写真・スタイルを選択
      │
      ▼
Mobile App → POST /api/v1/ai/hashtags (or /caption)
      │
      ▼
FastAPI Backend
      │
      ├── JWT 認証検証
      │
      ├── 日次使用量チェック (users.daily_ai_count)
      │     ├── Free: 10回/日 → 超過時 429 エラー
      │     └── Premium: 無制限
      │
      ├── Supabase Storage から写真バイナリをダウンロード
      │
      ├── Google Gemini API に画像+プロンプトを送信
      │     └── ハッシュタグまたはキャプションを生成
      │
      ├── 生成結果を ai_generations テーブルに記録
      │     └── generation_type, model, prompt, result, latency_ms 等
      │
      ├── users.daily_ai_count をインクリメント
      │
      └── HashtagResponse / CaptionResponse (generation_id 付き) を返却
            │
            ▼
      Mobile App が結果を表示・コピー・共有
```

1. ユーザーがモバイルアプリで対象写真と生成パラメータ (言語、スタイル、件数等) を選択
2. アプリがバックエンドの AI 生成エンドポイントを呼び出し
3. バックエンドが JWT を検証し、ユーザーの日次 AI 使用量を確認
4. 使用量が上限内であれば、Supabase Storage から対象写真のバイナリデータをダウンロード
5. Google Gemini API に画像データとプロンプトを送信して生成結果を取得
6. 生成結果を `ai_generations` テーブルに記録し、使用量カウンターをインクリメント
7. `generation_id` を含むレスポンスをモバイルアプリに返却

---

## 6. セキュリティ

### 6.1 JWT 認証

- Supabase Auth が発行する JWT を使用
- バックエンドは `supabase.auth.get_user(token)` でトークンを検証（署名・有効期限の検証は Supabase 側で実施）
- 認証が必要なエンドポイントでは `Depends(get_current_user)` により自動的にトークン検証が行われる

### 6.2 Row Level Security (RLS)

- 全テーブルに RLS ポリシーを適用
- ユーザーは自分が所有するリソースのみアクセス可能
- バックエンドの通常クライアント (anon key) は RLS を遵守
- 管理操作（アカウント削除等）には service role key を使用する admin クライアントで RLS をバイパス

### 6.3 ストレージ ACL

- Supabase Storage の `photos` バケットはフォルダベースのユーザー隔離を採用
- 各ユーザーの写真は `{user_id}/photos/` パスに格納
- アクセスは署名付き URL 経由で提供

### 6.4 レート制限

- AI 生成エンドポイントにインメモリレート制限を適用 (`RateLimitStore`)
- Free プランユーザーは 1 日 10 回まで、Premium プランは無制限
- DB 上の `users.daily_ai_count` と `daily_ai_reset_at` でも二重チェック
- 日次リセットは日付が変わった時点で自動実行

### 6.5 CORS 設定

- `settings.CORS_ORIGINS` 環境変数で許可するオリジンを管理
- デフォルト: `http://localhost:3000`
- カンマ区切りで複数オリジンを指定可能

---

## 7. 技術スタック

### モバイル (Flutter)

| カテゴリ | 技術 | バージョン | 用途 |
| --- | --- | --- | --- |
| フレームワーク | Flutter | 3.x | クロスプラットフォームモバイルUI |
| 言語 | Dart | ^3.8.1 (SDK) | アプリケーション言語 |
| 状態管理 | flutter_riverpod | ^2.6.1 | リアクティブ状態管理 |
| ルーティング | go_router | ^14.8.1 | 宣言的ナビゲーション |
| カメラ | camera | ^0.11.0+2 | カメラ撮影 |
| 画像選択 | image_picker | ^1.1.2 | ギャラリーからの画像選択 |
| 画像編集 | image_cropper | ^8.0.2 | 画像トリミング |
| BaaS | supabase_flutter | ^2.8.4 | Supabase クライアント (Auth, Storage) |
| HTTP | dio | ^5.7.0 | HTTP クライアント |
| 画像キャッシュ | cached_network_image | ^3.4.1 | ネットワーク画像のキャッシュ表示 |
| 共有 | share_plus | ^10.1.4 | OS ネイティブ共有機能 |
| セキュアストレージ | flutter_secure_storage | ^9.2.4 | トークンの暗号化保存 |
| 広告 | google_mobile_ads | ^5.3.0 | AdMob 広告表示 |
| 課金 | in_app_purchase | ^3.2.0 | アプリ内課金 (iOS / Android) |
| 国際化 | intl | ^0.19.0 | 日付・数値フォーマット |
| ファイルパス | path_provider | ^2.1.5 | アプリファイルシステムアクセス |
| コード生成 | freezed / json_serializable | ^2.5.7 / ^6.9.4 | イミュータブルモデル・JSON シリアライズ |
| テスト | flutter_test / mockito | SDK / ^5.4.5 | ユニットテスト・モック |

### バックエンド (Python)

| カテゴリ | 技術 | バージョン | 用途 |
| --- | --- | --- | --- |
| 言語 | Python | 3.12 | アプリケーション言語 |
| フレームワーク | FastAPI | - | Web API フレームワーク |
| ASGI サーバー | Uvicorn | - | 非同期 HTTP サーバー |
| AI | google-genai (Gemini) | - | Google Gemini API クライアント |
| BaaS クライアント | supabase-py | - | Supabase Python クライアント |
| HTTP クライアント | httpx | - | 非同期 HTTP クライアント |
| バリデーション | Pydantic v2 | - | データバリデーション・シリアライズ |
| 設定管理 | pydantic-settings | - | 環境変数ベースの設定管理 |
| JWT | python-jose | - | JWT トークン処理 |
| リント | Ruff | - | Python リンター・フォーマッター |
| テスト | pytest | - | テストフレームワーク |

### データベース・インフラ

| カテゴリ | 技術 | バージョン | 用途 |
| --- | --- | --- | --- |
| データベース | PostgreSQL | 15 (Alpine) | リレーショナルデータベース |
| 認証 | Supabase Auth | - | ユーザー認証・JWT 発行 |
| ストレージ | Supabase Storage | - | 写真ファイルのオブジェクトストレージ |
| コンテナ | Docker Compose | - | ローカル開発環境のオーケストレーション |
| CI/CD | GitHub Actions | - | 継続的インテグレーション・デリバリー |

---

## 8. デプロイメント

### 8.1 ローカル開発環境

`docker-compose.yml` により、以下のサービスをローカルで起動できます。

| サービス | イメージ | ポート | 説明 |
| --- | --- | --- | --- |
| `backend` | カスタム (backend/Dockerfile) | 8000 | FastAPI アプリケーション |
| `db` | postgres:15-alpine | 5432 | PostgreSQL データベース |

```bash
# ローカル開発環境の起動
docker compose up -d

# バックエンドの環境変数は backend/.env に設定
# DB接続情報: postgres:postgres@localhost:5432/ai_photographer
```

`backend` サービスは `db` サービスに依存しており、PostgreSQL が起動完了後にバックエンドが起動します。データは `postgres_data` ボリュームに永続化されます。

### 8.2 CI/CD パイプライン

GitHub Actions で 3 つのワークフローを運用しています。

#### mobile-ci.yml (Mobile CI)

- **トリガー**: `mobile/` 配下のファイルに対する push / pull_request
- **環境**: ubuntu-latest, Flutter 3.x (stable)
- **ステップ**:
  1. 依存パッケージのインストール (`flutter pub get`)
  2. 静的解析 (`flutter analyze`)
  3. テスト実行 (`flutter test`)

#### backend-ci.yml (Backend CI)

- **トリガー**: `backend/` 配下のファイルに対する push / pull_request
- **環境**: ubuntu-latest, Python 3.12
- **ステップ**:
  1. 依存パッケージのインストール (`pip install -r requirements.txt`)
  2. リント (`ruff check .`)
  3. テスト実行 (`pytest -v`)

#### db-migration.yml (DB Migration)

- **トリガー**: `supabase/` 配下のファイルに対する push / pull_request
- **環境**: ubuntu-latest
- **ステップ**:
  1. SQL ファイルの存在確認と内容検証（空ファイルがないことを確認）

各ワークフローはパスフィルタリングにより、変更があったディレクトリに対応するパイプラインのみが実行されます。これにより、CI の実行時間とコストを最小限に抑えています。
