import SwiftUI

struct NotesLibraryView: View {
    @ObservedObject var noteManager = NoteManager.shared

    @State private var searchText = ""
    @State private var selectedFolder: Folder?
    @State private var selectedCategory: Category?
    @State private var selectedTag: String?
    @State private var showingDateFilter = false
    @State private var createdAfter: Date?
    @State private var createdBefore: Date?
    @State private var updatedAfter: Date?
    @State private var updatedBefore: Date?
    @State private var showPinnedOnly = false
    @State private var noteToShow: Note?
    @State private var showingTrash = false

    private var filteredNotes: [Note] {
        let allNotes = showingTrash ? noteManager.trashedNotes : noteManager.activeNotes

        return allNotes.filter { note in
            // Search query
            if !searchText.isEmpty && !note.matches(searchText: searchText) {
                return false
            }

            // Folder filter
            if let folderID = selectedFolder?.id, note.folderID != folderID {
                return false
            }

            // Category filter
            if let categoryID = selectedCategory?.id, note.categoryID != categoryID {
                return false
            }

            // Tag filter
            if let tag = selectedTag, !note.hasTag(tag) {
                return false
            }

            // Date filters
            if let createdAfter = createdAfter, note.createdAt < createdAfter {
                return false
            }
            if let createdBefore = createdBefore, note.createdAt > createdBefore {
                return false
            }
            if let updatedAfter = updatedAfter, note.updatedAt < updatedAfter {
                return false
            }
            if let updatedBefore = updatedBefore, note.updatedAt > updatedBefore {
                return false
            }

            // Pinned filter
            if showPinnedOnly && !note.isPinned {
                return false
            }

            return true
        }
    }

    var body: some View {
        NavigationSplitView {
            // Sidebar
            sidebarView
                .background(CustomColors.surfaceSecondary)
        } detail: {
            // Main content
            notesListView
        }
        .background(CustomColors.surfaceBase)
        .searchable(text: $searchText, prompt: "Search notes...")
        .sheet(item: $noteToShow) { note in
            NoteDetailView(note: note)
                .onAppear {
                    print("🔍 Sheet appeared with note: \(note.smartTitle)")
                }
        }
    }

