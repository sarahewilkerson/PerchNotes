import Foundation
import SwiftUI

/// Manages onboarding state and presentation
class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()

    @Published var shouldShowOnboarding = false

    private let hasSeenOnboardingKey = "hasSeenOnboarding"

    init() {
        // Check if user has seen onboarding
        if !UserDefaults.standard.bool(forKey: hasSeenOnboardingKey) {
            shouldShowOnboarding = true
        }
    }

    func markOnboardingComplete() {
        UserDefaults.standard.set(true, forKey: hasSeenOnboardingKey)
        shouldShowOnboarding = false
    }

    func showOnboarding() {
        shouldShowOnboarding = true
    }

    func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: hasSeenOnboardingKey)
        shouldShowOnboarding = true
    }
}
