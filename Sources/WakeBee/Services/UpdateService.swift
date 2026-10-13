import AppKit
import WakeBeeCore
import Combine
import Observation
import OSLog
import Sparkle

@MainActor @Observable
final class UpdateService: NSObject, SPUUpdaterDelegate {
    private(set) var canCheckForUpdates = false
    private(set) var isUpdateInProgress = false
    private(set) var automaticallyChecksForUpdates = false
    private(set) var lastCheckDate: Date?
    private(set) var startupError: String?
    private(set) var isInstalling = false
    @ObservationIgnored var safetyPolicy: (() -> UpdateSafetyPolicy)?
    @ObservationIgnored private var controller: SPUStandardUpdaterController!
    @ObservationIgnored private var observations: Set<AnyCancellable> = []
    @ObservationIgnored private var started = false
    @ObservationIgnored private let log = Logger(subsystem: "app.wakebee.WakeBee", category: "Updates")

    override init() {
        super.init()
        controller = SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: self, userDriverDelegate: nil)
        observe(\.canCheckForUpdates) { $0.canCheckForUpdates = $1 }
        observe(\.sessionInProgress) { $0.isUpdateInProgress = $1 }
        observe(\.automaticallyChecksForUpdates) { $0.automaticallyChecksForUpdates = $1 }
        observe(\.lastUpdateCheckDate) { $0.lastCheckDate = $1 }
    }

    // Sparkle's API and its KVO notifications are confined to the main thread.
    private func observe<Value>(_ keyPath: KeyPath<SPUUpdater, Value>,
                                update: @escaping @MainActor (UpdateService, Value) -> Void) {
        controller.updater.publisher(for: keyPath).sink { [weak self] value in
            MainActor.assumeIsolated {
                guard let self else { return }
                update(self, value)
            }
        }.store(in: &observations)
    }

    func start() {
        guard !started else { return }
        do {
            try controller.updater.start()
            started = true
            startupError = nil
            log.info("Sparkle updater started")
        } catch {
            startupError = error.localizedDescription
            log.error("Updater could not start: \(error.localizedDescription, privacy: .public)")
        }
    }

    func checkForUpdates() {
        guard canCheckForUpdates else { return }
        NSApp.activate(ignoringOtherApps: true)
        controller.checkForUpdates(nil)
    }

    func setAutomaticChecks(_ enabled: Bool) {
        // Sparkle owns persistence. Only write in response to the user's choice.
        controller.updater.automaticallyChecksForUpdates = enabled
    }

    var allowsStartingSession: Bool { !controller.updater.sessionInProgress && !isInstalling }

    func updater(_ updater: SPUUpdater, mayPerform updateCheck: SPUUpdateCheck) throws {
        try validateSafety()
    }

    func updater(_ updater: SPUUpdater, shouldProceedWithUpdate updateItem: SUAppcastItem,
                 updateCheck: SPUUpdateCheck) throws {
        try validateSafety()
    }

    func updater(_ updater: SPUUpdater, willInstallUpdate item: SUAppcastItem) {
        isInstalling = true
    }

    func updater(_ updater: SPUUpdater, didFinishUpdateCycleFor updateCheck: SPUUpdateCheck, error: Error?) {
        isInstalling = false
    }

    private func validateSafety() throws {
        guard let safetyPolicy else {
            throw NSError(domain: "app.wakebee.updates", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "WakeBee is still starting. Try again in a moment."])
        }
        try safetyPolicy().validate()
    }
}
