import Foundation
import Combine
import SwiftUI

@MainActor
class NoteManager: ObservableObject {
    static let shared = NoteManager()

    @Published var notes: [Note] = []
    @Published var categories: [Category] = []
    @Published var folders: [Folder] = []
    @Published var draftContent: String = "" // For auto-save

    private let notesFileURL: URL
    private let categoriesFileURL: URL
    private let foldersFileURL: URL
    private let draftFileURL: URL

    private init() {
        // Set up file URLs in Application Support
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("PerchNotes", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)

        self.notesFileURL = appFolder.appendingPathComponent("notes.json")
        self.categoriesFileURL = appFolder.appendingPathComponent("categories.json")
        self.foldersFileURL = appFolder.appendingPathComponent("folders.json")
        self.draftFileURL = appFolder.appendingPathComponent("draft.txt")

        // Load data
        loadNotes()
        loadCategories()
        loadFolders()
        loadDraft()
    }

    // MARK: - Notes Management

    func createNote(
        title: String = "",
        content: String,
        categoryID: UUID? = nil,
        folderID: UUID? = nil,
        tags: [String] = []
    ) -> Note {
        let note = Note(
            title: title,
            content: content,
            categoryID: categoryID,
            folderID: folderID,
            tags: tags
        )
        notes.insert(note, at: 0) // Most recent first
        saveNotes()
        return note
    }

