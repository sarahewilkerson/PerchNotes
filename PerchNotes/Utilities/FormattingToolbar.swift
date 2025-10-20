import SwiftUI
import AppKit

// MARK: - Formatting Actions

enum FormattingAction {
    case bold
    case italic
    case underline
    case heading1
    case heading2
    case heading3
    case bulletList
    case numberedList
    case checkbox
    case indent
    case outdent
    case link
    case horizontalRule
    case copyAsMarkdown
    case copyAsPlainText
    case copyAsRichText

    var keyboardShortcut: KeyEquivalent? {
        switch self {
        case .bold: return "b"
        case .italic: return "i"
        case .underline: return "u"
        case .heading1: return "1"
        case .heading2: return "2"
        case .heading3: return "3"
        case .bulletList: return "l"
        case .numberedList: return "n"
        case .checkbox: return "c"
        case .indent: return "]"
        case .outdent: return "["
        case .link: return "k"
        default: return nil
        }
    }

    var modifiers: EventModifiers {
        switch self {
        case .bold, .italic, .underline, .indent, .outdent, .link:
            return .command
        case .heading1, .heading2, .heading3:
            return [.command, .option]
        case .bulletList, .numberedList, .checkbox:
            return [.command, .shift]
        default:
            return []
        }
    }
}

// MARK: - Rich Text Formatting Handler

class RichTextFormattingHandler: ObservableObject {
    weak var textView: NSTextView?

    init(textView: NSTextView? = nil) {
        self.textView = textView
    }

    func handle(_ action: FormattingAction) {
        guard let textView = textView else { return }

        switch action {
        case .bold:
            applyBold(to: textView)
        case .italic:
            applyItalic(to: textView)
        case .underline:
            applyUnderline(to: textView)
        case .heading1:
            applyHeading(to: textView, level: 1)
        case .heading2:
            applyHeading(to: textView, level: 2)
        case .heading3:
            applyHeading(to: textView, level: 3)
        case .bulletList:
            insertBulletList(to: textView)
        case .numberedList:
            insertNumberedList(to: textView)
        case .checkbox:
            insertCheckbox(to: textView)
        case .indent:
            increaseIndent(to: textView)
        case .outdent:
            decreaseIndent(to: textView)
        case .link:
            insertLink(to: textView)
        case .horizontalRule:
            insertHorizontalRule(to: textView)
        case .copyAsMarkdown:
            copyAsMarkdown(from: textView)
        case .copyAsPlainText:
            copyAsPlainText(from: textView)
        case .copyAsRichText:
            copyAsRichText(from: textView)
        }
    }

    // MARK: - Text Style Formatting

    private func applyBold(to textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }
        let range = textView.selectedRange()

        // Bounds check
        guard range.location >= 0 && range.location <= textStorage.length else { return }
        guard range.length >= 0 && range.location + range.length <= textStorage.length else { return }

        let baseFont = textView.font ?? NSFont.systemFont(ofSize: 14)

