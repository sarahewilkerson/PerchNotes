import Foundation
import AppKit

/// Manages app-wide preferences
class AppPreferences: ObservableObject {
    static let shared = AppPreferences()

    @Published var hideDockIcon: Bool {
        didSet {
            UserDefaults.standard.set(hideDockIcon, forKey: "hideDockIcon")
            applyDockIconPreference()
        }
    }

    @Published var preferredPopoverSize: String {
        didSet {
            UserDefaults.standard.set(preferredPopoverSize, forKey: "preferredPopoverSize")
        }
    }

    private init() {
        // Load saved preferences
        self.hideDockIcon = UserDefaults.standard.bool(forKey: "hideDockIcon")
        self.preferredPopoverSize = UserDefaults.standard.string(forKey: "preferredPopoverSize") ?? "default"

        // Apply the preference on launch
        DispatchQueue.main.async {
            self.applyDockIconPreference()
        }
    }

    var popoverSizeEnum: MenuBarManager.PopoverSize {
        switch preferredPopoverSize {
        case "compact": return .compact
        case "default": return .default
        case "expanded": return .expanded
        case "large": return .large
        default: return .default
        }
    }

    private func applyDockIconPreference() {
        if hideDockIcon {
            // Hide dock icon - use accessory activation policy
            NSApp.setActivationPolicy(.accessory)
        } else {
            // Show dock icon - use regular activation policy
            NSApp.setActivationPolicy(.regular)
        }
    }
}
