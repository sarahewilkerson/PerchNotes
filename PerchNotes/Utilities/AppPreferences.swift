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

    private init() {
        // Load saved preference
        self.hideDockIcon = UserDefaults.standard.bool(forKey: "hideDockIcon")

        // Apply the preference on launch
        DispatchQueue.main.async {
            self.applyDockIconPreference()
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
