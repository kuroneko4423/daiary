# dAIary（ダイアリー） 実装計画書

**バージョン:** 2.0  
**作成日:** 2026年3月6日  
**最終更新:** 2026年4月12日  
**ステータス:** ドラフト

---

## 1. 開発体制・方針

### 1.1 開発方針

- アジャイル開発（2週間スプリント）
- MVP（Minimum Viable Product）を最短でリリースし、ユーザーフィードバックに基づいて改善
- モバイル（Flutter）とバックエンド（FastAPI）を並行開発
- モノレポ構成を採用し、フロントエンド・バックエンド・共有リソースを単一リポジトリで管理

### 1.2 開発環境

| 項目 | ツール |
|---|---|
| バージョン管理 | GitHub（モノレポ） |
| CI/CD | GitHub Actions（パス指定による差分ビルド） |
| プロジェクト管理 | GitHub Issues + Projects |
| デザイン | Figma |
| API仕様書 | FastAPI自動生成（Swagger / ReDoc） |
| コミュニケーション | Discord |
| タスクランナー | Makefile（ルートから各パッケージの操作を統一） |

### 1.3 ブランチ戦略

```
main ─── develop ─── feature/xxx
              │
              ├──── feature/mobile/cam-001-camera
              ├──── feature/backend/ai-001-hashtag
              ├──── feature/mobile/alb-001-album
              ├──── feature/infra/ci-setup
              └──── release/v1.0.0
```

- `main`: 本番リリース用
- `develop`: 開発統合ブランチ
- `feature/mobile/*`: モバイル機能開発ブランチ
- `feature/backend/*`: バックエンド機能開発ブランチ
- `feature/infra/*`: インフラ・CI/CD関連ブランチ
- `release/*`: リリース候補ブランチ
- `hotfix/*`: 緊急修正用ブランチ

### 1.4 モノレポ運用ルール

- CI/CDはパスフィルタにより変更のあったパッケージのみビルド・テストを実行
  - `mobile/` 配下の変更 → Flutter lint / test / build（オンライン版）
  - `mobile-offline/` 配下の変更 → Flutter lint / test / build（オフライン版）
  - `backend/` 配下の変更 → pytest / lint
  - `supabase/` 配下の変更 → マイグレーション検証
- ルートの `Makefile` から各パッケージの主要操作を統一実行可能
- 共有ドキュメント（API仕様・設計資料）は `docs/` に集約
- 環境変数テンプレートは各パッケージの `.env.example` で管理

---

## 2. 技術設計

### 2.1 モノレポ全体構成

```
daiary/                           # リポジトリルート
├── README.md
├── Makefile                      # 統一タスクランナー
├── .github/
│   └── workflows/
│       ├── mobile-ci.yml         # Flutter CI（mobile/変更時のみ）
│       ├── mobile-offline-ci.yml # Flutter CI（mobile-offline/変更時のみ）
│       ├── backend-ci.yml        # FastAPI CI（backend/変更時のみ）
│       └── db-migration.yml      # マイグレーション検証
├── mobile/                       # Flutter アプリ（オンライン版）
│   ├── pubspec.yaml
│   ├── analysis_options.yaml
│   ├── .env.example
│   ├── lib/
│   ├── test/
│   ├── integration_test/
│   └── android/ & ios/
├── mobile-offline/               # Flutter アプリ（オフライン版）
│   ├── pubspec.yaml
│   ├── lib/
│   ├── test/
│   └── android/ & ios/
├── backend/                      # FastAPI サーバー（オンライン版のみ）
│   ├── pyproject.toml
│   ├── requirements.txt
│   ├── Dockerfile
│   ├── .env.example
│   ├── main.py
│   ├── api/
│   ├── models/
│   ├── schemas/
│   ├── services/
│   ├── middleware/
│   └── tests/
├── supabase/                     # Supabase設定・マイグレーション
│   ├── config.toml
│   ├── migrations/
│   │   ├── 001_create_users.sql
│   │   ├── 002_create_photos.sql
│   │   ├── 003_create_albums.sql
│   │   └── 004_create_ai_generations.sql
│   ├── seed.sql                  # 開発用シードデータ
│   └── functions/                # Supabase Edge Functions（将来拡張）
├── docs/                         # 共有ドキュメント
│   ├── api-spec.md               # API仕様書
│   ├── architecture.md           # アーキテクチャ設計
│   ├── er-diagram.md             # ER図
│   └── prompt-design.md          # AIプロンプト設計書
└── docker-compose.yml            # ローカル開発用（backend + Supabase）
```

