import Flutter
import Foundation

/// Platform Channel plugin for Gemma 4 E2B on-device AI inference on iOS.
///
/// Uses MediaPipe LLM Inference API to run Gemma model natively.
/// This is a scaffold implementation — actual MediaPipe integration
/// requires adding the MediaPipeTasksGenAI pod and model files.
class GemmaPlugin: NSObject, FlutterPlugin {
    static let channelName = "com.daiary.offline/gemma"
    private let channel: FlutterMethodChannel
    private var downloadTask: URLSessionDownloadTask?

    private static let modelFilename = "gemma-4-e2b-it-int4.bin"

    private var modelDir: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("ai_models")
    }

    private var modelFile: URL {
        return modelDir.appendingPathComponent(Self.modelFilename)
    }

    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
    }

    static func register(with messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
        let instance = GemmaPlugin(channel: channel)
        channel.setMethodCallHandler(instance.handle)
    }

    // Required by FlutterPlugin protocol
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
        let instance = GemmaPlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isModelReady":
            result(isModelReady())
        case "downloadModel":
            downloadModel(result: result)
        case "cancelDownload":
            cancelDownload(result: result)
        case "deleteModel":
            deleteModel(result: result)
        case "generateHashtags":
            generateHashtags(call: call, result: result)
        case "generateCaption":
            generateCaption(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func isModelReady() -> Bool {
        return FileManager.default.fileExists(atPath: modelFile.path)
    }

    private func downloadModel(result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            do {
                try FileManager.default.createDirectory(at: self.modelDir, withIntermediateDirectories: true)
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "DOWNLOAD_ERROR", message: error.localizedDescription, details: nil))
                }
                return
            }

            // TODO: Replace with actual model download from CDN
            // Simulating download progress for now
            for i in 1...100 {
                Thread.sleep(forTimeInterval: 0.05)
                DispatchQueue.main.async {
                    self.channel.invokeMethod("onDownloadProgress", arguments: Double(i) / 100.0)
                }
            }

            // Create placeholder file
            if !FileManager.default.fileExists(atPath: self.modelFile.path) {
                FileManager.default.createFile(atPath: self.modelFile.path, contents: "placeholder".data(using: .utf8))
            }

            DispatchQueue.main.async {
                result(nil)
            }
        }
    }

    private func cancelDownload(result: @escaping FlutterResult) {
        downloadTask?.cancel()
        downloadTask = nil
        result(nil)
    }

    private func deleteModel(result: @escaping FlutterResult) {
        do {
            if FileManager.default.fileExists(atPath: modelFile.path) {
                try FileManager.default.removeItem(at: modelFile)
            }
            // TODO: Release MediaPipe LlmInference resources
            result(nil)
        } catch {
            result(FlutterError(code: "DELETE_ERROR", message: error.localizedDescription, details: nil))
        }
    }

    private func generateHashtags(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let _ = args["photoPath"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "photoPath is required", details: nil))
            return
        }

        guard isModelReady() else {
            result(FlutterError(code: "MODEL_NOT_READY", message: "AI model is not downloaded", details: nil))
            return
        }

        let language = args["language"] as? String ?? "ja"
        let count = args["count"] as? Int ?? 10

        DispatchQueue.global(qos: .userInitiated).async {
            // TODO: Replace with actual MediaPipe LLM inference
            let response = self.placeholderHashtags(language: language, count: count)

            DispatchQueue.main.async {
                result(response)
            }
        }
    }

    private func generateCaption(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let _ = args["photoPath"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "photoPath is required", details: nil))
            return
        }

        guard isModelReady() else {
            result(FlutterError(code: "MODEL_NOT_READY", message: "AI model is not downloaded", details: nil))
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            // TODO: Replace with actual MediaPipe LLM inference
            let response = """
            {"caption": "AI caption placeholder — replace with actual Gemma inference"}
            """

            DispatchQueue.main.async {
                result(response)
            }
        }
    }

    private func placeholderHashtags(language: String, count: Int) -> String {
        let tags: [String]
        if language == "ja" {
            tags = ["#写真", "#日常", "#風景", "#カメラ", "#撮影", "#フォト", "#思い出",
                    "#インスタ", "#写真好き", "#カメラ好き", "#日本", "#旅行", "#散歩",
                    "#自然", "#空"]
        } else {
            tags = ["#photo", "#daily", "#landscape", "#camera", "#photography",
                    "#memories", "#instagram", "#photooftheday", "#nature", "#travel",
                    "#beautiful", "#instagood", "#picoftheday", "#sky", "#wanderlust"]
        }
        let selected = Array(tags.prefix(count))
        let joined = selected.map { "\"\($0)\"" }.joined(separator: ",")
        return "{\"hashtags\": [\(joined)]}"
    }
}
