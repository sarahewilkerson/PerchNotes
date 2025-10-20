import Foundation
import AppKit

/// Converts between NSAttributedString and Markdown format
class NSAttributedStringMarkdownConverter {

    // MARK: - Markdown to NSAttributedString

    /// Converts markdown text to NSAttributedString with formatting
    static func convertFromMarkdown(_ markdown: String, baseFontSize: CGFloat = 14) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        let lines = markdown.components(separatedBy: .newlines)

        let baseFont = NSFont.systemFont(ofSize: baseFontSize)
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: baseFont,
            .foregroundColor: NSColor.textColor
        ]

        for (index, line) in lines.enumerated() {
            let processedLine = processMarkdownLine(line, baseFont: baseFont, baseFontSize: baseFontSize)

            attributedString.append(processedLine)

            // Add newline except for last line
            if index < lines.count - 1 {
                attributedString.append(NSAttributedString(string: "\n", attributes: baseAttributes))
            }
        }

        return attributedString
    }

    private static func processMarkdownLine(_ line: String, baseFont: NSFont, baseFontSize: CGFloat) -> NSAttributedString {
        let attributedLine = NSMutableAttributedString()
        var remainingLine = line

        // Check for headers - keep the markdown markers and render as bold with consistent font size
        if line.hasPrefix("# ") {
            let font = NSFont.systemFont(ofSize: baseFontSize, weight: .bold)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.textColor
            ]
            // Keep the # markers visible
            return NSAttributedString(string: line, attributes: attrs)
        } else if line.hasPrefix("## ") {
            let font = NSFont.systemFont(ofSize: baseFontSize, weight: .bold)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.textColor
            ]
            return NSAttributedString(string: line, attributes: attrs)
        } else if line.hasPrefix("### ") {
            let font = NSFont.systemFont(ofSize: baseFontSize, weight: .bold)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.textColor
            ]
            return NSAttributedString(string: line, attributes: attrs)
        }

        // Check for list items
        if line.hasPrefix("- ") || line.hasPrefix("* ") {
            remainingLine = "• " + String(line.dropFirst(2))
        } else if let match = line.range(of: #"^\d+\.\s"#, options: .regularExpression) {
            remainingLine = String(line[match.upperBound...])
            let number = String(line[..<match.upperBound])
            remainingLine = number + remainingLine
        } else if line.hasPrefix("[ ] ") {
            remainingLine = "☐ " + String(line.dropFirst(4))
        } else if line.hasPrefix("[x] ") || line.hasPrefix("[X] ") {
            remainingLine = "☑ " + String(line.dropFirst(4))
        }

        // Check for horizontal rule
        if line.trimmingCharacters(in: .whitespaces) == "---" ||
           line.trimmingCharacters(in: .whitespaces) == "***" {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: baseFont,
                .foregroundColor: NSColor.separatorColor
            ]
            return NSAttributedString(string: "───────────────────", attributes: attrs)
        }

        // Process inline formatting (bold, italic, code, links)
        let processedInline = processInlineMarkdown(remainingLine, baseFont: baseFont, baseFontSize: baseFontSize)
        return processedInline
    }

    private static func processInlineMarkdown(_ text: String, baseFont: NSFont, baseFontSize: CGFloat) -> NSAttributedString {
        let result = NSMutableAttributedString()
        var currentText = text
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: baseFont,
            .foregroundColor: NSColor.textColor
        ]

        // Process markdown patterns in order of precedence
        while !currentText.isEmpty {
            var foundPattern = false

            // Bold: **text**
            if let boldRange = currentText.range(of: #"\*\*(.+?)\*\*"#, options: .regularExpression) {
                // Add text before pattern
                let beforeRange = currentText.startIndex..<boldRange.lowerBound
                if !currentText[beforeRange].isEmpty {
                    result.append(NSAttributedString(string: String(currentText[beforeRange]), attributes: baseAttributes))
                }

                // Add bold text - use base font size consistently
                let boldText = String(currentText[boldRange]).dropFirst(2).dropLast(2)
                var boldFont = NSFont.systemFont(ofSize: baseFontSize)
                boldFont = NSFontManager.shared.convert(boldFont, toHaveTrait: .boldFontMask)
                let boldAttrs: [NSAttributedString.Key: Any] = [
                    .font: boldFont,
                    .foregroundColor: NSColor.textColor
                ]
                result.append(NSAttributedString(string: String(boldText), attributes: boldAttrs))

                currentText = String(currentText[boldRange.upperBound...])
                foundPattern = true
            }
            // Italic: *text*
            else if let italicRange = currentText.range(of: #"(?<!\*)\*([^*]+?)\*(?!\*)"#, options: .regularExpression) {
                let beforeRange = currentText.startIndex..<italicRange.lowerBound
                if !currentText[beforeRange].isEmpty {
                    result.append(NSAttributedString(string: String(currentText[beforeRange]), attributes: baseAttributes))
                }

                let italicText = String(currentText[italicRange]).dropFirst().dropLast()
                let italicFont = NSFontManager.shared.convert(baseFont, toHaveTrait: .italicFontMask)
                let italicAttrs: [NSAttributedString.Key: Any] = [
                    .font: italicFont,
                    .foregroundColor: NSColor.textColor
                ]
                result.append(NSAttributedString(string: String(italicText), attributes: italicAttrs))

                currentText = String(currentText[italicRange.upperBound...])
                foundPattern = true
            }
            // Inline code: `code` - treat as plain text with consistent font
            else if let codeRange = currentText.range(of: #"`([^`]+)`"#, options: .regularExpression) {
                let beforeRange = currentText.startIndex..<codeRange.lowerBound
                if !currentText[beforeRange].isEmpty {
                    result.append(NSAttributedString(string: String(currentText[beforeRange]), attributes: baseAttributes))
                }

                // Keep backticks visible and use base font
                let codeText = String(currentText[codeRange])
                let codeAttrs: [NSAttributedString.Key: Any] = [
                    .font: baseFont,
                    .foregroundColor: NSColor.textColor
                ]
                result.append(NSAttributedString(string: codeText, attributes: codeAttrs))

                currentText = String(currentText[codeRange.upperBound...])
                foundPattern = true
            }
            // Links: [text](url) - keep markdown syntax visible with consistent font
            else if let linkRange = currentText.range(of: #"\[([^\]]+)\]\(([^)]+)\)"#, options: .regularExpression) {
                let beforeRange = currentText.startIndex..<linkRange.lowerBound
                if !currentText[beforeRange].isEmpty {
                    result.append(NSAttributedString(string: String(currentText[beforeRange]), attributes: baseAttributes))
                }

                // Show the full markdown link syntax
                let linkMatch = String(currentText[linkRange])
                let linkAttrs: [NSAttributedString.Key: Any] = [
                    .font: baseFont,
                    .foregroundColor: NSColor.textColor
                ]
                result.append(NSAttributedString(string: linkMatch, attributes: linkAttrs))

                currentText = String(currentText[linkRange.upperBound...])
                foundPattern = true
            }

            // If no pattern found, add the rest as plain text
            if !foundPattern {
                result.append(NSAttributedString(string: currentText, attributes: baseAttributes))
                break
            }
        }

        return result
    }

    // MARK: - NSAttributedString to Markdown

    /// Converts NSAttributedString to markdown text
    static func convertToMarkdown(_ attributedString: NSAttributedString) -> String {
        var markdown = ""
        let fullRange = NSRange(location: 0, length: attributedString.length)
        let text = attributedString.string

        attributedString.enumerateAttributes(in: fullRange) { attributes, range, _ in
            let substring = (text as NSString).substring(with: range)

            // Skip empty strings
            guard !substring.isEmpty else { return }

            var formatted = substring

            // Check for explicit heading level attribute first
            if let headingLevel = attributes[NSAttributedString.Key("HeadingLevel")] as? NSNumber {
                let level = headingLevel.intValue
                switch level {
                case 1: formatted = "# " + formatted
                case 2: formatted = "## " + formatted
                case 3: formatted = "### " + formatted
                default: break
                }
            } else if let font = attributes[.font] as? NSFont {
                // Fall back to font size detection for headings
                let fontSize = font.pointSize
                let traits = NSFontManager.shared.traits(of: font)

                // Headers (based on font size - baseFont is typically 14pt)
                if fontSize >= 24 {  // H1 (28pt with 14pt base)
                    formatted = "# " + formatted
                } else if fontSize >= 18 && fontSize < 24 {  // H2 (21pt) or H3 (18pt)
                    if fontSize >= 20 {
                        formatted = "## " + formatted
                    } else {
                        formatted = "### " + formatted
                    }
                } else {
                    // Bold
                    if traits.contains(.boldFontMask) {
                        formatted = "**" + formatted + "**"
                    }

                    // Italic
                    if traits.contains(.italicFontMask) {
                        formatted = "*" + formatted + "*"
                    }
                }
            }

            // Check for underline
            if let underline = attributes[.underlineStyle] as? Int, underline != 0 {
                // Markdown doesn't have native underline, use HTML
                formatted = "<u>" + formatted + "</u>"
            }

            // Check for links
            if attributes[.link] != nil {
                if let linkURL = attributes[.link] as? String {
                    formatted = "[\(substring)](\(linkURL))"
                } else if let linkURL = attributes[.link] as? URL {
                    formatted = "[\(substring)](\(linkURL.absoluteString))"
                }
            }

            // Check for code (monospace + background)
            if let font = attributes[.font] as? NSFont,
               font.fontName.contains("Mono") {
                formatted = "`" + formatted + "`"
            }

            markdown += formatted
        }

        // Post-process to clean up list markers
        markdown = markdown.replacingOccurrences(of: "• ", with: "- ")
        markdown = markdown.replacingOccurrences(of: "☐ ", with: "[ ] ")
        markdown = markdown.replacingOccurrences(of: "☑ ", with: "[x] ")

        // Clean up horizontal rules
        markdown = markdown.replacingOccurrences(
            of: "───────────────────",
            with: "---"
        )

        return markdown
    }
}

// MARK: - Extension for Storage

extension NSAttributedString {
    /// Converts attributed string to markdown for storage
    func toMarkdownForStorage() -> String {
        return NSAttributedStringMarkdownConverter.convertToMarkdown(self)
    }

    /// Creates attributed string from markdown storage
    static func fromMarkdownStorage(_ markdown: String, fontSize: CGFloat = 14) -> NSAttributedString {
        return NSAttributedStringMarkdownConverter.convertFromMarkdown(markdown, baseFontSize: fontSize)
    }
}

// MARK: - String Extension

extension String {
    /// Creates an attributed string from this markdown string
    func toAttributedString(fontSize: CGFloat = 14) -> NSAttributedString {
        return NSAttributedStringMarkdownConverter.convertFromMarkdown(self, baseFontSize: fontSize)
    }
}
