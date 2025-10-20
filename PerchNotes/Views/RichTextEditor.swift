import SwiftUI
import AppKit

/// A rich text editor component using NSTextView with native formatting support
struct RichTextEditor: View {
    @Binding var attributedText: NSAttributedString
    @Binding var selectedRange: NSRange

    var placeholder: String = "Start typing..."
    var font: NSFont = .systemFont(ofSize: 14)
    var isEditable: Bool = true
    var onTextChange: ((NSAttributedString) -> Void)?
    var onSelectionChange: ((NSRange) -> Void)?

    var body: some View {
        ZStack(alignment: .topLeading) {
            RichTextEditorInternal(
                attributedText: $attributedText,
                selectedRange: $selectedRange,
                font: font,
                isEditable: isEditable,
                onTextChange: onTextChange,
                onSelectionChange: onSelectionChange
            )

            // Placeholder overlay - check both empty and whitespace-only content
            if attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(placeholder)
                    .font(Font(font))
                    .foregroundColor(Color(NSColor.placeholderTextColor))
                    .padding(.leading, 13)
                    .padding(.top, 8)
                    .allowsHitTesting(false)
            }
        }
    }
}

private struct RichTextEditorInternal: NSViewRepresentable {
    @Binding var attributedText: NSAttributedString
    @Binding var selectedRange: NSRange

    var font: NSFont
    var isEditable: Bool
    var onTextChange: ((NSAttributedString) -> Void)?
    var onSelectionChange: ((NSRange) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        // Configure text view
        textView.delegate = context.coordinator
        textView.isRichText = true
        textView.allowsUndo = true
        textView.isEditable = isEditable
        textView.isSelectable = true
        textView.font = font
        textView.textColor = .textColor
        textView.backgroundColor = .textBackgroundColor
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false

        // Enable rich text features
        textView.allowsDocumentBackgroundColorChange = false
        textView.usesRuler = false
        textView.usesInspectorBar = false

        // Set default typing attributes to ensure consistent font
        textView.typingAttributes = [
            .font: font,
            .foregroundColor: NSColor.textColor
        ]

        // Set initial content
        textView.textStorage?.setAttributedString(attributedText)

        // Position cursor at start
        textView.setSelectedRange(NSRange(location: 0, length: 0))

        // Store reference for later use
        context.coordinator.textView = textView

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        // Update text if changed externally
        if textView.attributedString() != attributedText {
            // Safely update the text storage
            if let textStorage = textView.textStorage {
                textStorage.beginEditing()
                textStorage.setAttributedString(attributedText)
                textStorage.endEditing()
            }

            // If text is now empty, position cursor at start
            if attributedText.string.isEmpty {
                textView.setSelectedRange(NSRange(location: 0, length: 0))
            }
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, NSTextViewDelegate {
        let parent: RichTextEditorInternal
        var isEditing = false
        weak var textView: NSTextView?

        init(_ parent: RichTextEditorInternal) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }

            let newAttributedString = textView.attributedString()

            // Always update binding to ensure SwiftUI refreshes
            // NSAttributedString comparison can be unreliable
            parent.attributedText = newAttributedString
            parent.onTextChange?(newAttributedString)
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }

            let newRange = textView.selectedRange()
            if newRange.location != parent.selectedRange.location ||
               newRange.length != parent.selectedRange.length {
                parent.selectedRange = newRange
                parent.onSelectionChange?(newRange)
            }
        }

        func textDidBeginEditing(_ notification: Notification) {
            isEditing = true
        }

        func textDidEndEditing(_ notification: Notification) {
            isEditing = false
        }

