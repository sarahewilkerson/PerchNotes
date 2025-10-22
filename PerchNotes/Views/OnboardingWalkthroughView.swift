import SwiftUI

/// Interactive onboarding walkthrough inspired by Things3
struct OnboardingWalkthroughView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var menuBarManager = MenuBarManager.shared
    @ObservedObject var noteManager = NoteManager.shared
    @ObservedObject var appPreferences = AppPreferences.shared

    @State private var expandedStep: Int? = 1  // Start with first step expanded
    @State private var completedSteps: Set<Int> = []
    @State private var initialNoteCount = 0
    @State private var hasOpenedLibrary = false
    @State private var scrollToStep: Int? = nil  // Track which step to scroll to

    var onComplete: (() -> Void)?

    private let totalSteps = 9

    var body: some View {
        ZStack {
            // Background
            CustomColors.surfaceBase
                .ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: true) {
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
                                title: "Open your notepad",
                                description: "PerchNotes lives in your menu bar—always there when you need it.\n\n**Try it:** Click the bird icon in your menu bar to open your notepad.",
                                icon: "BirdIconGreen",
                                iconIsAsset: true,
                                isCompleted: completedSteps.contains(1),
                                isExpanded: expandedStep == 1,
                                onToggle: { toggleStep(1) },
                                onComplete: { completeStep(1) }
                            )
                            .id("step-1")

                            WalkthroughStep(
                                stepNumber: 2,
                                title: "Pin it in place",
                                description: "See the pin icon in the top right? It keeps PerchNotes floating above your other windows so you can reference notes while you work.\n\n**Try it:** Click the pin to unpin it. (We'll automatically re-pin it for the next step.)",
                                icon: "pin.fill",
                                isCompleted: completedSteps.contains(2),
                                isExpanded: expandedStep == 2,
                                onToggle: { toggleStep(2) },
                                onComplete: { completeStep(2) }
                            )
                            .id("step-2")

                            WalkthroughStep(
                                stepNumber: 3,
                                title: "Format as you write",
                                description: "Your notes always appear clean and formatted. You can:\n\n• Paste markdown and see it rendered instantly\n• Use shortcuts like **Cmd+B** for bold or **Cmd+I** for italic\n• Click the formatting toolbar buttons\n• Type markdown syntax directly\n\n**Try it:** Click the **Aa >** button to open the formatting toolbar.",
                                icon: "textformat",
                                isCompleted: completedSteps.contains(3),
                                isExpanded: expandedStep == 3,
                                onToggle: { toggleStep(3) },
                                onComplete: { completeStep(3) }
                            )
                            .id("step-3")

                            WalkthroughStep(
                                stepNumber: 4,
                                title: "Copy in your preferred format",
                                description: "The copy button gives you three options:\n\n• **Markdown** – preserves formatting as markdown syntax\n• **Plain Text** – strips all formatting\n• **Rich Text** – keeps visual formatting for other apps\n\n**Try it:** Click the dropdown next to the copy icon to choose your default.",
                                icon: "doc.on.doc",
                                isCompleted: completedSteps.contains(4),
                                isExpanded: expandedStep == 4,
                                onToggle: { toggleStep(4) },
                                onComplete: { completeStep(4) }
                            )
                            .id("step-4")

                            WalkthroughStep(
                                stepNumber: 5,
                                title: "Resize to fit your workflow",
                                description: "Choose from Compact, Default, Expanded, or Large to match how you work.\n\n*Tip: Large gives you a full-height side panel—perfect for working alongside other apps.*\n\n**Try it:** Click the size selector in the top right and try a different size.",
                                icon: "arrow.up.left.and.arrow.down.right",
                                isCompleted: completedSteps.contains(5),
                                isExpanded: expandedStep == 5,
                                onToggle: { toggleStep(5) },
                                onComplete: { completeStep(5) }
                            )
                            .id("step-5")

                            WalkthroughStep(
                                stepNumber: 6,
                                title: "Move it anywhere",
                                description: "Detach your notepad from the menu bar to position it anywhere on screen. PerchNotes will remember where you put it.\n\n**Try it:** Click the location icon to detach the notepad and move it around.",
                                icon: "location.circle",
                                isCompleted: completedSteps.contains(6),
                                isExpanded: expandedStep == 6,
                                onToggle: { toggleStep(6) },
                                onComplete: { completeStep(6) }
                            )
                            .id("step-6")

                            WalkthroughStep(
                                stepNumber: 7,
                                title: "Save to your library",
                                description: "Your notepad autosaves as you type. When you're done with a note, save it to your library where you can organize with folders, tags, and categories.\n\n**Try it:** Click **Save**, then open the **Library** to see your saved notes.",
                                icon: "square.grid.2x2",
                                isCompleted: completedSteps.contains(7),
                                isExpanded: expandedStep == 7,
                                onToggle: { toggleStep(7) },
                                onComplete: { completeStep(7) }
                            )
                            .id("step-7")

                            WalkthroughStep(
                                stepNumber: 8,
                                title: "Notes go to trash first",
                                description: "Deleted notes move to **Trash** where they stay for 30 days before auto-deleting. You can restore them anytime during that window.\n\nYou'll find Trash in the Library sidebar under System.\n\n**Try it:** Click **Got it!** when you're ready to continue.",
                                icon: "trash",
                                isCompleted: completedSteps.contains(8),
                                isExpanded: expandedStep == 8,
                                onToggle: { toggleStep(8) },
                                onComplete: { completeStep(8) }
                            )
                            .id("step-8")

                            WalkthroughStep(
                                stepNumber: 9,
                                title: "Make it yours",
                                description: "Open **Preferences** in the Library to customize PerchNotes:\n\n• Hide the dock icon to stay menu-bar-only\n• Set your default notepad size\n• Return to this walkthrough anytime\n\n**Try it:** Click **Got it!** to finish and start using PerchNotes.",
                                icon: "gearshape",
                                isCompleted: completedSteps.contains(9),
                                isExpanded: expandedStep == 9,
                                onToggle: { toggleStep(9) },
                                onComplete: { completeStep(9) }
                            )
                            .id("step-9")
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)

                        // Completion message
                        if completedSteps.count == totalSteps {
                            VStack(spacing: 16) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(CustomColors.actionPrimary)

                                Text("You're all set!")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.primary)

                                Text("Access this guide anytime from Help → Show Walkthrough.")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                
                            Button(action: {
                                // Unpin the notepad before opening
                                menuBarManager.setFloatOnTop(false)

                                // Open the notepad
                                if !menuBarManager.isPopoverVisible {
                                    menuBarManager.togglePopover()
                                }

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
                .padding(.bottom, 100)
                }
                .onChange(of: scrollToStep) { step in
                    print("🔴 onChange triggered, scrollToStep: \(step ?? -1)")
                    guard let step = step else { return }

                    print("🟣 Scrolling to ID: step-\(step)")

                    // Smooth, visible scroll animation
                    // Use .center for better visibility, especially for later steps
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo("step-\(step)", anchor: .center)
                    }

                    print("✅ Scroll animation started for step-\(step)")

                    // Reset after scroll completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        scrollToStep = nil
                    }
                }
            }
        }
        .frame(width: 580, height: 720)
        .onAppear {
            initialNoteCount = noteManager.activeNotes.count
            // Scroll to first step on appear
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                scrollToStep = 1
            }
        }
        // Auto-completion observers
        .onChange(of: menuBarManager.isPopoverVisible) { newValue in
            // Step 1: Try the quick notepad
            if newValue && !completedSteps.contains(1) {
                completeStep(1)
            }
        }
        .onChange(of: menuBarManager.floatOnTop) { newValue in
            // Step 2: Pin or Unpin - complete if they unpin
            if !newValue && !completedSteps.contains(2) {
                completeStep(2)
                // Re-pin after a brief delay for step 3
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    menuBarManager.setFloatOnTop(true)
                }
            }
        }
        .onChange(of: menuBarManager.isFormattingToolbarVisible) { newValue in
            // Step 3: Format your notes - complete when they expand the toolbar
            if newValue && !completedSteps.contains(3) {
                completeStep(3)
            }
        }
        .onChange(of: appPreferences.preferredCopyFormat) { _ in
            // Step 4: Set one-click copy preferences
            if !completedSteps.contains(4) {
                completeStep(4)
            }
        }
        .onChange(of: menuBarManager.popoverSize) { _ in
            // Step 5: Resize for your workflow
            if !completedSteps.contains(5) {
                completeStep(5)
            }
        }
        .onChange(of: menuBarManager.isDetached) { newValue in
            // Step 6: Detach and move the notepad
            if newValue && !completedSteps.contains(6) {
                completeStep(6)
            }
        }
        .onChange(of: noteManager.activeNotes.count) { newValue in
            // Step 7: Save and organize - detect when a new note is saved
            if newValue > initialNoteCount && !completedSteps.contains(7) {
                completeStep(7)
            }
        }
    }

    private func toggleStep(_ step: Int) {
        print("🔵 toggleStep called for step \(step), expandedStep: \(expandedStep ?? -1)")
        if expandedStep == step {
            // Collapse current step
            withAnimation(.easeInOut(duration: 0.3)) {
                expandedStep = nil
            }
        } else {
            // Step 1: Close current step
            if expandedStep != nil {
                withAnimation(.easeInOut(duration: 0.25)) {
                    expandedStep = nil
                }
                // Step 2: Wait, then scroll
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    print("🟢 Setting scrollToStep to \(step)")
                    scrollToStep = step

                    // Step 3: Wait for scroll, then expand
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            expandedStep = step
                        }
                    }
                }
            } else {
                // No step open, just scroll then expand
                print("🟢 Setting scrollToStep to \(step)")
                scrollToStep = step
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        expandedStep = step
                    }
                }
            }
        }
    }

    private func completeStep(_ step: Int) {
        print("⭐ completeStep called for step \(step)")

        // Mark as completed
        completedSteps.insert(step)

        // Move to next step if not at end
        if step < totalSteps {
            // Step 1: Close current step
            withAnimation(.easeInOut(duration: 0.25)) {
                expandedStep = nil
            }

            // Step 2: Wait, then scroll to next
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                print("🟢 completeStep setting scrollToStep to \(step + 1)")
                scrollToStep = step + 1

                // Step 3: Wait for scroll, then expand next step
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        expandedStep = step + 1
                    }
                }
            }
        } else {
            // Last step completed, close it
            withAnimation(.easeInOut(duration: 0.25)) {
                expandedStep = nil
            }
        }
    }
}