    private var sidebarView: some View {
        List {
            // Folders Section
            Section {
                Label("All Notes", systemImage: "square.grid.2x2")
                    .foregroundColor(CustomColors.contentPrimary)
                    .onTapGesture {
                        selectedFolder = nil
                    }

                ForEach(noteManager.subfolders(of: nil)) { folder in
                    FolderRow(folder: folder, isSelected: selectedFolder?.id == folder.id)
                        .onTapGesture {
                            selectedFolder = folder
                        }
                }

                Button(action: {
                    // Create new folder
                    let _ = noteManager.createFolder(name: "New Folder")
                }) {
                    Label("New Folder", systemImage: "folder.badge.plus")
                        .foregroundColor(CustomColors.contentSecondary)
                }
                .buttonStyle(.plain)
            } header: {
                Text("Folders")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(CustomColors.contentSecondary)
                    .textCase(.uppercase)
            }

            // Tags Section
            if !noteManager.allTags.isEmpty {
                Section {
                    Label("All Tags", systemImage: "number")
                        .foregroundColor(CustomColors.contentPrimary)
                        .onTapGesture {
                            selectedTag = nil
                        }

                    ForEach(noteManager.allTags, id: \.self) { tag in
                        HStack(spacing: 8) {
                            Image(systemName: "number.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(CustomColors.actionPrimary)
                            Text(tag)
                                .foregroundColor(CustomColors.contentPrimary)
                            Spacer()
                            Text("\(noteManager.notes(withTag: tag).count)")
                                .foregroundColor(CustomColors.contentSecondary)
                                .font(.system(size: 11))
                        }
                        .onTapGesture {
                            selectedTag = tag
                        }
                    }
                } header: {
                    Text("Tags")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(CustomColors.contentSecondary)
                        .textCase(.uppercase)
                }
            }

            // Categories Section
            if !noteManager.categories.isEmpty {
                Section {
                    ForEach(noteManager.categories) { category in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(category.color.color)
                                .frame(width: 10, height: 10)
                            Text(category.name)
                                .foregroundColor(CustomColors.contentPrimary)
                        }
                        .onTapGesture {
                            selectedCategory = category
                        }
                    }
                } header: {
                    Text("Categories")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(CustomColors.contentSecondary)
                        .textCase(.uppercase)
                }
            }

            // Trash Section
            Section {
                Button(action: {
                    showingTrash.toggle()
                    if showingTrash {
                        // Clear filters when viewing trash
                        selectedFolder = nil
                        selectedCategory = nil
                        selectedTag = nil
                    }
                }) {
                    HStack {
                        Label("Trash", systemImage: "trash")
                            .foregroundColor(showingTrash ? CustomColors.actionPrimary : CustomColors.contentPrimary)
                            .fontWeight(showingTrash ? .semibold : .regular)

                        Spacer()

                        Text("\(noteManager.trashedNotes.count)")
                            .foregroundColor(CustomColors.contentSecondary)
                            .font(.system(size: 11))
                    }
                }
                .buttonStyle(.plain)

                if showingTrash && !noteManager.trashedNotes.isEmpty {
                    Button(action: {
                        noteManager.emptyTrash()
                    }) {
                        Label("Empty Trash", systemImage: "trash.slash")
                            .foregroundColor(.red)
                            .font(.system(size: 13))
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("System")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(CustomColors.contentSecondary)
                    .textCase(.uppercase)
            }

            // Filters Section
            Section {
                Toggle(isOn: $showPinnedOnly) {
                    Label("Pinned Only", systemImage: "pin.fill")
                        .foregroundColor(CustomColors.contentPrimary)
                }
                .tint(CustomColors.actionPrimary)
                .disabled(showingTrash)

                Button(action: {
                    showingDateFilter.toggle()
                }) {
                    Label("Date Filters", systemImage: "calendar")
                        .foregroundColor(CustomColors.contentPrimary)
                }
                .buttonStyle(.plain)

                if showingDateFilter {
                    DateFilterView(
                        createdAfter: $createdAfter,
                        createdBefore: $createdBefore,
                        updatedAfter: $updatedAfter,
                        updatedBefore: $updatedBefore
                    )
                }
            } header: {
                Text("Filters")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(CustomColors.contentSecondary)
                    .textCase(.uppercase)
            }

            // Preferences Section
            Section {
                PreferencesSectionView()
            } header: {
                Text("Preferences")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(CustomColors.contentSecondary)
                    .textCase(.uppercase)
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(CustomColors.surfaceSecondary)
        .frame(minWidth: 200)
    }

    private var notesListView: some View {
        VStack(spacing: 0) {
            // Header - matching notepad style
            HStack(spacing: 12) {
                // App icon with transparency
                if let appIcon = NSImage(named: "AppIconTransparent") {
                    Image(nsImage: appIcon)
                        .resizable()
                        .antialiased(true)
                        .frame(width: 28, height: 28)
                }

                Text(showingTrash ? "Trash" : "PerchNotes Library")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(CustomColors.contentPrimary)

                Spacer()

                Text("\(filteredNotes.count) \(showingTrash ? "trashed" : "") note\(filteredNotes.count == 1 ? "" : "s")")
                    .font(.system(size: 13))
                    .foregroundColor(CustomColors.contentSecondary)

                if selectedFolder != nil || selectedCategory != nil || selectedTag != nil ||
                   createdAfter != nil || createdBefore != nil || updatedAfter != nil || updatedBefore != nil {
                    Button("Clear Filters") {
                        selectedFolder = nil
                        selectedCategory = nil
                        selectedTag = nil
                        createdAfter = nil
                        createdBefore = nil
                        updatedAfter = nil
                        updatedBefore = nil
                        showPinnedOnly = false
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(CustomColors.actionPrimary)
                    .font(.system(size: 13))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(CustomColors.surfaceBase)

            Divider()

            // Notes grid
            if filteredNotes.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 16)
                    ], spacing: 16) {
                        ForEach(filteredNotes) { note in
                            NoteCardView(note: note, showingTrash: showingTrash)
                                .onTapGesture {
                                    if !showingTrash {
                                        print("🔍 Note tapped: \(note.smartTitle)")
                                        print("🔍 Note ID: \(note.id)")
                                        print("🔍 Note content length: \(note.content.count)")
                                        noteToShow = note
                                        print("🔍 noteToShow set to: \(note.smartTitle)")
                                    }
                                }
                        }
                    }
                    .padding(20)
                }
                .background(CustomColors.surfaceBase)
            }
        }
        .background(CustomColors.surfaceBase)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: showingTrash ? "trash" : "doc.text")
                .font(.system(size: 60))
                .foregroundColor(CustomColors.contentSecondary)

            Text(showingTrash ? "Trash is empty" : "No notes found")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(CustomColors.contentPrimary)

            Text(showingTrash ? "Deleted notes will appear here" : "Try adjusting your search or filters")
                .font(.system(size: 14))
                .foregroundColor(CustomColors.contentSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CustomColors.surfaceBase)
    }
}

// MARK: - Folder Row

struct FolderRow: View {
    let folder: Folder
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: folder.icon)
                .font(.system(size: 13))
                .foregroundColor(isSelected ? CustomColors.actionPrimary : CustomColors.contentSecondary)
            Text(folder.name)
                .font(.system(size: 13))
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(CustomColors.contentPrimary)
        }
    }
}

