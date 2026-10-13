import AppKit
import SwiftUI

struct WakeBeeRootView: View {
    let model: AppModel

    var body: some View {
        if model.showingSettings {
            SettingsView(model: model)
        } else if model.license.isUnlocked || model.session.isActive {
            SessionPanel(model: model)
        } else {
            VStack(spacing: 0) {
                LicenseView(license: model.license)
                Divider()
                HStack {
                    Button("Settings…") {
                        model.showSettings(.general)
                    }.keyboardShortcut(",", modifiers: .command)
                    Spacer()
                    Button("Quit") { model.shutdown(); NSApp.terminate(nil) }
                        .keyboardShortcut("q", modifiers: .command)
                }
                .buttonStyle(.borderless).font(.callout).padding(.horizontal, 24).padding(.vertical, 12)
            }
            .frame(width: 340)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}
