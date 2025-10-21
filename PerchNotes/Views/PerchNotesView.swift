import SwiftUI
import AppKit

struct PerchNotesView: View {
    @ObservedObject var noteManager = NoteManager.shared
    @ObservedObject var menuBarManager = MenuBarManager.shared
    @ObservedObject var appPreferences = AppPreferences.shared

    let onClose: () -> Void
    let onResizeRequest: (MenuBarManager.PopoverSize) -> Void

    @State private var selectedCategory: Category?
    @State private var selectedFolder: Folder?
    @State private var noteTags: [String] = []
    @State private var newTag: String = ""
    @State private var showingSuccessIndicator = false
    @State private var successMessage = ""
    @State private var attributedDraft = NSAttributedString(string: "")
    @State private var selectedRange = NSRange(location: 0, length: 0)
    @State private var textView: NSTextView?
    @State private var currentSize: MenuBarManager.PopoverSize = .default
    @State private var showFormattingToolbar = false
    @State private var showRecentNotes = false
    @State private var noteTitle: String = ""
    @FocusState private var isTextFieldFocused: Bool
    @FocusState private var isTitleFocused: Bool

    enum CopyFormat: String, CaseIterable {
        case markdown = "Markdown"
        case plainText = "Plain Text"
        case richText = "Rich Text"
    }

    @State private var preferredCopyFormat: CopyFormat = .markdown

    private let placeholderText = """
    Quick capture...

    • Ideas and notes
    • Tasks and reminders
    • Quick snippets

    ⌘+Enter to save
    """

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()
                .foregroundColor(CustomColors.borderSubtle)

            // Rich text capture area
            richTextCaptureArea

            // Recent notes drawer
            recentNotesDrawer

            Divider()
                .foregroundColor(CustomColors.borderSubtle)