### 2.2 Flutter オンライン版（mobile/）

#### アーキテクチャ: Riverpod + Go Router + Repository Pattern

```
mobile/lib/
├── main.dart
├── app.dart
├── config/
│   ├── env.dart              # 環境変数
│   ├── theme.dart            # テーマ定義
│   └── router.dart           # GoRouter設定
├── core/
│   ├── constants/
│   ├── exceptions/
│   ├── extensions/
│   ├── utils/
│   └── widgets/              # 共通ウィジェット
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/  # Supabase Auth
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   └── repositories/ # abstract
│   │   └── presentation/
│   │       ├── providers/    # Riverpod providers
│   │       ├── screens/
│   │       └── widgets/
│   ├── camera/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── ai_generate/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── album/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── settings/
│       ├── data/
│       ├── domain/
│       └── presentation/
└── services/
    ├── api_client.dart       # FastAPIクライアント
    ├── supabase_service.dart
    ├── admob_service.dart
    ├── purchase_service.dart
    └── share_service.dart    # OS共有シート連携
```

#### 主要パッケージ

| パッケージ | 用途 |
|---|---|
| flutter_riverpod | 状態管理 |
| go_router | ルーティング |
| camera | カメラ制御 |
| image_picker | フォトライブラリ取り込み |
| image_cropper | トリミング |
| photo_manager | 写真管理 |
| supabase_flutter | Supabase SDK |
| google_mobile_ads | AdMob |
| in_app_purchase | アプリ内課金 |
| flutter_secure_storage | トークン安全保管 |
| dio | HTTPクライアント |
| freezed / json_serializable | モデル生成 |
| cached_network_image | 画像キャッシュ |
| share_plus | OS標準共有シート |

### 2.2A Flutter オフライン版（mobile-offline/）

#### アーキテクチャ: Riverpod + Go Router + Repository Pattern + Platform Channel

オンライン版のClean Architectureを継承し、data層のdatasourceをremote→localに差し替えた構成。バックエンドサーバー不要。

```
mobile-offline/lib/
├── main.dart
├── app.dart
├── config/
│   ├── theme.dart            # テーマ定義
│   └── router.dart           # GoRouter設定（認証なし、初回起動リダイレクト）
├── core/
│   ├── constants/
│   ├── exceptions/
│   ├── extensions/
│   ├── utils/
│   └── widgets/              # 共通ウィジェット
├── features/
│   ├── camera/
│   │   ├── data/
│   │   │   └── repositories/ # CameraRepository（ローカル保存+DB登録+EXIF抽出+サムネイル生成）
│   │   ├── domain/
│   │   │   └── entities/     # Photo（localPath, exifData, width/height）
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/
│   │       └── widgets/
│   ├── ai_generate/
│   │   ├── data/
│   │   │   ├── datasources/  # AiLocalDataSource（Platform Channel経由）
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   └── repositories/
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/      # モデル未DL時のUI制御
│   │       └── widgets/
│   ├── album/
│   │   ├── data/
│   │   │   ├── datasources/  # PhotoLocalDataSource, AlbumLocalDataSource（SQLite）
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/      # 写真追加ピッカーUI、カバー写真表示
│   │       └── widgets/
│   ├── settings/
│   │   ├── data/
│   │   │   └── repositories/ # SettingsRepository（SharedPreferences）
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── providers/    # SettingsProvider, StorageProvider
│   │       └── screens/      # ストレージ使用量、全データ削除、AIモデル管理
│   └── onboarding/
│       └── presentation/
│           ├── providers/    # OnboardingNotifier（Wi-Fiチェック、モデルDL管理）
│           └── screens/      # 初回起動モデルDL画面
└── services/
    ├── database_service.dart  # SQLite初期化・マイグレーション・全データ削除
    ├── ai_model_service.dart  # Gemmaモデル状態確認
    ├── thumbnail_service.dart # ローカルサムネイル生成
    └── share_service.dart     # OS共有シート連携
```

