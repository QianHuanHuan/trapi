import Foundation

struct ChatLine: Identifiable {
    let id = UUID()
    let role: String
    var content: String
}

enum ChatServiceError: LocalizedError {
    case invalidURL
    case missingAPIKey
    case server(String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "接口地址无效，请检查服务商设置。"
        case .missingAPIKey: return "请先在服务商设置中填写 API Key。"
        case .server(let message): return message
        case .emptyResponse: return "模型返回了空内容。"
        }
    }
}

enum ChatService {
    static func reply(profile: ProviderProfile, apiKey: String, history: [ChatLine]) async throws -> String {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ChatServiceError.missingAPIKey
        }
        let base = profile.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard var components = URLComponents(string: base), components.scheme != nil, components.host != nil else {
            throw ChatServiceError.invalidURL
        }
        if !components.path.hasSuffix("/chat/completions") {
            components.path = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/chat/completions"
        }
        guard let url = components.url else { throw ChatServiceError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 90
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": profile.model,
            "messages": history.map { ["role": $0.role, "content": $0.content] }
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ChatServiceError.server("无法读取服务器响应。") }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw ChatServiceError.server("请求失败（HTTP \(http.statusCode)）：\(String(body.prefix(400)))")
        }
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = root["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String,
              !content.isEmpty else { throw ChatServiceError.emptyResponse }
        return content
    }
}