    func updateNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            var updatedNote = note
            updatedNote.updatedAt = Date()
            notes[index] = updatedNote
            saveNotes()
        }
    }

    func deleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        saveNotes()
    }

    func deleteNotes(_ notesToDelete: [Note]) {
        let idsToDelete = Set(notesToDelete.map { $0.id })
        notes.removeAll { idsToDelete.contains($0.id) }
        saveNotes()
    }

    // MARK: - Categories Management

    func createCategory(name: String, color: CategoryColor = .blue) -> Category {
        let category = Category(name: name, color: color)
        categories.append(category)
        saveCategories()
        return category
    }

    func updateCategory(_ category: Category) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
            saveCategories()
        }
    }

    func deleteCategory(_ category: Category) {
        // Remove category
        categories.removeAll { $0.id == category.id }

        // Clear categoryID from notes that used this category
        for i in 0..<notes.count {
            if notes[i].categoryID == category.id {
                notes[i].categoryID = nil
            }
        }

        saveCategories()
        saveNotes()
    }

    func category(for note: Note) -> Category? {
        guard let categoryID = note.categoryID else { return nil }
        return categories.first { $0.id == categoryID }
    }

    // MARK: - Folders Management

    func createFolder(name: String, icon: String = "folder", parentFolderID: UUID? = nil) -> Folder {
        let folder = Folder(name: name, icon: icon, parentFolderID: parentFolderID)
        folders.append(folder)
        saveFolders()
        return folder
    }

    func updateFolder(_ folder: Folder) {
        if let index = folders.firstIndex(where: { $0.id == folder.id }) {
            folders[index] = folder
            saveFolders()
        }
    }

    func deleteFolder(_ folder: Folder) {
        // Remove folder
        folders.removeAll { $0.id == folder.id }

        // Also remove any subfolders
        folders.removeAll { $0.parentFolderID == folder.id }

        // Clear folderID from notes in this folder
        for i in 0..<notes.count {
            if notes[i].folderID == folder.id {
                notes[i].folderID = nil
            }
        }

        saveFolders()
        saveNotes()
    }

    func folder(for note: Note) -> Folder? {
        guard let folderID = note.folderID else { return nil }
        return folders.first { $0.id == folderID }
    }

    func subfolders(of folder: Folder?) -> [Folder] {
        if let folder = folder {
            return folders.filter { $0.parentFolderID == folder.id }
        } else {
            // Return root folders
            return folders.filter { $0.parentFolderID == nil }
        }
    }

    // MARK: - Tags Management

    /// Returns all unique tags used across all notes
    var allTags: [String] {
        var tagSet = Set<String>()
        for note in notes {
            tagSet.formUnion(note.tags)
        }
        return Array(tagSet).sorted()
    }

    /// Returns notes that have the specified tag
    func notes(withTag tag: String) -> [Note] {
        return notes.filter { $0.hasTag(tag) }
    }

    /// Adds a tag to a note
    func addTag(_ tag: String, to note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index].addTag(tag)
            saveNotes()
        }
    }

    /// Removes a tag from a note
    func removeTag(_ tag: String, from note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index].removeTag(tag)
            saveNotes()
        }
    }

    // MARK: - Search & Filter

    /// Searches notes with optional filters
    func searchNotes(
        query: String = "",
        folderID: UUID? = nil,
        categoryID: UUID? = nil,
        tag: String? = nil,
        createdAfter: Date? = nil,
        createdBefore: Date? = nil,
        updatedAfter: Date? = nil,
        updatedBefore: Date? = nil,
        isPinned: Bool? = nil
    ) -> [Note] {
        var results = notes

        // Search query
        if !query.isEmpty {
            results = results.filter { $0.matches(searchText: query) }
        }

        // Filter by folder
        if let folderID = folderID {
            results = results.filter { $0.folderID == folderID }
        }

        // Filter by category
        if let categoryID = categoryID {
            results = results.filter { $0.categoryID == categoryID }
        }

        // Filter by tag
        if let tag = tag {
            results = results.filter { $0.hasTag(tag) }
        }

        // Filter by creation date
        if let createdAfter = createdAfter {
            results = results.filter { $0.createdAt >= createdAfter }
        }
        if let createdBefore = createdBefore {
            results = results.filter { $0.createdAt <= createdBefore }
        }

        // Filter by update date
        if let updatedAfter = updatedAfter {
            results = results.filter { $0.updatedAt >= updatedAfter }
        }
        if let updatedBefore = updatedBefore {
            results = results.filter { $0.updatedAt <= updatedBefore }
        }

        // Filter by pinned status
        if let isPinned = isPinned {
            results = results.filter { $0.isPinned == isPinned }
        }

        return results
    }

    /// Returns notes in the specified folder
    func notes(inFolder folder: Folder?) -> [Note] {
        if let folder = folder {
            return notes.filter { $0.folderID == folder.id }
        } else {
            // Return notes not in any folder
            return notes.filter { $0.folderID == nil }
        }
    }

    /// Toggles pin status for a note
    func togglePin(for note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index].isPinned.toggle()
            saveNotes()
        }
    }

    // MARK: - Draft Management

    func saveDraft(_ content: String) {
        draftContent = content
        try? content.write(to: draftFileURL, atomically: true, encoding: .utf8)
    }

    func clearDraft() {
        draftContent = ""
        try? FileManager.default.removeItem(at: draftFileURL)
    }

    // MARK: - Persistence

    private func loadNotes() {
        guard FileManager.default.fileExists(atPath: notesFileURL.path) else {
            notes = []
            return
        }

        do {
            let data = try Data(contentsOf: notesFileURL)
            notes = try JSONDecoder().decode([Note].self, from: data)
        } catch {
            print("Error loading notes: \(error)")
            notes = []
        }
    }

    private func saveNotes() {
        do {
            let data = try JSONEncoder().encode(notes)
            try data.write(to: notesFileURL, options: [.atomic])
        } catch {
            print("Error saving notes: \(error)")
        }
    }

    private func loadCategories() {
        guard FileManager.default.fileExists(atPath: categoriesFileURL.path) else {
            categories = []
            return
        }

        do {
            let data = try Data(contentsOf: categoriesFileURL)
            categories = try JSONDecoder().decode([Category].self, from: data)
        } catch {
            print("Error loading categories: \(error)")
            categories = []
        }
    }

    private func saveCategories() {
        do {
            let data = try JSONEncoder().encode(categories)
            try data.write(to: categoriesFileURL, options: [.atomic])
        } catch {
            print("Error saving categories: \(error)")
        }
    }

    private func loadFolders() {
        guard FileManager.default.fileExists(atPath: foldersFileURL.path) else {
            folders = []
            return
        }

        do {
            let data = try Data(contentsOf: foldersFileURL)
            folders = try JSONDecoder().decode([Folder].self, from: data)
        } catch {
            print("Error loading folders: \(error)")
            folders = []
        }
    }

    private func saveFolders() {
        do {
            let data = try JSONEncoder().encode(folders)
            try data.write(to: foldersFileURL, options: [.atomic])
        } catch {
            print("Error saving folders: \(error)")
        }
    }

    private func loadDraft() {
        guard FileManager.default.fileExists(atPath: draftFileURL.path) else {
            draftContent = ""
            return
        }

        do {
            draftContent = try String(contentsOf: draftFileURL, encoding: .utf8)
        } catch {
            print("Error loading draft: \(error)")
            draftContent = ""
        }
    }
}