#### ネイティブ側（Platform Channel）

```
mobile-offline/android/app/src/main/kotlin/.../
├── MainActivity.kt           # GemmaPlugin登録
└── GemmaPlugin.kt            # MediaPipe LLM Inference API統合

mobile-offline/ios/Runner/
├── AppDelegate.swift          # GemmaPlugin登録
└── GemmaPlugin.swift          # MediaPipe LLM Inference API統合
```

#### 主要パッケージ（オフライン版）

| パッケージ | 用途 |
|---|---|
| flutter_riverpod | 状態管理 |
| go_router | ルーティング |
| camera | カメラ制御 |
| image_picker | フォトライブラリ取り込み |
| image_cropper | トリミング |
| sqflite | SQLiteデータベース |
| path_provider | ローカルファイルパス取得 |
| uuid | UUID生成 |
| image | 画像処理・サムネイル生成 |
| exif | EXIF メタデータ抽出 |
| shared_preferences | 設定永続化・初回起動フラグ |
| connectivity_plus | ネットワーク接続状態チェック |
| share_plus | OS標準共有シート |

#### オンライン版との差分

| 項目 | オンライン版 | オフライン版 |
|---|---|---|
| datasource | Remote（Dio HTTP） | Local（SQLite） |
| 認証 | Supabase Auth | なし（初回起動リダイレクトのみ） |
| AI呼び出し | REST API → FastAPI → Gemini | Platform Channel → ネイティブMediaPipe |
| 写真保存 | Supabase Storage | ローカルファイル |
| 課金/広告 | AdMob + IAP | なし |
| 画像表示 | CachedNetworkImage | Image.file（cacheWidth最適化） |

### 2.3 FastAPI（backend/）

#### ディレクトリ構成

```
backend/
├── main.py
├── pyproject.toml
├── requirements.txt
├── Dockerfile
├── .env.example
├── config/
│   ├── settings.py           # 環境設定
│   └── database.py           # Supabase接続
├── api/
│   ├── v1/
│   │   ├── router.py
│   │   ├── auth.py
│   │   ├── photos.py
│   │   ├── albums.py
│   │   ├── ai_generate.py
│   │   └── payments.py
│   └── deps.py               # 依存性注入
├── models/
│   ├── user.py
│   ├── photo.py
│   ├── album.py
│   └── ai_generation.py
├── schemas/
│   ├── user.py
│   ├── photo.py
│   ├── ai_generate.py
│   └── album.py
├── services/
│   ├── ai_service.py         # Gemini API統合
│   ├── storage_service.py     # Supabase Storage
│   └── payment_service.py     # レシート検証
├── middleware/
│   ├── auth.py               # JWT検証
│   ├── rate_limit.py         # レート制限
│   └── logging.py
└── tests/
    ├── conftest.py
    ├── test_ai_generate.py
    ├── test_photos.py
    └── test_albums.py
```

#### 主要ライブラリ

| ライブラリ | 用途 |
|---|---|
| fastapi | Webフレームワーク |
| uvicorn | ASGIサーバー |
| google-genai | Gemini API SDK |
| supabase-py | Supabase Python SDK |
| httpx | 非同期HTTPクライアント |
| pydantic | バリデーション |
| python-jose | JWT処理 |
| alembic | DBマイグレーション |
| pytest + httpx | テスト |

### 2.4 AI生成 プロンプト設計方針

#### ハッシュタグ生成

```
システムプロンプト:
あなたはSNSマーケティングの専門家です。
与えられた写真を分析し、エンゲージメントを最大化する
ハッシュタグを{count}個生成してください。

条件:
- 言語: {language}
- 用途: {usage} (少なめ: X/Facebook向け / 多め: Instagram向け)
- ニッチすぎず、広すぎない適切な粒度
- トレンドを意識したハッシュタグを含む
- JSON形式で出力: {"hashtags": ["#tag1", "#tag2", ...]}
```

#### 投稿文生成

```
システムプロンプト:
あなたはSNSコンテンツクリエイターです。
与えられた写真に合う{style}スタイルの投稿文を生成してください。

条件:
- 文章スタイル: {style}
- 言語: {language}
- 文章長: {length} (短文: ~100文字 / 中文: ~300文字 / 長文: ~800文字)
- ハッシュタグは含めない（別途生成）
- JSON形式で出力: {"caption": "生成された投稿文"}
```

### 2.5 インフラ構成

```
┌─ Railway ───────────────────────────────┐
│  FastAPI (本番)                          │
│  └── API Server (uvicorn)               │
└─────────────────────────────────────────┘
         │
         ▼
┌─ Supabase Cloud ────────────────────────┐
│  ├── PostgreSQL (データベース)           │
│  ├── Auth (認証)                        │
│  ├── Storage (写真ストレージ)           │
│  └── Realtime (将来拡張用)              │
└─────────────────────────────────────────┘
         │
         ▼
┌─ 外部サービス ──────────────────────────┐
│  ├── Gemini API                         │
│  └── Firebase (FCM / Analytics)         │
└─────────────────────────────────────────┘
```

デプロイ先の候補:
- **Railway**: FastAPIのデプロイが容易、スケールも柔軟
- **Vercel**: FastAPIをServerless Functionsとしてデプロイ
- **AWS EC2**: フルコントロールが必要な場合

### 2.6 オフライン版インフラ構成

オフライン版はデプロイ先が不要（アプリ内で完結）。

```text
┌─ デバイス内 ────────────────────────────┐
│  Flutter App (Offline)                  │
│  ├── SQLite (データベース)              │
│  ├── ローカルファイルシステム (写真)    │
│  ├── SharedPreferences (設定)           │
│  └── Platform Channel                  │
│      └── MediaPipe + Gemma 4 E2B       │
└─────────────────────────────────────────┘
         │ (初回のみ)
         ▼
┌─ 外部 ─────────────────────────────────┐
│  AIモデルホスティング (CDN/Kaggle等)    │
│  └── gemma-4-e2b-it-int4.bin (~1GB)    │
└─────────────────────────────────────────┘
```

---

## 3. 開発フェーズ・スケジュール

### 3.1 オンライン版フェーズ概要

| フェーズ | 期間 | 内容 |
|---|---|---|
| Phase 0: 設計・準備 | 2週間 | 環境構築、UI設計、DB設計 |
| Phase 1: MVP開発 | 6週間 | コア機能の実装 |
| Phase 2: 課金・広告 | 3週間 | サブスクリプション・AdMob |
| Phase 3: テスト・リリース準備 | 3週間 | QA・ストア申請 |
| 合計 | 約14週間（3.5ヶ月） | |

### 3.2 Phase 0: 設計・準備（2週間）

**Sprint 0（Week 1-2）**

| タスク | 詳細 | 成果物 |
|---|---|---|
| モノレポ初期セットアップ | リポジトリ作成、ディレクトリ構成、Makefile、.gitignore | リポジトリルート構成 |
| 開発環境セットアップ | Flutter / FastAPI / Supabaseの初期設定 | mobile/ backend/ supabase/ |
| CI/CDパイプライン構築 | GitHub Actions設定（パスフィルタによる差分ビルド） | .github/workflows/ |
| ローカル開発環境整備 | docker-compose.yml（backend + Supabase Local） | docker-compose.yml |
| UI/UXデザイン | Figmaでワイヤーフレーム・モックアップ作成 | Figmaデザインファイル |
| DBスキーマ設計 | Supabaseテーブル定義・RLSポリシー設計 | supabase/migrations/ |
| API設計 | エンドポイント一覧・リクエスト/レスポンス定義 | docs/api-spec.md |
| Gemini API検証 | 画像解析・テキスト生成のPoC | 検証レポート |

### 3.3 Phase 1: MVP開発（6週間）

**Sprint 1（Week 3-4）: 認証 + カメラ基盤**

| タスク | 優先度 | 詳細 |
|---|---|---|
| Supabase Auth統合 | 高 | メール/Google/Apple認証 |
| ログイン/サインアップ画面 | 高 | Flutter UI実装 |
| カメラ撮影機能 | 高 | camera パッケージ統合 |
| フォトライブラリ取り込み | 高 | image_picker統合 |
| 写真のSupabase Storage保存 | 高 | アップロード処理・サムネイル生成 |
| FastAPI基盤構築 | 高 | プロジェクト構造・認証ミドルウェア |

**Sprint 2（Week 5-6）: AI生成機能**

| タスク | 優先度 | 詳細 |
|---|---|---|
| AI生成APIエンドポイント | 高 | FastAPI側のGemini API統合 |
| ハッシュタグ生成機能 | 高 | 画像送信→ハッシュタグ取得 |
| 投稿文生成機能 | 高 | スタイル指定→文章生成 |
| AI生成UI | 高 | スタイル選択・結果表示・編集画面 |
| クリップボードコピー・共有機能 | 高 | share_plus統合 |
| 生成回数制限管理 | 中 | 無料プランの日次制限ロジック |
| AI生成ログ記録 | 中 | 利用状況の記録・分析用 |

**Sprint 3（Week 7-8）: アルバム + 写真管理**

| タスク | 優先度 | 詳細 |
|---|---|---|
| アルバムCRUD | 高 | 作成・編集・削除・写真追加 |
| 写真一覧・詳細画面 | 高 | グリッドビュー・EXIF表示 |
| 写真編集機能 | 中 | トリミング・フィルタ・調整 |
| お気に入り・検索機能 | 中 | AIタグベース検索 |
| クラウド同期 | 中 | Supabase Storageとの同期処理 |
| ゴミ箱機能 | 低 | 論理削除・30日自動削除 |

### 3.4 Phase 2: 課金・広告（3週間）

**Sprint 4（Week 9-10）: サブスクリプション**

| タスク | 優先度 | 詳細 |
|---|---|---|
| iOS In-App Purchase統合 | 高 | StoreKit 2対応 |
| Android Google Play Billing | 高 | Billing Library 6.x |
| サーバーサイドレシート検証 | 高 | App Store / Google Play Developerサーバー通知 |
| プラン管理UI | 高 | 購入・復元・解約画面 |
| 無料トライアルフロー | 中 | 7日間トライアル |

**Sprint 5（Week 11）: 広告**

| タスク | 優先度 | 詳細 |
|---|---|---|
| AdMob統合 | 高 | バナー・インタースティシャル・リワード |
| 広告表示ロジック | 高 | プレミアムユーザー非表示判定 |
| リワード広告→AI回数追加 | 中 | 視聴完了コールバック処理 |
| 広告表示頻度の調整 | 中 | UXを損なわない頻度設定 |

### 3.5 Phase 3: テスト・リリース準備（3週間）

**Sprint 6（Week 12-13）: QA・最適化**

