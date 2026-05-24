import AppKit
import Foundation

/// Lightweight Gemini API client for vision tasks.
@MainActor
final class GeminiService {

    static let shared = GeminiService()

    enum AITask {
        case extractText
        case translate(to: String)
        case describeObjects
        case detectObjects  // returns JSON bounding boxes
        case smartReframe   // returns main subject bounding box
    }

    struct BoundingBox: Codable {
        let label: String
        let x: Double, y: Double, width: Double, height: Double
    }

    struct AIResult {
        let text: String
        let boxes: [BoundingBox]?
    }

    private let models = ["gemini-2.0-flash", "gemini-2.0-flash-lite"]
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"

    var isAvailable: Bool {
        !Settings.shared.geminiApiKey.isEmpty
    }

    func analyze(image: CGImage, task: AITask) async throws -> AIResult {
        guard isAvailable else { throw GeminiError.noApiKey }

        let base64 = try encodeImage(image)
        let prompt = promptFor(task)

        for model in models {
            do {
                return try await callAPI(model: model, base64: base64, prompt: prompt, task: task)
            } catch GeminiError.rateLimited {
                continue  // try next model
            }
        }
        throw GeminiError.rateLimited
    }

    private func callAPI(model: String, base64: String, prompt: String, task: AITask) async throws -> AIResult {
        let requestBody: [String: Any] = [
            "contents": [[
                "parts": [
                    ["text": prompt],
                    ["inline_data": ["mime_type": "image/png", "data": base64]]
                ]
            ]]
        ]

        let url = URL(string: "\(baseURL)/\(model):generateContent?key=\(Settings.shared.geminiApiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.apiError("No response")
        }

        if httpResponse.statusCode == 429 {
            throw GeminiError.rateLimited
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw GeminiError.apiError(body)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let text = extractText(from: json)

        switch task {
        case .detectObjects, .smartReframe:
            return AIResult(text: text, boxes: parseBoxes(from: text))
        default:
            return AIResult(text: text, boxes: nil)
        }
    }

    // MARK: - Private

    private func promptFor(_ task: AITask) -> String {
        switch task {
        case .extractText:
            return "Extract all visible text from this image. Return only the extracted text, nothing else."
        case .translate(let lang):
            return "Extract all text from this image and translate it to \(lang). Return only the translated text."
        case .describeObjects:
            return "List all distinct objects visible in this image, one per line."
        case .detectObjects:
            return """
            Detect all objects in this image. Return a JSON array where each element has:
            {"label": "object name", "x": 0.0, "y": 0.0, "width": 0.0, "height": 0.0}
            Coordinates are normalized 0-1 relative to image dimensions. Return only valid JSON.
            """
        case .smartReframe:
            return """
            Find the main subject in this image. Return a single JSON object:
            {"label": "subject", "x": 0.0, "y": 0.0, "width": 0.0, "height": 0.0}
            Coordinates are normalized 0-1 relative to image dimensions. Return only valid JSON.
            """
        }
    }

    private func encodeImage(_ image: CGImage) throws -> String {
        let rep = NSBitmapImageRep(cgImage: image)
        guard let png = rep.representation(using: .png, properties: [:]) else {
            throw GeminiError.encodingFailed
        }
        return png.base64EncodedString()
    }

    private func extractText(from json: [String: Any]?) -> String {
        guard let candidates = json?["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            return ""
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parseBoxes(from text: String) -> [BoundingBox] {
        // Extract JSON from response (may be wrapped in markdown code block)
        var jsonStr = text
        if let start = jsonStr.range(of: "["), let end = jsonStr.range(of: "]", options: .backwards) {
            jsonStr = String(jsonStr[start.lowerBound...end.upperBound])
        } else if let start = jsonStr.range(of: "{"), let end = jsonStr.range(of: "}", options: .backwards) {
            jsonStr = "[\(jsonStr[start.lowerBound...end.upperBound])]"
        }
        guard let data = jsonStr.data(using: .utf8),
              let boxes = try? JSONDecoder().decode([BoundingBox].self, from: data) else {
            return []
        }
        return boxes
    }

    enum GeminiError: LocalizedError {
        case noApiKey
        case encodingFailed
        case rateLimited
        case apiError(String)

        var errorDescription: String? {
            switch self {
            case .noApiKey: return "No Gemini API key configured."
            case .encodingFailed: return "Failed to encode image."
            case .rateLimited: return "Rate limited — please wait a moment and try again."
            case .apiError(let msg): return "Gemini API error: \(msg)"
            }
        }
    }
}
