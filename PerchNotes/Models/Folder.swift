import Foundation
import SwiftUI

/// Represents a folder for organizing notes hierarchically
struct Folder: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var icon: String
    var parentFolderID: UUID?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "folder",
        parentFolderID: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.parentFolderID = parentFolderID
        self.createdAt = createdAt
    }

    /// Returns true if this is a root folder (no parent)
    var isRootFolder: Bool {
        return parentFolderID == nil
    }

    /// Returns true if this is a subfolder
    var isSubfolder: Bool {
        return parentFolderID != nil
    }
}

/// Predefined folder icons
extension Folder {
    enum Icon: String, CaseIterable {
        case folder = "folder"
        case work = "briefcase"
        case personal = "person"
        case ideas = "lightbulb"
        case archive = "archivebox"
        case favorites = "star"
        case folders = "hammer"
        case notes = "note.text"

        var systemName: String {
            return rawValue
        }

        var displayName: String {
            switch self {
            case .folder: return "Folder"
            case .work: return "Work"
            case .personal: return "Personal"
            case .ideas: return "Ideas"
            case .archive: return "Archive"
            case .favorites: return "Favorites"
            case .folders: return "Folders"
            case .notes: return "Notes"
            }
        }
    }
}
