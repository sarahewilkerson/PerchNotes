import Foundation
import SwiftUI

/// Represents a category/notebook for organizing notes
struct Category: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var color: CategoryColor

    init(
        id: UUID = UUID(),
        name: String,
        color: CategoryColor = .blue
    ) {
        self.id = id
        self.name = name
        self.color = color
    }
}

/// Predefined colors for categories
enum CategoryColor: String, Codable, CaseIterable {
    case blue
    case green
    case orange
    case purple
    case pink
    case red
    case yellow
    case gray

    var color: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .purple: return .purple
        case .pink: return .pink
        case .red: return .red
        case .yellow: return .yellow
        case .gray: return .gray
        }
    }

    var displayName: String {
        return rawValue.capitalized
    }
}