// MARK: - Note Card View

struct NoteCardView: View {
    let note: Note
    let showingTrash: Bool
    @ObservedObject var noteManager = NoteManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(alignment: .top, spacing: 8) {
                if note.isPinned && !showingTrash {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 11))
                        .foregroundColor(CustomColors.actionPrimary)
                }

                Text(note.smartTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(showingTrash ? CustomColors.contentSecondary : CustomColors.contentPrimary)
                    .lineLimit(1)

                Spacer()

                if showingTrash {
                    // Show days remaining until auto-delete
                    if let deletedAt = note.deletedAt {
                        let daysSinceDeleted = Calendar.current.dateComponents([.day], from: deletedAt, to: Date()).day ?? 0
                        let daysRemaining = max(0, 30 - daysSinceDeleted)
                        Text("\(daysRemaining)d")
                            .font(.system(size: 11))
                            .foregroundColor(daysRemaining < 7 ? .red : CustomColors.contentSecondary)
                    }
                } else {
                    Text(note.createdAt, style: .date)
                        .font(.system(size: 11))
                        .foregroundColor(CustomColors.contentSecondary)
                }
            }

            // Content preview
            Text(note.preview)
                .font(.system(size: 13))
                .foregroundColor(CustomColors.contentSecondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            // Footer with tags, category, and actions
            HStack(alignment: .center, spacing: 8) {
                if showingTrash {
                    // Trash actions
                    HStack(spacing: 8) {
                        Button(action: {
                            noteManager.restoreFromTrash(note)
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.uturn.backward")
                                    .font(.system(size: 11))
                                Text("Restore")
                                    .font(.system(size: 11))
                            }
                            .foregroundColor(CustomColors.actionPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(CustomColors.actionPrimary.opacity(0.1))
                            .cornerRadius(4)
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            noteManager.permanentlyDelete(note)
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "trash.slash")
                                    .font(.system(size: 11))
                                Text("Delete Forever")
                                    .font(.system(size: 11))
                            }
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    // Tags
                    if !note.tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(note.tags.prefix(3), id: \.self) { tag in
                                Text(tag)
                                    .font(.system(size: 10))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(CustomColors.actionPrimary.opacity(0.2))
                                    .cornerRadius(4)
                            }
                            if note.tags.count > 3 {
                                Text("+\(note.tags.count - 3)")
                                    .font(.system(size: 10))
                                    .foregroundColor(CustomColors.contentSecondary)
                            }
                        }
                    }

                    Spacer()

                    // Delete button
                    Button(action: {
                        noteManager.moveToTrash(note)
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundColor(CustomColors.contentSecondary)
                    }
                    .buttonStyle(.plain)
                    .help("Move to trash")

                    // Category
                    if let category = noteManager.category(for: note) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(category.color.color)
                                .frame(width: 8, height: 8)
                            Text(category.name)
                                .font(.system(size: 11))
                                .foregroundColor(CustomColors.contentSecondary)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CustomColors.surfaceSecondary)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(red: 230/255, green: 227/255, blue: 220/255), lineWidth: 0.5)
        )
    }
}

// MARK: - Date Filter View

struct DateFilterView: View {
    @Binding var createdAfter: Date?
    @Binding var createdBefore: Date?
    @Binding var updatedAfter: Date?
    @Binding var updatedBefore: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Created").font(.caption).fontWeight(.semibold)

