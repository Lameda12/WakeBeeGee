import WakeBeeCore
import Foundation
import Observation

@MainActor @Observable
final class AppModel {
    let preferences: Preferences
    let license: LicenseStore
    let session: SessionController
    let closedLid = ClosedLidService()
    let loginItem = LoginItemService()
    let updates = UpdateService()
    var durationDraft: DurationDraft
    var sessionMode = SessionMode.duration
    var sessionEndDate = Date.now.addingTimeInterval(30 * 60)
    var settingsTab = SettingsTab.general
    var showingSettings = false
    var isPopoverVisible = false
    private(set) var blockedStartAttempts = 0
    @ObservationIgnored private var sessionMonitor: SessionMonitor?

    init() {
        let license = LicenseStore(storage: MigratingLicenseStorage())
        self.license = license
        let preferences = Preferences()
        self.preferences = preferences
        self.durationDraft = DurationDraft(totalMinutes: preferences.initialMinutes)
        let session = SessionController(power: PowerAssertionService(),
                                        keepDisplayAwake: preferences.keepDisplayAwake)
        session.setLicenseAccess(license.isUnlocked)
        self.session = session
        updates.safetyPolicy = { [weak self] in
            guard let self else {
                return UpdateSafetyPolicy(sessionActive: true, helperBusy: false, protectionActive: false,
                                          helperRegistered: false, sleepDisabled: nil)
            }
            return self.updateSafetyPolicy
        }
        self.sessionMonitor = SessionMonitor(session: session, beforeRefresh: { [weak self] in
            self?.synchronizeSafeguards()
        }) { [weak self] hasDemand in
            guard let self else { return }
            self.closedLid.update(hasDemand: hasDemand, policy: self.preferences.closedLidPolicy)
        }
    }

    func showSettings(_ tab: SettingsTab) {
        settingsTab = tab
        showingSettings = true
    }

    func start() {
        guard updates.allowsStartingSession, !session.isActive, let duration = requestedSession else { return }
        synchronizeSafeguards()
        session.updatePowerSafety(policy: preferences.sessionPowerPolicy, state: SystemPowerState.snapshot)
        if session.start(duration) {
            preferences.remember(duration)
        } else if session.statusMessage != nil {
            blockedStartAttempts += 1
        }
        refreshSession()
    }

    func end() {
        session.end()
        refreshSession()
    }

    func extend() {
        synchronizeSafeguards()
        session.extend()
        refreshSession()
    }

    func setDisplayAwake(_ enabled: Bool) {
        if session.setKeepDisplayAwake(enabled) { preferences.keepDisplayAwake = enabled }
    }

    func setupClosedLid() {
        guard license.isUnlocked, updates.allowsStartingSession else { return }
        closedLid.enableAfterSetup()
    }

    func setClosedLid(_ enabled: Bool) {
        guard !enabled || updates.allowsStartingSession else { return }
        guard !enabled || license.isUnlocked else { return }
        closedLid.setEnabled(enabled)
        sessionMonitor?.refresh()
    }

    func handleSystemSleep() {
        closedLid.setEnabled(false)
        session.end(reason: .systemSleep)
    }

    private func refreshSession() {
        sessionMonitor?.refresh()
    }

    var requestedSession: SessionDuration? {
        switch sessionMode {
        case .duration: durationDraft.duration
        case .untilTime: .until(Calendar.current.dateInterval(of: .minute, for: sessionEndDate)?.start ?? sessionEndDate)
        case .untilStopped: .indefinitely
        }
    }

    func refreshPowerSettings() {
        synchronizeSafeguards()
        refreshSession()
    }

    private func synchronizeSafeguards() {
        let wasActive = session.isActive
        license.refreshIfNeeded()
        session.setLicenseAccess(license.isUnlocked)
        // Idle monitoring still refreshes license access, but does not poll IOKit.
        if session.isActive {
            session.updatePowerSafety(policy: preferences.sessionPowerPolicy, state: SystemPowerState.snapshot)
        }
        if wasActive && !session.isActive { closedLid.setEnabled(false) }
    }

    func shutdown() {
        sessionMonitor?.stop()
        closedLid.setEnabled(false)
        session.end()
    }

    var canCheckForUpdates: Bool {
        updates.canCheckForUpdates && !session.isActive && !closedLid.isActive && !closedLid.isBusy
    }

    var updateSafetyPolicy: UpdateSafetyPolicy {
        UpdateSafetyPolicy(sessionActive: session.isActive, helperBusy: closedLid.isBusy,
                           protectionActive: closedLid.isActive, helperRegistered: closedLid.isRegistered,
                           sleepDisabled: closedLid.isRegistered ? try? SystemSleepState.readDisabled() : nil)
    }
}

enum SettingsTab: Hashable { case general, closedLid, license }
enum SessionMode: String, CaseIterable, Identifiable {
    case duration, untilTime, untilStopped
    var id: Self { self }
    var label: String {
        switch self {
        case .duration: "For a duration"
        case .untilTime: "Until a specific time"
        case .untilStopped: "Until I stop it"
        }
    }
}
