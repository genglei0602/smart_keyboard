import Foundation

enum LLMClient {
    struct Settings {
        let endpoint: String
        let model: String
        let apiKey: String
        let recipient: String
        let style: String
        let rewriteLevel: String
        let keepVoice: Bool
        let noGreasy: Bool
        let noEmoji: Bool
        let notFormal: Bool

        static var current: Settings {
            Settings(
                endpoint: SharedSettings.endpoint,
                model: SharedSettings.model,
                apiKey: SharedSettings.apiKey,
                recipient: SharedSettings.defaultRecipient,
                style: SharedSettings.style(for: SharedSettings.defaultRecipient),
                rewriteLevel: SharedSettings.rewriteLevel,
                keepVoice: SharedSettings.keepVoice,
                noGreasy: SharedSettings.noGreasy,
                noEmoji: SharedSettings.noEmoji,
                notFormal: SharedSettings.notFormal
            )
        }
    }

    enum ClientError: LocalizedError {
        case missingConfiguration
        case invalidEndpoint
        case emptyResponse
        case badStatus(Int, String)

        var errorDescription: String? {
            switch self {
            case .missingConfiguration: "请先配置 Endpoint、Model 和 API Key。"
            case .invalidEndpoint: "Endpoint 地址无效。"
            case .emptyResponse: "模型没有返回候选。"
            case let .badStatus(code, message): "请求失败（\(code)）：\(message)"
            }
        }
    }

    static func generateCandidates(text: String, action: String, settings: Settings = .current) async throws -> [String] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !settings.endpoint.isEmpty, !settings.model.isEmpty, !settings.apiKey.isEmpty else {
            throw ClientError.missingConfiguration
        }
        guard !trimmed.isEmpty else { return [] }
        guard let url = chatCompletionsURL(from: settings.endpoint) else {
            throw ClientError.invalidEndpoint
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(settings.apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 20
        request.httpBody = try JSONEncoder().encode(requestBody(text: trimmed, action: action, settings: settings))

        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, !(200..<300).contains(httpResponse.statusCode) {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw ClientError.badStatus(httpResponse.statusCode, body)
        }

        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        let content = decoded.choices.first?.message.content ?? ""
        let candidates = parseCandidates(from: content)
        guard !candidates.isEmpty else { throw ClientError.emptyResponse }
        return Array(candidates.prefix(3))
    }

    private static func chatCompletionsURL(from endpoint: String) -> URL? {
        let trimmed = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.hasSuffix("/chat/completions") {
            return URL(string: trimmed)
        }
        return URL(string: trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/chat/completions")
    }

    private static func requestBody(text: String, action: String, settings: Settings) -> ChatRequest {
        let constraints = [
            settings.keepVoice ? "保留用户原本说话味道" : nil,
            settings.noGreasy ? "不要油腻" : nil,
            settings.noEmoji ? "不要 emoji" : nil,
            settings.notFormal ? "不要太正式" : nil
        ].compactMap { $0 }.joined(separator: "；")

        let userPrompt = """
        原话：\(text)
        发给：\(recipientHint(for: settings.recipient))
        动作：\(actionHint(for: action))
        说话风格：\(toneHint(for: settings.style))
        改写程度：\(rewriteHint(for: settings.rewriteLevel))
        额外要求：\(constraints.isEmpty ? "无" : constraints)

        请输出 3 条适合中文微信聊天的候选。每条都要保留原意，但表达角度略有差异。
        只输出候选文本，每条一行，不要编号，不要解释，不要加引号。
        """

        return ChatRequest(
            model: settings.model,
            messages: [
                .init(role: "system", content: "你是中文微信短消息润色助手。输出要自然、短、像真人聊天，避免 AI 腔、长段落、过度客套和营销感。"),
                .init(role: "user", content: userPrompt)
            ],
            temperature: 0.7
        )
    }

    private static func toneHint(for tone: String) -> String {
        switch tone {
        case "高情商":
            "高情商表达，照顾对方感受，给对方台阶，体面但不油腻"
        case "自然温和":
            "自然口语，温和友善，像真实微信消息，不刻板不冷漠"
        case "幽默风趣":
            "轻松幽默，有一点巧思或反差感，但不过火、不冒犯、不阴阳怪气"
        case "油腻大叔":
            "油腻大叔风格，过度热情、土味夸张、带一点自来熟和尴尬幽默，但不要低俗或骚扰"
        case "精神小妹":
            "精神小妹风格，活泼随性、带点嗲感和年轻用语，语速快感、有活力，但不过分"
        case "专业正式":
            "专业克制的商务表达，讲逻辑、有结构、不啰嗦"
        case "礼貌克制":
            "礼貌有分寸，克制表达，给对方足够空间，不施加压力"
        default:
            "自然口语，像真实微信消息，少一点 AI 味"
        }
    }

    private static func actionHint(for action: String) -> String {
        switch action {
        case "委婉":
            "把表达变柔和，降低压迫感和攻击性，但意思不要变弱"
        case "高情商":
            "照顾对方感受，给对方台阶，表达体面但不要油腻"
        case "简短":
            "压缩成更短的微信消息，只保留最核心意思"
        case "催一下":
            "礼貌提醒进度，明确但不显得逼迫"
        case "拒绝":
            "明确拒绝，同时尽量不伤关系，不编造复杂理由"
        case "道歉":
            "真诚承认问题，降低辩解感，表达愿意补救"
        case "感谢":
            "真诚表达感谢，具体但不过度夸张"
        case "安慰":
            "共情对方情绪，给支持感，不讲大道理"
        case "夸人":
            "自然夸奖对方，具体可信，不尬吹"
        case "求帮忙":
            "清楚说明请求，降低负担感，给对方拒绝空间"
        case "提意见":
            "温和提出建议，先肯定再补充，避免指责"
        case "结束聊天":
            "自然收尾，礼貌结束，不显得敷衍"
        default:
            "保持原意，优化成更自然得体的微信表达"
        }
    }

    private static func rewriteHint(for level: String) -> String {
        switch level {
        case "轻微润色":
            "只做轻微调整，尽量保留原句结构和用户口吻"
        case "帮我重写":
            "可以重组表达，但必须保留原意和聊天场景"
        default:
            "明显优化表达，让语气更符合关系和场景"
        }
    }

    private static func recipientHint(for recipient: String) -> String {
        switch recipient {
        case "朋友":
            "朋友：自然随意，有亲近感，不用太正式"
        case "老板":
            "老板：尊重、清楚、稳妥，避免过度随便"
        case "客户":
            "客户：专业、礼貌、有耐心，避免压迫感"
        case "对象":
            "对象：亲近柔和，照顾情绪，不冷冰冰"
        default:
            "同事：礼貌协作，清楚直接，保持工作分寸"
        }
    }

    private static func parseCandidates(from content: String) -> [String] {
        content
            .components(separatedBy: .newlines)
            .map { line in
                line.trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: #"^[-*\d.、\)\s]+"#, with: "", options: .regularExpression)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\"'“”‘’ "))
            }
            .filter { !$0.isEmpty }
    }
}

private struct ChatRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
}

private struct ChatMessage: Codable {
    let role: String
    let content: String
}

private struct ChatResponse: Decodable {
    struct Choice: Decodable {
        let message: ChatMessage
    }

    let choices: [Choice]
}
