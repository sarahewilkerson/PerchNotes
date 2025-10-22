import SwiftUI
import AppKit

class PerchNotesAppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var onboardingWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()
    private var hasAnimatedOnboarding = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Enable menu bar on launch
        MenuBarManager.shared.enableMenuBar()

        // Show onboarding after a short delay on first launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if OnboardingManager.shared.shouldShowOnboarding {
                self.showOnboardingWindow()
            }
        }

        // Observe onboarding manager changes
        setupOnboardingObserver()

        // Observe menu bar popover visibility
        setupPopoverObserver()
    }

    private func setupOnboardingObserver() {
        OnboardingManager.shared.$shouldShowOnboarding
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shouldShow in
                if shouldShow {
                    Task { @MainActor in
                        self?.showOnboardingWindow()
                    }
                }
            }
            .store(in: &cancellables)
    }

    @MainActor
    private func setupPopoverObserver() {
        MenuBarManager.shared.$isPopoverVisible
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isVisible in
                if isVisible && !self!.hasAnimatedOnboarding {
                    Task { @MainActor in
                        self?.animateOnboardingToSide()
                    }
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
                self?.hasAnimatedOnboarding = false
            }
        )
        let hostingController = NSHostingController(rootView: onboardingView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Welcome to PerchNotes"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false

        // Start below menu bar icon (like a popover)
        window.setContentSize(NSSize(width: 580, height: 720))

        if let button = MenuBarManager.shared.statusBarButton,
           let buttonWindow = button.window,
           let screen = NSScreen.main {
            let buttonFrame = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
            let screenHeight = screen.frame.height

            // Verify we got a valid frame (menu bar should be near top of screen)
            if buttonFrame.origin.y > screenHeight * 0.8 {
                let windowSize = NSSize(width: 580, height: 720)
                let xPos = buttonFrame.midX - (windowSize.width / 2)
                let yPos = buttonFrame.minY - windowSize.height - 8

                window.setFrame(NSRect(x: xPos, y: yPos, width: windowSize.width, height: windowSize.height), display: true)
            } else {
                // Button frame not ready, center the window
                window.center()
            }
        } else {
            window.center()
        }

        onboardingWindow = window
        window.delegate = self
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // If button wasn't ready, try repositioning after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.tryRepositionOnboarding()
        }
    }

    @MainActor
    private func tryRepositionOnboarding() {
        guard let window = onboardingWindow,
              let button = MenuBarManager.shared.statusBarButton,
              let buttonWindow = button.window,
              let screen = NSScreen.main else { return }

        let buttonFrame = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        let screenHeight = screen.frame.height

        // Only reposition if we have a valid button frame (menu bar should be near top)
        if buttonFrame.origin.y > screenHeight * 0.8 {
            let windowSize = NSSize(width: 580, height: 720)
            let xPos = buttonFrame.midX - (windowSize.width / 2)
            let yPos = buttonFrame.minY - windowSize.height - 8

            let newFrame = NSRect(x: xPos, y: yPos, width: windowSize.width, height: windowSize.height)

            // Smoothly animate to the correct position
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                window.animator().setFrame(newFrame, display: true)
            })
        }
    }

    @MainActor
    private func animateOnboardingToSide() {
        guard let window = onboardingWindow, !hasAnimatedOnboarding else { return }
        guard let screen = NSScreen.main else { return }

        hasAnimatedOnboarding = true

        // Auto-pin the notepad now that it's actually open (with a small delay to ensure window is ready)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            MenuBarManager.shared.setFloatOnTop(true)
        }

        let screenFrame = screen.visibleFrame
        let windowWidth: CGFloat = 580
        let windowHeight: CGFloat = 720

        // Position in the left third of the screen
        let xPos = screenFrame.origin.x + (screenFrame.width * 0.25) - (windowWidth / 2)
        let yPos = screenFrame.origin.y + (screenFrame.height - windowHeight) / 2

        let newFrame = NSRect(x: xPos, y: yPos, width: windowWidth, height: windowHeight)

        // Animate the move
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.5
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(newFrame, display: true)
        })
    }
}

// MARK: - NSWindowDelegate

extension PerchNotesAppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // If onboarding window is closing, mark onboarding as complete
        // This ensures it won't show again even if user closes without finishing
        if notification.object as? NSWindow === onboardingWindow {
            OnboardingManager.shared.markOnboardingComplete()
            onboardingWindow = nil
            hasAnimatedOnboarding = false
        }
    }
}

import Combine
