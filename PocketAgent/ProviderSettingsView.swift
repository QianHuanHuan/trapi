import SwiftUI

struct ProviderSettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var editing: ProviderProfile?
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            List {
                Section("服务商配置") {
                    ForEach(settings.profiles) { profile in
                        HStack(spacing: 12) {
                            Button { settings.select(profile) } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: settings.selectedProfileID == profile.id ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(settings.selectedProfileID == profile.id ? Color.indigo : Color.secondary)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(profile.name).foregroundStyle(.primary)
                                        Text(profile.model).font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            Spacer()
                            Button { editing = profile } label: { Image(systemName: "pencil").foregroundStyle(.secondary) }
                                .buttonStyle(.plain).accessibilityLabel("编辑\(profile.name)")
                        }
                        .padding(.vertical, 3)
                    }.onDelete { offsets in offsets.map { settings.profiles[$0] }.forEach(settings.delete) }
                    Button { isCreating = true } label: { Label("添加服务商", systemImage: "plus.circle.fill") }
                }
                Section {
                    Label("支持 OpenAI Chat Completions 兼容接口", systemImage: "link")
                    Text("普通 iOS 应用只能在自身界面显示对话。跨应用悬浮与读取其他 App 屏幕需要单独评估系统权限和 TrollStore 插件方案。")
                        .font(.footnote).foregroundStyle(.secondary)
                } header: { Text("关于初版") }
            }
            .navigationTitle("模型与服务商")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("完成") { dismiss() } } }
            .sheet(item: $editing) { profile in ProviderEditorView(profile: profile).environmentObject(settings) }
            .sheet(isPresented: $isCreating) { ProviderEditorView(profile: nil).environmentObject(settings) }
        }
    }
}

private struct ProviderEditorView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    let profile: ProviderProfile?
    @State private var name = ""
    @State private var baseURL = "https://api.openai.com/v1"
    @State private var model = "gpt-4o-mini"
    @State private var apiKey = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("连接信息") {
                    TextField("服务商名称", text: $name)
                    TextField("API Base URL", text: $baseURL).textInputAutocapitalization(.never).keyboardType(.URL).autocorrectionDisabled()
                    TextField("模型名称", text: $model).textInputAutocapitalization(.never).autocorrectionDisabled()
                    SecureField(profile == nil ? "API Key" : "API Key（留空保持原值）", text: $apiKey)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                }
                Section { Text("示例：DeepSeek 可填 https://api.deepseek.com/v1 和 deepseek-chat。Key 仅保存在本机钥匙串。")
                    .font(.footnote).foregroundStyle(.secondary) }
            }
            .navigationTitle(profile == nil ? "添加服务商" : "编辑服务商")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || model.isEmpty || baseURL.isEmpty)
                }
            }
            .onAppear {
                if let profile {
                    name = profile.name; baseURL = profile.baseURL; model = profile.model
                    apiKey = settings.apiKey(for: profile)
                }
            }
        }
    }

    private func save() {
        let value = ProviderProfile(id: profile?.id ?? UUID(), name: name.trimmingCharacters(in: .whitespacesAndNewlines), baseURL: baseURL, model: model)
        settings.save(value, apiKey: apiKey)
        dismiss()
    }
}
