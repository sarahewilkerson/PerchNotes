import SwiftUI

/// Simple color system matching the PerchNotes UI design
enum CustomColors {
    // MARK: - Surface Colors
    static let surfaceBase = Color(red: 247/255, green: 245/255, blue: 243/255) // #f7f5f3
static let surfaceSecondary = Color(red: 239/255, green: 237/255, blue: 232/255) // #efede8
    static let surfaceHighlight = Color(NSColor.controlBackgroundColor).opacity(0.5)

    // MARK: - Content Colors
    static let contentPrimary = Color(NSColor.labelColor)
    static let contentSecondary = Color(NSColor.secondaryLabelColor)
    static let contentTertiary = Color(NSColor.tertiaryLabelColor)

    // MARK: - Action Colors
    static let actionPrimary = Color(red: 96/255, green: 158/255, blue: 123/255) // #609e7b
    static let actionPrimaryText = Color.white
    static let actionSecondary = Color(NSColor.controlBackgroundColor)

    // MARK: - Border Colors
    static let borderSubtle = Color(NSColor.separatorColor)

    // MARK: - Feedback Colors
    static let feedbackSuccess = Color(red: 96/255, green: 158/255, blue: 123/255) // #609e7b
}

/// Typography system
enum CustomFont {
    case title
    case subtitle
    case body
    case caption
    case customCaption
    case customBody
    case customSubtitle

    var font: Font {
        switch self {
        case .title:
            return .title
        case .subtitle:
            return .headline
        case .body, .customBody:
            return .body
        case .caption, .customCaption:
            return .caption
        case .customSubtitle:
            return .subheadline
        }
    }

    func with(color: Color) -> (Font, Color) {
        return (self.font, color)
    }
}

// MARK: - View Extensions for Easy Styling

extension View {
    /// Apply text styling
    func perchText(_ style: CustomFont, color: CustomColors.ColorType = .contentPrimary) -> some View {
        self
            .font(style.font)
            .foregroundColor(color.color)
    }

    /// Apply background color
    func perchBackground(_ color: CustomColors.ColorType) -> some View {
        self.background(color.color)
    }

    /// Apply border styling
    func perchBorder(_ color: CustomColors.ColorType) -> some View {
        self.foregroundColor(color.color)
    }

    /// Apply foreground color
    func perchForeground(_ color: CustomColors.ColorType) -> some View {
        self.foregroundColor(color.color)
    }
}

extension CustomColors {
    enum ColorType {
        case surfaceBase, surfaceSecondary, surfaceHighlight
        case contentPrimary, contentSecondary, contentTertiary
        case actionPrimary, actionPrimaryText, actionSecondary
        case borderSubtle
        case feedbackSuccess

        var color: Color {
            switch self {
            case .surfaceBase: return CustomColors.surfaceBase
            case .surfaceSecondary: return CustomColors.surfaceSecondary
            case .surfaceHighlight: return CustomColors.surfaceHighlight
            case .contentPrimary: return CustomColors.contentPrimary
            case .contentSecondary: return CustomColors.contentSecondary
            case .contentTertiary: return CustomColors.contentTertiary
            case .actionPrimary: return CustomColors.actionPrimary
            case .actionPrimaryText: return CustomColors.actionPrimaryText
            case .actionSecondary: return CustomColors.actionSecondary
            case .borderSubtle: return CustomColors.borderSubtle
            case .feedbackSuccess: return CustomColors.feedbackSuccess
            }
        }
    }
}
