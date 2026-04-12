# dAIary

写真で日々を記録し、AIが言葉を添えるフォトダイアリーアプリケーション。生成AIを活用してハッシュタグや投稿文を自動生成し、SNS投稿を効率化します。

本リポジトリは **オンライン版** と **オフライン版** の2つのモバイルアプリを、共有パッケージを核としたMelosモノレポで管理しています。

## バージョン比較

|項目|オンライン版 (`apps/online/`)|オフライン版 (`apps/offline/`)|
|----|----|----|
|データ保存|Supabase (PostgreSQL)|SQLite (ローカル)|
|認証|Supabase Auth (Email/OAuth)|なし（シングルユーザー）|
|ストレージ|Supabase Storage|ローカルファイルシステム|
|AI|Google Gemini API (クラウド)|Gemma 4 E2B (オンデバイス / MediaPipe)|
|バックエンド|FastAPI サーバー必須|不要（完全オフライン）|
|広告 / 課金|Google AdMob / IAP|なし|
|ネットワーク|常時必要|初回モデルDL後は不要|

## 技術スタック

### 共有パッケージ (`packages/shared/`)

|領域|技術|
|----|----|
|状態管理|flutter_riverpod|
|ルーティング|go_router|
|カメラ|camera + image_picker|
|共有|share_plus|

### オンライン版固有

|領域|技術|
|----|----|
|バックエンド|FastAPI (Python)|
|データベース|Supabase (PostgreSQL)|
|認証|Supabase Auth|
|AI|Google Gemini API|
|広告|Google AdMob|

### オフライン版固有

|領域|技術|
|----|----|
|データベース|SQLite (sqflite)|
|AI|Gemma 4 E2B (MediaPipe LLM Inference, Platform Channel経由)|
|EXIF抽出|exif パッケージ|
|設定永続化|shared_preferences|

## ディレクトリ構成

```text
daiary/
├── apps/
│   ├── online/             # Flutter アプリ（オンライン版）
│   └── offline/            # Flutter アプリ（オフライン版）
├── packages/
│   └── shared/             # 共有 Dart パッケージ
├── backend/                # FastAPI サーバー（オンライン版）
├── web/                    # Next.js Web版（オンライン版）
├── supabase/               # マイグレーション・RLSポリシー
├── docs/                   # 設計ドキュメント
├── melos.yaml              # Melos モノレポ設定
└── pubspec.yaml            # ワークスペースルート
```

## セットアップ

### 前提条件

- Flutter SDK 3.x
- Dart SDK 3.8+
- Python 3.12+（オンライン版のみ）
- Docker Desktop（オンライン版のみ）

### Melos セットアップ

```bash
# ルートの依存関係をインストール（Melos含む）
dart pub get

# 全パッケージの依存解決
dart run melos bootstrap
```

### オンライン版の起動

```bash
# バックエンドサーバー起動
make backend-run

# モバイルアプリ起動
cd apps/online && flutter run
```

環境変数: `backend/.env.example` を `.env` にコピーし値を設定。

### オフライン版の起動

```bash
cd apps/offline && flutter run
```

環境変数の設定は不要。初回起動時にAIモデル（約1GB）のダウンロードを求められます。

**注意:** ネイティブMediaPipe統合は現在スキャフォールド実装です。詳細は [docs/backlog_daiary.md](docs/backlog_daiary.md) の OL-001〜004 を参照。

### テスト

```bash
# 全パッケージの静的解析
cd packages/shared && flutter analyze
cd apps/online && flutter analyze
cd apps/offline && flutter analyze

# オフライン版テスト
cd apps/offline && flutter test

# バックエンド
make backend-test
```

## ドキュメント

- [要件定義書](docs/dAIary_要件定義書.md)
- [実装計画書](docs/dAIary_実装計画書.md)
- [アーキテクチャ](docs/architecture.md)
- [API仕様](docs/api-spec.md)
- [バックログ管理簿](docs/backlog_daiary.md)
- [リファクタリング計画書](docs/daiary-refactoring-plan.md)
- [ER図](docs/er-diagram.md)
- [デプロイガイド](docs/deployment-guide.md)
