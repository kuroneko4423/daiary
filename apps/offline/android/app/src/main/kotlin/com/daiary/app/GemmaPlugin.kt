package com.daiary.app

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.util.Log
import androidx.exifinterface.media.ExifInterface
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.genai.llminference.GraphOptions
import com.google.mediapipe.tasks.genai.llminference.LlmInference
import com.google.mediapipe.tasks.genai.llminference.LlmInferenceSession
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancelChildren
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import okhttp3.Call
import okhttp3.OkHttpClient
import okhttp3.Request
import okio.buffer
import okio.sink
import java.io.File
import java.security.MessageDigest
import java.util.concurrent.TimeUnit
import kotlin.math.max

/**
 * Platform Channel plugin for Gemma 3n on-device AI inference using MediaPipe LLM Inference.
 *
 * Methods:
 * - isModelReady: Check if the model file exists and is sufficiently large.
 * - downloadModel: Stream the .task model from BuildConfig.GEMMA_MODEL_URL with SHA-256 verify.
 * - cancelDownload: Cancel an in-progress download and remove the .part file.
 * - deleteModel: Release LlmInference and remove the file.
 * - generateHashtags / generateCaption: Run multimodal inference (image + text prompt).
 */
class GemmaPlugin private constructor(
    private val context: Context,
    private val channel: MethodChannel,
) : MethodChannel.MethodCallHandler {

    companion object {
        private const val TAG = "GemmaPlugin"
        private const val CHANNEL_NAME = "com.daiary.offline/gemma"
        private const val MODEL_FILENAME = "gemma-3n-E2B-it-int4.task"
        private const val MAX_IMAGE_DIM = 1024
        private const val MIN_VALID_MODEL_BYTES = 100L * 1024 * 1024
        private const val DOWNLOAD_BUFFER = 256L * 1024
        private const val PROGRESS_STEP = 0.01

        fun registerWith(flutterEngine: FlutterEngine, context: Context) {
            val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            val plugin = GemmaPlugin(context.applicationContext, channel)
            channel.setMethodCallHandler(plugin)
        }
    }

    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private val modelDir: File get() = File(context.filesDir, "ai_models")
    private val modelFile: File get() = File(modelDir, MODEL_FILENAME)
    private val partFile: File get() = File(modelDir, "$MODEL_FILENAME.part")

    private val httpClient: OkHttpClient by lazy {
        OkHttpClient.Builder()
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(0, TimeUnit.MILLISECONDS) // long downloads
            .build()
    }

    private var llmInference: LlmInference? = null
    private val llmLock = Mutex()

    @Volatile
    private var downloadCall: Call? = null

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

    private fun isModelReady(): Boolean =
        modelFile.exists() && modelFile.length() > MIN_VALID_MODEL_BYTES

    // ---------------------------------------------------------------------
    // Download
    // ---------------------------------------------------------------------

    private fun downloadModel(result: MethodChannel.Result) {
        val url = BuildConfig.GEMMA_MODEL_URL
        if (url.isBlank()) {
            result.error(
                "MODEL_URL_NOT_CONFIGURED",
                "GEMMA_MODEL_URL is not set. Define it in gradle.properties.",
                null,
            )
            return
        }

        scope.launch {
            try {
                modelDir.mkdirs()
                if (partFile.exists()) partFile.delete()

                Log.i(TAG, "downloadModel start url=$url")
                val request = Request.Builder().url(url).get().build()
                val call = httpClient.newCall(request)
                downloadCall = call

                val response = call.execute()
                if (!response.isSuccessful) {
                    response.close()
                    throw IllegalStateException("HTTP ${response.code}")
                }
                val body = response.body ?: throw IllegalStateException("empty body")
                val total = body.contentLength()
                Log.i(TAG, "downloadModel content-length=$total")

                var downloaded = 0L
                var lastReported = 0.0
                body.source().use { source ->
                    partFile.sink().buffer().use { sink ->
                        while (true) {
                            val read = source.read(sink.buffer, DOWNLOAD_BUFFER)
                            if (read == -1L) break
                            sink.emit()
                            downloaded += read
                            if (total > 0) {
                                val progress = downloaded.toDouble() / total.toDouble()
                                if (progress - lastReported >= PROGRESS_STEP) {
                                    lastReported = progress
                                    val capped = progress.coerceIn(0.0, 1.0)
                                    withContext(Dispatchers.Main) {
                                        channel.invokeMethod("onDownloadProgress", capped)
                                    }
                                }
                            }
                        }
                    }
                }

                downloadCall = null
                Log.i(TAG, "downloadModel transfer complete bytes=$downloaded")

                val expectedSha = BuildConfig.GEMMA_MODEL_SHA256
                if (expectedSha.isNotBlank()) {
                    val actual = sha256(partFile)
                    if (!actual.equals(expectedSha, ignoreCase = true)) {
                        partFile.delete()
                        throw IllegalStateException(
                            "SHA-256 mismatch (expected=$expectedSha actual=$actual)"
                        )
                    }
                    Log.i(TAG, "downloadModel SHA-256 OK")
                } else {
                    Log.w(TAG, "downloadModel SHA-256 not configured; skipping verify")
                }

                if (modelFile.exists()) modelFile.delete()
                if (!partFile.renameTo(modelFile)) {
                    throw IllegalStateException("rename .part -> final failed")
                }

                withContext(Dispatchers.Main) {
                    channel.invokeMethod("onDownloadProgress", 1.0)
                    result.success(null)
                }
            } catch (e: Throwable) {
                Log.e(TAG, "downloadModel failed", e)
                downloadCall = null
                if (partFile.exists()) partFile.delete()
                withContext(Dispatchers.Main) {
                    result.error("DOWNLOAD_ERROR", e.message, null)
                }
            }
        }
    }

    private fun cancelDownload(result: MethodChannel.Result) {
        downloadCall?.cancel()
        downloadCall = null
        scope.coroutineContext.cancelChildren()
        if (partFile.exists()) partFile.delete()
        Log.i(TAG, "downloadModel cancelled")
        result.success(null)
    }

    private fun deleteModel(result: MethodChannel.Result) {
        try {
            llmInference?.close()
            llmInference = null
            if (modelFile.exists()) modelFile.delete()
            if (partFile.exists()) partFile.delete()
            result.success(null)
        } catch (e: Exception) {
            result.error("DELETE_ERROR", e.message, null)
        }
    }

    private fun sha256(file: File): String {
        val md = MessageDigest.getInstance("SHA-256")
        file.inputStream().use { input ->
            val buf = ByteArray(64 * 1024)
            while (true) {
                val n = input.read(buf)
                if (n <= 0) break
                md.update(buf, 0, n)
            }
        }
        return md.digest().joinToString("") { "%02x".format(it) }
    }

    // ---------------------------------------------------------------------
    // Inference
    // ---------------------------------------------------------------------

    private suspend fun ensureLlmInference(): LlmInference = llmLock.withLock {
        llmInference?.let { return@withLock it }
        require(isModelReady()) { "model not present or below minimum size" }
        Log.i(
            TAG,
            "loading LlmInference path=${modelFile.absolutePath} bytes=${modelFile.length()}",
        )
        val opts = LlmInference.LlmInferenceOptions.builder()
            .setModelPath(modelFile.absolutePath)
            .setMaxNumImages(1)
            .setMaxTopK(64)
            .build()
        LlmInference.createFromOptions(context, opts).also { llmInference = it }
    }

    private fun loadAndOrientBitmap(path: String): Bitmap {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) {
            error("decode bounds failed: $path")
        }
        val sample = max(
            1,
            max(bounds.outWidth, bounds.outHeight) / MAX_IMAGE_DIM,
        )
        val opts = BitmapFactory.Options().apply { inSampleSize = sample }
        val raw = BitmapFactory.decodeFile(path, opts)
            ?: error("decode failed: $path")

        val orientation = runCatching {
            ExifInterface(path).getAttributeInt(
                ExifInterface.TAG_ORIENTATION,
                ExifInterface.ORIENTATION_NORMAL,
            )
        }.getOrDefault(ExifInterface.ORIENTATION_NORMAL)

        val matrix = Matrix().apply {
            when (orientation) {
                ExifInterface.ORIENTATION_ROTATE_90 -> postRotate(90f)
                ExifInterface.ORIENTATION_ROTATE_180 -> postRotate(180f)
                ExifInterface.ORIENTATION_ROTATE_270 -> postRotate(270f)
                ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> postScale(-1f, 1f)
                ExifInterface.ORIENTATION_FLIP_VERTICAL -> postScale(1f, -1f)
            }
        }
        return if (matrix.isIdentity) {
            raw
        } else {
            val rotated = Bitmap.createBitmap(
                raw, 0, 0, raw.width, raw.height, matrix, true,
            )
            if (rotated !== raw) raw.recycle()
            rotated
        }
    }

    private suspend fun runMultimodal(prompt: String, bitmap: Bitmap): String {
        val llm = ensureLlmInference()
        val sessionOpts = LlmInferenceSession.LlmInferenceSessionOptions.builder()
            .setTopK(40)
            .setTopP(0.95f)
            .setTemperature(0.8f)
            .setGraphOptions(
                GraphOptions.builder().setEnableVisionModality(true).build(),
            )
            .build()
        val session = LlmInferenceSession.createFromOptions(llm, sessionOpts)
        try {
            session.addImage(BitmapImageBuilder(bitmap).build())
            session.addQueryChunk(prompt)
            Log.d(
                TAG,
                "infer prompt(head)=${prompt.take(200)} bitmap=${bitmap.width}x${bitmap.height}",
            )
            val response = session.generateResponse()
            Log.d(
                TAG,
                "infer response.length=${response.length} head=${response.take(200)}",
            )
            return response
        } finally {
            try {
                session.close()
            } catch (e: Throwable) {
                Log.w(TAG, "session.close failed", e)
            }
            bitmap.recycle()
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
                val photoFile = File(photoPath)
                Log.d(
                    TAG,
                    "generateHashtags path=$photoPath bytes=${photoFile.length()} " +
                        "lang=$language count=$count usage=$usage",
                )
                val bitmap = loadAndOrientBitmap(photoPath)
                val prompt = buildHashtagPrompt(language, count, usage)
                val raw = runMultimodal(prompt, bitmap)
                withContext(Dispatchers.Main) { result.success(raw) }
            } catch (e: Throwable) {
                Log.e(TAG, "generateHashtags failed", e)
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
                val photoFile = File(photoPath)
                Log.d(
                    TAG,
                    "generateCaption path=$photoPath bytes=${photoFile.length()} " +
                        "lang=$language style=$style length=$length",
                )
                val bitmap = loadAndOrientBitmap(photoPath)
                val prompt = buildCaptionPrompt(language, style, length, customPrompt)
                val raw = runMultimodal(prompt, bitmap)
                withContext(Dispatchers.Main) { result.success(raw) }
            } catch (e: Throwable) {
                Log.e(TAG, "generateCaption failed", e)
                withContext(Dispatchers.Main) {
                    result.error("GENERATION_ERROR", e.message, null)
                }
            }
        }
    }

    private fun buildHashtagPrompt(language: String, count: Int, usage: String): String {
        val langLabel = if (language == "ja") "Japanese (日本語)" else "English"
        return """
            You are an SNS marketing expert. Look at the image attached to this message
            and propose $count hashtags that best describe its visible subject, mood,
            colors, and context. Optimize for $usage engagement.

            Rules:
            - Output language: $langLabel
            - Each tag MUST start with '#' and contain no spaces.
            - Base the tags on what is actually visible in the image, not generic filler.
            - Return ONLY a JSON object, no prose, no code fences:
              {"hashtags": ["#tag1", "#tag2", ...]}
        """.trimIndent()
    }

    private fun buildCaptionPrompt(
        language: String,
        style: String,
        length: String,
        customPrompt: String?,
    ): String {
        val langLabel = if (language == "ja") "Japanese (日本語)" else "English"
        // GenerationLength enum on Dart side: short_/medium/long_ — `.name` is forwarded as-is.
        val charGuide = when (length) {
            "short_" -> "about 100 characters"
            "long_" -> "about 800 characters"
            else -> "about 300 characters"
        }
        val customLine = if (!customPrompt.isNullOrBlank()) {
            "- Additional user instruction: $customPrompt"
        } else {
            ""
        }
        return """
            You are an SNS content creator. Look at the attached image and write a
            $style-style social post caption describing what you see and the feeling it evokes.

            Constraints:
            - Output language: $langLabel
            - Length: $charGuide
            $customLine
            - Return ONLY a JSON object, no prose, no code fences:
              {"caption": "..."}
        """.trimIndent()
    }
}
