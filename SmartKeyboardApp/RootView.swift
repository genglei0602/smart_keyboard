import SwiftUI
import UIKit

struct RootView: View {
    enum Tab: String, CaseIterable {
        case home = "首页"
        case preference = "偏好"
        case actions = "动作"
        case privacy = "隐私"

        var systemImage: String {
            switch self {
            case .home: "house"
            case .preference: "slider.horizontal.3"
            case .actions: "sparkles"
            case .privacy: "lock.shield"
            }
        }
    }

    @State private var selectedTab: Tab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label(Tab.home.rawValue, systemImage: Tab.home.systemImage) }
                .tag(Tab.home)

            PreferenceView()
                .tabItem { Label(Tab.preference.rawValue, systemImage: Tab.preference.systemImage) }
                .tag(Tab.preference)

            ActionsView()
                .tabItem { Label(Tab.actions.rawValue, systemImage: Tab.actions.systemImage) }
                .tag(Tab.actions)

            PrivacyView()
                .tabItem { Label(Tab.privacy.rawValue, systemImage: Tab.privacy.systemImage) }
                .tag(Tab.privacy)
        }
        .tint(Theme.green)
    }
}

enum Theme {
    static let green = Color(red: 0.086, green: 0.639, blue: 0.290)
    static let greenSoft = Color(red: 0.91, green: 0.97, blue: 0.93)
    static let text = Color(red: 0.067, green: 0.094, blue: 0.153)
    static let muted = Color(red: 0.420, green: 0.447, blue: 0.502)
    static let line = Color(red: 0.898, green: 0.906, blue: 0.922)
    static let bg = Color(red: 0.976, green: 0.980, blue: 0.984)
    static let keyboard = Color(red: 0.851, green: 0.867, blue: 0.890)
    static let warning = Color(red: 0.976, green: 0.451, blue: 0.086)
    static let danger = Color(red: 0.863, green: 0.149, blue: 0.149)
}

struct HomeView: View {
    @Environment(\.openURL) private var openURL
    @AppStorage(SharedSettings.Key.endpoint, store: SharedSettings.defaults) private var endpoint = ""
    @AppStorage(SharedSettings.Key.model, store: SharedSettings.defaults) private var model = "gpt-4o-mini"
    @AppStorage(SharedSettings.Key.apiKey, store: SharedSettings.defaults) private var apiKey = "sk-5f4ada82969d418f82c2d108c531129a"
    @State private var showSettingsAlert = false
    @State private var showSettingsGuide = false
    @State private var selectedScenario = "润色"
    @State private var demoMode: KeyboardPreviewMode = .normal
    @State private var showScenarioEditorAlert = false
    @State private var showTestSheet = false
    @State private var showAPISettings = false

