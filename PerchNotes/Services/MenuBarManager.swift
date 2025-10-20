import SwiftUI
import AppKit

@MainActor
class MenuBarManager: NSObject, ObservableObject {
    static let shared = MenuBarManager()

    private var statusBarItem: NSStatusItem?
    private var popover: NSPopover?
    private var libraryWindow: NSWindow?

    @Published var isEnabled = false
    @Published var isPopoverVisible = false
    @Published var popoverSize: PopoverSize = .default
    @Published var floatOnTop = false

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

        if isPopoverVisible {
            hidePopover()
        } else {
            showPopover(relativeTo: button)
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
        guard let window = popover?.contentViewController?.view.window else { return }

        if floatOnTop {
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        } else {
            window.level = .normal
            window.collectionBehavior = []
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