        if range.length > 0 {
            textStorage.applyFontTraits(.boldFontMask, range: range, baseFont: baseFont)
        } else {
            // Toggle typing attributes
            var attrs = textView.typingAttributes
            if let font = attrs[.font] as? NSFont {
                let traits = NSFontManager.shared.traits(of: font)
                let isBold = traits.contains(.boldFontMask)

                var newFont = NSFont.systemFont(ofSize: baseFont.pointSize)
                if !isBold {
                    newFont = NSFontManager.shared.convert(newFont, toHaveTrait: .boldFontMask)
                }
                // Preserve italic if present
                if traits.contains(.italicFontMask) {
                    newFont = NSFontManager.shared.convert(newFont, toHaveTrait: .italicFontMask)
                }

                attrs[.font] = newFont
                attrs[.foregroundColor] = NSColor.textColor
                textView.typingAttributes = attrs
            }
        }
    }

    private func applyItalic(to textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }
        let range = textView.selectedRange()

        // Bounds check
        guard range.location >= 0 && range.location <= textStorage.length else { return }
        guard range.length >= 0 && range.location + range.length <= textStorage.length else { return }

        let baseFont = textView.font ?? NSFont.systemFont(ofSize: 14)

        if range.length > 0 {
            textStorage.applyFontTraits(.italicFontMask, range: range, baseFont: baseFont)
        } else {
            var attrs = textView.typingAttributes
            if let font = attrs[.font] as? NSFont {
                let traits = NSFontManager.shared.traits(of: font)
                let isItalic = traits.contains(.italicFontMask)

                var newFont = NSFont.systemFont(ofSize: baseFont.pointSize)
                if !isItalic {
                    newFont = NSFontManager.shared.convert(newFont, toHaveTrait: .italicFontMask)
                }
                // Preserve bold if present
                if traits.contains(.boldFontMask) {
                    newFont = NSFontManager.shared.convert(newFont, toHaveTrait: .boldFontMask)
                }

                attrs[.font] = newFont
                attrs[.foregroundColor] = NSColor.textColor
                textView.typingAttributes = attrs
            }
        }
    }

    private func applyUnderline(to textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }
        let range = textView.selectedRange()

        // Bounds check
        guard range.location >= 0 && range.location < textStorage.length else { return }
        guard range.length >= 0 && range.location + range.length <= textStorage.length else { return }

        if range.length > 0 {
            let currentUnderline = textStorage.attribute(.underlineStyle, at: range.location, effectiveRange: nil) as? Int ?? 0
            let newUnderline = currentUnderline == 0 ? NSUnderlineStyle.single.rawValue : 0
            textStorage.addAttribute(.underlineStyle, value: newUnderline, range: range)
        }
    }

    private func applyHeading(to textView: NSTextView, level: Int) {
        guard let textStorage = textView.textStorage else { return }
        let range = textView.selectedRange()

        // Always use consistent base font size for calculations
        let baseFontSize: CGFloat = 14

        // Calculate heading font size based on level (absolute sizes)
        let fontSize: CGFloat
        switch level {
        case 1: fontSize = baseFontSize * 2.0      // H1: 28pt
        case 2: fontSize = baseFontSize * 1.5      // H2: 21pt
        case 3: fontSize = baseFontSize * 1.3      // H3: 18pt
        default: fontSize = baseFontSize
        }

        // Create bold font with appropriate size
        let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)

        // Store heading level as custom attribute for markdown conversion
        let headingLevel = NSNumber(value: level)

        if range.length > 0 {
            // Apply heading style to selection
            textStorage.addAttribute(.font, value: font, range: range)
            textStorage.addAttribute(.foregroundColor, value: NSColor.textColor, range: range)
            textStorage.addAttribute(NSAttributedString.Key("HeadingLevel"), value: headingLevel, range: range)
        } else {
            // Set typing attributes for heading
            var typingAttrs = textView.typingAttributes
            typingAttrs[.font] = font
            typingAttrs[.foregroundColor] = NSColor.textColor
            typingAttrs[NSAttributedString.Key("HeadingLevel")] = headingLevel
            textView.typingAttributes = typingAttrs
        }
    }

    // MARK: - List Formatting

    private func insertBulletList(to textView: NSTextView) {
        insertListItem(to: textView, prefix: "• ")
    }

    private func insertNumberedList(to textView: NSTextView) {
        insertListItem(to: textView, prefix: "1. ")
    }

    private func insertCheckbox(to textView: NSTextView) {
        insertListItem(to: textView, prefix: "☐ ")
    }

    private func insertListItem(to textView: NSTextView, prefix: String) {
        guard let textStorage = textView.textStorage else { return }
        let currentRange = textView.selectedRange()
        let text = textStorage.string

        // Find start of current line
        var lineStart = currentRange.location
        while lineStart > 0 && text[text.index(text.startIndex, offsetBy: lineStart - 1)] != "\n" {
            lineStart -= 1
        }

        // Check if we're already at start of line
        let insertPrefix = (currentRange.location == lineStart) ? prefix : "\n" + prefix

        let attrs: [NSAttributedString.Key: Any] = [
            .font: textView.font ?? NSFont.systemFont(ofSize: 14),
            .foregroundColor: NSColor.textColor
        ]
        let attributedPrefix = NSAttributedString(string: insertPrefix, attributes: attrs)

        textStorage.insert(attributedPrefix, at: currentRange.location)
        textView.setSelectedRange(NSRange(location: currentRange.location + insertPrefix.count, length: 0))
    }

    // MARK: - Indentation

    private func increaseIndent(to textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }
        let currentRange = textView.selectedRange()

        let attrs: [NSAttributedString.Key: Any] = [
            .font: textView.font ?? NSFont.systemFont(ofSize: 14),
            .foregroundColor: NSColor.textColor
        ]
        let spaces = NSAttributedString(string: "    ", attributes: attrs)
        textStorage.insert(spaces, at: currentRange.location)
        textView.setSelectedRange(NSRange(location: currentRange.location + 4, length: 0))
    }

    private func decreaseIndent(to textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }
        let currentRange = textView.selectedRange()
        let text = textStorage.string

        // Find start of line
        var lineStart = currentRange.location
        while lineStart > 0 && text[text.index(text.startIndex, offsetBy: lineStart - 1)] != "\n" {
            lineStart -= 1
        }

        // Count leading spaces
        var spacesToRemove = 0
        var checkIndex = lineStart
        while spacesToRemove < 4 && checkIndex < text.count {
            let char = text[text.index(text.startIndex, offsetBy: checkIndex)]
            if char == " " {
                spacesToRemove += 1
                checkIndex += 1
            } else {
                break
            }
        }

        if spacesToRemove > 0 {
            textStorage.deleteCharacters(in: NSRange(location: lineStart, length: spacesToRemove))
            textView.setSelectedRange(NSRange(location: max(lineStart, currentRange.location - spacesToRemove), length: 0))
        }
    }

    // MARK: - Special Elements

    private func insertLink(to textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }
        let currentRange = textView.selectedRange()

        let selectedText = currentRange.length > 0 ?
            textStorage.attributedSubstring(from: currentRange).string :
            "link text"

        let linkPlaceholder = "[\(selectedText)](url)"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: textView.font ?? NSFont.systemFont(ofSize: 14),
            .foregroundColor: NSColor.textColor
        ]
        let attributedLink = NSAttributedString(string: linkPlaceholder, attributes: attrs)

        if currentRange.length > 0 {
            textStorage.replaceCharacters(in: currentRange, with: attributedLink)
        } else {
            textStorage.insert(attributedLink, at: currentRange.location)
        }

        // Select the "url" part for easy editing
        let urlStart = currentRange.location + selectedText.count + 3 // After "]("
        textView.setSelectedRange(NSRange(location: urlStart, length: 3))
    }

    private func insertHorizontalRule(to textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }
        let currentRange = textView.selectedRange()

        let hrText = "\n---\n"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: textView.font ?? NSFont.systemFont(ofSize: 14),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        let attributedHR = NSAttributedString(string: hrText, attributes: attrs)

        textStorage.insert(attributedHR, at: currentRange.location)
        textView.setSelectedRange(NSRange(location: currentRange.location + hrText.count, length: 0))
    }

    // MARK: - Copy Actions

    private func copyAsMarkdown(from textView: NSTextView) {
        let markdown = NSAttributedStringMarkdownConverter.convertToMarkdown(textView.attributedString())
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(markdown, forType: .string)
    }

    private func copyAsPlainText(from textView: NSTextView) {
        let plainText = textView.string
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(plainText, forType: .string)
    }

    private func copyAsRichText(from textView: NSTextView) {
        let attributedString = textView.attributedString()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(attributedString.string, forType: .string)
        NSPasteboard.general.setData(
            try? attributedString.data(from: NSRange(location: 0, length: attributedString.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]),
            forType: .rtf
        )
    }
}

