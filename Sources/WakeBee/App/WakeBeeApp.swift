import AppKit

@main
@MainActor
struct WakeBeeApp {
    static func main() {
        LegacyMigration.importPreferences()
        // AppKit owns one status item. No SwiftUI window scenes can be opened
        // or restored independently of its popover.
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        withExtendedLifetime(delegate) {
            application.run()
        }
    }
}
