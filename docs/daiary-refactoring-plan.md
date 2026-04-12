# dAIary リファクタリング計画書

## 1. 現状分析

### 1.1 リポジトリ構成の現状

```
daiary/
├── mobile/            # オンライン版 Flutter アプリ（独立プロジェクト）
├── mobile-offline/    # オフライン版 Flutter アプリ（独立プロジェクト）
├── backend/           # FastAPI サーバー
├── web/               # Next.js Web版
├── supabase/          # マイグレーション・RLS
└── docs/              # 設計ドキュメント
```

### 1.2 特定された課題

#### 課題A: コードの大量重複

`mobile/` と `mobile-offline/` が**完全に独立した2つの Flutter プロジェクト**として存在しています。以下のコードが重複しています。

| 重複箇所 | mobile/ | mobile-offline/ | 重複度 |
|----------|---------|-----------------|--------|
| domain/entities/generation_result.dart | あり | あり（同一） | 100% |
| features/camera/ | あり | あり（ほぼ同一） | ~90% |
| features/album/ | あり | あり（ストレージ部分のみ差異） | ~80% |
| features/settings/ | あり | あり | ~70% |
| core/（constants, exceptions, extensions, utils, widgets） | あり | あり（同一 SHA） | 100% |
| services/share_service.dart | あり | あり（同一 SHA） | 100% |
| presentation/ の UI ウィジェット群 | あり | あり（ほぼ同一） | ~85% |

`core/` ディレクトリは Git SHA が完全一致しており、コピー&ペーストされたことが確認できます。

#### 課題B: AI サービスのインターフェース不統一

- オンライン版: `AiRepository` が `photoId`（Supabase上のID）を受け取る
- オフライン版: `AiRepository` が `photoLocalPath`（ローカルパス）を受け取る
- 両者とも `AiRepository` という抽象クラスを持つが、**メソッドシグネチャが異なる**ため共通化されていない

#### 課題C: オフライン版のAI統合がスキャフォールド状態

README に明記されている通り、オフライン版のネイティブ MediaPipe 統合は**プレースホルダー実装**で、MethodChannel 経由の呼び出しは定義されているが、Android/iOS 側のネイティブコードが未実装です。

#### 課題D: pubspec.yaml の依存関係重複

両プロジェクトで共通の依存パッケージ（riverpod, go_router, camera, image_picker, image_cropper, freezed 等）を個別に管理しており、バージョン不整合のリスクがあります。

#### 課題E: flutter_gemma 未採用

オフライン版は MethodChannel で自前のネイティブブリッジを構築する前提ですが、前回の技術スタック提案で推奨した `flutter_gemma` プラグインを使えば、ネイティブコードの自前実装を大幅に削減できます。

---

## 2. リファクタリング目標

先の技術スタック提案（ai-mobile-app-tech-stack.md）に基づき、以下を実現します。

1. **共有コアパッケージの抽出** — 重複コードを単一の Dart パッケージに集約
2. **AI サービスの Strategy パターン統合** — 共通インターフェースでオンライン/オフラインを切り替え
3. **flutter_gemma 導入** — MethodChannel 自前実装から公式プラグインへ移行
4. **モノレポ構成の再編** — Melos による統一的なパッケージ管理

---

## 3. 目標ディレクトリ構成

