import WakeBeeCore
import Foundation
import Security

@MainActor
struct LicenseKeychain: LicenseStorage {
    let service: String

    init(service: String = "app.wakebee.WakeBee.license") { self.service = service }

    private var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: "polar-license-v1",
         kSecAttrSynchronizable as String: false]
    }

    func load() throws -> LicenseRecord? {
        var query = query
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw LicenseError.keychain(operation: "read", status: status) }
        guard let data = result as? Data else { throw LicenseError.storage }
        do { return try JSONDecoder().decode(LicenseRecord.self, from: data) }
        catch { throw LicenseError.storage }
    }

    func save(_ record: LicenseRecord) throws {
        let data = try JSONEncoder().encode(record)
        let attributes = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecSuccess { return }
        guard status == errSecItemNotFound else { throw LicenseError.keychain(operation: "save", status: status) }
        var item = query
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let added = SecItemAdd(item as CFDictionary, nil)
        guard added == errSecSuccess else { throw LicenseError.keychain(operation: "save", status: added) }
    }

    func remove() throws {
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw LicenseError.keychain(operation: "remove", status: status) }
    }
}
