import AppKit

class StampView: NSView {
    private let stampLabel    = NSTextField(labelWithString: "")
    private let metadataLabel = NSTextField(labelWithString: "")
    private var timer: Timer?

    private static let metadataKey = "StampMetadata"

    var metadata: String {
        get { UserDefaults.standard.string(forKey: Self.metadataKey) ?? "" }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.metadataKey)
            metadataLabel.stringValue = newValue
            resizeWindow()
        }
    }

    // ── Appearance ──────────────────────────────────────────────────────
    private let cornerRadius: CGFloat = 10

    private static let darkModeKey = "StampDarkMode"
    private static let positionKey = "StampPosition"
    private static let useUTCKey = "StampUseUTC"
    private static let dimmedKey = "StampDimmed"
    private static let highlightKey = "StampHighlight"

    private var isHighlighted: Bool {
        get { UserDefaults.standard.bool(forKey: Self.highlightKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.highlightKey)
            needsDisplay = true
        }
    }

    private var isDimmed: Bool {
        get { UserDefaults.standard.bool(forKey: Self.dimmedKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.dimmedKey)
            window?.alphaValue = newValue ? 0.5 : 1.0
        }
    }

    private var useUTC: Bool {
        get { UserDefaults.standard.bool(forKey: Self.useUTCKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.useUTCKey)
            tick()
        }
    }

    private var useDarkMode: Bool {
        get { UserDefaults.standard.object(forKey: Self.darkModeKey) as? Bool ?? true }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.darkModeKey)
            updateColors()
        }
    }
    private var bgColor: NSColor {
        useDarkMode ? NSColor(white: 0.12, alpha: 0.82) : NSColor(white: 0.96, alpha: 0.88)
    }
    private var textColor: NSColor {
        useDarkMode ? .white : NSColor(white: 0.1, alpha: 1)
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        wantsLayer = true
        // cornerRadius handled in draw(), not by the layer

        let fontSize: CGFloat = 14
        for label in [stampLabel, metadataLabel] {
            label.font      = .monospacedDigitSystemFont(ofSize: fontSize, weight: .medium)
            label.alignment = .center
            label.isBezeled = false
            label.drawsBackground = false
        }
        metadataLabel.font = .systemFont(ofSize: fontSize, weight: .medium)
        metadataLabel.stringValue = metadata
        updateColors()

        addSubview(stampLabel)
        addSubview(metadataLabel)

        tick()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }

        // right-click menu
        let menu = NSMenu()
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
        let versionItem = NSMenuItem(title: "Stamp \(version)", action: nil, keyEquivalent: "")
        versionItem.isEnabled = false
        menu.addItem(versionItem)
        menu.addItem(.separator())
        let metadataItem = NSMenuItem(title: "Set metadata…", action: #selector(promptForMetadata), keyEquivalent: "")
        metadataItem.target = self
        menu.addItem(metadataItem)
        let clearItem = NSMenuItem(title: "Clear metadata", action: #selector(clearMetadata), keyEquivalent: "")
        clearItem.target = self
        menu.addItem(clearItem)
        menu.addItem(.separator())
        let tzItem = NSMenuItem(title: useUTC ? "Switch to local time" : "Switch to UTC", action: #selector(toggleTimezone), keyEquivalent: "")
        tzItem.target = self
        tzItem.tag = 98
        menu.addItem(tzItem)
        let themeItem = NSMenuItem(title: useDarkMode ? "Switch to light mode" : "Switch to dark mode", action: #selector(toggleTheme), keyEquivalent: "")
        themeItem.target = self
        themeItem.tag = 99
        menu.addItem(themeItem)
        let dimItem = NSMenuItem(title: isDimmed ? "Switch to bright" : "Switch to dim", action: #selector(toggleDim), keyEquivalent: "")
        dimItem.target = self
        dimItem.tag = 97
        menu.addItem(dimItem)
        let highlightItem = NSMenuItem(title: isHighlighted ? "Switch to subtle" : "Switch to highlight", action: #selector(toggleHighlight), keyEquivalent: "")
        highlightItem.target = self
        highlightItem.tag = 96
        menu.addItem(highlightItem)
        menu.addItem(.separator())
        let savePos = NSMenuItem(title: "Set position", action: #selector(savePosition), keyEquivalent: "")
        savePos.target = self
        menu.addItem(savePos)
        let resetPos = NSMenuItem(title: "Clear position", action: #selector(resetPosition), keyEquivalent: "")
        resetPos.target = self
        menu.addItem(resetPos)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)
        self.menu = menu
    }

    private func updateColors() {
        let color = textColor
        stampLabel.textColor = color
        metadataLabel.textColor = color
        needsDisplay = true
    }

    private lazy var stampFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy  h:mm:ss a zzz"
        return df
    }()

    private func tick() {
        let now = Date()
        stampFormatter.timeZone = useUTC ? TimeZone(identifier: "UTC")! : TimeZone.current
        stampLabel.stringValue = stampFormatter.string(from: now).replacingOccurrences(of: "GMT", with: "UTC")
    }

    @objc private func savePosition() {
        guard let window = self.window else { return }
        let origin = window.frame.origin
        UserDefaults.standard.set("\(origin.x),\(origin.y)", forKey: Self.positionKey)
    }

    @objc private func resetPosition() {
        UserDefaults.standard.removeObject(forKey: Self.positionKey)
    }

    static func savedPosition() -> NSPoint? {
        guard let str = UserDefaults.standard.string(forKey: positionKey) else { return nil }
        let parts = str.split(separator: ",")
        guard parts.count == 2,
              let x = Double(parts[0]),
              let y = Double(parts[1]) else { return nil }
        return NSPoint(x: x, y: y)
    }

    @objc private func toggleTimezone() {
        useUTC.toggle()
        if let item = menu?.item(withTag: 98) {
            item.title = useUTC ? "Switch to local time" : "Switch to UTC"
        }
    }

    @objc private func toggleTheme() {
        useDarkMode.toggle()
        if let item = menu?.item(withTag: 99) {
            item.title = useDarkMode ? "Switch to light mode" : "Switch to dark mode"
        }
    }

    @objc private func toggleDim() {
        isDimmed.toggle()
        if let item = menu?.item(withTag: 97) {
            item.title = isDimmed ? "Switch to bright" : "Switch to dim"
        }
    }

    @objc private func toggleHighlight() {
        isHighlighted.toggle()
        if let item = menu?.item(withTag: 96) {
            item.title = isHighlighted ? "Switch to subtle" : "Switch to highlight"
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    @objc private func clearMetadata() {
        metadata = ""
    }

    @objc private func promptForMetadata() {
        NSApp.activate(ignoringOtherApps: true)

        let panelWidth: CGFloat = 320
        let padding: CGFloat = 16
        let contentWidth = panelWidth - padding * 2

        let dialog = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: 130),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        dialog.title = "Stamp"
        dialog.isFloatingPanel = true

        let contentView = NSView(frame: dialog.contentView!.bounds)
        dialog.contentView = contentView

        let label = NSTextField(labelWithString: "Enter a name, email, audit title, or other text to display.")
        label.font = .systemFont(ofSize: 12)
        label.lineBreakMode = .byWordWrapping
        label.preferredMaxLayoutWidth = contentWidth
        label.frame = NSRect(x: padding, y: 72, width: contentWidth, height: 32)
        contentView.addSubview(label)

        let input = NSTextField(frame: NSRect(x: padding, y: 44, width: contentWidth, height: 24))
        input.stringValue = metadata
        contentView.addSubview(input)

        let okButton = NSButton(title: "OK", target: nil, action: nil)
        okButton.frame = NSRect(x: panelWidth - padding - 68, y: 8, width: 68, height: 28)
        okButton.keyEquivalent = "\r"
        contentView.addSubview(okButton)

        let clearButton = NSButton(title: "Clear", target: nil, action: nil)
        clearButton.frame = NSRect(x: panelWidth - padding - 68 - 8 - 68, y: 8, width: 68, height: 28)
        contentView.addSubview(clearButton)

        let cancelButton = NSButton(title: "Cancel", target: nil, action: nil)
        cancelButton.frame = NSRect(x: padding, y: 8, width: 68, height: 28)
        cancelButton.keyEquivalent = "\u{1b}"
        contentView.addSubview(cancelButton)

        okButton.tag = 1
        clearButton.tag = 2
        cancelButton.tag = 3
        for btn in [okButton, clearButton, cancelButton] {
            btn.target = self
            btn.action = #selector(dialogButtonClicked(_:))
        }

        dialog.center()
        dialog.makeFirstResponder(input)
        input.selectText(nil)

        dialogClickedTag = 3
        NSApp.runModal(for: dialog)
        dialog.close()

        let clickedTag = dialogClickedTag

        if clickedTag == 1 {
            metadata = input.stringValue
        } else if clickedTag == 2 {
            metadata = ""
        }
    }

    private var dialogClickedTag = 3

    @objc private func dialogButtonClicked(_ sender: NSButton) {
        dialogClickedTag = sender.tag
        NSApp.stopModal(withCode: .stop)
    }

    private let defaultWidth: CGFloat = 280
    private let padding: CGFloat = 20

    private func resizeWindow() {
        guard let window = self.window else { return }
        let hasMetadata = !metadata.isEmpty
        let newHeight: CGFloat = hasMetadata ? 48 : 30

        // Measure worst-case stamp width (widest month + timezone)
        let worstCase = NSAttributedString(string: "Sep 30, 2026, 12:59:59 PM UTC",
            attributes: [.font: stampLabel.font!])
        let stampW = worstCase.size().width + padding * 2

        let metaW = hasMetadata ? metadataLabel.attributedStringValue.size().width + padding * 2 : 0
        let newWidth = max(defaultWidth, stampW, metaW)

        var frame = window.frame
        let deltaH = newHeight - frame.height
        let deltaW = newWidth - frame.width
        frame.origin.y -= deltaH
        frame.origin.x -= deltaW  // grow leftward (anchored to right edge)
        frame.size.height = newHeight
        frame.size.width = newWidth
        window.setFrame(frame, display: true, animate: true)
    }

    override func layout() {
        super.layout()
        let w = bounds.width, h = bounds.height
        let hasMetadata = !metadata.isEmpty
        metadataLabel.isHidden = !hasMetadata

        stampLabel.sizeToFit()
        metadataLabel.sizeToFit()
        let lineH = stampLabel.frame.height

        if hasMetadata {
            let totalH = lineH * 2
            let topY = (h + totalH) / 2 - lineH
            stampLabel.frame    = NSRect(x: 0, y: topY,          width: w, height: lineH)
            metadataLabel.frame = NSRect(x: 0, y: topY - lineH, width: w, height: lineH)
        } else {
            stampLabel.frame = NSRect(x: 0, y: (h - lineH) / 2, width: w, height: lineH)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.setFillColor(bgColor.cgColor)
        let path = CGPath(roundedRect: bounds, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        ctx.addPath(path)
        ctx.fillPath()

        if isHighlighted {
            let lineW: CGFloat = 2.5
            let inset = lineW / 2 + 1
            let borderRect = bounds.insetBy(dx: inset, dy: inset)
            let r = cornerRadius - inset
            let borderPath = CGPath(roundedRect: borderRect, cornerWidth: r, cornerHeight: r, transform: nil)
            ctx.setStrokeColor(NSColor.systemRed.cgColor)
            ctx.setLineWidth(lineW)
            ctx.addPath(borderPath)
            ctx.strokePath()
        }
    }
}