    private var apiConfigured: Bool {
        !endpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HeaderBlock(title: "会说话键盘", subtitle: "微信里的中文表达助手。写得直，发得体。")

                        StatusCard(rows: [
                            .init(title: "API Key", value: apiConfigured ? "已配置" : "未配置", style: apiConfigured ? .ok : .warning),
                            .init(title: "键盘权限", value: "请到系统设置确认", style: .warning),
                            .init(title: "Full Access", value: "请到系统设置确认", style: .warning)
                        ])

                        VStack(spacing: 10) {
                        Button {
                            showAPISettings = true
                        } label: {
                            PrimaryButton(title: apiConfigured ? "更新 API 设置" : "配置 API", systemImage: "key")
                        }
                            .buttonStyle(.plain)

                        Button {
                            openSystemSettings()
                        } label: {
                            SecondaryButton(title: "去开启键盘", systemImage: "keyboard")
                        }
                            .buttonStyle(.plain)

                        Button {
                            showTestSheet = true
                        } label: {
                            SecondaryButton(title: "测试一句", systemImage: "text.bubble")
                        }
                            .buttonStyle(.plain)
                        }

                    SectionCard(title: "常用场景", trailing: nil) {
                        HStack {
                            Spacer()
                            Button("编辑") {
                                showScenarioEditorAlert = true
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.muted)
                            .buttonStyle(.plain)
                        }
                        SelectableChips(items: ["润色", "委婉", "拒绝", "催一下"], selection: $selectedScenario)
                    }

                        PrivacyNote(text: "AI 只在你点击润色、委婉等操作时处理文本，并发送到你配置的模型服务商。")

                        DemoKeyboardCard(mode: $demoMode)
                            .id("demo-keyboard")
                    }
                    .padding(20)
                }
            }
            .background(Theme.bg)
            .navigationTitle("首页")
            .alert("无法打开设置", isPresented: $showSettingsAlert) {
                Button("确定", role: .cancel) {}
            } message: {
                Text("请手动前往：设置 > 通用 > 键盘 > 键盘，添加“会说话键盘”并开启“允许完全访问”。")
            }
            .alert("键盘场景编辑", isPresented: $showScenarioEditorAlert) {
                Button("确定", role: .cancel) {}
            } message: {
                Text("MVP 阶段支持场景切换，完整编辑能力会在后续版本开放。")
            }
            .alert("开启键盘指引", isPresented: $showSettingsGuide) {
                Button("确定", role: .cancel) {}
            } message: {
                Text("请前往：设置 > 通用 > 键盘 > 键盘，添加“会说话键盘”并开启“允许完全访问”。")
            }
            .sheet(isPresented: $showTestSheet) {
                TestSentenceView()
            }
            .sheet(isPresented: $showAPISettings) {
                APISettingsView()
            }
        }
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            showSettingsAlert = true
            return
        }

        openURL(url) { accepted in
            if !accepted {
                showSettingsAlert = true
            } else {
                showSettingsGuide = true
            }
        }
    }
}

struct APISettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SharedSettings.Key.provider, store: SharedSettings.defaults) private var provider = "OpenAI Compatible"
    @AppStorage(SharedSettings.Key.endpoint, store: SharedSettings.defaults) private var endpoint = ""
    @AppStorage(SharedSettings.Key.model, store: SharedSettings.defaults) private var model = "gpt-4o-mini"
    @AppStorage(SharedSettings.Key.apiKey, store: SharedSettings.defaults) private var apiKey = "sk-5f4ada82969d418f82c2d108c531129a"
    @State private var testStatus = ""
    @State private var isTesting = false

    private let providers = ["OpenAI Compatible", "DeepSeek", "质朴"]

    var body: some View {
        NavigationStack {
            Form {
                Section("服务商") {
                    Picker("服务商", selection: $provider) {
                        ForEach(providers, id: \.self) { item in
                            Text(item).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)

                    Button("应用默认 Endpoint / Model") {
                        applyProviderPreset(provider)
                    }

                    TextField("https://api.openai.com/v1", text: $endpoint)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                    TextField("gpt-4o-mini", text: $model)
                        .textInputAutocapitalization(.never)
                    SecureField("API Key", text: $apiKey)
                        .textInputAutocapitalization(.never)
                }

                Section("验证") {
                    Button(isTesting ? "测试中..." : "测试连接") {
                        testConnection()
                    }
                    .disabled(isTesting)

                    if !testStatus.isEmpty {
                        Text(testStatus)
                            .font(.system(size: 13))
                            .foregroundStyle(testStatus.hasPrefix("成功") ? Theme.green : Theme.danger)
                    }
                }

                Section {
                    Button("保存并关闭") {
                        SharedSettings.synchronize()
                        dismiss()
                    }
                }
            }
            .navigationTitle("API 设置")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        SharedSettings.synchronize()
                        dismiss()
                    }
                }
            }
            .onAppear {
                if endpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    applyProviderPreset(provider)
                }
            }
            .onChange(of: provider) { _, value in
                applyProviderPreset(value)
            }
        }
    }

    private func applyProviderPreset(_ value: String) {
        switch value {
        case "DeepSeek":
            endpoint = "https://api.deepseek.com/v1"
            model = "deepseek-chat"
        case "质朴":
            endpoint = "https://open.bigmodel.cn/api/paas/v4"
            model = "glm-4-flash"
        default:
            endpoint = "https://api.openai.com/v1"
            model = "gpt-4o-mini"
        }
    }

    private func testConnection() {
        SharedSettings.synchronize()
        isTesting = true
        testStatus = ""

        Task {
            do {
                let candidates = try await LLMClient.generateCandidates(text: "你怎么还没发给我", action: "催一下")
                await MainActor.run {
                    testStatus = candidates.isEmpty ? "失败：模型没有返回候选" : "成功：已返回 \(candidates.count) 条候选"
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    testStatus = "失败：\(error.localizedDescription)"
                    isTesting = false
                }
            }
        }
    }
}

