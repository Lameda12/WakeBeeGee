import Observation
import ServiceManagement

@MainActor @Observable
final class LoginItemService {
    private(set) var status = SMAppService.mainApp.status
    var errorMessage: String?

    var isRegistered: Bool { status == .enabled || status == .requiresApproval }
    var needsApproval: Bool { status == .requiresApproval }

    func refresh() { status = SMAppService.mainApp.status }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
            errorMessage = nil
        } catch {
            errorMessage = "Launch at login couldn’t be changed. \(error.localizedDescription)"
        }
        refresh()
    }

    func openSystemSettings() { SMAppService.openSystemSettingsLoginItems() }
}
