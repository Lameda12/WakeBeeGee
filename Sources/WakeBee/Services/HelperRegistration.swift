import WakeBeeCore
import WakeBeeHelperProtocol
import CryptoKit
import Foundation
import ServiceManagement

@MainActor protocol HelperRegistering: AnyObject {
    var status: SMAppService.Status { get }
    func register() async throws
    func unregister() async throws
}

@MainActor final class SystemHelperRegistration: HelperRegistering {
    private var service: SMAppService { .daemon(plistName: HelperIdentity.plist) }
    var status: SMAppService.Status { service.status }
    func register() async throws {
        // Both launchctl and ServiceManagement may block. Never run them on
        // the UI executor: users must still be able to dismiss or quit.
        try await Task.detached(priority: .userInitiated) {
            try LegacyHelperGuard.ensureReady(checkRecovery: false)
            try SMAppService.daemon(plistName: HelperIdentity.plist).register()
        }.value
    }
    func unregister() async throws { try await service.unregister() }
}

/// Re-register changed bundles only after the kernel confirms that sleep is
/// enabled. Never remove the recovery helper while it might hold protection.
@MainActor final class HelperRegistration {
    let system: any HelperRegistering
    private let defaults: UserDefaults
    private let fingerprint: String?
    private let readSleepDisabled: () throws -> Bool
    private let pause: () async throws -> Void
    private let restorationChecks: Int
    private let key = "registeredClosedLidHelperFingerprint"
    private let pendingKey = "closedLidHelperUpdatePending"
    private var registeredThisLaunch = false

    init(system: any HelperRegistering = SystemHelperRegistration(), defaults: UserDefaults = .standard,
         fingerprint: String? = HelperRegistration.bundleFingerprint(),
         readSleepDisabled: @escaping () throws -> Bool = { try SystemSleepState.readDisabled() },
         restorationChecks: Int = 35,
         pause: @escaping () async throws -> Void = { try await Task.sleep(for: .seconds(1)) }) {
        self.system = system; self.defaults = defaults; self.fingerprint = fingerprint
        self.readSleepDisabled = readSleepDisabled; self.restorationChecks = restorationChecks; self.pause = pause
    }

    var needsUpdate: Bool { !registeredThisLaunch && (fingerprint == nil || defaults.string(forKey: key) != fingerprint) }
    var hasPendingUpdate: Bool { defaults.bool(forKey: pendingKey) }

    func prepare(force: Bool = false) async throws {
        guard system.status == .enabled || system.status == .notFound
                || (system.status == .notRegistered && hasPendingUpdate) else { return }
        guard force || needsUpdate || hasPendingUpdate else { return }
        guard fingerprint != nil else { throw Failure.missingBundle }
        try await waitForRestoration()
        defaults.set(true, forKey: pendingKey)
        // A missing service has no registration to remove. BTM rejects that
        // unregister with EPERM before the first registration can run.
        if system.status != .notRegistered && system.status != .notFound {
            try await system.unregister()
        }
        try Task.checkCancellation()
        try await registerAfterUpdate()
    }

    func install() async throws {
        guard fingerprint != nil else { throw Failure.missingBundle }
        try await system.register()
        registeredThisLaunch = true
    }

    func confirmedResponsive() {
        if let fingerprint { defaults.set(fingerprint, forKey: key) }
        defaults.removeObject(forKey: pendingKey)
    }

    func forget() {
        registeredThisLaunch = false
        defaults.removeObject(forKey: key); defaults.removeObject(forKey: pendingKey)
    }

    private func registerAfterUpdate() async throws {
        // Some macOS releases briefly return EPERM even after asynchronous
        // unregister completes (Apple DTS thread 783539). Retry only this
        // transition race; approval and other failures remain user-visible.
        for attempt in 0..<3 {
            do {
                try await system.register()
                registeredThisLaunch = true
                return
            } catch {
                if system.status == .requiresApproval { return }
                let failure = error as NSError
                let transient = (failure.domain == "SMAppServiceErrorDomain" && failure.code == 1)
                    || (failure.domain == NSPOSIXErrorDomain && failure.code == Int(EPERM))
                guard transient, attempt < 2,
                      system.status == .notRegistered || system.status == .notFound else { throw error }
                try await pause()
                try Task.checkCancellation()
            }
        }
    }

    private func waitForRestoration() async throws {
        for attempt in 0...restorationChecks {
            try Task.checkCancellation()
            if try !readSleepDisabled() { return }
            guard attempt < restorationChecks else { throw Failure.restorationPending }
            try await pause()
        }
    }

    static func bundleFingerprint(bundle: Bundle = .main) -> String? {
        let helper = bundle.bundleURL.appendingPathComponent("Contents/Library/HelperTools/WakeBeeHelper")
        let plist = bundle.bundleURL.appendingPathComponent("Contents/Library/LaunchDaemons/\(HelperIdentity.plist)")
        guard let executable = try? Data(contentsOf: helper), let configuration = try? Data(contentsOf: plist) else { return nil }
        var digest = SHA256()
        digest.update(data: executable); digest.update(data: configuration)
        digest.update(data: Data(bundle.bundleURL.path.utf8))
        digest.update(data: Data((bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "").utf8))
        return digest.finalize().map { String(format: "%02x", $0) }.joined()
    }

    enum Failure: LocalizedError {
        case missingBundle, restorationPending
        var errorDescription: String? {
            switch self {
            case .missingBundle: "The helper is missing from this app. Reinstall WakeBee to repair it."
            case .restorationPending: "Waiting for normal sleep settings to return. Keep the lid open, then try again."
            }
        }
    }
}
