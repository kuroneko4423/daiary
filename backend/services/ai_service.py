import base64
import json
import logging
import time

from google import genai

logger = logging.getLogger(__name__)


class AIService:
    def __init__(self, api_key: str):
        self.client = genai.Client(api_key=api_key)
        self.model = "gemini-2.0-flash"

    async def generate_hashtags(
        self,
        image_bytes: bytes,
        language: str = "ja",
        count: int = 15,
        usage: str = "instagram",
    ) -> dict:
        """Generate hashtags for an image using Gemini."""
        system_prompt = (
            "あなたはSNSマーケティングの専門家です。与えられた写真を分析し、"
            f"エンゲージメントを最大化するハッシュタグを{count}個生成してください。\n\n"
            f"対象プラットフォーム: {usage}\n"
            f"言語: {language}\n\n"
            "JSON形式で返してください: {\"hashtags\": [\"#tag1\", \"#tag2\", ...]}\n"
            "JSONのみを返し、他のテキストは含めないでください。"
        )

        start_ms = time.monotonic()
        try:
            b64 = base64.standard_b64encode(image_bytes).decode("utf-8")
            response = self.client.models.generate_content(
                model=self.model,
                contents=[
                    {
                        "role": "user",
                        "parts": [
                            {"inline_data": {"mime_type": "image/jpeg", "data": b64}},
                            {"text": system_prompt},
                        ],
                    }
                ],
            )
            elapsed_ms = int((time.monotonic() - start_ms) * 1000)

            text = response.text.strip()
            # Strip markdown code fences if present
            if text.startswith("```"):
                text = text.split("\n", 1)[1] if "\n" in text else text[3:]
                if text.endswith("```"):
                    text = text[:-3].strip()

            result = json.loads(text)
            result["latency_ms"] = elapsed_ms
            return result
        except json.JSONDecodeError:
            logger.error("Failed to parse Gemini hashtag response: %s", text)
            raise ValueError("AI returned invalid JSON for hashtags")
        except Exception as e:
            logger.error("Gemini hashtag generation failed: %s", e)
            raise

    async def generate_caption(
        self,
        image_bytes: bytes,
        language: str = "ja",
        style: str = "casual",
        length: str = "medium",
        custom_prompt: str | None = None,
    ) -> dict:
        """Generate a caption for an image using Gemini."""
        length_guide = {
            "short": "約100文字",
            "medium": "約300文字",
            "long": "約800文字",
        }
        char_guide = length_guide.get(length, "約300文字")

        if custom_prompt:
            system_prompt = (
                f"あなたはSNSコンテンツクリエイターです。以下の指示に従って投稿文を生成してください。\n\n"
                f"指示: {custom_prompt}\n"
                f"言語: {language}\n"
                f"文字数目安: {char_guide}\n\n"
                "JSON形式で返してください: {\"caption\": \"生成されたテキスト\"}\n"
                "JSONのみを返し、他のテキストは含めないでください。"
            )
        else:
            system_prompt = (
                f"あなたはSNSコンテンツクリエイターです。与えられた写真に合う{style}スタイルの投稿文を生成してください。\n\n"
                f"スタイル: {style}\n"
                f"言語: {language}\n"
                f"文字数目安: {char_guide}\n\n"
                "JSON形式で返してください: {\"caption\": \"生成されたテキスト\"}\n"
                "JSONのみを返し、他のテキストは含めないでください。"
            )

        start_ms = time.monotonic()
        try:
            b64 = base64.standard_b64encode(image_bytes).decode("utf-8")
            response = self.client.models.generate_content(
                model=self.model,
                contents=[
                    {
                        "role": "user",
                        "parts": [
                            {"inline_data": {"mime_type": "image/jpeg", "data": b64}},
                            {"text": system_prompt},
                        ],
                    }
                ],
            )
            elapsed_ms = int((time.monotonic() - start_ms) * 1000)

            text = response.text.strip()
            # Strip markdown code fences if present
            if text.startswith("```"):
                text = text.split("\n", 1)[1] if "\n" in text else text[3:]
                if text.endswith("```"):
                    text = text[:-3].strip()

            result = json.loads(text)
            result["latency_ms"] = elapsed_ms
            return result
        except json.JSONDecodeError:
            logger.error("Failed to parse Gemini caption response: %s", text)
            raise ValueError("AI returned invalid JSON for caption")
        except Exception as e:
            logger.error("Gemini caption generation failed: %s", e)
            raise
