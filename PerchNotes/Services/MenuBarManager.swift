import SwiftUI
import AppKit

@MainActor
class MenuBarManager: NSObject, ObservableObject {
    static let shared = MenuBarManager()

    private var statusBarItem: NSStatusItem?
    private var popover: NSPopover?
    private var detachedWindow: NSWindow?
    private var libraryWindow: NSWindow?

    @Published var isEnabled = false
    @Published var isPopoverVisible = false
    @Published var isDetached = false
    @Published var popoverSize: PopoverSize = .default
    @Published var floatOnTop = false

    private let detachedWindowFrameKey = "detachedWindowFrame"

    enum PopoverSize {
        case compact    // 380 x 500
        case `default`  // 480 x 600
        case expanded   // 600 x 800
        case large      // 800 x 900

        var dimensions: NSSize {
            switch self {
            case .compact: return NSSize(width: 380, height: 500)
            case .default: return NSSize(width: 480, height: 600)
            case .expanded: return NSSize(width: 600, height: 800)
            case .large: return NSSize(width: 800, height: 900)
            }
        }

        var displayName: String {
            switch self {
            case .compact: return "Compact"
            case .default: return "Default"
            case .expanded: return "Expanded"
            case .large: return "Large"
            }
        }
    }

    override init() {
        super.init()
    }

    func enableMenuBar() {
        guard statusBarItem == nil else { return }

        // Create status bar item
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusBarItem?.button {
            // Use custom icon from Assets.xcassets
            if let customIcon = NSImage(named: "MenuBarIcon") {
                customIcon.isTemplate = true // Ensure it renders as template image
                button.image = customIcon
            } else {
                // Fallback to system icon if custom icon not found
                button.image = NSImage(systemSymbolName: "note.text", accessibilityDescription: "PerchNotes")
            }
            button.imagePosition = .imageOnly
            button.action = #selector(statusBarButtonClicked)
            button.target = self

            button.toolTip = "PerchNotes - Quick Notes"
        }

        // Create popover
        createPopover()

        isEnabled = true
    }

    func disableMenuBar() {
        if let statusBarItem = statusBarItem {
            NSStatusBar.system.removeStatusItem(statusBarItem)
            self.statusBarItem = nil
        }

        popover?.close()
        popover = nil
        isEnabled = false
        isPopoverVisible = false
    }

    @objc private func statusBarButtonClicked() {
        guard let button = statusBarItem?.button else { return }

        if isDetached {
            // Toggle detached window visibility
            if let window = detachedWindow, window.isVisible {
                hideDetachedWindow()
            } else {
                showDetachedWindow()
            }
        } else {
            // Toggle popover visibility
            if isPopoverVisible {
                hidePopover()
            } else {
                showPopover(relativeTo: button)
            }
        }
    }

    private func showPopover(relativeTo view: NSView) {
        guard let popover = popover else { return }

        popover.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
        isPopoverVisible = true

        // Make popover key window for proper keyboard handling
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func hidePopover() {
        popover?.close()
        isPopoverVisible = false
    }

    private func createPopover() {
        popover = NSPopover()
        popover?.contentSize = popoverSize.dimensions
        popover?.behavior = .transient
        popover?.animates = true

        let contentView = PerchNotesView(
            onClose: { [weak self] in
                self?.hidePopover()
            },
            onResizeRequest: { [weak self] newSize in
                self?.resizePopover(to: newSize)
            }
        )

        popover?.contentViewController = NSHostingController(rootView: contentView)

        // Handle popover close events
        popover?.delegate = self
    }

    func resizePopover(to size: PopoverSize) {
        popoverSize = size
        popover?.contentSize = size.dimensions

        // Animate the resize
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            popover?.contentSize = size.dimensions
        }
    }

    func togglePopover() {
        guard let button = statusBarItem?.button else { return }

        if isPopoverVisible {
            hidePopover()
        } else {
            showPopover(relativeTo: button)
        }
    }

    func setFloatOnTop(_ enabled: Bool) {
        floatOnTop = enabled
        updateWindowLevel()
    }

    private func updateWindowLevel() {
        if isDetached {
            // Update detached window
            guard let window = detachedWindow else { return }

            if floatOnTop {
                window.level = .floating
                window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            } else {
                window.level = .normal
                window.collectionBehavior = []
            }
        } else {
            // Update popover window
            guard let window = popover?.contentViewController?.view.window else { return }

            if floatOnTop {
                // Change popover behavior to prevent auto-close when clicking outside
                popover?.behavior = .applicationDefined
                window.level = .floating
                window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            } else {
                // Restore transient behavior (auto-close when clicking outside)
                popover?.behavior = .transient
                window.level = .normal
                window.collectionBehavior = []
            }
        }
    }

    // MARK: - Detach/Attach

    func detachNotepad() {
        // Close popover
        hidePopover()

        // Mark as detached
        isDetached = true

        // Show detached window
        showDetachedWindow()
    }

    func attachNotepad() {
        // Close detached window
        hideDetachedWindow()

        // Mark as attached
        isDetached = false

        // Show popover
        if let button = statusBarItem?.button {
            showPopover(relativeTo: button)
        }
    }

    private func showDetachedWindow() {
        if let window = detachedWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            isPopoverVisible = true
            return
        }

        let contentView = PerchNotesView(
            onClose: { [weak self] in
                self?.hideDetachedWindow()
            },
            onResizeRequest: { [weak self] newSize in
                self?.resizeDetachedWindow(to: newSize)
            }
        )

        let hostingController = NSHostingController(rootView: contentView)
        let window = NSWindow(contentViewController: hostingController)

        window.title = ""
        window.styleMask = [.titled, .closable, .resizable]
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.setContentSize(popoverSize.dimensions)
        window.isReleasedWhenClosed = false

        // Restore saved position or position below menu bar
        if let frameString = UserDefaults.standard.string(forKey: detachedWindowFrameKey),
           let savedFrame = NSRectFromString(frameString) as NSRect? {
            window.setFrame(savedFrame, display: true)
        } else {
            // Position below menu bar icon
            if let button = statusBarItem?.button, let screen = NSScreen.main {
                let buttonFrame = button.window?.convertToScreen(button.convert(button.bounds, to: nil)) ?? .zero
                let windowSize = popoverSize.dimensions

                let xPos = buttonFrame.midX - (windowSize.width / 2)
                let yPos = buttonFrame.minY - windowSize.height - 8

                window.setFrame(NSRect(x: xPos, y: yPos, width: windowSize.width, height: windowSize.height), display: true)
            } else {
                window.center()
            }
        }

        // Apply float on top if enabled
        if floatOnTop {
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        }

        detachedWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        isPopoverVisible = true

        // Save position when window moves
        NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.saveDetachedWindowFrame()
        }
    }

    private func hideDetachedWindow() {
        saveDetachedWindowFrame()
        detachedWindow?.orderOut(nil)
        isPopoverVisible = false
    }

    private func saveDetachedWindowFrame() {
        guard let window = detachedWindow else { return }
        let frameString = NSStringFromRect(window.frame)
        UserDefaults.standard.set(frameString, forKey: detachedWindowFrameKey)
    }

    private func resizeDetachedWindow(to size: PopoverSize) {
        popoverSize = size
        guard let window = detachedWindow else { return }

        let currentFrame = window.frame
        let newSize = size.dimensions

        // Keep top-left corner in same position
        let newFrame = NSRect(
            x: currentFrame.origin.x,
            y: currentFrame.origin.y + (currentFrame.height - newSize.height),
            width: newSize.width,
            height: newSize.height
        )

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(newFrame, display: true)
        }
    }

    // MARK: - Library Window

    func openLibraryWindow() {
        if let window = libraryWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let libraryView = NotesLibraryView()
        let hostingController = NSHostingController(rootView: libraryView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "PerchNotes Library"
        window.setContentSize(NSSize(width: 1200, height: 800))
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.center()
        window.isReleasedWhenClosed = false

        libraryWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func closeLibraryWindow() {
        libraryWindow?.close()
        libraryWindow = nil
    }
}

// MARK: - NSPopoverDelegate

extension MenuBarManager: NSPopoverDelegate {
    func popoverDidClose(_ notification: Notification) {
        isPopoverVisible = false
    }
}