struct TestSentenceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var input = "你怎么还没发给我"
    @State private var relation = "同事"
    @State private var action = "催一下"
    @State private var outputs: [String] = []

    private let relations = ["朋友", "同事", "老板", "客户", "对象"]
    private let actions = ["润色", "委婉", "高情商", "简短", "催一下", "拒绝"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                TextField("输入一句想测试的话", text: $input, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3, reservesSpace: true)

                Picker("关系", selection: $relation) {
                    ForEach(relations, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.segmented)

                Picker("动作", selection: $action) {
                    ForEach(actions, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)

                Button {
                    outputs = LocalCandidateGenerator.generate(text: input, recipient: relation, action: action)
                } label: {
                    PrimaryButton(title: "生成 3 条候选", systemImage: "sparkles")
                }
                .buttonStyle(.plain)

                if outputs.isEmpty {
                    Text("点击“生成 3 条候选”开始测试")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(Array(outputs.enumerated()), id: \.offset) { idx, item in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("候选 \(idx + 1)")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(Theme.muted)
                                    Text(item)
                                        .font(.system(size: 15))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line))
                            }
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .background(Theme.bg)
            .navigationTitle("测试一句")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

}

struct PreferenceView: View {
    @AppStorage(SharedSettings.Key.defaultRecipient, store: SharedSettings.defaults) private var recipient = "同事"
    @AppStorage(SharedSettings.Key.rewriteLevel, store: SharedSettings.defaults) private var rewriteLevel = "明显优化"
    @AppStorage(SharedSettings.Key.keepVoice, store: SharedSettings.defaults) private var keepVoice = true
    @AppStorage(SharedSettings.Key.noGreasy, store: SharedSettings.defaults) private var noGreasy = true
    @AppStorage(SharedSettings.Key.noEmoji, store: SharedSettings.defaults) private var noEmoji = false
    @AppStorage(SharedSettings.Key.notFormal, store: SharedSettings.defaults) private var notFormal = false

    @State private var recipientStyles: [String: String] = [
        "朋友": SharedSettings.style(for: "朋友"),
        "同事": SharedSettings.style(for: "同事"),
        "老板": SharedSettings.style(for: "老板"),
        "客户": SharedSettings.style(for: "客户"),
        "对象": SharedSettings.style(for: "对象")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HeaderBlock(title: "偏好", subtitle: "设置每个聊天对象的默认语气风格。")

                    SectionCard(title: "默认发给谁") {
                        SelectableChips(items: ["朋友", "同事", "老板", "客户", "对象"], selection: $recipient)
                    }

                    SectionCard(title: "风格（按对象）") {
                        ForEach(["朋友", "同事", "老板", "客户", "对象"], id: \.self) { person in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(person)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Theme.muted)
                                SelectableChips(
                                    items: SharedSettings.allStyles,
                                    selection: Binding(
                                        get: { recipientStyles[person] ?? SharedSettings.defaultStylePerRecipient[person] ?? "自然温和" },
                                        set: { newValue in
                                            recipientStyles[person] = newValue
                                            SharedSettings.setStyle(newValue, for: person)
                                            SharedSettings.synchronize()
                                        }
                                    )
                                )
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    SectionCard(title: "改写程度") {
                        Picker("改写程度", selection: $rewriteLevel) {
                            Text("轻微润色").tag("轻微润色")
                            Text("明显优化").tag("明显优化")
                            Text("帮我重写").tag("帮我重写")
                        }
                        .pickerStyle(.segmented)
                    }

                    SectionCard(title: "输出习惯") {
                        Toggle("保留我的说话味道", isOn: $keepVoice)
                        Toggle("不要太油", isOn: $noGreasy)
                        Toggle("不要 emoji", isOn: $noEmoji)
                        Toggle("不要太正式", isOn: $notFormal)
                    }
                }
                .padding(20)
            }
            .background(Theme.bg)
            .navigationTitle("偏好")
        }
    }
}

