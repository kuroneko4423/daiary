# AI Photographer API仕様書

## 概要

AI Photographerアプリケーションのバックエンド API 仕様です。
全てのAPIは Supabase Edge Functions 上で動作し、ベースURLは以下の通りです。

- ローカル開発: `http://localhost:54321/functions/v1`
- 本番環境: `https://<project-ref>.supabase.co/functions/v1`

## 認証

認証が必要なエンドポイントには、リクエストヘッダーに Bearer トークンを含める必要があります。

```
Authorization: Bearer <access_token>
```

トークンは Supabase Auth から取得します。

## 共通エラーレスポンス

全てのエンドポイントで以下の共通エラー形式を使用します。

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "エラーの説明"
  }
}
```

| HTTPステータス | コード | 説明 |
|---|---|---|
| 400 | `BAD_REQUEST` | リクエストパラメータが不正 |
| 401 | `UNAUTHORIZED` | 認証が必要 |
| 403 | `FORBIDDEN` | アクセス権限がない |
| 404 | `NOT_FOUND` | リソースが見つからない |
| 409 | `CONFLICT` | リソースが競合している |
| 413 | `PAYLOAD_TOO_LARGE` | ファイルサイズが上限を超過 |
| 429 | `RATE_LIMIT_EXCEEDED` | レート制限を超過 |
| 500 | `INTERNAL_ERROR` | サーバー内部エラー |

---

## 1. 認証 (Auth)

### POST /auth/signup

新規ユーザー登録を行います。

- **認証**: 不要

**リクエスト**
```json
{
  "email": "user@example.com",
  "password": "securePassword123",
  "username": "photographer01"
}
```

**レスポンス** `201 Created`
```json
{
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "username": "photographer01"
  },
  "session": {
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "v1.MjA...",
    "expires_in": 3600,
    "token_type": "bearer"
  }
}
```

**エラー**
| ステータス | コード | 説明 |
|---|---|---|
| 400 | `BAD_REQUEST` | メールアドレスまたはパスワードが不正 |
| 409 | `CONFLICT` | メールアドレスが既に登録済み |

---

### POST /auth/login

ログインしてセッショントークンを取得します。

- **認証**: 不要

**リクエスト**
```json
{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

**レスポンス** `200 OK`
```json
{
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "username": "photographer01",
    "plan": "free"
  },
  "session": {
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "v1.MjA...",
    "expires_in": 3600,
    "token_type": "bearer"
  }
}
```

**エラー**
| ステータス | コード | 説明 |
|---|---|---|
| 401 | `UNAUTHORIZED` | メールアドレスまたはパスワードが不正 |

---

### POST /auth/refresh

リフレッシュトークンを使ってアクセストークンを更新します。

- **認証**: 不要

**リクエスト**
```json
{
  "refresh_token": "v1.MjA..."
}
```

**レスポンス** `200 OK`
```json
{
  "session": {
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "v1.Nzk...",
    "expires_in": 3600,
    "token_type": "bearer"
  }
}
```

**エラー**
| ステータス | コード | 説明 |
|---|---|---|
| 401 | `UNAUTHORIZED` | リフレッシュトークンが無効または期限切れ |

---

### POST /auth/password-reset

パスワードリセットメールを送信します。

- **認証**: 不要

**リクエスト**
```json
{
  "email": "user@example.com"
}
```

**レスポンス** `200 OK`
```json
{
  "message": "パスワードリセットメールを送信しました"
}
```

**エラー**
| ステータス | コード | 説明 |
|---|---|---|
| 400 | `BAD_REQUEST` | メールアドレスが不正 |

---

### DELETE /auth/account

ユーザーアカウントを削除します。関連する全てのデータ（写真、アルバム等）も削除されます。

- **認証**: 必要

**リクエスト**
```json
{
  "confirmation": "DELETE"
}
```

**レスポンス** `200 OK`
```json
{
  "message": "アカウントが削除されました"
}
```

**エラー**
| ステータス | コード | 説明 |
|---|---|---|
| 400 | `BAD_REQUEST` | 確認文字列が不正 |
| 401 | `UNAUTHORIZED` | 認証が必要 |

---

## 2. 写真 (Photos)

### POST /photos/upload

写真をアップロードします。マルチパートフォームデータで送信します。

- **認証**: 必要

**リクエスト** `multipart/form-data`
| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `file` | File | はい | 写真ファイル (JPEG, PNG, WebP, HEIC) |

**レスポンス** `201 Created`
```json
{
  "photo": {
    "id": "660e8400-e29b-41d4-a716-446655440000",
    "storage_path": "550e8400-.../photos/IMG_001.jpg",
    "thumbnail_path": "550e8400-.../thumbnails/IMG_001_thumb.jpg",
    "original_filename": "IMG_001.jpg",
    "file_size": 2097152,
    "width": 4032,
    "height": 3024,
    "exif_data": {
      "Make": "Apple",
      "Model": "iPhone 15 Pro",
      "DateTimeOriginal": "2025:12:01 17:30:00"
    },
    "ai_tags": [],
    "is_favorite": false,
    "created_at": "2025-12-01T17:30:00.000Z"
  }
}
```

**エラー**
| ステータス | コード | 説明 |
|---|---|---|
| 400 | `BAD_REQUEST` | ファイル形式が不正 |
| 401 | `UNAUTHORIZED` | 認証が必要 |
| 413 | `PAYLOAD_TOO_LARGE` | ファイルサイズが10MBを超過 |
| 429 | `RATE_LIMIT_EXCEEDED` | ストレージ容量の上限に到達 |

---

### GET /photos

ユーザーの写真一覧を取得します。ページネーション対応。

- **認証**: 必要

**クエリパラメータ**
| パラメータ | 型 | デフォルト | 説明 |
|---|---|---|---|
| `page` | integer | 1 | ページ番号 |
| `per_page` | integer | 20 | 1ページあたりの件数 (最大100) |
| `sort` | string | `created_at` | ソートフィールド (`created_at`, `file_size`) |
| `order` | string | `desc` | ソート順 (`asc`, `desc`) |
| `favorite` | boolean | - | お気に入りのみ取得 |

**レスポンス** `200 OK`
```json
{
  "photos": [
    {
      "id": "660e8400-e29b-41d4-a716-446655440000",
      "storage_path": "550e8400-.../photos/IMG_001.jpg",
      "thumbnail_path": "550e8400-.../thumbnails/IMG_001_thumb.jpg",
      "original_filename": "IMG_001.jpg",
      "file_size": 2097152,
      "width": 4032,
      "height": 3024,
      "ai_tags": ["sunset", "sky", "landscape"],
      "is_favorite": true,
      "created_at": "2025-12-01T17:30:00.000Z"
    }
  ],
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total": 45,
    "total_pages": 3
  }
}
```

---

### GET /photos/{id}

写真の詳細情報を取得します。

- **認証**: 必要

**パスパラメータ**
| パラメータ | 型 | 説明 |
|---|---|---|
| `id` | UUID | 写真ID |

**レスポンス** `200 OK`
```json
{
  "photo": {
    "id": "660e8400-e29b-41d4-a716-446655440000",
    "storage_path": "550e8400-.../photos/IMG_001.jpg",
    "thumbnail_path": "550e8400-.../thumbnails/IMG_001_thumb.jpg",
    "original_filename": "IMG_001.jpg",
    "file_size": 2097152,
    "width": 4032,
    "height": 3024,
    "exif_data": {
      "Make": "Apple",
      "Model": "iPhone 15 Pro",
      "DateTimeOriginal": "2025:12:01 17:30:00",
      "GPSLatitude": 35.6762,
      "GPSLongitude": 139.6503
    },
    "ai_tags": ["sunset", "sky", "landscape"],
    "is_favorite": true,
    "created_at": "2025-12-01T17:30:00.000Z",
    "signed_url": "https://...supabase.co/storage/v1/object/sign/photos/...",
    "thumbnail_signed_url": "https://...supabase.co/storage/v1/object/sign/photos/..."
  }
}
```

**エラー**
| ステータス | コード | 説明 |
|---|---|---|
| 404 | `NOT_FOUND` | 写真が見つからない |

---

### PATCH /photos/{id}

写真のメタデータを更新します。

- **認証**: 必要

**パスパラメータ**
| パラメータ | 型 | 説明 |
|---|---|---|
| `id` | UUID | 写真ID |

**リクエスト**
```json
{
  "is_favorite": true,
  "ai_tags": ["sunset", "sky", "landscape", "tokyo"]
}
```

**レスポンス** `200 OK`
```json
{
  "photo": {
    "id": "660e8400-e29b-41d4-a716-446655440000",
    "is_favorite": true,
    "ai_tags": ["sunset", "sky", "landscape", "tokyo"],
    "updated_at": "2025-12-02T10:00:00.000Z"
  }
}
```

**エラー**
| ステータス | コード | 説明 |
|---|---|---|
| 404 | `NOT_FOUND` | 写真が見つからない |

---

### DELETE /photos/{id}

写真をソフトデリートします（ゴミ箱に移動）。

- **認証**: 必要

**パスパラメータ**
| パラメータ | 型 | 説明 |
|---|---|---|
| `id` | UUID | 写真ID |

**レスポンス** `200 OK`
```json
{
  "message": "写真をゴミ箱に移動しました",
  "deleted_at": "2025-12-02T10:00:00.000Z"
}
```

**エラー**
| ステータス | コード | 説明 |
|---|---|---|
| 404 | `NOT_FOUND` | 写真が見つからない |

---

### GET /photos/search

写真をAIタグやメタデータで検索します。

- **認証**: 必要

**クエリパラメータ**
| パラメータ | 型 | 説明 |
|---|---|---|
| `q` | string | 検索クエリ（AIタグ、ファイル名で検索） |
| `tags` | string | カンマ区切りのタグ（AND検索） |
| `date_from` | string | 開始日 (ISO 8601) |
| `date_to` | string | 終了日 (ISO 8601) |
| `page` | integer | ページ番号（デフォルト: 1） |
| `per_page` | integer | 1ページあたりの件数（デフォルト: 20） |

**レスポンス** `200 OK`
```json
{
  "photos": [
    {
      "id": "660e8400-e29b-41d4-a716-446655440000",
      "storage_path": "550e8400-.../photos/IMG_001.jpg",
      "thumbnail_path": "550e8400-.../thumbnails/IMG_001_thumb.jpg",
      "original_filename": "IMG_001.jpg",
      "ai_tags": ["sunset", "sky", "landscape"],
      "is_favorite": true,
      "created_at": "2025-12-01T17:30:00.000Z"
    }
  ],
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total": 5,
    "total_pages": 1
  }
}
```

---

## 3. AI生成 (AI)

### POST /ai/hashtags

写真からInstagram/SNS向けハッシュタグを生成します。

- **認証**: 必要

**リクエスト**
```json
{
  "photo_id": "660e8400-e29b-41d4-a716-446655440000",
  "style": "instagram",
  "language": "ja",
  "count": 10
}
```

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `photo_id` | UUID | はい | 対象の写真ID |
| `style` | string | いいえ | スタイル (`instagram`, `twitter`, `casual`, `professional`) デフォルト: `instagram` |
| `language` | string | いいえ | 言語コード (`ja`, `en`) デフォルト: `ja` |
| `count` | integer | いいえ | 生成するハッシュタグ数 (1-30) デフォルト: 10 |

**レスポンス** `200 OK`
```json
{
  "generation_id": "770e8400-e29b-41d4-a716-446655440000",
  "photo_id": "660e8400-e29b-41d4-a716-446655440000",
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
    "#goldenhour"
  ],
  "model": "gemini-3-flash-preview",
  "latency_ms": 1250
}
```

**エラー**
| ステータス | コード | 説明 |
|---|---|---|
| 404 | `NOT_FOUND` | 写真が見つからない |
| 429 | `RATE_LIMIT_EXCEEDED` | 1日のAI生成回数上限に到達（無料: 5回/日, Premium: 無制限） |

---

### POST /ai/caption

写真からSNS投稿用キャプションを生成します。

- **認証**: 必要

**リクエスト**
```json
{
  "photo_id": "660e8400-e29b-41d4-a716-446655440000",
  "style": "poetic",
  "language": "ja",
  "max_length": 200
}
```

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `photo_id` | UUID | はい | 対象の写真ID |
| `style` | string | いいえ | スタイル (`poetic`, `casual`, `professional`, `funny`) デフォルト: `casual` |
| `language` | string | いいえ | 言語コード (`ja`, `en`) デフォルト: `ja` |
| `max_length` | integer | いいえ | 最大文字数 (10-500) デフォルト: 200 |

**レスポンス** `200 OK`
```json
{
  "generation_id": "880e8400-e29b-41d4-a716-446655440000",
  "photo_id": "660e8400-e29b-41d4-a716-446655440000",
  "caption": "東京の空が燃えるように染まる夕暮れ。都会の喧騒を忘れさせてくれる、一日の終わりの贈り物。",
  "model": "gemini-3-flash-preview",
  "latency_ms": 980
}
```

**エラー**
| ステータス | コード | 説明 |
|---|---|---|
| 404 | `NOT_FOUND` | 写真が見つからない |
| 429 | `RATE_LIMIT_EXCEEDED` | 1日のAI生成回数上限に到達 |

---

### GET /ai/usage

現在のAI生成使用状況を取得します。

- **認証**: 必要

**レスポンス** `200 OK`
```json
{
  "plan": "free",
  "daily_limit": 5,
  "daily_used": 3,
  "daily_remaining": 2,
  "reset_at": "2025-12-03T00:00:00.000Z"
}
```

---

## 4. アルバム (Albums)

### POST /albums

新しいアルバムを作成します。

- **認証**: 必要

**リクエスト**
```json
{
  "name": "Tokyo Favorites",
  "is_public": false
}
```

**レスポンス** `201 Created`
```json
{
  "album": {
    "id": "990e8400-e29b-41d4-a716-446655440000",
    "name": "Tokyo Favorites",
    "cover_photo_id": null,
    "is_public": false,
    "share_token": null,
    "photo_count": 0,
    "created_at": "2025-12-01T10:00:00.000Z",
    "updated_at": "2025-12-01T10:00:00.000Z"
  }
}
```

---

### GET /albums

ユーザーのアルバム一覧を取得します。

- **認証**: 必要

**クエリパラメータ**
| パラメータ | 型 | デフォルト | 説明 |
|---|---|---|---|
| `page` | integer | 1 | ページ番号 |
| `per_page` | integer | 20 | 1ページあたりの件数 |

**レスポンス** `200 OK`
```json
{
  "albums": [
    {
      "id": "990e8400-e29b-41d4-a716-446655440000",
      "name": "Tokyo Favorites",
      "cover_photo_id": "660e8400-e29b-41d4-a716-446655440000",
      "cover_photo_thumbnail_url": "https://...",
      "is_public": true,
      "share_token": "share_abc123def456",
      "photo_count": 12,
      "created_at": "2025-12-01T10:00:00.000Z",
      "updated_at": "2025-12-05T15:00:00.000Z"
    }
  ],
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total": 3,
    "total_pages": 1
  }
}
```

---

### GET /albums/{id}

アルバムの詳細と写真一覧を取得します。公開アルバムの場合、share_tokenによるアクセスも可能です。

- **認証**: 必要（公開アルバムの場合は不要）

**パスパラメータ**
| パラメータ | 型 | 説明 |
|---|---|---|
| `id` | UUID | アルバムID |

**クエリパラメータ**
| パラメータ | 型 | 説明 |
|---|---|---|
| `share_token` | string | 公開アルバムのシェアトークン（認証なしアクセス時に必要） |
| `page` | integer | ページ番号（デフォルト: 1） |
| `per_page` | integer | 1ページあたりの件数（デフォルト: 20） |

**レスポンス** `200 OK`
```json
{
  "album": {
    "id": "990e8400-e29b-41d4-a716-446655440000",
    "name": "Tokyo Favorites",
    "is_public": true,
    "share_token": "share_abc123def456",
    "created_at": "2025-12-01T10:00:00.000Z",
    "updated_at": "2025-12-05T15:00:00.000Z"
  },
  "photos": [
    {
      "id": "660e8400-e29b-41d4-a716-446655440000",
      "thumbnail_signed_url": "https://...",
      "original_filename": "IMG_001.jpg",
      "width": 4032,
      "height": 3024,
      "sort_order": 0,
      "added_at": "2025-12-01T10:00:00.000Z"
    }
  ],
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total": 12,
    "total_pages": 1
  }
}
```

**エラー**
| ステータス | コード | 説明 |
|---|---|---|
| 404 | `NOT_FOUND` | アルバムが見つからない |

---

### PATCH /albums/{id}

アルバムの情報を更新します。

- **認証**: 必要

**パスパラメータ**
| パラメータ | 型 | 説明 |
|---|---|---|
| `id` | UUID | アルバムID |

**リクエスト**
```json
{
  "name": "Tokyo Best Shots",
  "cover_photo_id": "660e8400-e29b-41d4-a716-446655440000",
  "is_public": true
}
```

**レスポンス** `200 OK`
```json
{
  "album": {
    "id": "990e8400-e29b-41d4-a716-446655440000",
    "name": "Tokyo Best Shots",
    "cover_photo_id": "660e8400-e29b-41d4-a716-446655440000",
    "is_public": true,
    "share_token": "share_xyz789ghi012",
    "updated_at": "2025-12-05T16:00:00.000Z"
  }
}
```

**エラー**
| ステータス | コード | 説明 |
|---|---|---|
| 404 | `NOT_FOUND` | アルバムが見つからない |

---

### DELETE /albums/{id}

アルバムを削除します。アルバム内の写真自体は削除されません。

- **認証**: 必要

**パスパラメータ**
| パラメータ | 型 | 説明 |
|---|---|---|
| `id` | UUID | アルバムID |

**レスポンス** `200 OK`
```json
{
  "message": "アルバムを削除しました"
}
```

**エラー**
| ステータス | コード | 説明 |
|---|---|---|
| 404 | `NOT_FOUND` | アルバムが見つからない |

---

### POST /albums/{id}/photos

アルバムに写真を追加します。

- **認証**: 必要

**パスパラメータ**
| パラメータ | 型 | 説明 |
|---|---|---|
| `id` | UUID | アルバムID |

**リクエスト**
```json
{
  "photo_ids": [
    "660e8400-e29b-41d4-a716-446655440000",
    "770e8400-e29b-41d4-a716-446655440001"
  ]
}
```

**レスポンス** `200 OK`
```json
{
  "added_count": 2,
  "album_photo_count": 14
}
```

**エラー**
| ステータス | コード | 説明 |
|---|---|---|
| 404 | `NOT_FOUND` | アルバムまたは写真が見つからない |
| 409 | `CONFLICT` | 写真が既にアルバムに追加済み |

---

### DELETE /albums/{id}/photos/{photo_id}

アルバムから写真を削除します。写真自体は削除されません。

- **認証**: 必要

**パスパラメータ**
| パラメータ | 型 | 説明 |
|---|---|---|
| `id` | UUID | アルバムID |
| `photo_id` | UUID | 写真ID |

**レスポンス** `200 OK`
```json
{
  "message": "アルバムから写真を削除しました"
}
```

**エラー**
| ステータス | コード | 説明 |
|---|---|---|
| 404 | `NOT_FOUND` | アルバムまたは写真が見つからない |

---

## 5. 決済 (Payments)

### POST /payments/verify-receipt

App Store / Google Play のレシートを検証し、プランをアップグレードします。

- **認証**: 必要

**リクエスト**
```json
{
  "platform": "ios",
  "receipt_data": "MIIbngYJKoZIhvcNAQcCoIIbj...",
  "product_id": "premium_monthly"
}
```

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `platform` | string | はい | プラットフォーム (`ios`, `android`) |
| `receipt_data` | string | はい | レシートデータ（Base64エンコード） |
| `product_id` | string | はい | 商品ID (`premium_monthly`, `premium_yearly`) |

**レスポンス** `200 OK`
```json
{
  "valid": true,
  "plan": "premium",
  "expires_at": "2026-01-01T00:00:00.000Z",
  "product_id": "premium_monthly"
}
```

**エラー**
| ステータス | コード | 説明 |
|---|---|---|
| 400 | `BAD_REQUEST` | レシートデータが不正 |
| 403 | `FORBIDDEN` | レシートの検証に失敗 |

---

### GET /payments/subscription

現在のサブスクリプション状態を取得します。

- **認証**: 必要

**レスポンス** `200 OK`
```json
{
  "plan": "premium",
  "status": "active",
  "product_id": "premium_monthly",
  "expires_at": "2026-01-01T00:00:00.000Z",
  "auto_renew": true,
  "features": {
    "ai_daily_limit": null,
    "storage_limit_bytes": 10737418240,
    "watermark_free": true,
    "priority_support": true
  }
}
```

Freeプランの場合:
```json
{
  "plan": "free",
  "status": "active",
  "product_id": null,
  "expires_at": null,
  "auto_renew": false,
  "features": {
    "ai_daily_limit": 5,
    "storage_limit_bytes": 1073741824,
    "watermark_free": false,
    "priority_support": false
  }
}
```

---

### POST /payments/webhook/appstore

Apple App Store のサーバー通知を受信します。サブスクリプションの更新、キャンセル、期限切れ等を処理します。

- **認証**: 不要（App Store署名で検証）

**リクエスト**: Apple Server Notification V2 形式

**レスポンス** `200 OK`
```json
{
  "status": "processed"
}
```

---

### POST /payments/webhook/playstore

Google Play のリアルタイム開発者通知を受信します。

- **認証**: 不要（Google署名で検証）

**リクエスト**: Google Play Real-time Developer Notification 形式

**レスポンス** `200 OK`
```json
{
  "status": "processed"
}
```

---

## プラン別制限

| 機能 | Free | Premium |
|---|---|---|
| AI生成（ハッシュタグ/キャプション） | 5回/日 | 無制限 |
| ストレージ容量 | 1 GB | 10 GB |
| ウォーターマーク | あり | なし |
| 優先サポート | なし | あり |

---

## レート制限

全てのAPIエンドポイントには以下のレート制限が適用されます。

| エンドポイント | 制限 |
|---|---|
| 認証系 (`/auth/*`) | 10回/分 |
| 写真アップロード (`POST /photos/upload`) | 30回/分 |
| AI生成 (`/ai/*`) | Free: 5回/日, Premium: 60回/分 |
| その他 | 100回/分 |

レート制限に達した場合、`429 Too Many Requests` が返されます。レスポンスヘッダーに制限情報が含まれます。

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1701500000
```
