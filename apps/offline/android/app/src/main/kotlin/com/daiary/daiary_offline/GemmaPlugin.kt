package com.daiary.daiary_offline

import android.content.Context
import android.graphics.BitmapFactory
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.io.File

/**
 * Platform Channel plugin for Gemma 4 E2B on-device AI inference.
 *
 * Uses MediaPipe LLM Inference API to run Gemma model natively on Android.
 * This is a scaffold implementation — the actual MediaPipe integration
 * requires adding the mediapipe-tasks-genai dependency and model files.
 *
 * Methods:
 * - isModelReady: Check if the model file exists and is loaded
 * - downloadModel: Download the Gemma model (placeholder for actual download logic)
 * - cancelDownload: Cancel an in-progress download
 * - deleteModel: Remove the downloaded model file
 * - generateHashtags: Generate hashtags from a photo
 * - generateCaption: Generate a caption from a photo
 */
class GemmaPlugin private constructor(
    private val context: Context,
    private val channel: MethodChannel
) : MethodChannel.MethodCallHandler {

    companion object {
        private const val CHANNEL_NAME = "com.daiary.offline/gemma"
        private const val MODEL_FILENAME = "gemma-4-e2b-it-int4.bin"

        fun registerWith(flutterEngine: FlutterEngine, context: Context) {
            val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            val plugin = GemmaPlugin(context, channel)
            channel.setMethodCallHandler(plugin)
        }
    }

    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private val modelDir: File get() = File(context.filesDir, "ai_models")
    private val modelFile: File get() = File(modelDir, MODEL_FILENAME)

    // TODO: Replace with actual MediaPipe LlmInference instance
    // private var llmInference: LlmInference? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isModelReady" -> result.success(isModelReady())
            "downloadModel" -> downloadModel(result)
            "cancelDownload" -> cancelDownload(result)
            "deleteModel" -> deleteModel(result)
            "generateHashtags" -> generateHashtags(call, result)
            "generateCaption" -> generateCaption(call, result)
            else -> result.notImplemented()
        }
    }

    private fun isModelReady(): Boolean {
        return modelFile.exists() && modelFile.length() > 0
    }

    private fun downloadModel(result: MethodChannel.Result) {
        scope.launch {
            try {
                modelDir.mkdirs()

                // TODO: Implement actual model download from a CDN/server
                for (i in 1..100) {
                    delay(50) // Simulate download
                    withContext(Dispatchers.Main) {
                        channel.invokeMethod("onDownloadProgress", i / 100.0)
                    }
                }

                // Create placeholder to mark as "ready"
                if (!modelFile.exists()) {
                    modelFile.writeText("placeholder")
                }

                withContext(Dispatchers.Main) {
                    result.success(null)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("DOWNLOAD_ERROR", e.message, null)
                }
            }
        }
    }

    private fun cancelDownload(result: MethodChannel.Result) {
        scope.coroutineContext.cancelChildren()
        result.success(null)
    }

    private fun deleteModel(result: MethodChannel.Result) {
        try {
            if (modelFile.exists()) {
                modelFile.delete()
            }
            result.success(null)
        } catch (e: Exception) {
            result.error("DELETE_ERROR", e.message, null)
        }
    }

    private fun generateHashtags(call: MethodCall, result: MethodChannel.Result) {
        val photoPath = call.argument<String>("photoPath") ?: run {
            result.error("INVALID_ARGS", "photoPath is required", null)
            return
        }
        val language = call.argument<String>("language") ?: "ja"
        val count = call.argument<Int>("count") ?: 10
        val usage = call.argument<String>("usage") ?: "instagram"

        if (!isModelReady()) {
            result.error("MODEL_NOT_READY", "AI model is not downloaded", null)
            return
        }

        scope.launch {
            try {
                val prompt = buildHashtagPrompt(photoPath, language, count, usage)

                // TODO: Replace with actual MediaPipe LLM inference
                val response = generatePlaceholderHashtags(language, count)

                withContext(Dispatchers.Main) {
                    result.success(response)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("GENERATION_ERROR", e.message, null)
                }
            }
        }
    }

    private fun generateCaption(call: MethodCall, result: MethodChannel.Result) {
        val photoPath = call.argument<String>("photoPath") ?: run {
            result.error("INVALID_ARGS", "photoPath is required", null)
            return
        }
        val language = call.argument<String>("language") ?: "ja"
        val style = call.argument<String>("style") ?: "casual"
        val length = call.argument<String>("length") ?: "medium"
        val customPrompt = call.argument<String>("customPrompt")

        if (!isModelReady()) {
            result.error("MODEL_NOT_READY", "AI model is not downloaded", null)
            return
        }

        scope.launch {
            try {
                val prompt = buildCaptionPrompt(photoPath, language, style, length, customPrompt)

                // TODO: Replace with actual MediaPipe LLM inference
                val response = """{"caption": "AI caption placeholder — replace with actual Gemma inference"}"""

                withContext(Dispatchers.Main) {
                    result.success(response)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("GENERATION_ERROR", e.message, null)
                }
            }
        }
    }

    private fun buildHashtagPrompt(
        photoPath: String,
        language: String,
        count: Int,
        usage: String
    ): String {
        val langLabel = if (language == "ja") "日本語" else "English"
        return """
            You are an SNS marketing expert. Analyze the given photo and generate
            $count hashtags that maximize engagement.
            Platform: $usage
            Language: $langLabel
            Return JSON only: {"hashtags": ["#tag1", "#tag2", ...]}
        """.trimIndent()
    }

    private fun buildCaptionPrompt(
        photoPath: String,
        language: String,
        style: String,
        length: String,
        customPrompt: String?
    ): String {
        val langLabel = if (language == "ja") "日本語" else "English"
        val charGuide = when (length) {
            "short_" -> "about 100 characters"
            "medium" -> "about 300 characters"
            "long_" -> "about 800 characters"
            else -> "about 300 characters"
        }
        return """
            You are an SNS content creator. Generate a $style style post caption.
            Language: $langLabel
            Length: $charGuide
            ${if (customPrompt != null) "Custom instruction: $customPrompt" else ""}
            Return JSON only: {"caption": "generated text"}
        """.trimIndent()
    }

    // Placeholder response until actual model is integrated
    private fun generatePlaceholderHashtags(language: String, count: Int): String {
        val tags = if (language == "ja") {
            listOf("#写真", "#日常", "#風景", "#カメラ", "#撮影", "#フォト", "#思い出",
                "#インスタ", "#写真好き", "#カメラ好き", "#日本", "#旅行", "#散歩",
                "#自然", "#空")
        } else {
            listOf("#photo", "#daily", "#landscape", "#camera", "#photography",
                "#memories", "#instagram", "#photooftheday", "#nature", "#travel",
                "#beautiful", "#instagood", "#picoftheday", "#sky", "#wanderlust")
        }
        val selected = tags.take(count)
        return """{"hashtags": [${selected.joinToString(",") { "\"$it\"" }}]}"""
    }
}