| タスク | 優先度 | 詳細 |
|---|---|---|
| 総合テスト | 高 | 機能テスト・回帰テスト |
| パフォーマンス最適化 | 高 | 画像キャッシュ・遅延読込・メモリ管理 |
| セキュリティテスト | 高 | 認証フロー・RLS検証 |
| UI/UX改善 | 中 | ユーザビリティテスト結果の反映 |
| エラーハンドリング整備 | 中 | オフライン時・API障害時の挙動 |
| クラッシュレポート統合 | 中 | Firebase Crashlytics |

**Sprint 7（Week 14）: リリース**

| タスク | 優先度 | 詳細 |
|---|---|---|
| App Store審査申請 | 高 | スクリーンショット・説明文・プライバシーポリシー |
| Google Play審査申請 | 高 | ストアリスティング・コンテンツレーティング |
| プライバシーポリシー作成 | 高 | 個人情報保護法準拠 |
| 利用規約作成 | 高 | サービス利用条件 |
| ランディングページ作成 | 中 | アプリ紹介サイト |
| 運用監視設定 | 中 | ログ・アラート・ダッシュボード |

### 3.6 オフライン版フェーズ概要

| フェーズ | 期間 | 内容 |
|---|---|---|
| Phase OL-1: 基盤構築 | 1週間 | mobile/からのコピー、SQLite化、認証/課金/広告除去、pubspec更新 |
| Phase OL-2: ローカルデータ層 | 1週間 | PhotoLocalDataSource、AlbumLocalDataSource、エンティティ改修、provider書き換え |
| Phase OL-3: カメラ・写真フロー | 1週間 | DB連携、サムネイル生成、EXIF抽出、画像サイズ取得、ゴミ箱クリーンアップ |
| Phase OL-4: UI/UX・設定 | 1週間 | ルーティング、設定画面、テーマ反映、ストレージ表示、全データ削除 |
| Phase OL-5: AI統合 | 2週間 | Platform Channel、GemmaPlugin(Android/iOS)、オンボーディング、Wi-Fiチェック |
| Phase OL-6: テスト・仕上げ | 1週間 | ユニットテスト、画像最適化、エラーハンドリング |
| 合計 | 約7週間 | |

#### Phase OL-1〜4: 実装済み

基盤構築からUI/UX・設定までの全項目は実装完了。

| 完了項目 | 内容 |
|---|---|
| SQLiteスキーマ | 4テーブル + インデックス、DatabaseService |
| ローカルデータ層 | PhotoLocalDataSource、AlbumLocalDataSource（SQLite CRUD） |
| カメラ・写真フロー | 撮影→保存→DB登録→サムネイル生成→EXIF抽出→画像サイズ取得 |
| アルバム機能 | 写真追加ピッカーUI、カバー写真表示 |
| ルーティング | go_router（認証なし、初回起動リダイレクト） |
| 設定画面 | テーマ反映、ストレージ使用量表示、全データ削除 |
| AI UI | モデル未DL時のボタン無効化＋案内バナー |
| オンボーディング | 初回起動フロー、Wi-Fiチェック、モデルDL画面 |
| テスト | データ層ユニットテスト（sqflite_common_ffi） |
| 最適化 | cacheWidth + frameBuilderフェードイン |

#### Phase OL-5: ネイティブAI統合（未実装）

GemmaPlugin.kt / GemmaPlugin.swiftのスキャフォールドは作成済み。MediaPipe Tasks GenAI SDKの実統合が残タスク。

| タスク | 優先度 | 詳細 |
|---|---|---|
| Android MediaPipe LLM統合 | 高 | mediapipe-tasks-genai AAR依存追加、LlmInference実装 |
| iOS MediaPipe LLM統合 | 高 | MediaPipeTasksGenAI Pod追加、LlmInference実装 |
| Gemmaモデル実ダウンロード | 高 | CDN/Kaggleからの実DL処理、中断・再開対応 |
| マルチモーダル画像入力 | 高 | 画像+テキストプロンプトのネイティブ処理 |
| プロンプト最適化 | 中 | Gemma向けJSON出力安定性・日本語品質の調整 |
| リソース解放 | 中 | アプリバックグラウンド遷移時のメモリ管理 |