            HStack {
                Text("After:")
                    .font(.caption2)
                DatePicker("", selection: Binding(
                    get: { createdAfter ?? Date() },
                    set: { createdAfter = $0 }
                ), displayedComponents: .date)
                .labelsHidden()
                .disabled(createdAfter == nil)

                Button(createdAfter == nil ? "Set" : "Clear") {
                    if createdAfter == nil {
                        createdAfter = Date()
                    } else {
                        createdAfter = nil
                    }
                }
                .font(.caption2)
            }

            HStack {
                Text("Before:")
                    .font(.caption2)
                DatePicker("", selection: Binding(
                    get: { createdBefore ?? Date() },
                    set: { createdBefore = $0 }
                ), displayedComponents: .date)
                .labelsHidden()
                .disabled(createdBefore == nil)

                Button(createdBefore == nil ? "Set" : "Clear") {
                    if createdBefore == nil {
                        createdBefore = Date()
                    } else {
                        createdBefore = nil
                    }
                }
                .font(.caption2)
            }

            Divider()

            Text("Updated").font(.caption).fontWeight(.semibold)

            HStack {
                Text("After:")
                    .font(.caption2)
                DatePicker("", selection: Binding(
                    get: { updatedAfter ?? Date() },
                    set: { updatedAfter = $0 }
                ), displayedComponents: .date)
                .labelsHidden()
                .disabled(updatedAfter == nil)

                Button(updatedAfter == nil ? "Set" : "Clear") {
                    if updatedAfter == nil {
                        updatedAfter = Date()
                    } else {
                        updatedAfter = nil
                    }
                }
                .font(.caption2)
            }

            HStack {
                Text("Before:")
                    .font(.caption2)
                DatePicker("", selection: Binding(
                    get: { updatedBefore ?? Date() },
                    set: { updatedBefore = $0 }
                ), displayedComponents: .date)
                .labelsHidden()
                .disabled(updatedBefore == nil)

                Button(updatedBefore == nil ? "Set" : "Clear") {
                    if updatedBefore == nil {
                        updatedBefore = Date()
                    } else {
                        updatedBefore = nil
                    }
                }
                .font(.caption2)
            }
        }
        .padding(.leading, 16)
    }
}

// MARK: - Note Detail View

struct NoteDetailView: View {
    var note: Note
    @Environment(\.dismiss) var dismiss
    @ObservedObject var noteManager = NoteManager.shared
    @ObservedObject var appPreferences = AppPreferences.shared

    @State private var attributedText: NSAttributedString
    @State private var selectedRange = NSRange(location: 0, length: 0)
    @State private var textView: NSTextView?
    @State private var showFormattingToolbar = false
    @State private var noteTitle: String
    @State private var noteTags: [String]
    @State private var newTag = ""
    @State private var preferredCopyFormat: CopyFormat = .markdown

    enum CopyFormat: String, CaseIterable {
        case markdown = "Markdown"
        case plainText = "Plain Text"
        case richText = "Rich Text"
    }

    init(note: Note) {
        self.note = note
        _attributedText = State(initialValue: note.attributedContent)
        _noteTitle = State(initialValue: note.title)
        _noteTags = State(initialValue: note.tags)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                TextField("Note title (optional)", text: $noteTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                Button("Done") {
                    saveAndDismiss()
                }
                .buttonStyle(.plain)
                .foregroundColor(CustomColors.actionPrimary)
                .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(CustomColors.surfaceBase)

            Divider()

            // Formatting toolbar
            formattingToolbarView

            Divider()

            // Rich text editor
            RichTextEditor(
                attributedText: $attributedText,
                selectedRange: $selectedRange,
                placeholder: "Edit your note...",
                font: .systemFont(ofSize: 14),
                onTextChange: { _ in },
                onSelectionChange: { newRange in
                    selectedRange = newRange
                }
            )
            .background(
                RichTextViewExtractor(textView: $textView)
            )
            .background(CustomColors.surfaceBase)

            Divider()

            // Action bar
            actionBarView
        }
        .frame(width: 700, height: 800)
        .onAppear {
            // Load preferred copy format
            switch appPreferences.preferredCopyFormat {
            case "markdown": preferredCopyFormat = .markdown
            case "plainText": preferredCopyFormat = .plainText
            case "richText": preferredCopyFormat = .richText
            default: preferredCopyFormat = .markdown
            }
        }
    }

