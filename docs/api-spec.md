# AI Photographer API仕様書

## 概要

AI Photographerアプリケーションのバックエンド API 仕様です。
FastAPI で構築されており、バージョニングは URL パスプレフィックスで管理します。

| 項目 | 値 |
|---|---|
| フレームワーク | FastAPI 1.0.0 |
| ベースURL（ローカル） | `http://localhost:8000/api/v1` |
| APIバージョン | `v1` |
| データ形式 | JSON（写真アップロードのみ `multipart/form-data`） |

---

## 認証

認証が必要なエンドポイントには、リクエストヘッダーに Supabase Auth が発行する JWT を Bearer トークンとして含めます。

```
Authorization: Bearer <access_token>
```

バックエンドは `supabase.auth.get_user(token)` でトークンを検証し、`public.users` テーブルからプロフィール情報（plan, username 等）を取得します。

---

## 共通エラーレスポンス

FastAPI 標準の `HTTPException` に準拠した形式でエラーを返します。

```json
{
  "detail": "エラーの説明"
}
```

| HTTPステータス | 説明 |
|---|---|
| 400 Bad Request | リクエストパラメータが不正 |
| 401 Unauthorized | 認証が必要、またはトークンが無効・期限切れ |
| 404 Not Found | リソースが見つからない |
| 422 Unprocessable Entity | リクエストボディのバリデーションエラー（Pydantic） |
| 429 Too Many Requests | レート制限またはAI日次上限を超過 |
| 500 Internal Server Error | サーバー内部エラー |

---

## 1. 認証 (Auth)

ベースパス: `/api/v1/auth`

### POST /auth/signup

新規ユーザー登録を行います。

- **認証**: 不要
- **ステータス**: `201 Created`

**リクエスト**
```json
{
  "email": "user@example.com",
  "password": "securePassword123",
  "username": "photographer01"
}
```

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `email` | string (EmailStr) | はい | メールアドレス |
| `password` | string | はい | パスワード |
| `username` | string | いいえ | ユーザー名（省略時はメールの@前部分） |

**レスポンス** `201 Created` — `TokenResponse`
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "v1.MjA...",
  "token_type": "bearer",
  "expires_in": 3600,
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "username": "photographer01",
    "avatar_url": null,
    "plan": "free",
    "storage_used_bytes": 0,
    "created_at": "2025-12-01T17:30:00.000Z"
  }
}
```

> メール確認が必要な設定の場合、`access_token` と `refresh_token` は空文字列、`expires_in` は 0 で返されます。

**エラー**
| ステータス | 説明 |
|---|---|
| 400 | メールアドレス・パスワードが不正、または既に登録済み |

---

### POST /auth/login

ログインしてセッショントークンを取得します。

- **認証**: 不要
- **ステータス**: `200 OK`

**リクエスト**
```json
{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `email` | string (EmailStr) | はい | メールアドレス |
| `password` | string | はい | パスワード |

**レスポンス** `200 OK` — `TokenResponse`
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "v1.MjA...",
  "token_type": "bearer",
  "expires_in": 3600,
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "username": "photographer01",
    "avatar_url": "https://example.com/avatar.jpg",
    "plan": "free",
    "storage_used_bytes": 52428800,
    "created_at": "2025-12-01T17:30:00.000Z"
  }
}
```

**エラー**
| ステータス | 説明 |
|---|---|
| 401 | メールアドレスまたはパスワードが不正 |

---

### POST /auth/refresh

リフレッシュトークンを使ってアクセストークンを更新します。

- **認証**: 不要
- **ステータス**: `200 OK`

**リクエスト** — クエリパラメータ

| パラメータ | 型 | 必須 | 説明 |
|---|---|---|---|
| `refresh_token` | string | はい | リフレッシュトークン |

**レスポンス** `200 OK` — `TokenResponse`
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "v1.Nzk...",
  "token_type": "bearer",
  "expires_in": 3600,
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "username": "photographer01",
    "avatar_url": null,
    "plan": "free",
    "storage_used_bytes": 0,
    "created_at": "2025-12-01T17:30:00.000Z"
  }
}
```

**エラー**
| ステータス | 説明 |
|---|---|
| 401 | リフレッシュトークンが無効または期限切れ |

---

### POST /auth/password-reset

パスワードリセットメールを送信します。セキュリティ上、メールアドレスの存在有無に関わらず同じレスポンスを返します。