            // Action bar
            actionBarView
        }
        .background(CustomColors.surfaceBase)
        .frame(
            width: currentSize.dimensions.width,
            height: currentSize.dimensions.height
        )
        .onAppear {
            isTextFieldFocused = true
            // Load any existing draft
            if !noteManager.draftContent.isEmpty {
                attributedDraft = noteManager.draftContent.toAttributedString()
            }
            // Set current size to match the preferred size
            currentSize = appPreferences.popoverSizeEnum
            // Load preferred copy format
            switch appPreferences.preferredCopyFormat {
            case "markdown": preferredCopyFormat = .markdown
            case "plainText": preferredCopyFormat = .plainText
            case "richText": preferredCopyFormat = .richText
            default: preferredCopyFormat = .markdown
            }
        }
        .onChange(of: preferredCopyFormat) { newFormat in
            // Sync to AppPreferences for persistence and auto-completion detection
            switch newFormat {
            case .markdown: appPreferences.preferredCopyFormat = "markdown"
            case .plainText: appPreferences.preferredCopyFormat = "plainText"
            case .richText: appPreferences.preferredCopyFormat = "richText"
            }
        }
        .background {
            // Hidden keyboard shortcut handlers
            Group {
                // Formatting shortcuts
                Button("") { handleFormattingAction(.bold) }
                    .keyboardShortcut("b", modifiers: .command)
                    .hidden()

                Button("") { handleFormattingAction(.italic) }
                    .keyboardShortcut("i", modifiers: .command)
                    .hidden()

                Button("") { handleFormattingAction(.underline) }
                    .keyboardShortcut("u", modifiers: .command)
                    .hidden()

                // Heading shortcuts
                Button("") { handleFormattingAction(.heading1) }
                    .keyboardShortcut("1", modifiers: [.command, .option])
                    .hidden()

                Button("") { handleFormattingAction(.heading2) }
                    .keyboardShortcut("2", modifiers: [.command, .option])
                    .hidden()

                Button("") { handleFormattingAction(.heading3) }
                    .keyboardShortcut("3", modifiers: [.command, .option])
                    .hidden()

                // List shortcuts
                Button("") { handleFormattingAction(.bulletList) }
                    .keyboardShortcut("l", modifiers: [.command, .shift])
                    .hidden()

                Button("") { handleFormattingAction(.numberedList) }
                    .keyboardShortcut("n", modifiers: [.command, .shift])
                    .hidden()

                Button("") { handleFormattingAction(.checkbox) }
                    .keyboardShortcut("c", modifiers: [.command, .shift])
                    .hidden()

                // Indentation shortcuts
                Button("") { handleFormattingAction(.indent) }
                    .keyboardShortcut("]", modifiers: .command)
                    .hidden()

                Button("") { handleFormattingAction(.outdent) }
                    .keyboardShortcut("[", modifiers: .command)
                    .hidden()

                // Special elements
                Button("") { handleFormattingAction(.link) }
                    .keyboardShortcut("k", modifiers: .command)
                    .hidden()

                Button("") { handleFormattingAction(.horizontalRule) }
                    .keyboardShortcut("r", modifiers: [.command, .shift])
                    .hidden()

                // Toggle formatting toolbar
                Button("") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showFormattingToolbar.toggle()
                        menuBarManager.isFormattingToolbarVisible = showFormattingToolbar
                    }
                }
                .keyboardShortcut("f", modifiers: [.command, .shift])
                .hidden()
            }
        }
    }

    private var headerView: some View {
        HStack(spacing: 12) {
            // Left side - App icon + Folder dropdown
            HStack(spacing: 8) {
                // App icon with transparency
                if let appIcon = NSImage(named: "AppIconTransparent") {
                    Image(nsImage: appIcon)
                        .resizable()
                        .antialiased(true)
                        .frame(width: 28, height: 28)
                } else {
                    Image(systemName: "note.text")
                        .font(.title3)
                        .foregroundColor(CustomColors.actionPrimary)
                }

                // Folder dropdown (folder/category selector)
                folderPickerMenu
            }

            Spacer()

            // Right side - Float on top toggle + Detach/Attach button + Size selector
            HStack(spacing: 12) {
                // Float on top button
                Button(action: {
                    menuBarManager.setFloatOnTop(!menuBarManager.floatOnTop)
                }) {
                    Image(systemName: menuBarManager.floatOnTop ? "pin.fill" : "pin.slash")
                        .font(.system(size: 13))
                        .foregroundColor(menuBarManager.floatOnTop ? CustomColors.actionPrimary : CustomColors.contentSecondary)
                }
                .buttonStyle(.plain)
                .help(menuBarManager.floatOnTop ? "Unpin from top" : "Pin on top of all windows")

                // Detach/Attach button
                Button(action: {
                    if menuBarManager.isDetached {
                        menuBarManager.attachNotepad()
                    } else {
                        menuBarManager.detachNotepad()
                    }
                }) {
                    Image(systemName: menuBarManager.isDetached ? "location.circle.fill" : "location.north.circle")
                        .font(.system(size: 13))
                        .foregroundColor(menuBarManager.isDetached ? CustomColors.actionPrimary : CustomColors.contentSecondary)
                }
                .buttonStyle(.plain)
                .help(menuBarManager.isDetached ? "Attach to menu bar" : "Detach from menu bar")

                // Size selector
                Menu {
                    Button(action: {
                        onResizeRequest(.compact)
                        currentSize = .compact
                        appPreferences.preferredPopoverSize = "compact"
                    }) {
                        HStack {
                            Text("Compact")
                            if appPreferences.preferredPopoverSize == "compact" {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }

                    Button(action: {
                        onResizeRequest(.default)
                        currentSize = .default
                        appPreferences.preferredPopoverSize = "default"
                    }) {
                        HStack {
                            Text("Default")
                            if appPreferences.preferredPopoverSize == "default" {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }

                    Button(action: {
                        onResizeRequest(.expanded)
                        currentSize = .expanded
                        appPreferences.preferredPopoverSize = "expanded"
                    }) {
                        HStack {
                            Text("Expanded")
                            if appPreferences.preferredPopoverSize == "expanded" {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }

                    Button(action: {
                        onResizeRequest(.large)
                        currentSize = .large
                        appPreferences.preferredPopoverSize = "large"
                    }) {
                        HStack {
                            Text("Large")
                            if appPreferences.preferredPopoverSize == "large" {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.caption2)
                        Text(currentSize.displayName)
                            .font(.system(size: 13))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9))
                    }
                    .foregroundColor(CustomColors.contentSecondary)
                }
                .buttonStyle(.plain)
                .help("Resize window (checkmark = default)")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(CustomColors.surfaceBase)
    }

    private var folderPickerMenu: some View {
        Menu {
            // Folder section
            if !noteManager.folders.isEmpty {
                Section("Folders") {
                    Button("No Folder") {
                        selectedFolder = nil
                    }

                    ForEach(noteManager.folders.filter { $0.parentFolderID == nil }) { folder in
                        Button(action: {
                            selectedFolder = folder
                        }) {
                            HStack {
                                Image(systemName: folder.icon)
                                Text(folder.name)
                                if selectedFolder?.id == folder.id {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }

            // Category section
            if !noteManager.categories.isEmpty {
                Section("Categories") {
                    Button("No Category") {
                        selectedCategory = nil
                    }

                    ForEach(noteManager.categories) { category in
                        Button(action: {
                            selectedCategory = category
                        }) {
                            HStack {
                                Circle()
                                    .fill(category.color.color)
                                    .frame(width: 8, height: 8)
                                Text(category.name)
                                if selectedCategory?.id == category.id {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "folder")
                    .font(.system(size: 14))

                // Show current selection or "Folder"
                Text(folderDisplayName)
                    .font(.system(size: 14))

                Image(systemName: "chevron.down")
                    .font(.system(size: 9))
            }
            .foregroundColor(CustomColors.contentPrimary)
        }
        .buttonStyle(.plain)
    }

    private var folderDisplayName: String {
        if let folder = selectedFolder {
            return folder.name
        } else if let category = selectedCategory {
            return category.name
        } else {
            return "Folder"
        }
    }

    private var categoryPickerMenu: some View {
        Menu {
            Button("No Category") {
                selectedCategory = nil
            }

            Divider()

            ForEach(noteManager.categories) { category in
                Button(action: {
                    selectedCategory = category
                }) {
                    HStack {
                        Circle()
                            .fill(category.color.color)
                            .frame(width: 8, height: 8)
                        Text(category.name)
                        if selectedCategory?.id == category.id {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                if let category = selectedCategory {
                    Circle()
                        .fill(category.color.color)
                        .frame(width: 8, height: 8)
                    Text(category.name)
                        .font(.caption)
                        .foregroundColor(CustomColors.contentSecondary)
                } else {
                    Image(systemName: "folder")
                        .font(.caption)
                        .foregroundColor(CustomColors.contentSecondary)
                    Text("Category")
                        .font(.caption)
                        .foregroundColor(CustomColors.contentSecondary)
                }
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundColor(CustomColors.contentTertiary)
            }
        }
        .buttonStyle(.plain)
    }

    private var folder2PickerMenu: some View {
        Menu {
            Button("No Folder") {
                selectedFolder = nil
            }

            Divider()

            ForEach(noteManager.folders.filter { $0.parentFolderID == nil }) { folder in
                Button(action: {
                    selectedFolder = folder
                }) {
                    HStack {
                        Image(systemName: folder.icon)
                        Text(folder.name)
                        if selectedFolder?.id == folder.id {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                if let folder = selectedFolder {
                    Image(systemName: folder.icon)
                        .font(.caption)
                        .foregroundColor(CustomColors.contentSecondary)
                    Text(folder.name)
                        .font(.caption)
                        .foregroundColor(CustomColors.contentSecondary)
                } else {
                    Image(systemName: "folder")
                        .font(.caption)
                        .foregroundColor(CustomColors.contentSecondary)
                    Text("Folder")
                        .font(.caption)
                        .foregroundColor(CustomColors.contentSecondary)
                }
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundColor(CustomColors.contentTertiary)
            }
        }
        .buttonStyle(.plain)
    }

    private var richTextCaptureArea: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                // Left side: Formatting toolbar controls
                if showFormattingToolbar {
                    // Expanded: Show collapse button and scrollable toolbar
                    HStack(spacing: 0) {
                        // Collapse button
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showFormattingToolbar = false
                                menuBarManager.isFormattingToolbarVisible = false
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(.plain)
                        .help("Hide Formatting Toolbar")
                        .padding(.leading, 16)

                        // Scrollable formatting toolbar
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 0) {
                                // Text Formatting
                                toolbarSection {
                                    formatButton(icon: "bold") { handleFormattingAction(.bold) }
                                    formatButton(icon: "italic") { handleFormattingAction(.italic) }
                                    formatButton(icon: "underline") { handleFormattingAction(.underline) }
                                }

                                Divider().frame(height: 20).padding(.horizontal, 8)

                                // Headings
                                toolbarSection {
                                    formatButton(text: "H1") { handleFormattingAction(.heading1) }
                                    formatButton(text: "H2") { handleFormattingAction(.heading2) }
                                    formatButton(text: "H3") { handleFormattingAction(.heading3) }
                                }

                                Divider().frame(height: 20).padding(.horizontal, 8)

                                // Lists
                                toolbarSection {
                                    formatButton(icon: "list.bullet") { handleFormattingAction(.bulletList) }
                                    formatButton(icon: "list.number") { handleFormattingAction(.numberedList) }
                                    formatButton(icon: "checklist") { handleFormattingAction(.checkbox) }
                                }

                                Divider().frame(height: 20).padding(.horizontal, 8)

                                // Indentation
                                toolbarSection {
                                    formatButton(icon: "increase.indent") { handleFormattingAction(.indent) }
                                    formatButton(icon: "decrease.indent") { handleFormattingAction(.outdent) }
                                }

                                Divider().frame(height: 20).padding(.horizontal, 8)

                                // Special Elements
                                toolbarSection {
                                    formatButton(icon: "link") { handleFormattingAction(.link) }
                                    formatButton(icon: "minus") { handleFormattingAction(.horizontalRule) }
                                }
                            }
                            .padding(.horizontal, 8)
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                } else {
                    // Collapsed: Show Aa > button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showFormattingToolbar = true
                            menuBarManager.isFormattingToolbarVisible = true
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text("Aa")
                                .font(.system(size: 13, weight: .semibold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9))
                        }
                        .foregroundColor(CustomColors.actionPrimary)
                    }
                    .buttonStyle(.plain)
                    .help("Show Formatting Toolbar (⌘⇧F)")
                    .padding(.leading, 16)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }

                Spacer()

                // Right side: Copy button
                Menu {
                    Menu("Preferred Format") {
                        ForEach(CopyFormat.allCases, id: \.self) { format in
                            Button(action: {
                                preferredCopyFormat = format
                            }) {
                                HStack {
                                    Text(format.rawValue)
                                    if preferredCopyFormat == format {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }

                    Divider()

                    Button("Copy as Markdown") {
                        copyContent(as: .markdown)
                    }
                    Button("Copy as Plain Text") {
                        copyContent(as: .plainText)
                    }
                    Button("Copy as Rich Text") {
                        copyContent(as: .richText)
                    }
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 14))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
                } primaryAction: {
                    copyContent(as: preferredCopyFormat)
                }
                .fixedSize()
                .menuStyle(.borderlessButton)
                .buttonStyle(.plain)
                .help("Copy (\(preferredCopyFormat.rawValue))")
                .padding(.trailing, 16)
            }
            .frame(height: 44)
            .background(CustomColors.surfaceBase)

            RichTextEditor(
                attributedText: $attributedDraft,
                selectedRange: $selectedRange,
                placeholder: placeholderText,
                font: .systemFont(ofSize: 14),
                onTextChange: { newText in
                    // Auto-save draft
                    noteManager.saveDraft(newText.string)
                },
                onSelectionChange: { newRange in
                    selectedRange = newRange
                }
            )
            .frame(minHeight: 140, maxHeight: .infinity)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .background(
                RichTextViewExtractor(textView: $textView)
            )
        }
        .background(CustomColors.surfaceBase)
    }

    private var recentNotesDrawer: some View {
        VStack(spacing: 0) {
            // Drawer handle/toggle
            HStack(spacing: 0) {
                // Recent Notes toggle button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showRecentNotes.toggle()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: showRecentNotes ? "chevron.down" : "chevron.up")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text("Recent Notes")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(CustomColors.contentSecondary)

                        Text("(\(min(noteManager.activeNotes.count, 20)))")
                            .font(.caption)
                            .foregroundColor(CustomColors.contentTertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Spacer()

                // Library button (opens library window)
                Button(action: {
                    MenuBarManager.shared.openLibraryWindow()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.grid.2x2")
                            .font(.caption)
                        Text("Library")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(CustomColors.actionPrimary)
                }
                .buttonStyle(.plain)
                .help("Open Notes Library")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(CustomColors.surfaceSecondary)

            // Drawer content - carousel of recent notes
            if showRecentNotes {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(noteManager.activeNotes.prefix(20))) { note in
                            RecentNoteCard(note: note) {
                                // Copy note content to capture area
                                attributedDraft = note.attributedContent
                                selectedCategory = noteManager.category(for: note)

                                // Close drawer
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showRecentNotes = false
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .frame(height: 120)
                .background(CustomColors.surfaceBase)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // Helper view to extract NSTextView reference
    private struct RichTextViewExtractor: NSViewRepresentable {
        @Binding var textView: NSTextView?

        func makeNSView(context: Context) -> NSView {
            let view = NSView()

            // Multiple attempts to find the text view
            DispatchQueue.main.async {
                self.attemptToFindTextView(from: view)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if self.textView == nil {
                    self.attemptToFindTextView(from: view)
                }
            }

            return view
        }

        func updateNSView(_ nsView: NSView, context: Context) {}

        private func attemptToFindTextView(from view: NSView) {
            var currentView: NSView? = view.superview
            var depth = 0
            let maxDepth = 20

            while currentView != nil && depth < maxDepth {
                if let scrollView = currentView as? NSScrollView,
                   let foundTextView = scrollView.documentView as? NSTextView {
                    self.textView = foundTextView
                    return
                }
                currentView = currentView?.superview
                depth += 1
            }

            if let window = view.window {
                findTextViewInView(window.contentView)
            }
        }

        private func findTextViewInView(_ view: NSView?) {
            guard let view = view else { return }

            if let scrollView = view as? NSScrollView,
               let foundTextView = scrollView.documentView as? NSTextView {
                self.textView = foundTextView
                return
            }

            for subview in view.subviews {
                findTextViewInView(subview)
                if textView != nil { return }
            }
        }
    }

    private var actionBarView: some View {
        HStack {
            // Character count
            Text("\(attributedDraft.string.count) chars")
                .font(.caption)
                .foregroundColor(CustomColors.contentTertiary)

            // Success feedback
            if showingSuccessIndicator {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(CustomColors.feedbackSuccess)
                    Text(successMessage)
                        .font(.caption)
                        .foregroundColor(CustomColors.feedbackSuccess)
                }
                .transition(.opacity.combined(with: .scale))
            }

            Spacer()

            // Tags display and input
            if !noteTags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(noteTags, id: \.self) { tag in
                        HStack(spacing: 2) {
                            Text(tag)
                                .font(.caption2)
                                .foregroundColor(CustomColors.contentPrimary)
                            Button(action: {
                                noteTags.removeAll { $0 == tag }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(CustomColors.actionPrimary.opacity(0.2))
                        .cornerRadius(4)
                    }
                }
            }

            // Tag input field
            HStack(spacing: 4) {
                Image(systemName: "tag")
                    .font(.caption2)
                    .foregroundColor(CustomColors.contentSecondary)
                TextField("Tag", text: $newTag)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .frame(width: 60)
                    .onSubmit {
                        addTag()
                    }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(4)

            // Optional title field
            TextField("Title (optional)", text: $noteTitle)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($isTitleFocused)
                .frame(width: 120)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .cornerRadius(4)

            if !noteTitle.isEmpty {
                Button(action: {
                    noteTitle = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            Button("Clear") {
                attributedDraft = NSAttributedString(string: "")
                noteTitle = ""
                noteManager.clearDraft()
            }
            .font(.caption)
            .foregroundColor(CustomColors.contentSecondary)
            .buttonStyle(.plain)
            .disabled(attributedDraft.string.isEmpty && noteTitle.isEmpty)

            Button("Save") {
                saveNote()
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(CustomColors.actionPrimaryText)
            .disabled(attributedDraft.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(attributedDraft.string.isEmpty ? Color.gray : CustomColors.actionPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .buttonStyle(.plain)
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(CustomColors.surfaceHighlight)
    }

    private func handleFormattingAction(_ action: FormattingAction) {
        guard let textView = textView else { return }
        let handler = RichTextFormattingHandler(textView: textView)
        handler.handle(action)
    }

    // MARK: - Toolbar Helpers

    @ViewBuilder
    private func toolbarSection<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 4) {
            content()
        }
    }

    private func formatButton(icon: String? = nil, text: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Group {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 13))
                } else if let text = text {
                    Text(text)
                        .font(.system(size: 11, weight: .medium))
                }
            }
            .foregroundColor(.secondary)
            .frame(width: 28, height: 28)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func copyContent(as format: CopyFormat) {
        guard !attributedDraft.string.isEmpty else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch format {
        case .markdown:
            let markdown = NSAttributedStringMarkdownConverter.convertToMarkdown(attributedDraft)
            pasteboard.setString(markdown, forType: .string)
        case .plainText:
            pasteboard.setString(attributedDraft.string, forType: .string)
        case .richText:
            pasteboard.setString(attributedDraft.string, forType: .string)
            if let rtfData = try? attributedDraft.data(
                from: NSRange(location: 0, length: attributedDraft.length),
                documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
            ) {
                pasteboard.setData(rtfData, forType: .rtf)
            }
        }
    }

    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty else { return }
        guard !noteTags.contains(trimmedTag) else {
            newTag = ""
            return
        }

        noteTags.append(trimmedTag)
        newTag = ""
    }

    private func saveNote() {
        let trimmedText = attributedDraft.string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        // Convert attributed string to markdown for storage
        var markdown = NSAttributedStringMarkdownConverter.convertToMarkdown(attributedDraft)

        // Prepend title as heading if provided
        if !noteTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            markdown = "# \(noteTitle.trimmingCharacters(in: .whitespacesAndNewlines))\n\n\(markdown)"
        }

        // Create note
        let _ = noteManager.createNote(
            title: noteTitle,
            content: markdown,
            categoryID: selectedCategory?.id,
            folderID: selectedFolder?.id,
            tags: noteTags
        )

        // Clear the capture area, title, and tags
        attributedDraft = NSAttributedString(string: "")
        noteTitle = ""
        noteTags = []
        noteManager.clearDraft()

        // Show success feedback
        showSaveSuccess()

        // Keep focus for next capture
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isTextFieldFocused = true
        }
    }

    private func showSaveSuccess() {
        successMessage = "✅ Saved!"

        withAnimation(.easeInOut(duration: 0.4)) {
            showingSuccessIndicator = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.showingSuccessIndicator = false
            }
        }
    }
}

// MARK: - Recent Note Card

struct RecentNoteCard: View {
    let note: Note
    let onTap: () -> Void
    @ObservedObject var noteManager = NoteManager.shared

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack(spacing: 6) {
                    Image(systemName: "note.text")
                        .font(.caption2)
                        .foregroundColor(CustomColors.actionPrimary)

                    Text(note.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(CustomColors.contentTertiary)
                }

                // Content preview
                Text(note.content.prefix(80))
                    .font(.caption)
                    .foregroundColor(CustomColors.contentPrimary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                // Category badge
                if let category = noteManager.category(for: note) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(category.color.color)
                            .frame(width: 6, height: 6)
                        Text(category.name)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(CustomColors.contentSecondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(4)
                }
            }
            .padding(12)
            .frame(width: 180, height: 100)
            .background(CustomColors.surfaceSecondary)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(CustomColors.borderSubtle, lineWidth: 1)
            )
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .help("Tap to edit this note")
    }
}