> 詳細なバックログは [backlog_daiary.md](backlog_daiary.md) の OL-001〜063 を参照。

---

## 4. API設計（主要エンドポイント）

### 4.1 認証

| メソッド | パス | 説明 |
|---|---|---|
| POST | /api/v1/auth/signup | サインアップ |
| POST | /api/v1/auth/login | ログイン |
| POST | /api/v1/auth/refresh | トークンリフレッシュ |
| POST | /api/v1/auth/password-reset | パスワードリセット |
| DELETE | /api/v1/auth/account | アカウント削除 |

### 4.2 写真

| メソッド | パス | 説明 |
|---|---|---|
| POST | /api/v1/photos/upload | 写真アップロード |
| GET | /api/v1/photos | 写真一覧取得 |
| GET | /api/v1/photos/{id} | 写真詳細取得 |
| PATCH | /api/v1/photos/{id} | 写真メタ情報更新 |
| DELETE | /api/v1/photos/{id} | 写真削除（論理削除） |
| GET | /api/v1/photos/search?q={query} | 写真検索 |

### 4.3 AI生成

| メソッド | パス | 説明 |
|---|---|---|
| POST | /api/v1/ai/hashtags | ハッシュタグ生成 |
| POST | /api/v1/ai/caption | 投稿文生成 |
| GET | /api/v1/ai/usage | AI生成回数の残数確認 |

リクエスト例（ハッシュタグ生成）:
```json
{
  "photo_id": "uuid",
  "language": "ja",
  "count": 15,
  "usage": "instagram"
}
```

リクエスト例（投稿文生成）:
```json
{
  "photo_id": "uuid",
  "language": "ja",
  "style": "poem",
  "length": "medium",
  "custom_prompt": null
}
```

### 4.4 アルバム

| メソッド | パス | 説明 |
|---|---|---|
| POST | /api/v1/albums | アルバム作成 |
| GET | /api/v1/albums | アルバム一覧 |
| GET | /api/v1/albums/{id} | アルバム詳細 |
| PATCH | /api/v1/albums/{id} | アルバム更新 |
| DELETE | /api/v1/albums/{id} | アルバム削除 |
| POST | /api/v1/albums/{id}/photos | 写真追加 |
| DELETE | /api/v1/albums/{id}/photos/{photo_id} | 写真削除 |

### 4.5 課金

| メソッド | パス | 説明 |
|---|---|---|
| POST | /api/v1/payments/verify-receipt | レシート検証 |
| GET | /api/v1/payments/subscription | サブスクリプション状態 |
| POST | /api/v1/payments/webhook/appstore | App Storeサーバー通知 |
| POST | /api/v1/payments/webhook/playstore | Google Playサーバー通知 |

---

## 5. テスト計画

### 5.1 テスト方針（オンライン版）

| テスト種別 | 対象 | ツール | カバレッジ目標 |
|---|---|---|---|
| ユニットテスト | ビジネスロジック・モデル | Flutter Test / pytest | 80%以上 |
| ウィジェットテスト | Flutter UI | Flutter Widget Test | 主要画面 |
| 統合テスト | API⇔DB⇔外部API | pytest + httpx | 全エンドポイント |
| E2Eテスト | ユーザーフロー | integration_test | 主要フロー3本 |

### 5.2 テスト方針（オフライン版）