- **認証**: 不要
- **ステータス**: `200 OK`

**リクエスト** — クエリパラメータ

| パラメータ | 型 | 必須 | 説明 |
|---|---|---|---|
| `email` | string | はい | メールアドレス |

**レスポンス** `200 OK`
```json
{
  "message": "If the email exists, a password reset link has been sent."
}
```

---

### DELETE /auth/account

ユーザーアカウントを完全に削除します。Supabase Admin API を使用してアカウントを削除します。

- **認証**: 必要
- **ステータス**: `204 No Content`

**リクエスト**: ボディなし

**レスポンス**: `204 No Content`（ボディなし）

**エラー**
| ステータス | 説明 |
|---|---|
| 401 | 認証が必要 |
| 500 | アカウント削除に失敗 |

---

## 2. 写真 (Photos)

ベースパス: `/api/v1/photos`

### POST /photos/upload

写真をアップロードします。`multipart/form-data` で送信します。

- **認証**: 必要
- **ステータス**: `201 Created`

**リクエスト** `multipart/form-data`

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `file` | File | はい | 写真ファイル（JPEG, PNG, WebP, HEIC） |
| `is_favorite` | boolean | いいえ | お気に入りフラグ（デフォルト: `false`） |

ファイルサイズ上限: **10MB**

**レスポンス** `201 Created` — `PhotoResponse`
```json
{
  "id": "660e8400-e29b-41d4-a716-446655440000",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "storage_path": "550e8400-.../photos/IMG_001.jpg",
  "thumbnail_path": null,
  "original_filename": "IMG_001.jpg",
  "file_size": 2097152,
  "width": null,
  "height": null,
  "exif_data": {},
  "ai_tags": [],
  "is_favorite": false,
  "url": "https://...supabase.co/storage/v1/object/sign/photos/...",
  "created_at": "2025-12-01T17:30:00.000Z"
}
```

**エラー**
| ステータス | 説明 |
|---|---|
| 400 | ファイル形式が不正、またはファイルサイズが10MBを超過 |
| 401 | 認証が必要 |
| 500 | ストレージへのアップロードまたはDBレコード作成に失敗 |

---

### GET /photos/

ユーザーの写真一覧を取得します。offset/limit ベースのページネーションに対応しています。

- **認証**: 必要
- **ステータス**: `200 OK`

**クエリパラメータ**
| パラメータ | 型 | デフォルト | 説明 |
|---|---|---|---|
| `offset` | integer | `0` | オフセット（0以上） |
| `limit` | integer | `20` | 取得件数（1〜100） |
| `favorites_only` | boolean | `false` | お気に入りのみ取得 |
| `include_deleted` | boolean | `false` | 削除済み写真を含める |

**レスポンス** `200 OK` — `PhotoListResponse`
```json
{
  "items": [
    {
      "id": "660e8400-e29b-41d4-a716-446655440000",
      "user_id": "550e8400-e29b-41d4-a716-446655440000",
      "storage_path": "550e8400-.../photos/IMG_001.jpg",
      "thumbnail_path": null,
      "original_filename": "IMG_001.jpg",
      "file_size": 2097152,
      "width": 4032,
      "height": 3024,
      "exif_data": {},
      "ai_tags": ["sunset", "sky", "landscape"],
      "is_favorite": true,
      "url": "https://...supabase.co/storage/v1/object/sign/photos/...",
      "created_at": "2025-12-01T17:30:00.000Z"
    }
  ],
  "total": 45,
  "offset": 0,
  "limit": 20
}
```

---

### GET /photos/{photo_id}

写真の詳細情報を取得します。

- **認証**: 必要
- **ステータス**: `200 OK`

**パスパラメータ**
| パラメータ | 型 | 説明 |
|---|---|---|
| `photo_id` | UUID | 写真ID |

**レスポンス** `200 OK` — `PhotoResponse`
```json
{
  "id": "660e8400-e29b-41d4-a716-446655440000",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "storage_path": "550e8400-.../photos/IMG_001.jpg",
  "thumbnail_path": null,
  "original_filename": "IMG_001.jpg",
  "file_size": 2097152,
  "width": 4032,
  "height": 3024,
  "exif_data": {
    "Make": "Apple",
    "Model": "iPhone 15 Pro"
  },
  "ai_tags": ["sunset", "sky", "landscape"],
  "is_favorite": true,
  "url": "https://...supabase.co/storage/v1/object/sign/photos/...",
  "created_at": "2025-12-01T17:30:00.000Z"
}
```

