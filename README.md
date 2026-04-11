# dAIary

写真で日々を記録し、AIが言葉を添えるフォトダイアリーアプリケーション。生成AIを活用してハッシュタグや投稿文を自動生成し、SNS投稿を効率化します。

本リポジトリは **オンライン版** と **オフライン版** の2つのモバイルアプリを提供します。

## バージョン比較

|項目|オンライン版 (`mobile/`)|オフライン版 (`mobile-offline/`)|
|----|----|----|
|データ保存|Supabase (PostgreSQL)|SQLite (ローカル)|
|認証|Supabase Auth (Email/OAuth)|なし（シングルユーザー）|
|ストレージ|Supabase Storage|ローカルファイルシステム|
|AI|Google Gemini API (クラウド)|Gemma 4 E2B (オンデバイス / MediaPipe)|
|バックエンド|FastAPI サーバー必須|不要（完全オフライン）|
|広告 / 課金|Google AdMob / IAP|なし|
|ネットワーク|常時必要|初回モデルDL後は不要|

## 技術スタック

### オンライン版 (`mobile/`)

|領域|技術|
|----|----|
|モバイル|Flutter (Riverpod + GoRouter)|
|バックエンド|FastAPI (Python)|
|データベース|Supabase (PostgreSQL)|
|認証|Supabase Auth|
|ストレージ|Supabase Storage|
|AI|Google Gemini API|
|広告|Google AdMob|
|CI/CD|GitHub Actions|

### オフライン版 (`mobile-offline/`)

|領域|技術|
|----|----|
|モバイル|Flutter (Riverpod + GoRouter)|
|データベース|SQLite (sqflite)|
|ストレージ|ローカルファイルシステム (path_provider)|
|AI|Gemma 4 E2B (MediaPipe LLM Inference, Platform Channel経由)|
|EXIF抽出|exif パッケージ|
|設定永続化|shared_preferences|

## ディレクトリ構成

```
daiary/
├── mobile/           # Flutter アプリ（オンライン版）
├── mobile-offline/   # Flutter アプリ（オフライン版）
├── backend/          # FastAPI サーバー（オンライン版のみ）
├── web/              # Next.js Web版（オンライン版）
├── supabase/         # マイグレーション・RLSポリシー
├── docs/             # 設計ドキュメント・バックログ管理
├── .github/          # CI/CD ワークフロー
├── Makefile          # 統一タスクランナー
└── docker-compose.yml
```

## セットアップ

### 前提条件

- Flutter SDK 3.x
- Python 3.12+（オンライン版のみ）
- Docker Desktop（オンライン版のみ）
- Supabase CLI（オンライン版のみ）

### オンライン版の起動

```bash
# 全依存関係のインストール
make setup

# ローカル開発環境の起動（Docker）
make docker-up

# バックエンドサーバー起動
make backend-run

# モバイルアプリ起動
make mobile-run
```

#### 環境変数

各パッケージの `.env.example` を `.env` にコピーし、値を設定してください。

### オフライン版の起動

```bash
cd mobile-offline
flutter pub get
flutter run
```

環境変数の設定は不要です。初回起動時にAIモデル（Gemma 4 E2B、約1GB）のダウンロードを求められます。

**注意:** 現時点ではネイティブMediaPipe統合はスキャフォールド実装で、プレースホルダーレスポンスを返します。実AI推論にはAndroid/iOS側のMediaPipe Tasks GenAI SDK統合が必要です。詳細は [docs/backlog_daiary.md](docs/backlog_daiary.md) の OL-001〜004 を参照。

### テスト

```bash
# オンライン版
make backend-test
make mobile-test

# オフライン版
cd mobile-offline && flutter test
```

## ドキュメント

- [要件定義書](docs/dAIary_要件定義書.md)
- [実装計画書](docs/dAIary_実装計画書.md)
- [アーキテクチャ](docs/architecture.md)
- [API仕様](docs/api-spec.md)
- [バックログ管理簿](docs/backlog_daiary.md) — オンライン版・オフライン版の全バックログ
- [ER図](docs/er-diagram.md)
- [デプロイガイド](docs/deployment-guide.md)
