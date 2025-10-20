import SwiftUI

@main
struct PerchNotesApp: App {
    @StateObject private var noteManager = NoteManager.shared
    @StateObject private var menuBarManager = MenuBarManager.shared

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }

    init() {
        // Enable menu bar on launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            MenuBarManager.shared.enableMenuBar()
        }
    }
}

// Temporary settings view
struct SettingsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "note.text")
                .font(.system(size: 48))
                .foregroundColor(.green)

            Text("PerchNotes")
                .font(.title)
                .fontWeight(.semibold)

            Text("Quick notes from your menu bar")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Divider()
                .padding()

            Text("Look for the 📝 icon in your menu bar")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 300, height: 250)
        .padding()
    }
}
