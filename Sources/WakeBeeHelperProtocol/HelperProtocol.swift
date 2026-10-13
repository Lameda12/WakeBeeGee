import Foundation
import Security

@objc public protocol WakeBeeHelperProtocol {
    /// Read-only startup check. It never creates or extends a sleep lease.
    func checkHealth(reply: @escaping @Sendable (Bool, String) -> Void)
    // Retained for older signed apps. It always uses adapter-only defaults.
    func renew(reply: @escaping @Sendable (Bool, String) -> Void)
    func renewWithPolicy(allowsBattery: Bool, minimumBatteryPercent: Int, maximumBatteryMinutes: Int,
                         reply: @escaping @Sendable (Bool, String) -> Void)
    func releaseLease(reply: @escaping @Sendable (Bool, String) -> Void)
}

public enum HelperIdentity {
    public static let service = "app.wakebee.helper"
    public static let plist = "app.wakebee.helper.plist"
    public static var teamID: String? {
        var code: SecCode?
        guard SecCodeCopySelf([], &code) == errSecSuccess, let code else { return nil }
        var staticCode: SecStaticCode?
        guard SecCodeCopyStaticCode(code, [], &staticCode) == errSecSuccess, let staticCode else { return nil }
        var details: CFDictionary?
        guard SecCodeCopySigningInformation(staticCode, SecCSFlags(rawValue: kSecCSSigningInformation), &details) == errSecSuccess,
              let values = details as? [String: Any],
              let team = values[kSecCodeInfoTeamIdentifier as String] as? String,
              team.range(of: "^[A-Z0-9]{10}$", options: .regularExpression) != nil else { return nil }
        return team
    }
    public static func requirement(identifier: String, team: String) -> String {
        "anchor apple generic and identifier \"\(identifier)\" and certificate leaf[subject.OU] = \"\(team)\""
    }
}
