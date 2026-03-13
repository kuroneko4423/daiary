# dAIary

写真で日々を記録し、AIが言葉を添えるフォトダイアリーアプリケーション。生成AIを活用してハッシュタグや投稿文を自動生成し、SNS投稿を効率化します。

## 技術スタック

| 領域 | 技術 |
|------|------|
| モバイル | Flutter (Riverpod + GoRouter) |
| バックエンド | FastAPI (Python) |
| データベース | Supabase (PostgreSQL) |
| 認証 | Supabase Auth |
| ストレージ | Supabase Storage |
| AI | Google Gemini API |
| 広告 | Google AdMob |
| CI/CD | GitHub Actions |

## ディレクトリ構成

```
daiary/
├── mobile/          # Flutter アプリ
├── backend/         # FastAPI サーバー
├── supabase/        # マイグレーション・RLSポリシー
├── docs/            # 設計ドキュメント
├── .github/         # CI/CD ワークフロー
├── Makefile         # 統一タスクランナー
└── docker-compose.yml
```

## セットアップ

### 前提条件

- Flutter SDK 3.x
- Python 3.12+
- Docker Desktop
- Supabase CLI

### 環境変数

各パッケージの `.env.example` を `.env` にコピーし、値を設定してください。

### 起動

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

### テスト

```bash
make backend-test
make mobile-test
```
