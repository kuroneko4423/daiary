# dAIary Offline

dAIary のオフライン版モバイルアプリ。認証不要・サーバー不要で、完全にオフライン環境で動作します。

## 特徴

- **完全オフライン**: Supabase/バックエンドサーバー不要。初回AIモデルダウンロード後はネットワーク接続不要
- **プライバシー重視**: 全データ（写真・アルバム・AI生成結果）がデバイス内のSQLiteに保存され、外部に送信されない
- **オンデバイスAI**: Gemma 4 E2B（MediaPipe LLM Inference API）を使用してハッシュタグ・キャプションをローカル生成
- **シングルユーザー**: 認証・課金・広告なし

## 技術スタック

|領域|技術|
|----|----|
|フレームワーク|Flutter (Riverpod + GoRouter)|
|データベース|SQLite (sqflite)|
|ストレージ|ローカルファイルシステム (path_provider)|
|AI|Gemma 4 E2B (MediaPipe LLM Inference, Platform Channel経由)|
|EXIF抽出|exif パッケージ|
|設定永続化|shared_preferences|

## アーキテクチャ

Clean Architecture を踏襲。`features/<name>/{data, domain, presentation}` でフィーチャー単位に分割。

```
Flutter (UI / Presentation)
  ├── Local Repository → SQLite + ローカルファイル
  └── Platform Channel → Kotlin/Swift (MediaPipe + Gemma)
```

### SQLite スキーマ

- `photos`: 写真メタデータ（local_path, thumbnail_path, exif_data, ai_tags, is_favorite, deleted_at）
- `albums`: アルバム情報（name, cover_photo_id）
- `album_photos`: 写真とアルバムの多対多関係
- `ai_generations`: AI生成履歴（ハッシュタグ/キャプション）

## セットアップ

```bash
cd mobile-offline
flutter pub get
flutter run
```

環境変数の設定は不要です。

## 初回起動フロー

1. 初回起動時、オンボーディング画面が自動表示される
2. Wi-Fi接続を確認し、Gemma 4 E2Bモデル（約1GB）をダウンロード
3. ダウンロード完了後、カメラ画面に遷移

以降はローカルデータのみで動作します。

## テスト

```bash
flutter test
```

`sqflite_common_ffi` によるインメモリSQLiteでデータ層のユニットテストを実行します。

## 未実装項目（バックログ）

実装中・未実装の機能は [../docs/backlog_daiary.md](../docs/backlog_daiary.md) の `OL-*` プレフィックスで管理しています。

特に以下はネイティブ側の実装が必要です:

- **OL-001〜004**: Android/iOS のMediaPipe LLM Inference API実統合（現在はスキャフォールド）
- **OL-003**: Gemmaモデルの実ダウンロード実装（現在はプレースホルダー）
- **OL-060, OL-061**: Android/iOS ビルド設定（MediaPipe依存追加）

## ディレクトリ構成

```
mobile-offline/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── config/           # ルーティング・テーマ
│   ├── core/             # 共通ウィジェット・定数・例外
│   ├── features/
│   │   ├── camera/       # カメラ撮影
│   │   ├── album/        # 写真・アルバム管理
│   │   ├── ai_generate/  # AI生成（ハッシュタグ・キャプション）
│   │   ├── settings/     # 設定画面
│   │   └── onboarding/   # 初回モデルDL画面
│   └── services/         # DatabaseService, ThumbnailService, ShareService等
├── android/
│   └── app/src/main/kotlin/.../GemmaPlugin.kt   # Android MediaPipe Plugin
├── ios/
│   └── Runner/GemmaPlugin.swift                  # iOS MediaPipe Plugin
└── test/
    └── datasources/      # データ層ユニットテスト
```
