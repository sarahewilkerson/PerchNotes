import SwiftUI

@main
struct PerchNotesApp: App {
    @NSApplicationDelegateAdaptor(PerchNotesAppDelegate.self) var appDelegate
    @StateObject private var noteManager = NoteManager.shared
    @StateObject private var menuBarManager = MenuBarManager.shared

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

// Settings view
struct SettingsView: View {
    @StateObject private var onboardingManager = OnboardingManager.shared

    var body: some View {
        VStack(spacing: 20) {
            Image("AppIconTransparent")
                .resizable()
                .frame(width: 64, height: 64)

            Text("PerchNotes")
                .font(.title)
                .fontWeight(.semibold)

            Text("Quick notes from your menu bar")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Divider()
                .padding()

            Button(action: {
                onboardingManager.showOnboarding()
            }) {
                Text("Show Walkthrough")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 180, height: 32)
                    .background(CustomColors.actionPrimary)
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)

            Text("Look for the PerchNotes icon in your menu bar")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 320, height: 280)
        .padding()
    }
}