```
daiary/
├── apps/
│   ├── online/                    # オンライン版エントリポイント（軽量）
│   │   ├── lib/
│   │   │   ├── main.dart
│   │   │   ├── app.dart
│   │   │   ├── di/                # 依存性注入（オンライン固有の Provider）
│   │   │   │   └── online_providers.dart
│   │   │   └── features/
│   │   │       └── auth/          # 認証（オンライン版のみ）
│   │   ├── android/
│   │   ├── ios/
│   │   └── pubspec.yaml           # shared + online固有の依存のみ
│   │
│   └── offline/                   # オフライン版エントリポイント（軽量）
│       ├── lib/
│       │   ├── main.dart
│       │   ├── app.dart
│       │   ├── di/
│       │   │   └── offline_providers.dart
│       │   └── features/
│       │       └── onboarding/    # モデルDLオンボーディング（オフラインのみ）
│       ├── android/
│       ├── ios/
│       └── pubspec.yaml           # shared + flutter_gemma 等
│
├── packages/
│   └── shared/                    # 共有 Dart パッケージ
│       ├── lib/
│       │   ├── shared.dart        # バレルファイル
│       │   ├── domain/
│       │   │   ├── models/
│       │   │   │   ├── generation_result.dart
│       │   │   │   ├── photo.dart
│       │   │   │   └── album.dart
│       │   │   └── interfaces/
│       │   │       ├── ai_service.dart          # 統一 AI インターフェース
│       │   │       ├── photo_repository.dart
│       │   │       └── storage_service.dart
│       │   ├── infrastructure/
│       │   │   └── image/
│       │   │       └── image_preprocessor.dart  # 画像前処理（共通）
│       │   ├── features/
│       │   │   ├── camera/        # カメラ機能（共有 UI + ロジック）
│       │   │   ├── album/         # アルバム機能（共有 UI）
│       │   │   ├── ai_generate/
│       │   │   │   └── presentation/  # AI生成 UI（共有ウィジェット）
│       │   │   └── settings/      # 設定画面（共有部分）
│       │   ├── core/
│       │   │   ├── constants/
│       │   │   ├── exceptions/
│       │   │   ├── extensions/
│       │   │   ├── utils/
│       │   │   └── widgets/       # 共有 UI コンポーネント
│       │   └── config/
│       │       ├── theme.dart
│       │       └── router.dart    # 共有ルート定義
│       └── pubspec.yaml
│
├── backend/                       # FastAPI（変更なし）
├── web/                           # Next.js（変更なし）
├── supabase/                      # マイグレーション（変更なし）
├── docs/
├── melos.yaml                     # Melos モノレポ設定（新規）
└── pubspec.yaml                   # ワークスペースルート
```

---

## 4. リファクタリング工程

### Phase 1: モノレポ基盤構築（1週間）

**目的**: 既存コードを壊さずに新しいディレクトリ構造の骨格を作る

| # | タスク | 詳細 |
|---|--------|------|
| 1-1 | Melos 導入 | `melos.yaml` を作成し、ワークスペースに `apps/**` と `packages/**` を登録 |
| 1-2 | shared パッケージ作成 | `packages/shared/` の Flutter パッケージを初期化（`pubspec.yaml`, バレルファイル） |
| 1-3 | ディレクトリ構造作成 | `apps/online/`, `apps/offline/` のスキャフォールドを生成 |
| 1-4 | CI 更新 | GitHub Actions を Melos ベースのビルド・テストに変更 |

**判定基準**: `melos bootstrap` が成功し、各パッケージの `flutter pub get` が通ること。

---

### Phase 2: 共有ドメイン層の抽出（2週間）

**目的**: 重複しているドメインモデルとインターフェースを `packages/shared` に集約

| # | タスク | 移動元 → 移動先 |
|---|--------|-----------------|
| 2-1 | ドメインモデル統合 | 両方の `domain/entities/` → `packages/shared/lib/domain/models/` |
| 2-2 | AI サービスインターフェース設計 | 新規作成 → `packages/shared/lib/domain/interfaces/ai_service.dart` |
| 2-3 | Photo/Album リポジトリ IF | 両方の `domain/repositories/` から共通部分を抽出 |
| 2-4 | core/ 統合 | `mobile/lib/core/` → `packages/shared/lib/core/`（SHA 一致のため丸ごと移動） |
| 2-5 | share_service 移動 | 両方の `services/share_service.dart` → `packages/shared/` |

**AI サービス統一インターフェースの設計**:

```dart
// packages/shared/lib/domain/interfaces/ai_service.dart

/// オンライン/オフライン共通のAIサービスインターフェース
abstract class AiService {
  /// 画像からハッシュタグを生成
  Future<HashtagResult> generateHashtags({
    required ImageInput image,       // photoId/pathの差異を吸収
    required String language,
    required int count,
    required String usage,
  });

  /// 画像からキャプションを生成
  Future<CaptionResult> generateCaption({
    required ImageInput image,
    required String language,
    required GenerationStyle style,
    required GenerationLength length,
    String? customPrompt,
  });

  /// サービスが利用可能か
  Future<bool> get isAvailable;
}

/// 画像入力の抽象化 — ID渡し/パス渡し/バイト渡しの差異を吸収
class ImageInput {
  final String? remoteId;      // Supabase上の写真ID
  final String? localPath;     // ローカルファイルパス
  final Uint8List? bytes;      // 前処理済み画像バイト列

  const ImageInput.remote(this.remoteId)
      : localPath = null, bytes = null;
  const ImageInput.local(this.localPath)
      : remoteId = null, bytes = null;
  const ImageInput.fromBytes(this.bytes)
      : remoteId = null, localPath = null;
}
```