| テスト種別 | 対象 | ツール | カバレッジ目標 |
|---|---|---|---|
| ユニットテスト | データ層（SQLite CRUD） | Flutter Test + sqflite_common_ffi | DataSource全メソッド |
| ユニットテスト | リポジトリ層 | Flutter Test + mock | 主要リポジトリ |
| ウィジェットテスト | Flutter UI | Flutter Widget Test | 主要画面 |
| 統合テスト | オフライン動作検証 | 手動テスト（機内モード） | 全機能 |

### 5.3 主要テストシナリオ

**オンライン版:**

1. **新規登録→写真撮影→AI生成→クリップボードコピー** の一連フロー
2. **無料プラン制限** が正しく機能する（AI生成10回/日上限）
3. **サブスクリプション購入** 後にプレミアム機能が解放される

**オフライン版:**

1. **初回起動→オンボーディング→モデルDL→カメラ撮影→AI生成→シェア** の一連フロー
2. **機内モード** で全機能（撮影・アルバム・AI生成）が動作することの検証
3. **ゴミ箱自動クリーンアップ** が30日経過した写真を起動時に削除すること
4. **AIモデル未DL時** に生成ボタンが無効化され案内バナーが表示されること

---

## 6. リリース後運用計画

### 6.1 監視・アラート

| 監視項目 | ツール | アラート条件 |
|---|---|---|
| APIレスポンスタイム | Sentry | p95 > 3秒 |
| エラーレート | Sentry | 5分間で10件以上 |
| Gemini API使用量 | Google Cloud Console | 日次予算の80%到達 |
| Supabase使用量 | Supabase Dashboard | ストレージ80%到達 |
| アプリクラッシュ | Firebase Crashlytics | クラッシュフリー率 < 99% |

### 6.2 リリース後ロードマップ

| バージョン | 時期 | 主な機能追加 |
|---|---|---|
| v1.1 | リリース後1ヶ月 | バグ修正・パフォーマンス改善・UI調整 |
| v1.2 | リリース後2ヶ月 | 動画対応（短尺動画の撮影・AI解析） |
| v1.3 | リリース後3ヶ月 | AI画像加工（背景除去・フィルタ強化） |
| v2.0 | リリース後6ヶ月 | SNS直接連携（X / Instagram / TikTok） |

### 6.3 KPI

| 指標 | 目標（リリース後3ヶ月） |
|---|---|
| MAU（月間アクティブユーザー） | 5,000人 |
| DAU / MAU比率 | 30%以上 |
| サブスクリプション転換率 | 5% |
| 平均AI生成回数/ユーザー/日 | 3回 |
| アプリストア評価 | 4.0以上 |
| クラッシュフリー率 | 99.5%以上 |

---

## 7. コスト見積もり（月額・概算）

| 項目 | 無料枠 | 想定月額（MAU 5,000人時） |
|---|---|---|
| Supabase（Pro） | 無料枠あり | $25 |
| Gemini API | 無料枠あり | $50〜150（利用量依存） |
| Railway | 無料枠あり | $20〜50 |
| Firebase | 無料枠あり | $0（無料枠内） |
| ドメイン・SSL | ― | $15/年 |
| Apple Developer Program | ― | $99/年 |
| Google Play Developer | ― | $25（初回のみ） |
| **合計** | | **$95〜225/月** |

---

## 8. リスク管理

| リスク | 影響度 | 発生確率 | 対策 |
|---|---|---|---|
| Gemini APIのレート制限 | 中 | 中 | キャッシュ活用、リトライ制御、フォールバック |
| App Store審査リジェクト | 高 | 中 | ガイドライン事前確認、余裕あるスケジュール |
| ユーザーデータ漏洩 | 高 | 低 | RLS徹底、暗号化、定期セキュリティレビュー |
| AI生成の不適切コンテンツ | 中 | 中 | コンテンツフィルタ、Geminiセーフティ設定活用 |
| 開発遅延 | 中 | 中 | MVP優先、フェーズ分割、スコープ調整 |
| Gemini API仕様変更・料金改定 | 中 | 中 | APIラッパー層で吸収、代替モデルの検討 |
