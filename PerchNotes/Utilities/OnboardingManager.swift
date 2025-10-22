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

    /// Creates sample notes if no notes exist (for onboarding)
    @MainActor
    func createSampleNoteIfNeeded() {
        // Only create if no active notes exist
        guard NoteManager.shared.activeNotes.isEmpty else { return }

        // Create welcome note
        let welcomeContent = """
Welcome to PerchNotes!

This is your first note - a quick capture notepad that lives in your menu bar.

Key Features You'll Learn:
• Smart note titles from your first line
• One-click copying in multiple formats
• Quick organization with folders & categories
• Easy trash & restore functionality

Try It Out:
Feel free to edit or delete this note as you explore. You can always create new notes anytime!

Happy note-taking! 🪶
"""

        _ = NoteManager.shared.createNote(
            title: "Welcome to PerchNotes",
            content: welcomeContent
        )

        // Create a second sample note for users to try trashing
        let sampleContent = """
Try Trashing This Note

This is a sample note to help you learn how PerchNotes handles deletions.

When you delete a note:
• It moves to Trash (not permanently deleted)
• You have 30 days to restore it
• After 30 days, it auto-deletes

**Try It:**
Click the trash icon in the Library to see how it works. You can always restore it from the Trash folder in the sidebar!
"""

        _ = NoteManager.shared.createNote(
            title: "Try Trashing This Note",
            content: sampleContent
        )
    }
}
