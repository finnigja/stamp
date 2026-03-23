import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: NSPanel!
    var stampView: StampView!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory) // no Dock icon

        let hasMetadata = UserDefaults.standard.string(forKey: "StampMetadata")?.isEmpty == false
        let size = NSSize(width: 280, height: hasMetadata ? 48 : 30)
        panel = NSPanel(
            contentRect: NSRect(origin: StampView.savedPosition() ?? screenBottomRight(size: size), size: size),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .titled],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel   = true      // stays above all windows
        panel.level             = .floating
        panel.isMovableByWindowBackground = true
        panel.titlebarAppearsTransparent  = true
        panel.titleVisibility   = .hidden
        panel.backgroundColor   = .clear
        panel.isOpaque          = false
        panel.hasShadow         = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Main menu with Cmd-Q
        let mainMenu = NSMenu()
        let appMenu = NSMenu()
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenu.addItem(quitItem)
        let appMenuItem = NSMenuItem()
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        NSApp.mainMenu = mainMenu

        stampView = StampView(frame: NSRect(origin: .zero, size: size))
        panel.contentView = stampView
        panel.alphaValue = UserDefaults.standard.bool(forKey: "StampDimmed") ? 0.5 : 1.0
        panel.orderFront(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ app: NSApplication) -> Bool { false }

    private func screenBottomRight(size: NSSize) -> NSPoint {
        guard let screen = NSScreen.main else { return .zero }
        let f = screen.visibleFrame
        return NSPoint(
            x: f.maxX - size.width  - 16,
            y: f.minY               + 16
        )
    }
}
