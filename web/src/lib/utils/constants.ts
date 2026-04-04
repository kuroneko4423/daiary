export const GENERATION_STYLES = [
  { value: "poem", label: "ポエム風" },
  { value: "business", label: "ビジネス風" },
  { value: "casual", label: "カジュアル風" },
  { value: "news", label: "ニュース風" },
  { value: "humor", label: "ユーモア風" },
  { value: "custom", label: "カスタム" },
] as const;

export const GENERATION_LENGTHS = [
  { value: "short", label: "短文" },
  { value: "medium", label: "中文" },
  { value: "long", label: "長文" },
] as const;

export const LANGUAGES = [
  { value: "ja", label: "日本語" },
  { value: "en", label: "English" },
] as const;

export const ALLOWED_IMAGE_TYPES = [
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/heic",
];

export const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB
