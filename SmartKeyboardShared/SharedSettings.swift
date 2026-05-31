import Foundation

enum SharedSettings {
    static let appGroupID = "group.com.leogeng.smartkeyboard"

    enum Key {
        static let provider = "api.provider"
        static let endpoint = "api.endpoint"
        static let model = "api.model"
        static let apiKey = "api.key"
        static let defaultRecipient = "preference.defaultRecipient"
        static let tone = "preference.tone"
        static let rewriteLevel = "preference.rewriteLevel"
        static let keepVoice = "preference.keepVoice"
        static let noGreasy = "preference.noGreasy"
        static let noEmoji = "preference.noEmoji"
        static let notFormal = "preference.notFormal"
        static let recipientStyle = "preference.recipientStyle"
    }

    static let allStyles = ["高情商", "自然温和", "幽默风趣", "油腻大叔", "精神小妹", "专业正式", "礼貌克制"]

    static let defaultStylePerRecipient: [String: String] = [
        "朋友": "自然温和",
        "同事": "高情商",
        "老板": "专业正式",
        "客户": "礼貌克制",
        "对象": "自然温和"
    ]

    static func style(for recipient: String) -> String {
        let dict = recipientStyleDict
        return dict[recipient] ?? defaultStylePerRecipient[recipient] ?? "自然温和"
    }

    static func setStyle(_ style: String, for recipient: String) {
        var dict = recipientStyleDict
        dict[recipient] = style
        if let data = try? JSONEncoder().encode(dict) {
            defaults.set(data, forKey: Key.recipientStyle)
        }
    }

    private static var recipientStyleDict: [String: String] {
        guard let data = defaults.data(forKey: Key.recipientStyle),
              let dict = try? JSONDecoder().decode([String: String].self, from: data) else {
            return [:]
        }
        return dict
    }

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static var provider: String {
        get { defaults.string(forKey: Key.provider) ?? "OpenAI Compatible" }
        set { defaults.set(newValue, forKey: Key.provider) }
    }

    static var endpoint: String {
        get { defaults.string(forKey: Key.endpoint) ?? "" }
        set { defaults.set(newValue, forKey: Key.endpoint) }
    }

    static var model: String {
        get { defaults.string(forKey: Key.model) ?? "gpt-4o-mini" }
        set { defaults.set(newValue, forKey: Key.model) }
    }

    static var apiKey: String {
        get { defaults.string(forKey: Key.apiKey) ?? "sk-5f4ada82969d418f82c2d108c531129a" }
        set { defaults.set(newValue, forKey: Key.apiKey) }
    }

    static var defaultRecipient: String {
        get { defaults.string(forKey: Key.defaultRecipient) ?? "同事" }
        set { defaults.set(newValue, forKey: Key.defaultRecipient) }
    }

    static var tone: String {
        get { defaults.string(forKey: Key.tone) ?? "自然" }
        set { defaults.set(newValue, forKey: Key.tone) }
    }

    static var rewriteLevel: String {
        get { defaults.string(forKey: Key.rewriteLevel) ?? "明显优化" }
        set { defaults.set(newValue, forKey: Key.rewriteLevel) }
    }

    static var keepVoice: Bool {
        get { defaults.object(forKey: Key.keepVoice) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.keepVoice) }
    }

    static var noGreasy: Bool {
        get { defaults.object(forKey: Key.noGreasy) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.noGreasy) }
    }

    static var noEmoji: Bool {
        get { defaults.bool(forKey: Key.noEmoji) }
        set { defaults.set(newValue, forKey: Key.noEmoji) }
    }

    static var notFormal: Bool {
        get { defaults.bool(forKey: Key.notFormal) }
        set { defaults.set(newValue, forKey: Key.notFormal) }
    }

    static var isAPIConfigured: Bool {
        !endpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func synchronize() {
        defaults.synchronize()
    }
}