struct ActionsView: View {
    private let pinned = ["润色", "委婉", "高情商", "简短"]
    private let more = ["催一下", "拒绝", "道歉", "感谢", "安慰", "夸人", "求帮忙", "提意见", "结束聊天"]
    @State private var selectedAction: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HeaderBlock(title: "动作", subtitle: "把高频微信场景放到键盘顶部，其余动作放在更多里。")

                    SectionCard(title: "固定在键盘顶部", trailing: "排序") {
                        ForEach(pinned, id: \.self) { item in
                            ActionRow(title: item, subtitle: pinnedSubtitle(for: item), pinned: true)
                        }
                    }

                    SectionCard(title: "更多动作") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                            ForEach(more, id: \.self) { item in
                                Button {
                                    selectedAction = item
                                } label: {
                                    Text(item)
                                        .font(.system(size: 15, weight: .semibold))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 42)
                                        .background(Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedAction == item ? Theme.green : Theme.line, lineWidth: selectedAction == item ? 1.5 : 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    WeChatKeyboardPreview(mode: .moreActions)
                }
                .padding(20)
            }
            .background(Theme.bg)
            .navigationTitle("动作")
            .alert("动作已选择", isPresented: Binding(get: { selectedAction != nil }, set: { if !$0 { selectedAction = nil } })) {
                Button("确定", role: .cancel) {
                    selectedAction = nil
                }
            } message: {
                Text("已选择「\(selectedAction ?? "")」。MVP 中该动作会在键盘中触发相应改写。")
            }
        }
    }

    private func pinnedSubtitle(for item: String) -> String {
        switch item {
        case "润色": "保持原意，表达更自然"
        case "委婉": "降低攻击性，更柔和"
        case "高情商": "更体面，但不要油腻"
        default: "压缩文字，保留重点"
        }
    }
}

struct PrivacyView: View {
    @State private var showClearCacheAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HeaderBlock(title: "隐私", subtitle: "清楚说明 AI 什么时候工作、文本发到哪里、Key 存在哪里。")

                    SectionCard(title: "AI 什么时候工作？") {
                        BodyText("只有当你点击润色、委婉、高情商等操作时，才会处理当前文本。基础输入不会触发 AI。")
                    }

                    SectionCard(title: "文本发到哪里？") {
                        BodyText("发送到你配置的模型服务商。MVP 默认不经过产品自有服务器。")
                    }

                    SectionCard(title: "API Key 存在哪里？") {
                        BodyText("当前版本保存在 App 与键盘扩展共享的本机设置中，用于让键盘扩展直接调用你配置的 OpenAI-compatible 服务。")
                    }

                    Button {
                        showClearCacheAlert = true
                    } label: {
                        SecondaryButton(title: "清除本地缓存", systemImage: "trash")
                            .foregroundStyle(Theme.danger)
                    }
                    .buttonStyle(.plain)

                    WeChatKeyboardPreview(mode: .sensitive)
                }
                .padding(20)
            }
            .background(Theme.bg)
            .navigationTitle("隐私")
            .alert("暂无缓存可清除", isPresented: $showClearCacheAlert) {
                Button("确定", role: .cancel) {}
            } message: {
                Text("当前版本没有实现本地缓存或 API Key 保存，所以这个按钮不会删除任何真实数据。")
            }
        }
    }
}

