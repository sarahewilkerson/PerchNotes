import Foundation
import SwiftUI

/// Represents a note in PerchNotes
struct Note: Identifiable, Codable {
    let id: UUID
    var title: String
    var content: String // Stored as markdown
    var categoryID: UUID?
    var folderID: UUID?
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool
    var isTrashed: Bool
    var deletedAt: Date?

    // Custom coding keys for backwards compatibility
    enum CodingKeys: String, CodingKey {
        case id, title, content, categoryID, folderID, tags
        case createdAt, updatedAt, isPinned, isTrashed, deletedAt
    }

    // Custom decoder to provide default values for new properties
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        categoryID = try container.decodeIfPresent(UUID.self, forKey: .categoryID)
        folderID = try container.decodeIfPresent(UUID.self, forKey: .folderID)
        tags = try container.decode([String].self, forKey: .tags)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        isPinned = try container.decode(Bool.self, forKey: .isPinned)

        // New properties with default values for backwards compatibility
        isTrashed = try container.decodeIfPresent(Bool.self, forKey: .isTrashed) ?? false
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
    }

    init(
        id: UUID = UUID(),
        title: String = "",
        content: String = "",
        categoryID: UUID? = nil,
        folderID: UUID? = nil,
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isPinned: Bool = false,
        isTrashed: Bool = false,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.categoryID = categoryID
        self.folderID = folderID
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPinned = isPinned
        self.isTrashed = isTrashed
        self.deletedAt = deletedAt
    }

    /// Creates an attributed string from the markdown content
    var attributedContent: NSAttributedString {
        return content.toAttributedString()
    }

    /// Updates the content from attributed string
    mutating func updateContent(from attributedString: NSAttributedString) {
        self.content = NSAttributedStringMarkdownConverter.convertToMarkdown(attributedString)
        self.updatedAt = Date()
    }

    // MARK: - Search & Filter Helpers

    /// Returns true if the note matches the search query
    func matches(searchText: String) -> Bool {
        guard !searchText.isEmpty else { return true }

        let query = searchText.lowercased()
        return title.lowercased().contains(query) ||
               content.lowercased().contains(query) ||
               tags.contains(where: { $0.lowercased().contains(query) })
    }

    /// Returns true if the note has the specified tag
    func hasTag(_ tag: String) -> Bool {
        return tags.contains(where: { $0.lowercased() == tag.lowercased() })
    }

    /// Adds a tag if it doesn't already exist
    mutating func addTag(_ tag: String) {
        let trimmedTag = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty && !hasTag(trimmedTag) else { return }
        tags.append(trimmedTag)
        updatedAt = Date()
    }

    /// Removes a tag
    mutating func removeTag(_ tag: String) {
        tags.removeAll { $0.lowercased() == tag.lowercased() }
        updatedAt = Date()
    }

    /// Returns preview text (first 100 characters)
    var preview: String {
        let text = content.prefix(100)
        return String(text) + (content.count > 100 ? "..." : "")
    }

    /// Generates a smart title from the first three words of content
    var smartTitle: String {
        // If title is already set and not empty, use it
        if !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return title
        }

        // Extract first three words from content
        let cleanContent = content
            .replacingOccurrences(of: #"^#+\s*"#, with: "", options: .regularExpression) // Remove markdown headers
            .replacingOccurrences(of: #"[*_`]"#, with: "", options: .regularExpression) // Remove markdown formatting
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let words = cleanContent.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .prefix(3)

        if words.isEmpty {
            return "Untitled Note"
        }

        return words.joined(separator: " ")
    }

    /// Returns true if note should be auto-deleted (30 days in trash)
    var shouldAutoDelete: Bool {
        guard isTrashed, let deletedAt = deletedAt else { return false }
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return deletedAt < thirtyDaysAgo
    }
}
