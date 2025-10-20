import SwiftUI

/// Interactive onboarding walkthrough inspired by Things3
struct OnboardingWalkthroughView: View {
    @Environment(\.dismiss) var dismiss
    @State private var expandedStep: Int? = nil
    @State private var completedSteps: Set<Int> = []

    var onComplete: (() -> Void)?

    var body: some View {
        ZStack {
            // Background
            CustomColors.surfaceBase
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        Image("AppIconTransparent")
                            .resizable()
                            .frame(width: 64, height: 64)

                        Text("Welcome to PerchNotes")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.primary)

                        Text("Let's get you started with a quick tour. Complete each step to learn the basics.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 32)

                    // Steps
                    VStack(spacing: 16) {
                        WalkthroughStep(
                            stepNumber: 1,
                            title: "Try the quick notepad",
                            description: "PerchNotes lives in your menu bar for instant access. Click the menu bar icon to open your notepad anytime.",
                            isCompleted: completedSteps.contains(1),
                            isExpanded: expandedStep == 1,
                            onToggle: { toggleStep(1) },
                            onComplete: { completeStep(1) }
                        )

                        WalkthroughStep(
                            stepNumber: 2,
                            title: "Format your notes with Markdown",
                            description: "Use the formatting toolbar or keyboard shortcuts:\n• **Cmd+B** for bold\n• **Cmd+I** for italic\n• **Cmd+Opt+1** for H1 headings\n• **Cmd+Shift+L** for bullet lists",
                            isCompleted: completedSteps.contains(2),
                            isExpanded: expandedStep == 2,
                            onToggle: { toggleStep(2) },
                            onComplete: { completeStep(2) }
                        )

                        WalkthroughStep(
                            stepNumber: 3,
                            title: "Pin your notepad on top",
                            description: "Click the pin icon at the top right to keep PerchNotes floating above other windows. Perfect for working with notes alongside other apps.",
                            isCompleted: completedSteps.contains(3),
                            isExpanded: expandedStep == 3,
                            onToggle: { toggleStep(3) },
                            onComplete: { completeStep(3) }
                        )

                        WalkthroughStep(
                            stepNumber: 4,
                            title: "Save and organize in the library",
                            description: "Click **Save Note** to add your notes to the library. Open the library to organize with folders, tags, and categories.",
                            isCompleted: completedSteps.contains(4),
                            isExpanded: expandedStep == 4,
                            onToggle: { toggleStep(4) },
                            onComplete: { completeStep(4) }
                        )

                        WalkthroughStep(
                            stepNumber: 5,
                            title: "Resize for your workflow",
                            description: "Use the size selector in the top right to adjust the notepad size between Compact, Default, Expanded, or Large.",
                            isCompleted: completedSteps.contains(5),
                            isExpanded: expandedStep == 5,
                            onToggle: { toggleStep(5) },
                            onComplete: { completeStep(5) }
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)

                    // Completion message
                    if completedSteps.count == 5 {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(CustomColors.actionPrimary)

                            Text("You're all set!")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.primary)

                            Text("You can always access this guide from Help → Show Walkthrough.")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)

                            Button(action: {
                                onComplete?()
                                dismiss()
                            }) {
                                Text("Get Started")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 200, height: 36)
                                    .background(CustomColors.actionPrimary)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 8)
                        }
                        .padding(.vertical, 32)
                        .transition(.opacity.combined(with: .scale))
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .frame(width: 580, height: 720)
    }

    private func toggleStep(_ step: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedStep == step {
                expandedStep = nil
            } else {
                expandedStep = step
            }
        }
    }

    private func completeStep(_ step: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            completedSteps.insert(step)
            expandedStep = nil
        }
    }
}

/// Individual walkthrough step component
struct WalkthroughStep: View {
    let stepNumber: Int
    let title: String
    let description: String
    let isCompleted: Bool
    let isExpanded: Bool
    let onToggle: () -> Void
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Step header
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    // Checkbox
                    ZStack {
                        Circle()
                            .stroke(isCompleted ? CustomColors.actionPrimary : Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 20, height: 20)

                        if isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(CustomColors.actionPrimary)
                        }
                    }

                    // Title
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(isCompleted ? .secondary : .primary)
                        .strikethrough(isCompleted, color: .secondary)

                    Spacer()

                    // Info icon
                    if !isCompleted {
                        Image(systemName: isExpanded ? "chevron.down" : "info.circle")
                            .font(.system(size: 14))
                            .foregroundColor(CustomColors.actionPrimary.opacity(0.7))
                    }
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
            .buttonStyle(.plain)

            // Expanded description
            if isExpanded && !isCompleted {
                VStack(alignment: .leading, spacing: 16) {
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button(action: onComplete) {
                        Text("Got it!")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(CustomColors.actionPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(CustomColors.actionPrimary.opacity(0.1))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

#Preview {
    OnboardingWalkthroughView()
}