struct DemoKeyboardCard: View {
    @Binding var mode: KeyboardPreviewMode

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("微信内效果")
                    .font(.headline)
                Spacer()
                Picker("模式", selection: $mode) {
                    Text("默认").tag(KeyboardPreviewMode.normal)
                    Text("候选").tag(KeyboardPreviewMode.candidates)
                    Text("关系").tag(KeyboardPreviewMode.recipient)
                    Text("更多动作").tag(KeyboardPreviewMode.moreActions)
                    Text("敏感提醒").tag(KeyboardPreviewMode.sensitive)
                }
                .pickerStyle(.menu)
            }

            WeChatKeyboardPreview(mode: mode)
        }
    }
}

enum KeyboardPreviewMode {
    case normal
    case candidates
    case moreActions
    case recipient
    case sensitive
}

struct WeChatKeyboardPreview: View {
    let mode: KeyboardPreviewMode

    var body: some View {
        VStack(spacing: 0) {
            WeChatNav(title: mode == .moreActions ? "朋友" : "项目沟通")

            VStack(alignment: .leading, spacing: 12) {
                ChatBubble(text: mode == .moreActions ? "晚上一起吃饭？" : "这个资料今天方便发我吗？", incoming: true)
                if mode != .moreActions {
                    ChatBubble(text: "我看下，稍等", incoming: false)
                    ChatBubble(text: "好，我这边后面可能要用到", incoming: true)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(height: 190)
            .background(Color(red: 0.929, green: 0.929, blue: 0.929))

            HStack(spacing: 8) {
                Image(systemName: "plus.circle")
                Text(mode == .moreActions ? "我不想去" : mode == .sensitive ? "验证码是 482913" : "你怎么还没发给我")
                    .font(.system(size: 15))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .frame(height: 36)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                Image(systemName: "face.smiling")
            }
            .padding(8)
            .background(Color(red: 0.969, green: 0.969, blue: 0.969))

            KeyboardSurface(mode: mode)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Theme.line))
    }
}

struct KeyboardSurface: View {
    let mode: KeyboardPreviewMode

    var body: some View {
        VStack(spacing: 0) {
            switch mode {
            case .candidates:
                CandidatePanel()
            case .moreActions:
                MoreActionsPanel()
            case .recipient:
                RecipientPanel()
            case .sensitive:
                SensitivePanel()
                Toolbar(accessWarning: true)
            case .normal:
                Toolbar(accessWarning: false)
            }

            KeyRows()
        }
        .background(Theme.keyboard)
    }
}

struct Toolbar: View {
    let accessWarning: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(accessWarning ? "Full Access 未开启" : "发给：同事 ▾")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(accessWarning ? Theme.danger : Theme.green)
                .padding(.horizontal, 10)
                .frame(height: 28)
                .background(accessWarning ? Color.red.opacity(0.10) : Theme.greenSoft)
                .clipShape(Capsule())

            HStack(spacing: 6) {
                ForEach(["润色", "委婉", "高情商", "简短", "更多"], id: \.self) { title in
                    Text(title)
                        .font(.system(size: 13, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(title == "润色" && !accessWarning ? Theme.green : Color.white)
                        .foregroundStyle(title == "润色" && !accessWarning ? Color.white : Theme.text)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(title == "润色" && !accessWarning ? Theme.green : Theme.line))
                }
            }
        }
        .padding(8)
        .background(Theme.bg)
    }
}

struct CandidatePanel: View {
    private let candidates = [
        "我想问下这个方便什么时候发我呀？我这边好提前安排一下。",
        "辛苦啦，我这边可能快要用到了，方便的话麻烦你晚点发我一下。",
        "这个今天方便发我吗？我这边后面需要用到。"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("选择一个发出去")
                Spacer()
                Text("同事 · 催一下")
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Theme.muted)

            ForEach(Array(candidates.enumerated()), id: \.offset) { index, text in
                Text(text)
                    .font(.system(size: 14))
                    .lineSpacing(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(alignment: .leading) {
                        if index == 0 {
                            Rectangle()
                                .fill(Theme.green)
                                .frame(width: 3)
                                .clipShape(RoundedRectangle(cornerRadius: 2))
                        }
                    }
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(index == 0 ? Theme.green.opacity(0.4) : Theme.line))
            }

