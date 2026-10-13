import AppKit

/// Include room for the activity dot only while a session is running.
@MainActor enum MenuBarStatusIcon {
    static func make(active: Bool) -> NSImage {
        let bee = NSApplication.shared.applicationIconImage.copy() as! NSImage
        let image = NSImage(size: NSSize(width: active ? 28 : 18, height: 18))
        image.lockFocus()
        bee.draw(in: NSRect(x: 0, y: 0, width: 18, height: 18))
        if active {
            NSColor.systemGreen.setFill()
            NSBezierPath(ovalIn: NSRect(x: 22, y: 6, width: 6, height: 6)).fill()
        }
        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}
