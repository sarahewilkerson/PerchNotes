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
    @State private var selectedNote: Note?
    @State private var showingNoteDetail = false
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
        .sheet(isPresented: $showingNoteDetail) {
            if let note = selectedNote {
                NoteDetailView(note: note)
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
                                        selectedNote = note
                                        showingNoteDetail = true
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
    let note: Note
    @Environment(\.dismiss) var dismiss
    @ObservedObject var noteManager = NoteManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(note.smartTitle)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(CustomColors.contentPrimary)

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundColor(CustomColors.actionPrimary)
                .font(.system(size: 14))
            }
            .padding(20)
            .background(CustomColors.surfaceSecondary)

            Divider()
                .foregroundColor(Color(red: 230/255, green: 227/255, blue: 220/255))

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Metadata
                    HStack {
                        Label("Created: \(note.createdAt.formatted(date: .long, time: .shortened))", systemImage: "calendar")
                            .font(.system(size: 12))
                            .foregroundColor(CustomColors.contentSecondary)
                        Spacer()
                        Label("Updated: \(note.updatedAt.formatted(date: .long, time: .shortened))", systemImage: "clock")
                            .font(.system(size: 12))
                            .foregroundColor(CustomColors.contentSecondary)
                    }

                    Divider()
                        .foregroundColor(Color(red: 230/255, green: 227/255, blue: 220/255))

                    // Tags
                    if !note.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(CustomColors.contentPrimary)
                            HStack {
                                ForEach(note.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 11))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(CustomColors.actionPrimary.opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }

                    // Content
                    Text(note.content)
                        .font(.system(size: 14))
                        .foregroundColor(CustomColors.contentPrimary)
                        .textSelection(.enabled)
                }
                .padding(20)
            }
            .background(CustomColors.surfaceBase)
        }
        .background(CustomColors.surfaceBase)
        .frame(width: 600, height: 700)
    }
}