            HStack {
                Text("重新生成")
                Spacer()
                Text("复制")
            }
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Theme.green)
        }
        .padding(10)
        .background(Theme.bg)
    }
}

struct MoreActionsPanel: View {
    private let actions = ["催一下", "拒绝", "道歉", "感谢", "安慰", "夸人", "求帮忙", "提意见", "结束聊天"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("更多")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.muted)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 7), count: 3), spacing: 7) {
                ForEach(actions, id: \.self) { action in
                    Text(action)
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 11))
                        .overlay(RoundedRectangle(cornerRadius: 11).stroke(Theme.line))
                }
            }
        }
        .padding(10)
        .background(Theme.bg)
    }
}

struct RecipientPanel: View {
    private let recipients = [
        ("朋友", "自然一点"),
        ("同事", "当前"),
        ("老板", "更稳妥"),
        ("客户", "更专业"),
        ("对象", "更柔和")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("这句话发给谁？")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.muted)

            VStack(spacing: 0) {
                ForEach(recipients, id: \.0) { item in
                    HStack {
                        Text(item.0)
                            .font(.system(size: 15, weight: .semibold))
                        Spacer()
                        Text(item.1)
                            .font(.system(size: 13))
                            .foregroundStyle(item.1 == "当前" ? Theme.green : Theme.muted)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 44)
                    .background(Color.white)
                    .overlay(alignment: .bottom) {
                        if item.0 != recipients.last?.0 {
                            Rectangle().fill(Theme.line).frame(height: 1)
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line))
        }
        .padding(10)
        .background(Theme.bg)
    }
}

struct SensitivePanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("可能包含敏感信息")
                    .foregroundStyle(Color(red: 0.604, green: 0.204, blue: 0.071))
                Spacer()
                Text("客户 · 润色")
                    .foregroundStyle(Theme.muted)
            }
            .font(.system(size: 13, weight: .semibold))

            Text("点击继续后，这段内容会发送到你配置的模型服务商。")
                .font(.system(size: 14))
                .foregroundStyle(Color(red: 0.604, green: 0.204, blue: 0.071))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color(red: 1.0, green: 0.969, blue: 0.929))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 0.996, green: 0.843, blue: 0.667)))

            HStack {
                Text("取消").foregroundStyle(Theme.muted)
                Spacer()
                Text("继续").foregroundStyle(Theme.green)
            }
            .font(.system(size: 13, weight: .bold))
        }
        .padding(10)
        .background(Theme.bg)
    }
}

struct KeyRows: View {
    private let rows = [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ["⇧", "z", "x", "c", "v", "b", "n", "m", "⌫"]
    ]

    var body: some View {
        VStack(spacing: 7) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 5) {
                    ForEach(row, id: \.self) { key in
                        Text(key)
                            .font(.system(size: key.count == 1 ? 18 : 15, weight: .medium))
                            .frame(maxWidth: key == "⇧" || key == "⌫" ? 48 : 35)
                            .frame(height: 41)
                            .background(key == "⇧" || key == "⌫" ? Color(red: 0.820, green: 0.835, blue: 0.859) : Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                            .shadow(color: Color.black.opacity(0.20), radius: 0, x: 0, y: 1)
                    }
                }
            }

            HStack(spacing: 5) {
                KeyboardKey("🌐", width: 48)
                KeyboardKey("123", width: 48)
                KeyboardKey("空格", width: 150)
                KeyboardKey("回车", width: 70)
            }
        }
        .padding(8)
    }
}

struct KeyboardKey: View {
    let title: String
    let width: CGFloat

    init(_ title: String, width: CGFloat) {
        self.title = title
        self.width = width
    }

    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: .medium))
            .frame(width: width, height: 41)
            .background(Color(red: 0.820, green: 0.835, blue: 0.859))
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .shadow(color: Color.black.opacity(0.20), radius: 0, x: 0, y: 1)
    }
}