**エラー**
| ステータス | 説明 |
|---|---|
| 404 | 写真が見つからない |

---

### PATCH /photos/{photo_id}

写真のメタデータを更新します。送信したフィールドのみ更新されます（部分更新）。

- **認証**: 必要
- **ステータス**: `200 OK`

**パスパラメータ**
| パラメータ | 型 | 説明 |
|---|---|---|
| `photo_id` | UUID | 写真ID |

**リクエスト** — `PhotoUpdate`
```json
{
  "is_favorite": true,
  "ai_tags": ["sunset", "sky", "landscape", "tokyo"]
}
```

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `is_favorite` | boolean | いいえ | お気に入りフラグ |
| `ai_tags` | list[string] | いいえ | AIタグ |

**レスポンス** `200 OK` — `PhotoResponse`

更新後の完全な `PhotoResponse` が返されます（構造は GET /photos/{photo_id} と同一）。

**エラー**
| ステータス | 説明 |
|---|---|
| 400 | 更新フィールドが指定されていない |
| 404 | 写真が見つからない |

---

### DELETE /photos/{photo_id}

写真をソフトデリートします（`deleted_at` タイムスタンプを設定）。ストレージ上のファイルは即座には削除されません。

- **認証**: 必要
- **ステータス**: `204 No Content`

**パスパラメータ**
| パラメータ | 型 | 説明 |
|---|---|---|
| `photo_id` | UUID | 写真ID |

**レスポンス**: `204 No Content`（ボディなし）

**エラー**
| ステータス | 説明 |
|---|---|
| 404 | 写真が見つからない |

---

### GET /photos/search/

写真をAIタグで検索します。

- **認証**: 必要
- **ステータス**: `200 OK`

**クエリパラメータ**
| パラメータ | 型 | 必須 | デフォルト | 説明 |
|---|---|---|---|---|
| `q` | string | はい | - | 検索クエリ（AIタグに対する contains 検索） |
| `offset` | integer | いいえ | `0` | オフセット（0以上） |
| `limit` | integer | いいえ | `20` | 取得件数（1〜100） |

**レスポンス** `200 OK` — `PhotoListResponse`
```json
{
  "items": [
    {
      "id": "660e8400-e29b-41d4-a716-446655440000",
      "user_id": "550e8400-e29b-41d4-a716-446655440000",
      "storage_path": "550e8400-.../photos/IMG_001.jpg",
      "thumbnail_path": null,
      "original_filename": "IMG_001.jpg",
      "file_size": 2097152,
      "width": 4032,
      "height": 3024,
      "exif_data": {},
      "ai_tags": ["sunset", "sky", "landscape"],
      "is_favorite": true,
      "url": "https://...supabase.co/storage/v1/object/sign/photos/...",
      "created_at": "2025-12-01T17:30:00.000Z"
    }
  ],
  "total": 5,
  "offset": 0,
  "limit": 20
}
```

---

## 3. AI生成 (AI)

ベースパス: `/api/v1/ai`

### POST /ai/hashtags

写真からSNS向けハッシュタグをAIで生成します。Google Gemini APIを使用します。

- **認証**: 必要
- **ステータス**: `201 Created`

**リクエスト** — `HashtagRequest`
```json
{
  "photo_id": "660e8400-e29b-41d4-a716-446655440000",
  "language": "ja",
  "count": 15,
  "usage": "instagram"
}
```

| フィールド | 型 | 必須 | デフォルト | 説明 |
|---|---|---|---|---|
| `photo_id` | UUID | はい | - | 対象の写真ID |
| `language` | string | いいえ | `"ja"` | 言語コード |
| `count` | integer | いいえ | `15` | 生成するハッシュタグ数（1〜30） |
| `usage` | string | いいえ | `"instagram"` | 用途 |

**レスポンス** `201 Created` — `HashtagResponse`
```json
{
  "hashtags": [
    "#夕焼け",
    "#東京タワー",
    "#ゴールデンアワー",
    "#風景写真",
    "#日本の風景",
    "#sunset",
    "#tokyophotography",
    "#landscapephotography",
    "#photooftheday",
    "#goldenhour",
    "#写真好きな人と繋がりたい",
    "#カメラ好き",
    "#japanphoto",
    "#cityscape",
    "#eveningsky"
  ],
  "generation_id": "770e8400-e29b-41d4-a716-446655440000"
}
```