// MARK: - NSMutableAttributedString Extension

extension NSMutableAttributedString {
    func applyFontTraits(_ traits: NSFontTraitMask, range: NSRange, baseFont: NSFont) {
        enumerateAttribute(.font, in: range) { value, subRange, _ in
            guard let font = value as? NSFont else { return }

            // Start with base font at base size
            var newFont = NSFont.systemFont(ofSize: baseFont.pointSize)

            // Get current traits
            let currentTraits = NSFontManager.shared.traits(of: font)

            // Toggle the requested trait
            if currentTraits.contains(traits) {
                // Remove the trait by not applying it
                if traits == .boldFontMask && currentTraits.contains(.italicFontMask) {
                    newFont = NSFontManager.shared.convert(newFont, toHaveTrait: .italicFontMask)
                } else if traits == .italicFontMask && currentTraits.contains(.boldFontMask) {
                    newFont = NSFontManager.shared.convert(newFont, toHaveTrait: .boldFontMask)
                }
            } else {
                // Add the requested trait
                newFont = NSFontManager.shared.convert(newFont, toHaveTrait: traits)
                // Preserve other traits
                if traits == .boldFontMask && currentTraits.contains(.italicFontMask) {
                    newFont = NSFontManager.shared.convert(newFont, toHaveTrait: .italicFontMask)
                } else if traits == .italicFontMask && currentTraits.contains(.boldFontMask) {
                    newFont = NSFontManager.shared.convert(newFont, toHaveTrait: .boldFontMask)
                }
            }

            addAttribute(.font, value: newFont, range: subRange)
            addAttribute(.foregroundColor, value: NSColor.textColor, range: subRange)
        }
    }
}