struct WeChatNav: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 17, weight: .bold))
            Spacer()
            Image(systemName: "ellipsis")
                .font(.system(size: 18, weight: .bold))
        }
        .padding(.top, 18)
        .padding(.horizontal, 16)
        .frame(height: 66)
        .background(Color(red: 0.929, green: 0.929, blue: 0.929))
    }
}

struct ChatBubble: View {
    let text: String
    let incoming: Bool

    var body: some View {
        Text(text)
            .font(.system(size: 15))
            .lineSpacing(2)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(incoming ? Color.white : Color(red: 0.584, green: 0.925, blue: 0.412))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .frame(maxWidth: .infinity, alignment: incoming ? .leading : .trailing)
    }
}

struct HeaderBlock: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 31, weight: .bold))
            Text(subtitle)
                .font(.system(size: 15))
                .foregroundStyle(Theme.muted)
                .lineSpacing(3)
        }
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    let trailing: String?
    @ViewBuilder let content: Content

    init(title: String, trailing: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.trailing = trailing
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                if let trailing {
                    Text(trailing)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.muted)
                }
            }
            content
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.line))
    }
}

struct StatusCard: View {
    struct Row {
        let title: String
        let value: String
        let style: Style
    }

    enum Style {
        case ok
        case warning
    }

    let rows: [Row]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                HStack {
                    Text(row.title)
                        .font(.system(size: 15, weight: .semibold))
                    Spacer()
                    Text(row.value)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(row.style == .ok ? Theme.green : Theme.warning)
                }
                .frame(height: 54)
                .padding(.horizontal, 14)
                .overlay(alignment: .bottom) {
                    if index < rows.count - 1 {
                        Rectangle().fill(Theme.line).frame(height: 1)
                    }
                }
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.line))
    }
}

struct PrimaryButton: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 16, weight: .bold))
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Theme.green)
            .foregroundStyle(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct SecondaryButton: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 16, weight: .bold))
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.white)
            .foregroundStyle(Theme.text)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line))
    }
}

struct ChipWrap: View {
    let items: [String]
    let selected: String

    var body: some View {
        FlowLayout(spacing: 9) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.system(size: 14, weight: item == selected ? .bold : .regular))
                    .padding(.horizontal, 13)
                    .frame(height: 34)
                    .background(item == selected ? Theme.greenSoft : Color.white)
                    .foregroundStyle(item == selected ? Theme.green : Theme.text)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(item == selected ? Theme.green.opacity(0.35) : Theme.line))
            }
        }
    }
}

struct SelectableChips: View {
    let items: [String]
    @Binding var selection: String

    var body: some View {
        FlowLayout(spacing: 9) {
            ForEach(items, id: \.self) { item in
                Button {
                    selection = item
                } label: {
                    Text(item)
                        .font(.system(size: 14, weight: item == selection ? .bold : .regular))
                        .padding(.horizontal, 13)
                        .frame(height: 34)
                        .background(item == selection ? Theme.greenSoft : Color.white)
                        .foregroundStyle(item == selection ? Theme.green : Theme.text)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(item == selection ? Theme.green.opacity(0.35) : Theme.line))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct ActionRow: View {
    let title: String
    let subtitle: String
    let pinned: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: pinned ? "pin.fill" : "sparkles")
                .foregroundStyle(Theme.green)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.muted)
            }
            Spacer()
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(Theme.muted)
        }
        .padding(.vertical, 4)
    }
}

struct BodyText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 15))
            .foregroundStyle(Theme.muted)
            .lineSpacing(3)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PrivacyNote: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(Color(red: 0.604, green: 0.204, blue: 0.071))
            .lineSpacing(3)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 1.0, green: 0.969, blue: 0.929))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(red: 0.996, green: 0.843, blue: 0.667)))
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX > 0 && currentX + size.width > maxWidth {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }

        return CGSize(width: maxWidth, height: currentY + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX > bounds.minX && currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize(size))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