**エラー**
| ステータス | 説明 |
|---|---|
| 404 | 写真が見つからない |
| 429 | 1日のAI生成回数上限に到達（無料: 10回/日） |
| 500 | AI生成またはログの保存に失敗 |

---

### POST /ai/caption

写真からSNS投稿用キャプションをAIで生成します。Google Gemini APIを使用します。

- **認証**: 必要
- **ステータス**: `201 Created`

**リクエスト** — `CaptionRequest`
```json
{
  "photo_id": "660e8400-e29b-41d4-a716-446655440000",
  "language": "ja",
  "style": "casual",
  "length": "medium",
  "custom_prompt": null
}
```

| フィールド | 型 | 必須 | デフォルト | 説明 |
|---|---|---|---|---|
| `photo_id` | UUID | はい | - | 対象の写真ID |
| `language` | string | いいえ | `"ja"` | 言語コード |
| `style` | string | いいえ | `"casual"` | キャプションのスタイル |
| `length` | string | いいえ | `"medium"` | キャプションの長さ |
| `custom_prompt` | string | いいえ | `null` | カスタムプロンプト |

**レスポンス** `201 Created` — `CaptionResponse`
```json
{
  "caption": "東京の空が燃えるように染まる夕暮れ。都会の喧騒を忘れさせてくれる、一日の終わりの贈り物。",
  "generation_id": "880e8400-e29b-41d4-a716-446655440000"
}
```

**エラー**
| ステータス | 説明 |
|---|---|
| 404 | 写真が見つからない |
| 429 | 1日のAI生成回数上限に到達 |
| 500 | AI生成またはログの保存に失敗 |

---

### GET /ai/usage

現在のAI生成使用状況を取得します。日付が変わるとカウンターはリセットされます。

- **認証**: 必要
- **ステータス**: `200 OK`

**レスポンス** `200 OK` — `UsageResponse`

Freeプランの場合:
```json
{
  "used": 3,
  "limit": 10,
  "remaining": 7,
  "is_premium": false
}
```

Premiumプランの場合:
```json
{
  "used": 25,
  "limit": 999999,
  "remaining": 999974,
  "is_premium": true
}
```

| フィールド | 型 | 説明 |
|---|---|---|
| `used` | integer | 本日の使用回数 |
| `limit` | integer | 1日の上限（Free: 10, Premium: 999999） |
| `remaining` | integer | 残り回数 |
| `is_premium` | boolean | プレミアムプランかどうか |

---

## 4. アルバム (Albums)

ベースパス: `/api/v1/albums`

### POST /albums/

新しいアルバムを作成します。作成時に `share_token` が自動生成されます。

- **認証**: 必要
- **ステータス**: `201 Created`

**リクエスト** — `AlbumCreate`
```json
{
  "name": "Tokyo Favorites",
  "cover_photo_id": null,
  "is_public": false
}
```

| フィールド | 型 | 必須 | デフォルト | 説明 |
|---|---|---|---|---|
| `name` | string | はい | - | アルバム名 |
| `cover_photo_id` | UUID | いいえ | `null` | カバー写真ID |
| `is_public` | boolean | いいえ | `false` | 公開フラグ |

**レスポンス** `201 Created` — `AlbumResponse`
```json
{
  "id": "990e8400-e29b-41d4-a716-446655440000",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Tokyo Favorites",
  "cover_photo_id": null,
  "is_public": false,
  "share_token": "dG9reW9fZmF2b3JpdGVz...",
  "photo_count": 0,
  "created_at": "2025-12-01T10:00:00.000Z",
  "updated_at": "2025-12-01T10:00:00.000Z"
}
```

---

### GET /albums/

ユーザーのアルバム一覧を取得します。ページネーションなしで全件返します。

- **認証**: 必要
- **ステータス**: `200 OK`

**レスポンス** `200 OK` — `list[AlbumResponse]`
```json
[
  {
    "id": "990e8400-e29b-41d4-a716-446655440000",
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Tokyo Favorites",
    "cover_photo_id": "660e8400-e29b-41d4-a716-446655440000",
    "is_public": true,
    "share_token": "dG9reW9fZmF2b3JpdGVz...",
    "photo_count": 12,
    "created_at": "2025-12-01T10:00:00.000Z",
    "updated_at": "2025-12-05T15:00:00.000Z"
  }
]
```

