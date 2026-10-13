import Foundation
import Testing
import WakeBeeCore
@testable import WakeBee

@MainActor private final class MigrationStorage: LicenseStorage {
    var record: LicenseRecord?
    var fails = false
    var reads = 0
    init(_ record: LicenseRecord? = nil) { self.record = record }
    func load() throws -> LicenseRecord? {
        reads += 1
        if fails { throw LicenseError.storage }
        return record
    }
    func save(_ record: LicenseRecord) throws {
        if fails { throw LicenseError.storage }
        self.record = record
    }
    func remove() throws { record = nil }
}

@Suite @MainActor struct LegacyMigrationTests {
    private func withDefaults(_ body: (UserDefaults, String) throws -> Void) throws {
        let name = "WakeBeeMigrationTests.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        try body(defaults, name)
    }

    @Test func preferencesImportOnceWithoutOverwritingChoicesOrHelperState() throws {
        try withDefaults { defaults, domain in
            defaults.set(false, forKey: "showTimeInMenuBar")
            let old: [String: Any] = ["showTimeInMenuBar": true, "savedMinutes": 45,
                                     "registeredClosedLidHelperFingerprint": "old", "unknown": "ignored"]
            LegacyMigration.importPreferences(into: defaults, domain: domain, legacy: old)
            #expect(!defaults.bool(forKey: "showTimeInMenuBar"))
            #expect(defaults.integer(forKey: "savedMinutes") == 45)
            #expect(defaults.object(forKey: "registeredClosedLidHelperFingerprint") == nil)
            #expect(defaults.object(forKey: "unknown") == nil)
            defaults.set(60, forKey: "savedMinutes")
            LegacyMigration.importPreferences(into: defaults, domain: domain, legacy: old)
            #expect(defaults.integer(forKey: "savedMinutes") == 60)
        }
    }

    @Test func licenseReusesActivationButRequiresOnlineVerificationAndNeverResurrectsAfterRemoval() throws {
        try withDefaults { defaults, _ in
            let activation = UUID()
            let previous = LicenseRecord(key: "TEST", activationID: activation, validatedAt: .now)
            let old = MigrationStorage(previous), current = MigrationStorage()
            let migration = MigratingLicenseStorage(current: current, legacy: old, defaults: defaults)
            let loaded = try migration.load()
            let imported = try #require(loaded)
            #expect(imported.activationID == activation)
            #expect(imported.validatedAt == nil)
            #expect(!imported.allowsUse(at: .now))
            #expect(old.record?.validatedAt != nil)
            try migration.remove()
            let removed = try migration.load()
            #expect(removed == nil)
            #expect(old.reads == 1)
        }
    }

    @Test func failedCopyCanRetryAndDoesNotDeleteTheOldLicense() throws {
        try withDefaults { defaults, _ in
            let old = MigrationStorage(LicenseRecord(key: "TEST", activationID: UUID()))
            let current = MigrationStorage(); current.fails = true
            let migration = MigratingLicenseStorage(current: current, legacy: old, defaults: defaults)
            #expect(throws: LicenseError.self) { try migration.load() }
            #expect(old.record != nil)
            current.fails = false
            let retried = try migration.load()
            #expect(retried?.key == "TEST")
        }
    }

    @Test func currentLicenseTakesPrecedenceWithoutAccessingLegacyKeychain() throws {
        try withDefaults { defaults, _ in
            let current = MigrationStorage(LicenseRecord(key: "CURRENT"))
            let old = MigrationStorage(); old.fails = true
            let migration = MigratingLicenseStorage(current: current, legacy: old, defaults: defaults)
            let loaded = try migration.load()
            #expect(loaded?.key == "CURRENT")
            #expect(old.reads == 0)
        }
    }
}
