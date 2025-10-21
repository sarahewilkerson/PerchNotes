import SwiftUI

/// Interactive onboarding walkthrough inspired by Things3
struct OnboardingWalkthroughView: View {
    @Environment(\.dismiss) var dismiss
    @State private var expandedStep: Int? = 1  // Start with first step expanded
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
                            description: "Perch Notes lives in your menu bar for instant access anytime. See the little bird perched up there? Go ahead and give it a click!",
                            isCompleted: completedSteps.contains(1),
                            isExpanded: expandedStep == 1,
                            onToggle: { toggleStep(1) },
                            onComplete: { completeStep(1) }
                        )

                        WalkthroughStep(
                            stepNumber: 2,
                            title: "Pin or Unpin",
                            description: "Notice the **pin icon** is active at the top right? This keeps PerchNotes floating above other windows so you can work with notes alongside other apps.\n\nIt's pinned for this walkthrough, but you can unpin anytime by clicking the icon.",
                            isCompleted: completedSteps.contains(2),
                            isExpanded: expandedStep == 2,
                            onToggle: { toggleStep(2) },
                            onComplete: { completeStep(2) }
                        )

                        WalkthroughStep(
                            stepNumber: 3,
                            title: "Format your notes",
                            description: "PerchNotes always shows a clean, formatted view. You can:\n• Paste in markdown and see it formatted instantly\n• Use keyboard shortcuts (**Cmd+B** for bold, **Cmd+I** for italic, **Cmd+Opt+1** for headings)\n• Click formatting buttons in the toolbar\n• Or just type plain markdown syntax as you work. Go ahead and give it a try!",
                            isCompleted: completedSteps.contains(3),
                            isExpanded: expandedStep == 3,
                            onToggle: { toggleStep(3) },
                            onComplete: { completeStep(3) }
                        )

                        WalkthroughStep(
                            stepNumber: 4,
                            title: "Set one-click copy preferences",
                            description: "Use the toggle alongside the copy icon to copy your notes in different formats:\n• **Copy as Markdown** - preserves all formatting as markdown syntax\n• **Copy as Plain Text** - strips all formatting\n• **Copy as Rich Text** - keeps visual formatting for pasting into other apps. Click the toggle now to set your one-click copy default.",
                            isCompleted: completedSteps.contains(4),
                            isExpanded: expandedStep == 4,
                            onToggle: { toggleStep(4) },
                            onComplete: { completeStep(4) }
                        )

                        WalkthroughStep(
                            stepNumber: 5,
                            title: "Resize for your workflow",
                            description: "Use the size selector in the top right corner to adjust the notepad size between Compact, Default, Expanded, or Large.",
                            isCompleted: completedSteps.contains(5),
                            isExpanded: expandedStep == 5,
                            onToggle: { toggleStep(5) },
                            onComplete: { completeStep(5) }
                        )

                        WalkthroughStep(
                            stepNumber: 6,
                            title: "Save and organize in the library",
                            description: "Your notes autosave as you work, but when you finish a note, click **Save Note** to save it to your library and clear your notepad for fresh starts.\n\nOpen the library to organize with folders, tags, and categories.\n\n*Tip: This is a good time to try unpinning if you don't want the notepad and library to overlap!*",
                            isCompleted: completedSteps.contains(6),
                            isExpanded: expandedStep == 6,
                            onToggle: { toggleStep(6) },
                            onComplete: { completeStep(6) }
                        )

                        WalkthroughStep(
                            stepNumber: 7,
                            title: "Customize your experience",
                            description: "In the Library view, find **Preferences** at the bottom of the sidebar to:\n• Hide the dock icon for menu-bar-only mode\n• Access this walkthrough anytime.",
                            isCompleted: completedSteps.contains(7),
                            isExpanded: expandedStep == 7,
                            onToggle: { toggleStep(7) },
                            onComplete: { completeStep(7) }
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)

                    // Completion message
                    if completedSteps.count == 7 {
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
        }

        // Auto-expand the next step after a brief delay
        if step < 7 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedStep = step + 1
                }
            }
        } else {
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
            HStack(spacing: 12) {
                // Checkbox - clickable to complete
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
                .frame(width: 32, height: 32) // Larger tap area
                .contentShape(Rectangle()) // Make entire area tappable
                .onTapGesture {
                    if !isCompleted {
                        onComplete()
                    }
                }
                .help(isCompleted ? "Completed" : "Mark as complete")

                // Title - clickable to expand/collapse
                Button(action: onToggle) {
                    HStack(spacing: 8) {
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
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)

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