        // MARK: - Paste Handling

        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            // Let normal typing pass through
            return true
        }

        // Override paste to normalize formatting
        func textView(_ textView: NSTextView, willChangeSelectionFromCharacterRange oldSelectedCharRange: NSRange, toCharacterRange newSelectedCharRange: NSRange) -> NSRange {
            return newSelectedCharRange
        }

        // Handle paste operations and smart list continuation
        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSTextView.paste(_:)) {
                return handlePaste(textView)
            }

            // Handle Enter key for list continuation
            if commandSelector == #selector(NSTextView.insertNewline(_:)) {
                return handleEnterInList(textView)
            }

            // Handle Backspace for exiting lists
            if commandSelector == #selector(NSTextView.deleteBackward(_:)) {
                return handleBackspaceInList(textView)
            }

            return false
        }

        // Smart list continuation: Enter creates new list item
        private func handleEnterInList(_ textView: NSTextView) -> Bool {
            let selectedRange = textView.selectedRange()
            guard let textStorage = textView.textStorage else { return false }

            // Get the current line
            let string = textStorage.string as NSString
            let lineRange = string.lineRange(for: selectedRange)
            let line = string.substring(with: lineRange).trimmingCharacters(in: .newlines)

            // Check if we're in a list
            let listPatterns: [(pattern: String, prefix: String)] = [
                (#"^([ \t]*)([-*+])\s"#, "- "),           // Unordered list
                (#"^([ \t]*)(\d+)\.\s"#, "1. "),          // Ordered list
                (#"^([ \t]*)(\[[ x]\])\s"#, "[ ] ")       // Task list
            ]

            for (pattern, prefix) in listPatterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: []),
                   let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {

                    // Check if the line is empty except for the list marker
                    let contentRange = NSRange(location: match.range.length, length: line.count - match.range.length)
                    let content = (line as NSString).substring(with: contentRange).trimmingCharacters(in: .whitespaces)

                    if content.isEmpty {
                        // Empty list item - remove it and exit list mode
                        let lineStart = lineRange.location
                        let deleteRange = NSRange(location: lineStart, length: lineRange.length)
                        textStorage.replaceCharacters(in: deleteRange, with: "\n")
                        textView.setSelectedRange(NSRange(location: lineStart + 1, length: 0))
                        return true
                    }

                    // Non-empty list item - create new item
                    let indentation = (line as NSString).substring(with: match.range(at: 1))
                    let newListItem = "\n" + indentation + prefix
                    textView.insertText(newListItem, replacementRange: selectedRange)
                    return true
                }
            }

            return false // Not in a list, use default Enter behavior
        }

        // Handle backspace on empty list items
        private func handleBackspaceInList(_ textView: NSTextView) -> Bool {
            let selectedRange = textView.selectedRange()
            guard let textStorage = textView.textStorage else { return false }

            // Only handle if we're at the start of the selection (not deleting selected text)
            guard selectedRange.length == 0 else { return false }

            // Get the current line
            let string = textStorage.string as NSString
            let lineRange = string.lineRange(for: selectedRange)
            let line = string.substring(with: lineRange).trimmingCharacters(in: .newlines)

            // Check if we're at a list item marker
            let listPatterns = [
                #"^([ \t]*)([-*+])\s$"#,        // Empty unordered list
                #"^([ \t]*)(\d+)\.\s$"#,        // Empty ordered list
                #"^([ \t]*)(\[[ x]\])\s$"#      // Empty task list
            ]

            for pattern in listPatterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: []),
                   regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) != nil {

                    // We're at an empty list item - check if cursor is right after the marker
                    let cursorPosition = selectedRange.location
                    let lineStart = lineRange.location
                    let relativePosition = cursorPosition - lineStart

                    if relativePosition == line.count {
                        // Cursor is at the end of the list marker - remove the entire marker
                        textStorage.replaceCharacters(in: lineRange, with: "\n")
                        textView.setSelectedRange(NSRange(location: lineStart, length: 0))
                        return true
                    }
                }
            }

            return false // Not at an empty list item, use default backspace
        }

        private func handlePaste(_ textView: NSTextView) -> Bool {
            let pasteboard = NSPasteboard.general
            let currentRange = textView.selectedRange()

            // Try to get markdown first
            if let pastedString = pasteboard.string(forType: .string) {
                // Check if it looks like markdown
                let normalized: NSAttributedString

                if containsMarkdownSyntax(pastedString) {
                    // Convert markdown to attributed string
                    let attributedString = NSAttributedStringMarkdownConverter.convertFromMarkdown(
                        pastedString,
                        baseFontSize: parent.font.pointSize
                    )

                    // Normalize to ensure consistent font
                    normalized = normalizeFormatting(attributedString)
                } else {
                    // Plain text or rich text - strip everything except bold/italic
                    normalized = createNormalizedAttributedString(pastedString)
                }

                // Use shouldChangeText to ensure proper notifications
                if textView.shouldChangeText(in: currentRange, replacementString: nil) {
                    textView.textStorage?.replaceCharacters(in: currentRange, with: normalized)

                    // Update selection before didChangeText
                    let newLocation = currentRange.location + normalized.length
                    textView.setSelectedRange(NSRange(location: newLocation, length: 0))

                    // Trigger change notification - this will update bindings via textDidChange
                    textView.didChangeText()

                    return true
                }
            }

            return false
        }

        private func normalizeFormatting(_ attributedString: NSAttributedString) -> NSAttributedString {
            let normalized = NSMutableAttributedString()
            let fullRange = NSRange(location: 0, length: attributedString.length)
            let text = attributedString.string
            let baseFont = parent.font

            attributedString.enumerateAttributes(in: fullRange) { attributes, range, _ in
                let substring = (text as NSString).substring(with: range)
                guard !substring.isEmpty else { return }

                var newAttributes: [NSAttributedString.Key: Any] = [
                    .font: baseFont,
                    .foregroundColor: NSColor.textColor
                ]

                // Preserve font size, bold, and italic traits (for headings and emphasis)
                if let font = attributes[.font] as? NSFont {
                    let traits = NSFontManager.shared.traits(of: font)
                    var newFont = baseFont

                    // Preserve font size if it's significantly different (headings)
                    let sizeRatio = font.pointSize / baseFont.pointSize
                    if sizeRatio > 1.1 || sizeRatio < 0.9 {
                        // This is likely a heading or different text style - preserve size
                        newFont = NSFont(descriptor: baseFont.fontDescriptor, size: font.pointSize) ?? baseFont
                    }

                    if traits.contains(.boldFontMask) {
                        newFont = NSFontManager.shared.convert(newFont, toHaveTrait: .boldFontMask)
                    }
                    if traits.contains(.italicFontMask) {
                        newFont = NSFontManager.shared.convert(newFont, toHaveTrait: .italicFontMask)
                    }

                    newAttributes[.font] = newFont
                }

                // Preserve underline
                if let underline = attributes[.underlineStyle] {
                    newAttributes[.underlineStyle] = underline
                }

                // Preserve paragraph style (for lists, alignment, etc.)
                if let paragraphStyle = attributes[.paragraphStyle] {
                    newAttributes[.paragraphStyle] = paragraphStyle
                }

                normalized.append(NSAttributedString(string: substring, attributes: newAttributes))
            }

            return normalized
        }

        private func createNormalizedAttributedString(_ text: String) -> NSAttributedString {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: parent.font,
                .foregroundColor: NSColor.textColor
            ]
            return NSAttributedString(string: text, attributes: attributes)
        }

        private func containsMarkdownSyntax(_ text: String) -> Bool {
            let markdownPatterns = [
                #"^#+\s"#,           // Headers
                #"\*\*.*?\*\*"#,    // Bold
                #"\*.*?\*"#,        // Italic
                #"`.*?`"#,          // Code
                #"\[.*?\]\(.*?\)"#, // Links
                #"^[-*]\s"#,        // Lists
                #"^\d+\.\s"#,       // Numbered lists
                #"^\[[ x]\]\s"#     // Checkboxes
            ]

            for pattern in markdownPatterns {
                if text.range(of: pattern, options: .regularExpression) != nil {
                    return true
                }
            }

            return false
        }
    }
}