> 注: レスポンスは `AlbumResponse` の配列で直接返されます（ラッパーオブジェクトなし）。

---

### GET /albums/{album_id}

アルバムの詳細と所属する写真一覧を取得します。

- **認証**: 必要
- **ステータス**: `200 OK`

**パスパラメータ**
| パラメータ | 型 | 説明 |
|---|---|---|
| `album_id` | UUID | アルバムID |

**レスポンス** `200 OK` — `AlbumDetailResponse`
```json
{
  "id": "990e8400-e29b-41d4-a716-446655440000",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Tokyo Favorites",
  "cover_photo_id": "660e8400-e29b-41d4-a716-446655440000",
  "is_public": true,
  "share_token": "dG9reW9fZmF2b3JpdGVz...",
  "photo_count": 12,
  "created_at": "2025-12-01T10:00:00.000Z",
  "updated_at": "2025-12-05T15:00:00.000Z",
  "photos": [
    {
      "id": "660e8400-e29b-41d4-a716-446655440000",
      "user_id": "550e8400-e29b-41d4-a716-446655440000",
      "storage_path": "550e8400-.../photos/IMG_001.jpg",
      "thumbnail_path": null,
      "original_filename": "IMG_001.jpg",
      "file_size": 2097152,
      "width": 4032,
      "height": 3024,
      "exif_data": {},
      "ai_tags": ["sunset", "sky"],
      "is_favorite": true,
      "url": "https://...supabase.co/storage/v1/object/sign/photos/...",
      "created_at": "2025-12-01T17:30:00.000Z"
    }
  ]
}
```

`AlbumDetailResponse` は `AlbumResponse` を継承し、`photos` フィールド（`list[PhotoResponse]`）が追加されています。

**エラー**
| ステータス | 説明 |
|---|---|
| 404 | アルバムが見つからない |

---

### PATCH /albums/{album_id}

アルバムの情報を更新します。送信したフィールドのみ更新されます（部分更新）。

- **認証**: 必要
- **ステータス**: `200 OK`

**パスパラメータ**
| パラメータ | 型 | 説明 |
|---|---|---|
| `album_id` | UUID | アルバムID |

**リクエスト** — `AlbumUpdate`
```json
{
  "name": "Tokyo Best Shots",
  "cover_photo_id": "660e8400-e29b-41d4-a716-446655440000",
  "is_public": true
}
```

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `name` | string | いいえ | アルバム名 |
| `cover_photo_id` | UUID | いいえ | カバー写真ID |
| `is_public` | boolean | いいえ | 公開フラグ |

**レスポンス** `200 OK` — `AlbumResponse`

更新後の完全な `AlbumResponse` が返されます。

**エラー**
| ステータス | 説明 |
|---|---|
| 400 | 更新フィールドが指定されていない |
| 404 | アルバムが見つからない |

---

### DELETE /albums/{album_id}

アルバムを削除します。`album_photos` の関連レコードも削除されますが、写真自体は削除されません。

- **認証**: 必要
- **ステータス**: `204 No Content`

**パスパラメータ**
| パラメータ | 型 | 説明 |
|---|---|---|
| `album_id` | UUID | アルバムID |

**レスポンス**: `204 No Content`（ボディなし）

**エラー**
| ステータス | 説明 |
|---|---|
| 404 | アルバムが見つからない |

---

### POST /albums/{album_id}/photos

アルバムに写真を追加します。`sort_order` は既存の最大値に続けて自動採番されます。

- **認証**: 必要
- **ステータス**: `201 Created`

**パスパラメータ**
| パラメータ | 型 | 説明 |
|---|---|---|
| `album_id` | UUID | アルバムID |

**リクエスト** — `AlbumPhotosAdd`
```json
{
  "photo_ids": [
    "660e8400-e29b-41d4-a716-446655440000",
    "770e8400-e29b-41d4-a716-446655440001"
  ]
}
```

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `photo_ids` | list[UUID] | はい | 追加する写真IDのリスト |

**レスポンス** `201 Created`
```json
{
  "added": 2
}
```

**エラー**
| ステータス | 説明 |
|---|---|
| 404 | アルバムが見つからない |
| 500 | 写真の追加に失敗 |

