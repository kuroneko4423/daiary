# CLAUDE.md

このファイルは、Claude Code (claude.ai/code) がこのリポジトリのコードを扱う際のガイダンスを提供します。

## プロジェクト概要

dAIary - 写真撮影とAIによるコンテンツ生成を組み合わせた、SNS投稿向けモバイルフォトダイアリーアプリ。Melosモノレポ構成で、共有Dartパッケージ（`packages/shared`）を核に、オンライン版（Supabase + Gemini API）とオフライン版（SQLite + Gemma）の2つのFlutterアプリを提供。バックエンドはFastAPI、Web版はNext.js。

## ディレクトリ構成

```text
daiary/
├── apps/
│   ├── online/             # オンライン版 Flutter アプリ
│   └── offline/            # オフライン版 Flutter アプリ
├── packages/
│   └── shared/             # 共有 Dart パッケージ（ドメインモデル、UI、core）
├── backend/                # FastAPI サーバー
├── web/                    # Next.js Web版
├── supabase/               # マイグレーション・RLSポリシー
├── docs/                   # 設計ドキュメント
├── melos.yaml              # Melos モノレポ設定
└── pubspec.yaml            # ワークスペースルート
```

## よく使うコマンド

### セットアップ

```bash
dart pub get                 # ルートの依存（Melos）をインストール
dart run melos bootstrap     # 全パッケージの依存解決
```

### モバイル（Flutter, Dart SDK ^3.8.1）

```bash
cd apps/online && flutter run      # オンライン版アプリ実行
cd apps/offline && flutter run     # オフライン版アプリ実行
cd packages/shared && flutter analyze   # 共有パッケージの静的解析
cd apps/online && flutter analyze       # オンライン版の静的解析
cd apps/offline && flutter analyze      # オフライン版の静的解析
cd apps/offline && flutter test         # オフライン版のテスト実行
```

### バックエンド（FastAPI, Python 3.12+）

```bash
make backend-run        # 開発サーバー起動（uvicorn, ポート8000, 自動リロード）
make backend-test       # テスト実行（pytest -v）
make backend-lint       # リント（ruff check .）
```

### Web（Next.js, Node.js 20+）

```bash
make web-dev            # 開発サーバー起動（next dev, ポート3000）
make web-build          # プロダクションビルド
make web-lint           # リント（eslint）
```

### データベース（Supabase）

```bash
make db-migrate         # マイグレーション適用（npx supabase db push）
make db-reset           # データベースリセット
```

## アーキテクチャ

### 共有パッケージ（`packages/shared/`）

オンライン版・オフライン版で共通のコードを集約したDartパッケージ。

- **ドメインモデル**: `domain/models/` — Photo（スーパーセットモデル）、Album、GenerationResult等
- **インターフェース**: `domain/interfaces/` — AiService（sealed ImageInputで画像入力を抽象化）、PhotoRepository、AlbumRepository
- **共有UI**: `features/navigation/main_shell.dart`（ボトムナビ）、camera_controls、album_card、result_card、style_selector等
- **共有State/Notifier**: CameraState、AlbumListState/AlbumDetailState、AiGenerateState、AppSettings
- **core**: constants、exceptions、extensions、utils、widgets
- **config**: theme.dart
- **services**: share_service.dart

### オンライン版（`apps/online/`）

Supabase + Gemini API を使用するクラウド版。

- **認証**: Supabase Auth（Email/Google/Apple）
- **データソース**: REST API経由（Dio HttpClient → FastAPI → Supabase）
- **AI**: Gemini API（FastAPI経由）
- **固有機能**: 認証、課金（IAP）、広告（AdMob）、クラウド同期

### オフライン版（`apps/offline/`）

SQLite + Gemma 4 E2B を使用する完全オフライン版。

- **認証なし**: 初回起動時にオンボーディング画面を表示
- **データソース**: SQLite（sqflite）+ ローカルファイルシステム
- **AI**: Platform Channel → ネイティブ MediaPipe + Gemma（現在スキャフォールド実装）
- **固有機能**: オンボーディング、AIモデルDL管理、ストレージ使用量表示、ゴミ箱自動クリーンアップ

### バックエンド（`backend/`）

レイヤードアーキテクチャ: APIルート（`api/v1/`）→ サービス（`services/`）→ Supabaseクライアント（`config/database.py`）

- **依存性注入**: FastAPI `Depends` による実装
- **テスト**: pytest-asyncio + `httpx.AsyncClient` + ASGIトランスポート
- **Ruff設定**: target py312, line-length 88, ルール E/F/I/N/W/UP（`pyproject.toml`）

### Web（`web/`）

Next.js 14+ (App Router) + TypeScript + Tailwind CSS + shadcn/ui。

### 主要データフロー

- **オンライン AI生成**: Flutter → Dio → FastAPI → Gemini API → ai_generations テーブル
- **オフライン AI生成**: Flutter → Platform Channel → ネイティブ MediaPipe → Gemma → SQLite

### 環境変数

- バックエンド: `backend/.env.example` を `backend/.env` にコピー
- Web: `web/.env.example` を `web/.env.local` にコピー
- オンライン版モバイル: `apps/online/` 配下の `.env.example` を参照
- オフライン版モバイル: 環境変数不要

## 言語

プロジェクトドキュメントは日本語で記述。コードとAPIは英語で記述。
