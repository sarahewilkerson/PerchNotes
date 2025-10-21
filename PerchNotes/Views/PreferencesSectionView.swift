import SwiftUI

/// Preferences section for the library sidebar
struct PreferencesSectionView: View {
    @ObservedObject private var appPreferences = AppPreferences.shared
    @ObservedObject private var onboardingManager = OnboardingManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Hide Dock Icon toggle
            Toggle(isOn: $appPreferences.hideDockIcon) {
                Label("Hide Dock Icon", systemImage: "dock.rectangle")
                    .foregroundColor(CustomColors.contentPrimary)
                    .font(.system(size: 13))
            }
            .tint(CustomColors.actionPrimary)
            .help("Show only in menu bar, hide dock icon")

            Divider()
                .padding(.vertical, 8)

            // Show Walkthrough button
            Button(action: {
                onboardingManager.showOnboarding()
            }) {
                Label("Show Walkthrough", systemImage: "questionmark.circle")
                    .foregroundColor(CustomColors.actionPrimary)
                    .font(.system(size: 13))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .help("View the onboarding walkthrough again")
        }
    }
}

#Preview {
    PreferencesSectionView()
        .padding()
}