/// Individual walkthrough step component
struct WalkthroughStep: View {
    let stepNumber: Int
    let title: String
    let description: String
    let icon: String
    let iconIsAsset: Bool // true if using Assets.xcassets, false if SF Symbol
    let isCompleted: Bool
    let isExpanded: Bool
    let onToggle: () -> Void
    let onComplete: () -> Void

    init(stepNumber: Int, title: String, description: String, icon: String, iconIsAsset: Bool = false, isCompleted: Bool, isExpanded: Bool, onToggle: @escaping () -> Void, onComplete: @escaping () -> Void) {
        self.stepNumber = stepNumber
        self.title = title
        self.description = description
        self.icon = icon
        self.iconIsAsset = iconIsAsset
        self.isCompleted = isCompleted
        self.isExpanded = isExpanded
        self.onToggle = onToggle
        self.onComplete = onComplete
    }

    var body: some View {
        VStack(spacing: 0) {
            // Step header
            HStack(spacing: 12) {
                // Icon indicator
                if iconIsAsset {
                    if let nsImage = NSImage(named: icon) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .opacity(isCompleted ? 1.0 : 0.7)
                    }
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(isCompleted ? CustomColors.actionPrimary : CustomColors.actionPrimary.opacity(0.6))
                }

                Spacer()
                    .frame(width: 8)

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
                    // Parse description into main text and "Try it" section
                    let components = parseDescription(description)

                    // Main description
                    if let mainText = components.main {
                        Text(.init(mainText))
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // "Try it" call-to-action box
                    if let tryItText = components.tryIt {
                        VStack(alignment: .center, spacing: 12) {
                            Text("TRY IT")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(CustomColors.actionPrimary)
                                .tracking(1.2)

                            Text(.init(tryItText))
                                .font(.system(size: 14))
                                .foregroundColor(CustomColors.actionPrimary.opacity(0.9))
                                .lineSpacing(3)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)

                            Button(action: onComplete) {
                                Text("GOT IT")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                                    .tracking(0.5)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 10)
                                    .background(CustomColors.actionPrimary)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(CustomColors.actionPrimary.opacity(0.08))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(CustomColors.actionPrimary.opacity(0.2), lineWidth: 1)
                        )
                    } else {
                        // No "Try it" section, show regular button
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
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                .padding(.top, 4)
                .transition(.opacity)
            }
        }
    }

    private func parseDescription(_ text: String) -> (main: String?, tryIt: String?) {
        // Split on "**Try it:**" or variations
        let patterns = ["**Try it:**", "**Try it**:", "Try it:"]

        for pattern in patterns {
            if let range = text.range(of: pattern, options: .caseInsensitive) {
                let mainText = String(text[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                let tryItText = String(text[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)

                return (
                    main: mainText.isEmpty ? nil : mainText,
                    tryIt: tryItText.isEmpty ? nil : tryItText
                )
            }
        }

        // No "Try it" section found
        return (main: text, tryIt: nil)
    }
}

#Preview {
    OnboardingWalkthroughView()
}