---

### DELETE /albums/{album_id}/photos/{photo_id}

アルバムから写真を除外します。写真自体は削除されません。`photo_count` は自動更新されます。

- **認証**: 必要
- **ステータス**: `204 No Content`

**パスパラメータ**
| パラメータ | 型 | 説明 |
|---|---|---|
| `album_id` | UUID | アルバムID |
| `photo_id` | UUID | 写真ID |

**レスポンス**: `204 No Content`（ボディなし）

**エラー**
| ステータス | 説明 |
|---|---|
| 404 | アルバムが見つからない、または写真がアルバムに含まれていない |

---

## 5. 決済 (Payments)

ベースパス: `/api/v1/payments`

### POST /payments/verify-receipt

App Store / Google Play のレシートを検証し、サブスクリプションを有効化します。

- **認証**: 必要
- **ステータス**: `200 OK`

**リクエスト** — `VerifyReceiptRequest`
```json
{
  "platform": "ios",
  "receipt_data": "MIIbngYJKoZIhvcNAQcCoIIbj...",
  "product_id": "premium_monthly"
}
```

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `platform` | string | はい | プラットフォーム（`"ios"` または `"android"`） |
| `receipt_data` | string | はい | レシートデータ |
| `product_id` | string | はい | 商品ID |

**レスポンス** `200 OK` — `SubscriptionResponse`
```json
{
  "plan": "premium",
  "is_active": true,
  "expires_at": "2026-01-01T00:00:00.000Z",
  "product_id": "premium_monthly"
}
```

**エラー**
| ステータス | 説明 |
|---|---|
| 400 | platform が不正、またはレシートデータが無効 |
| 500 | サブスクリプション処理に失敗 |

---

### GET /payments/subscription

現在のサブスクリプション状態を取得します。

- **認証**: 必要
- **ステータス**: `200 OK`

**レスポンス** `200 OK` — `SubscriptionResponse`

Premiumプランの場合:
```json
{
  "plan": "premium",
  "is_active": true,
  "expires_at": "2026-01-01T00:00:00.000Z",
  "product_id": "premium_monthly"
}
```

Freeプランの場合:
```json
{
  "plan": "free",
  "is_active": false,
  "expires_at": null,
  "product_id": null
}
```

| フィールド | 型 | 説明 |
|---|---|---|
| `plan` | string | プラン名（`"free"` / `"premium"`） |
| `is_active` | boolean | サブスクリプションが有効かどうか |
| `expires_at` | datetime / null | サブスクリプションの有効期限 |
| `product_id` | string / null | 商品ID |

---

### POST /payments/cancel

現在のサブスクリプションをキャンセルします。

- **認証**: 必要
- **ステータス**: `200 OK`

**リクエスト**: ボディなし

**レスポンス** `200 OK` — `SubscriptionResponse`
```json
{
  "plan": "free",
  "is_active": false,
  "expires_at": null,
  "product_id": null
}
```

**エラー**
| ステータス | 説明 |
|---|---|
| 500 | キャンセル処理に失敗 |

---

### POST /payments/webhook/appstore

Apple App Store Server Notification を受信するウェブフックエンドポイントです。サブスクリプションの更新・キャンセル・返金等のライフサイクルイベントを処理します。

- **認証**: 不要（Apple が JWS で署名したペイロード）

**リクエスト**: Apple Server Notification V2 形式の JSON

**レスポンス** `200 OK`
```json
{
  "status": "ok"
}
```

---

### POST /payments/webhook/playstore

Google Play Real-Time Developer Notification (RTDN) を受信するウェブフックエンドポイントです。Google Cloud Pub/Sub 経由でサブスクリプション状態変更イベントが配信されます。

- **認証**: 不要（Pub/Sub 認証は別途処理）

**リクエスト**: Google Pub/Sub メッセージエンベロープ形式の JSON

**レスポンス** `200 OK`
```json
{
  "status": "ok"
}
```

---

## プラン別制限

| 機能 | Free | Premium |
|---|---|---|
| AI生成（ハッシュタグ/キャプション） | **10回/日** | 無制限 |
| ストレージ容量 | 1 GB | 50 GB |

---

## レート制限

AI生成エンドポイントにはインメモリのレート制限が適用されます。

