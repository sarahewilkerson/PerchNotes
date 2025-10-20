import SwiftUI
import AppKit

class PerchNotesAppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var onboardingWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Enable menu bar on launch
        MenuBarManager.shared.enableMenuBar()

        // Show onboarding after a short delay on first launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if OnboardingManager.shared.shouldShowOnboarding {
                self.showOnboardingWindow()
            }
        }

        // Observe onboarding manager changes
        setupOnboardingObserver()
    }

    private func setupOnboardingObserver() {
        OnboardingManager.shared.$shouldShowOnboarding
            .sink { [weak self] shouldShow in
                if shouldShow {
                    self?.showOnboardingWindow()
                }
            }
            .store(in: &cancellables)
    }

    @MainActor
    func showOnboardingWindow() {
        if let window = onboardingWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let onboardingView = OnboardingWalkthroughView(
            onComplete: { [weak self] in
                OnboardingManager.shared.markOnboardingComplete()
                self?.onboardingWindow?.close()
                self?.onboardingWindow = nil
            }
        )
        let hostingController = NSHostingController(rootView: onboardingView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Welcome to PerchNotes"
        window.styleMask = [.titled, .closable]
        window.center()
        window.isReleasedWhenClosed = false

        onboardingWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

import Combine