**変更理由**: 現状の `photoId` vs `photoLocalPath` の差異が統合の最大の障壁。`ImageInput` クラスで差異を吸収することで、UI 層からは同じインターフェースで AI を呼び出せます。

**判定基準**: `packages/shared` が単独で `flutter test` をパスし、両アプリから `import` できること。

---

### Phase 3: 共有 UI の抽出（2週間）

**目的**: 重複している画面・ウィジェットを共有パッケージに移動

| # | タスク | 詳細 |
|---|--------|------|
| 3-1 | カメラ機能の統合 | 両方の `features/camera/` → `packages/shared/lib/features/camera/`。データソースの差異はコールバックで注入 |
| 3-2 | アルバム機能の統合 | 共有 UI を抽出、ストレージアクセスはリポジトリ IF 経由に変更 |
| 3-3 | AI 生成 UI の統合 | プロバイダー以外の画面・ウィジェットを共有化 |
| 3-4 | 設定画面の統合 | 共通部分を共有、オンライン固有（認証/課金）はアプリ側に残す |
| 3-5 | core/widgets の統合 | 共有ウィジェットを `packages/shared/lib/core/widgets/` へ |

**方針**: UI コンポーネントはデータソースに依存しない純粋なウィジェットとして抽出し、データの取得・保存はコンストラクタ引数やプロバイダー経由で注入します。

**判定基準**: 共有 UI が `packages/shared` のテストで描画テスト（widget test）をパスすること。

---

### Phase 4: オンライン版の再構築（1〜2週間）

**目的**: `mobile/` のコードを `apps/online/` に再構成し、共有パッケージを参照

| # | タスク | 詳細 |
|---|--------|------|
| 4-1 | エントリポイント作成 | `apps/online/lib/main.dart` — Supabase 初期化、Riverpod で Online 固有の Provider を登録 |
| 4-2 | Online AI 実装 | `AiService` を実装する `OnlineAiService` クラス。内部で `ApiClient` 経由の Gemini API 呼び出し |
| 4-3 | 認証機能移行 | `features/auth/` を `apps/online/lib/features/auth/` に移動（Online 専用） |
| 4-4 | サービス移行 | `admob_service`, `purchase_service`, `supabase_service`, `api_client` → `apps/online/lib/services/` |
| 4-5 | ルーター設定 | 共有ルートに認証ガードを追加した Online 用ルーター |
| 4-6 | 回帰テスト | 既存のテストを移行し、全テストがパスすることを確認 |

**判定基準**: `apps/online` で `flutter run` が成功し、既存の全機能が動作すること。

---

### Phase 5: オフライン版の再構築 + flutter_gemma 導入（2〜3週間）

**目的**: `mobile-offline/` を `apps/offline/` に再構成し、MethodChannel から `flutter_gemma` に移行

| # | タスク | 詳細 |
|---|--------|------|
| 5-1 | flutter_gemma 導入 | `apps/offline/pubspec.yaml` に `flutter_gemma` を追加 |
| 5-2 | Offline AI 実装 | `AiService` を実装する `OfflineAiService` クラス |
| 5-3 | MethodChannel 削除 | `com.daiary.offline/gemma` チャンネルの Dart 側コードを削除 |
| 5-4 | モデル管理 | `flutter_gemma` の `ModelFileManager` を使ったダウンロード・キャッシュ管理に置換 |
| 5-5 | オンボーディング移行 | `features/onboarding/` → `apps/offline/lib/features/onboarding/` |
| 5-6 | プラットフォーム設定 | Android: OpenCL 設定、iOS: Podfile + entitlements（メモリ拡張） |
| 5-7 | 実機テスト | Android / iOS 実機で推論動作確認 |

**flutter_gemma 移行の具体例**:

```dart
// Before（現状 — MethodChannel）
class AiLocalDataSource {
  static const _channel = MethodChannel('com.daiary.offline/gemma');
  Future<bool> isModelReady() async {
    final result = await _channel.invokeMethod<bool>('isModelReady');
    return result ?? false;
  }
}

// After（flutter_gemma）
class OfflineAiService implements AiService {
  InferenceModel? _model;

  Future<void> initialize() async {
    _model = await FlutterGemmaPlugin.instance.createModel(
      modelType: ModelType.gemmaIt,
      preferredBackend: PreferredBackend.gpu,
      maxTokens: 4096,
      supportImage: true,
      maxNumImages: 1,
    );
  }

  @override
  Future<bool> get isAvailable async => _model != null;

  @override
  Future<HashtagResult> generateHashtags({
    required ImageInput image, ...
  }) async {
    // flutter_gemma のセッション API で推論
  }
}
```

**判定基準**: `apps/offline` で `flutter run` が成功し、モデルダウンロード → 推論のフローが動作すること。

---

### Phase 6: 旧ディレクトリ削除 + 整理（1週間）

| # | タスク | 詳細 |
|---|--------|------|
| 6-1 | 旧コード削除 | `mobile/`, `mobile-offline/` ディレクトリを削除 |
| 6-2 | Makefile 更新 | 新しいパスに合わせてタスクランナーを更新 |
| 6-3 | CLAUDE.md 更新 | 新しいアーキテクチャに合わせてプロジェクト概要を書き換え |
| 6-4 | README.md 更新 | セットアップ手順・ディレクトリ構成を更新 |
| 6-5 | docs/ 更新 | architecture.md, backlog を新構成に合わせて更新 |
| 6-6 | CI/CD 最終調整 | GitHub Actions のパスフィルター等を新構成に合わせる |

**判定基準**: `melos run test` で全パッケージのテストがパス、CI がグリーン。

---

## 5. 移行戦略

### 5-1. ブランチ戦略

```
main
 └── feature/refactor-monorepo      # Phase 1-6 の作業ブランチ
      ├── Phase 1 のコミット群
      ├── Phase 2 のコミット群
      └── ...（Phase ごとに中間 PR でレビュー）
```

各 Phase 完了時点で中間 PR を作成し、`main` に段階的にマージすることを推奨します。Phase 4 完了時点でオンライン版、Phase 5 完了時点でオフライン版がそれぞれ動作確認可能な状態にします。

### 5-2. 並行稼働期間

Phase 4〜5 の期間中は `mobile/` と `apps/online/` が一時的に並存します。この期間は旧ディレクトリでの開発を凍結（コードフリーズ）し、新ディレクトリのみで作業します。

### 5-3. リスクと対策

| リスク | 影響度 | 対策 |
|--------|--------|------|
| flutter_gemma のiOSビジョン未対応 | 高 | `.task` 形式に限定。iOS ビジョン対応のリリースを監視 |
| 共有パッケージへの依存による結合度増加 | 中 | インターフェースベースの設計で疎結合を維持 |
| Melos 学習コスト | 低 | 基本的な bootstrap / run のみで十分 |
| テストカバレッジの一時的低下 | 中 | Phase ごとに回帰テストを必須化 |
| 既存のバックログ（OL-001〜004）との競合 | 中 | Phase 5 で統合的に解消される |

---

## 6. 工数サマリー

| Phase | 内容 | 期間目安 | 前提条件 |
|-------|------|----------|----------|
| Phase 1 | モノレポ基盤構築 | 1 週間 | — |
| Phase 2 | 共有ドメイン層の抽出 | 2 週間 | Phase 1 完了 |
| Phase 3 | 共有 UI の抽出 | 2 週間 | Phase 2 完了 |
| Phase 4 | オンライン版の再構築 | 1〜2 週間 | Phase 3 完了 |
| Phase 5 | オフライン版の再構築 | 2〜3 週間 | Phase 3 完了（Phase 4 と並行可能） |
| Phase 6 | 旧コード削除・整理 | 1 週間 | Phase 4, 5 完了 |
| **合計** | | **9〜11 週間** | |

Phase 4 と Phase 5 は並行作業が可能なため、チームメンバーがいれば短縮可能です。

---

## 7. 成功指標

- [ ] `mobile/` と `mobile-offline/` 間のコード重複率が 0% になっている
- [ ] `AiService` インターフェース経由でオンライン/オフラインが透過的に切り替わる
- [ ] `flutter_gemma` による画像入力付き推論が Android 実機で動作する
- [ ] `melos run test` で全パッケージのテストがパスする
- [ ] `melos run analyze` で warning 0 件
- [ ] 既存の全機能（カメラ、ギャラリー、AI 生成、アルバム、共有、設定）がリグレッションなく動作する
