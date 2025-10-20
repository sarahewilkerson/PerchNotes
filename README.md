# PerchNotes 🪶

A lightweight, menu bar note-taking app for macOS with rich text editing, markdown support, and quick capture.

## Features

- **Menu Bar Access**: Always available from your menu bar
- **Rich Text Editing**: Bold, italic, headings, lists, links, and more
- **Markdown Support**: Automatic markdown conversion for storage and copy/paste
- **Multiple Formats**: Copy notes as Markdown, Plain Text, or Rich Text
- **Categories**: Organize notes with colored categories
- **Recent Notes**: Quick access to your 20 most recent notes
- **Resizable Window**: 4 size options (Compact, Default, Expanded, Large)
- **Keyboard Shortcuts**: Full keyboard navigation and formatting
- **Auto-Save Drafts**: Never lose your work in progress

## Setup Instructions

### Creating the Xcode Project

1. Open Xcode
2. File → New → Project
3. Choose "macOS" → "App"
4. Fill in:
   - Product Name: **PerchNotes**
   - Organization Identifier: **com.yourname** (or your preferred identifier)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None** (we're using JSON files)
5. Save it in the `PerchNotes` directory (replace the generated files)

### Adding Source Files

All source files are already organized in the correct structure:

```
PerchNotes/
├── PerchNotesApp.swift          # Main app entry point
├── Models/
│   ├── Note.swift               # Note data model
│   └── Category.swift           # Category data model
├── Views/
│   ├── PerchNotesView.swift     # Main menu bar view
│   └── RichTextEditor.swift     # Rich text editor component
├── Services/
│   ├── MenuBarManager.swift     # Menu bar integration
│   └── NoteManager.swift        # Data management
├── Utilities/
│   ├── CustomColors.swift       # Color system
│   ├── FormattingToolbar.swift  # Text formatting
│   └── NSAttributedStringMarkdownConverter.swift
└── Assets.xcassets/
    └── AppIcon.appiconset/
```

### Important: Set LSUIElement

The app runs as a **menu bar-only app** (no Dock icon).

This is already set in `Info.plist`:
```xml
<key>LSUIElement</key>
<true/>
```

If you need to show it in the Dock during development, set this to `<false/>`.

## Keyboard Shortcuts

### Formatting
- **⌘B**: Bold
- **⌘I**: Italic
- **⌘U**: Underline
- **⌘⌥1-3**: Headings (H1, H2, H3)
- **⌘⇧L**: Bullet list
- **⌘⇧N**: Numbered list
- **⌘⇧C**: Checkbox
- **⌘]**: Increase indent
- **⌘[**: Decrease indent
- **⌘K**: Insert link
- **⌘⇧R**: Horizontal rule
- **⌘⇧F**: Toggle formatting toolbar

### Actions
- **⌘↵**: Save note
- **Esc**: Close popover

## Data Storage

Notes and categories are stored as JSON files in:
```
~/Library/Application Support/PerchNotes/
├── notes.json
├── categories.json
└── draft.txt
```

## Customization

### Colors
Edit `CustomColors.swift` to customize the color scheme.

### Window Sizes
Edit `MenuBarManager.PopoverSize` to adjust window dimensions.

### Placeholder Text
Edit `PerchNotesView.placeholderText` to customize the placeholder.

## Architecture

- **SwiftUI**: Modern declarative UI
- **Combine**: Reactive data flow
- **NSTextView**: Native macOS rich text editing
- **JSON Storage**: Simple, portable data storage
- **Menu Bar Integration**: Using NSStatusBar

## Building

1. Open `PerchNotes.xcodeproj` in Xcode
2. Select "My Mac" as the destination
3. Press **⌘R** to build and run
4. Look for the 📝 icon in your menu bar

## License

Feel free to use and modify as needed!
