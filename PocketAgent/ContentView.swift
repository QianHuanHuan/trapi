import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var messages: [ChatLine] = []
    @State private var draft = ""
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var showingSettings = false
    @FocusState private var composerFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            if messages.isEmpty { welcome }
            else { conversation }
            if let errorMessage {
                Text(errorMessage).font(.footnote).foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20).padding(.bottom, 8)
            }
            composer
        }
        .background(Color(red: 0.96, green: 0.97, blue: 0.98).ignoresSafeArea())
        .sheet(isPresented: $showingSettings) { ProviderSettingsView().environmentObject(settings) }
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(Color.indigo.gradient).frame(width: 42, height: 42)
                Image(systemName: "sparkles").font(.system(size: 19, weight: .semibold)).foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Pocket Agent").font(.headline)
                Text(settings.selectedProfile?.name ?? "未配置服务商").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button { showingSettings = true } label: {
                Image(systemName: "slider.horizontal.3").font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.primary).frame(width: 42, height: 42)
                    .background(.white, in: RoundedRectangle(cornerRadius: 14))
            }.accessibilityLabel("服务商设置")
        }
        .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 14)
        .background(.white)
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer()
            Text("你好，今天想做什么？")
                .font(.system(size: 30, weight: .bold, design: .rounded)).tracking(-0.6)
            Text("连接你喜欢的模型服务，开始一段对话。")
                .font(.body).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 10) {
                suggestion("帮我整理一个想法", icon: "lightbulb")
                suggestion("解释一段代码", icon: "chevron.left.forwardslash.chevron.right")
                suggestion("用几句话总结这件事", icon: "text.alignleft")
            }.padding(.top, 10)
            Spacer()
        }
        .padding(.horizontal, 24).frame(maxWidth: .infinity, alignment: .leading)
    }

    private func suggestion(_ title: String, icon: String) -> some View {
        Button { draft = title; composerFocused = true } label: {
            Label(title, systemImage: icon).font(.subheadline).foregroundStyle(.primary)
                .padding(.horizontal, 14).padding(.vertical, 12).frame(maxWidth: .infinity, alignment: .leading)
                .background(.white, in: RoundedRectangle(cornerRadius: 15))
        }
    }

    private var conversation: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(messages) { message in
                        HStack {
                            if message.role == "user" { Spacer(minLength: 45) }
                            Text(message.content).font(.body).textSelection(.enabled)
                                .padding(.horizontal, 15).padding(.vertical, 12)
                                .background(message.role == "user" ? Color.indigo : .white,
                                            in: RoundedRectangle(cornerRadius: 18))
                                .foregroundStyle(message.role == "user" ? Color.white : Color.primary)
                            if message.role != "user" { Spacer(minLength: 35) }
                        }.id(message.id)
                    }
                    if isSending {
                        HStack { ProgressView().tint(.indigo); Text("正在思考…").font(.footnote).foregroundStyle(.secondary); Spacer() }
                            .padding(.horizontal, 8)
                    }
                }.padding(18)
            }
            .onChange(of: messages.count) { _ in
                if let last = messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
            }
        }
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("给 Pocket Agent 发消息…", text: $draft, axis: .vertical)
                .lineLimit(1...5).focused($composerFocused).padding(.horizontal, 14).padding(.vertical, 12)
                .background(Color(red: 0.96, green: 0.97, blue: 0.98), in: RoundedRectangle(cornerRadius: 18))
            Button(action: send) {
                Image(systemName: isSending ? "hourglass" : "arrow.up")
                    .font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                    .frame(width: 44, height: 44).background(Color.indigo, in: Circle())
            }.disabled(isSending || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(isSending || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
        }
        .padding(.horizontal, 14).padding(.vertical, 12).background(.white)
    }

    private func send() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSending else { return }
        guard let profile = settings.selectedProfile else { showingSettings = true; return }
        draft = ""; errorMessage = nil
        messages.append(ChatLine(role: "user", content: text))
        isSending = true
        Task {
            do {
                let answer = try await ChatService.reply(profile: profile, apiKey: settings.apiKey(for: profile), history: messages)
                messages.append(ChatLine(role: "assistant", content: answer))
            } catch {
                errorMessage = error.localizedDescription
                if messages.last?.role == "user" { messages.removeLast() }
                draft = text
            }
            isSending = false
        }
    }
}