    private var formattingToolbarView: some View {
        HStack(alignment: .center, spacing: 0) {
            // Left side: Formatting toolbar controls
            if showFormattingToolbar {
                HStack(spacing: 0) {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showFormattingToolbar = false
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

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            toolbarSection {
                                formatButton(icon: "bold") { handleFormattingAction(.bold) }
                                formatButton(icon: "italic") { handleFormattingAction(.italic) }
                                formatButton(icon: "underline") { handleFormattingAction(.underline) }
                            }

                            Divider().frame(height: 20).padding(.horizontal, 8)

                            toolbarSection {
                                formatButton(text: "H1") { handleFormattingAction(.heading1) }
                                formatButton(text: "H2") { handleFormattingAction(.heading2) }
                                formatButton(text: "H3") { handleFormattingAction(.heading3) }
                            }

                            Divider().frame(height: 20).padding(.horizontal, 8)

                            toolbarSection {
                                formatButton(icon: "list.bullet") { handleFormattingAction(.bulletList) }
                                formatButton(icon: "list.number") { handleFormattingAction(.numberedList) }
                                formatButton(icon: "checklist") { handleFormattingAction(.checkbox) }
                            }

                            Divider().frame(height: 20).padding(.horizontal, 8)

                            toolbarSection {
                                formatButton(icon: "increase.indent") { handleFormattingAction(.indent) }
                                formatButton(icon: "decrease.indent") { handleFormattingAction(.outdent) }
                            }

                            Divider().frame(height: 20).padding(.horizontal, 8)

                            toolbarSection {
                                formatButton(icon: "link") { handleFormattingAction(.link) }
                                formatButton(icon: "minus") { handleFormattingAction(.horizontalRule) }
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                }
            } else {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showFormattingToolbar = true
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
                .help("Show Formatting Toolbar")
                .padding(.leading, 16)
            }

            Spacer()

            // Right side: Copy button
            Menu {
                Menu("Preferred Format") {
                    ForEach(CopyFormat.allCases, id: \.self) { format in
                        Button(action: {
                            preferredCopyFormat = format
                            appPreferences.preferredCopyFormat = format.rawValue.lowercased().replacingOccurrences(of: " ", with: "")
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
    }

    private var actionBarView: some View {
        HStack(spacing: 12) {
            // Character count
            Text("\(attributedText.string.count) chars")
                .font(.caption)
                .foregroundColor(CustomColors.contentTertiary)

            // Metadata
            Text("Created: \(note.createdAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundColor(CustomColors.contentTertiary)

            Text("Updated: \(note.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundColor(CustomColors.contentTertiary)

            Spacer()

            // Tags
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

            // Tag input
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
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(CustomColors.surfaceHighlight)
    }

    // Helper view to extract NSTextView reference
    private struct RichTextViewExtractor: NSViewRepresentable {
        @Binding var textView: NSTextView?

        func makeNSView(context: Context) -> NSView {
            let view = NSView()
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

    private func handleFormattingAction(_ action: FormattingAction) {
        guard let textView = textView else { return }
        let handler = RichTextFormattingHandler(textView: textView)
        handler.handle(action)
    }

    private func copyContent(as format: CopyFormat) {
        guard !attributedText.string.isEmpty else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch format {
        case .markdown:
            let markdown = NSAttributedStringMarkdownConverter.convertToMarkdown(attributedText)
            pasteboard.setString(markdown, forType: .string)
        case .plainText:
            pasteboard.setString(attributedText.string, forType: .string)
        case .richText:
            pasteboard.setString(attributedText.string, forType: .string)
            if let rtfData = try? attributedText.data(
                from: NSRange(location: 0, length: attributedText.length),
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

    private func saveAndDismiss() {
        // Convert attributed string to markdown
        var markdown = NSAttributedStringMarkdownConverter.convertToMarkdown(attributedText)

        // Prepend title as heading if provided and not already in content
        if !noteTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            markdown = "# \(noteTitle.trimmingCharacters(in: .whitespacesAndNewlines))\n\n\(markdown)"
        }

        // Create updated note
        var updatedNote = note
        updatedNote.title = noteTitle
        updatedNote.content = markdown
        updatedNote.tags = noteTags
        updatedNote.updatedAt = Date()

        // Update the note
        noteManager.updateNote(updatedNote)

        dismiss()
    }
}
