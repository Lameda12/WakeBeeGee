import Foundation
import WakeBeeCore

/// Old identifiers are read only for the one-time migration, never used for new state.
@MainActor enum LegacyMigration {
    static let appID = "com.awakemac.AwakeMac"
    static let licenseService = "com.awakemac.AwakeMac.license"
    static let preferenceKeys = [
        "rememberDuration", "savedMinutes", "showTimeInMenuBar", "keepDisplayAwake",
        "allowClosedLidOnBattery", "closedLidBatteryCutoff", "closedLidBatteryMinutes",
        "endSessionOnLowBattery", "requirePowerAdapter", "SUEnableAutomaticChecks"
    ]

    static func importPreferences(into defaults: UserDefaults = .standard,
                                  domain: String = "app.wakebee.WakeBee",
                                  legacy: [String: Any]? = nil) {
        let marker = "wakeBeePreferencesMigrated"
        guard !defaults.bool(forKey: marker) else { return }
        let previous = legacy ?? defaults.persistentDomain(forName: appID) ?? [:]
        let current = defaults.persistentDomain(forName: domain) ?? [:]
        for key in preferenceKeys where current[key] == nil {
            if let value = previous[key] { defaults.set(value, forKey: key) }
        }
        // Do not copy helper fingerprints, login-item approvals, active sessions, or update caches.
        defaults.set(true, forKey: marker)
    }
}

@MainActor struct MigratingLicenseStorage: LicenseStorage {
    let current: any LicenseStorage
    let legacy: any LicenseStorage
    let defaults: UserDefaults
    private let marker = "wakeBeeLicenseMigrated"

    init(current: any LicenseStorage = LicenseKeychain(),
         legacy: any LicenseStorage = LicenseKeychain(service: LegacyMigration.licenseService),
         defaults: UserDefaults = .standard) {
        self.current = current; self.legacy = legacy; self.defaults = defaults
    }

    func load() throws -> LicenseRecord? {
        if let record = try current.load() { return record }
        guard !defaults.bool(forKey: marker) else { return nil }
        guard var record = try legacy.load() else {
            defaults.set(true, forKey: marker)
            return nil
        }
        // Reuse the activation, but require online verification under the new identity.
        record.validatedAt = nil
        try current.save(record)
        defaults.set(true, forKey: marker)
        return record
    }

    func save(_ record: LicenseRecord) throws {
        try current.save(record)
        defaults.set(true, forKey: marker)
    }

    func remove() throws {
        try current.remove()
        defaults.set(true, forKey: marker)
    }
}