| 対象 | 制限 | ウィンドウ |
|---|---|---|
| AI生成 (`/ai/hashtags`, `/ai/caption`) — Freeプラン | 10回 | 24時間（日次リセット） |
| AI生成 — Premiumプラン | 無制限 | - |

レート制限は `RateLimitStore` によるインメモリ管理と、`users` テーブルの `daily_ai_count` / `daily_ai_reset_at` カラムによるDB管理の二重チェックで実装されています。

制限超過時は `429 Too Many Requests` が返されます。

```json
{
  "detail": "Daily AI generation limit reached. Upgrade to premium for unlimited generations."
}
```

---

## スキーマ一覧

### TokenResponse

| フィールド | 型 | 説明 |
|---|---|---|
| `access_token` | string | アクセストークン |
| `refresh_token` | string | リフレッシュトークン |
| `token_type` | string | トークンタイプ（固定値: `"bearer"`） |
| `expires_in` | integer | トークンの有効期間（秒） |
| `user` | UserResponse | ユーザー情報 |

### UserResponse

| フィールド | 型 | 説明 |
|---|---|---|
| `id` | UUID | ユーザーID |
| `email` | string | メールアドレス |
| `username` | string / null | ユーザー名 |
| `avatar_url` | string / null | アバター画像URL |
| `plan` | string | プラン（`"free"` / `"premium"`） |
| `storage_used_bytes` | integer | 使用済みストレージ（バイト） |
| `created_at` | datetime | 作成日時 |

### PhotoResponse

| フィールド | 型 | 説明 |
|---|---|---|
| `id` | UUID | 写真ID |
| `user_id` | UUID | ユーザーID |
| `storage_path` | string | ストレージ上のパス |
| `thumbnail_path` | string / null | サムネイルのパス |
| `original_filename` | string / null | 元のファイル名 |
| `file_size` | integer / null | ファイルサイズ（バイト） |
| `width` | integer / null | 画像の幅（px） |
| `height` | integer / null | 画像の高さ（px） |
| `exif_data` | object | EXIF メタデータ |
| `ai_tags` | list[string] | AIタグ |
| `is_favorite` | boolean | お気に入りフラグ |
| `url` | string / null | 署名付きURL |
| `created_at` | datetime | 作成日時 |

### PhotoListResponse

| フィールド | 型 | 説明 |
|---|---|---|
| `items` | list[PhotoResponse] | 写真の配列 |
| `total` | integer | 総件数 |
| `offset` | integer | オフセット |
| `limit` | integer | 取得件数 |

### AlbumResponse

| フィールド | 型 | 説明 |
|---|---|---|
| `id` | UUID | アルバムID |
| `user_id` | UUID | ユーザーID |
| `name` | string | アルバム名 |
| `cover_photo_id` | UUID / null | カバー写真ID |
| `is_public` | boolean | 公開フラグ |
| `share_token` | string / null | シェアトークン |
| `photo_count` | integer | 写真数 |
| `created_at` | datetime | 作成日時 |
| `updated_at` | datetime | 更新日時 |

### AlbumDetailResponse (extends AlbumResponse)

| フィールド | 型 | 説明 |
|---|---|---|
| （AlbumResponse の全フィールド） | | |
| `photos` | list[PhotoResponse] | アルバム内の写真 |

### HashtagResponse

| フィールド | 型 | 説明 |
|---|---|---|
| `hashtags` | list[string] | 生成されたハッシュタグ |
| `generation_id` | UUID | AI生成レコードのID |

### CaptionResponse

| フィールド | 型 | 説明 |
|---|---|---|
| `caption` | string | 生成されたキャプション |
| `generation_id` | UUID | AI生成レコードのID |

### UsageResponse

| フィールド | 型 | 説明 |
|---|---|---|
| `used` | integer | 本日の使用回数 |
| `limit` | integer | 日次上限 |
| `remaining` | integer | 残り回数 |
| `is_premium` | boolean | プレミアムプランか |

### SubscriptionResponse

| フィールド | 型 | 説明 |
|---|---|---|
| `plan` | string | プラン名 |
| `is_active` | boolean | サブスクリプション有効フラグ |
| `expires_at` | datetime / null | 有効期限 |
| `product_id` | string / null | 商品ID |

### VerifyReceiptRequest

| フィールド | 型 | 説明 |
|---|---|---|
| `platform` | string | `"ios"` または `"android"` |
| `receipt_data` | string | レシートデータ |
| `product_id` | string | 商品ID |
