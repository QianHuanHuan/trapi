import Foundation
import Combine
import Security

struct ProviderProfile: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var baseURL: String
    var model: String
}

@MainActor
final class AppSettings: ObservableObject {
    @Published private(set) var profiles: [ProviderProfile] = []
    @Published var selectedProfileID: UUID? { didSet { persist() } }

    private let profilesKey = "providerProfiles"
    private let selectionKey = "selectedProviderProfile"

    init() {
        if let data = UserDefaults.standard.data(forKey: profilesKey),
           let saved = try? JSONDecoder().decode([ProviderProfile].self, from: data) {
            profiles = saved
        }
        if profiles.isEmpty {
            profiles = [ProviderProfile(name: "DeepSeek", baseURL: "https://api.deepseek.com/v1", model: "deepseek-chat")]
        }
        if let value = UserDefaults.standard.string(forKey: selectionKey),
           let id = UUID(uuidString: value), profiles.contains(where: { $0.id == id }) {
            selectedProfileID = id
        } else {
            selectedProfileID = profiles.first?.id
        }
        persist()
    }

    var selectedProfile: ProviderProfile? {
        profiles.first(where: { $0.id == selectedProfileID }) ?? profiles.first
    }

    func apiKey(for profile: ProviderProfile) -> String {
        Keychain.read(account: profile.id.uuidString) ?? ""
    }

    func save(_ profile: ProviderProfile, apiKey: String) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
        } else {
            profiles.append(profile)
        }
        if !apiKey.isEmpty { Keychain.save(apiKey, account: profile.id.uuidString) }
        if selectedProfileID == nil { selectedProfileID = profile.id }
        persist()
    }

    func select(_ profile: ProviderProfile) { selectedProfileID = profile.id }

    func delete(_ profile: ProviderProfile) {
        profiles.removeAll { $0.id == profile.id }
        Keychain.delete(account: profile.id.uuidString)
        if selectedProfileID == profile.id { selectedProfileID = profiles.first?.id }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(profiles) { UserDefaults.standard.set(data, forKey: profilesKey) }
        UserDefaults.standard.set(selectedProfileID?.uuidString, forKey: selectionKey)
    }
}

private enum Keychain {
    static func read(account: String) -> String? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: "PocketAgent.APIKey",
                                    kSecAttrAccount as String: account,
                                    kSecReturnData as String: true,
                                    kSecMatchLimit as String: kSecMatchLimitOne]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func save(_ value: String, account: String) {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: "PocketAgent.APIKey",
                                    kSecAttrAccount as String: account]
        let data = Data(value.utf8)
        if SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess {
            SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        } else {
            var item = query
            item[kSecValueData as String] = data
            SecItemAdd(item as CFDictionary, nil)
        }
    }

    static func delete(account: String) {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: "PocketAgent.APIKey",
                                    kSecAttrAccount as String: account]
        SecItemDelete(query as CFDictionary)
    }
}
