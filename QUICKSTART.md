# 🚀 PerchNotes - Quick Start Guide

## You're Ready to Go! 🎉

Everything has been set up for you. Just follow these simple steps:

## Step 1: Open the Project

```bash
open ~/Developer/PerchNotes/PerchNotes.xcodeproj
```

Or:
1. Open **Finder**
2. Navigate to `~/Developer/PerchNotes/`
3. Double-click **PerchNotes.xcodeproj**

## Step 2: Build and Run

In Xcode:
1. Wait for Xcode to finish indexing (progress bar in top center)
2. Select **"My Mac"** as the destination (top toolbar)
3. Press **⌘R** (or click the ▶️ Play button)

## Step 3: Find Your Menu Bar Icon

Look for the **📝 note icon** in your menu bar (top right of your screen)

Click it and start taking notes! 🪶

---

## What You Get

✅ **Menu bar app** - Always accessible, never in your way
✅ **Rich text editing** - Bold, italic, headings, lists, and more
✅ **Markdown support** - Export and import markdown seamlessly
✅ **Categories** - Organize with colored categories
✅ **Recent notes** - Quick access to your last 20 notes
✅ **Auto-save drafts** - Never lose your work
✅ **Keyboard shortcuts** - ⌘B, ⌘I, ⌘⇧L, and more

---

## First Time Setup (Optional)

### If You See a Signing Error

1. In Xcode, select the **PerchNotes** project (blue icon at top)
2. Select the **PerchNotes** target
3. Go to **"Signing & Capabilities"** tab
4. Under **Team**, select your Apple ID or "None" for local testing

### Enable Dock Icon (Development Only)

If you want to see PerchNotes in the Dock while developing:

1. Open `PerchNotes/Info.plist`
2. Find `LSUIElement`
3. Change `<true/>` to `<false/>`
4. Build and run again

(Change it back to `<true/>` when you're done!)

---

## Keyboard Shortcuts Reference

### Formatting
- **⌘B** - Bold
- **⌘I** - Italic
- **⌘U** - Underline
- **⌘⌥1** - Heading 1
- **⌘⌥2** - Heading 2
- **⌘⌥3** - Heading 3
- **⌘⇧L** - Bullet list
- **⌘⇧N** - Numbered list
- **⌘⇧C** - Checkbox
- **⌘]** - Indent
- **⌘[** - Outdent
- **⌘K** - Insert link
- **⌘⇧R** - Horizontal rule
- **⌘⇧F** - Toggle formatting toolbar

### Actions
- **⌘↵** - Save note
- **Esc** - Close popover (or click away)

---

## Where Are My Notes?

Your notes are saved as JSON files in:
```
~/Library/Application Support/PerchNotes/
├── notes.json        # All your notes
├── categories.json   # Your categories
└── draft.txt         # Current draft (auto-saved)
```

You can back these up, version control them, or sync them with cloud storage!

---

## Troubleshooting

### "Build Failed" - Missing Files

If Xcode can't find the files:
1. Right-click **PerchNotes** folder in the sidebar
2. Select **"Add Files to PerchNotes..."**
3. Select all `.swift` files in the folder
4. Make sure **"Copy items if needed"** is **unchecked**
5. Click **Add**

### Menu Bar Icon Doesn't Appear

1. Make sure the app is running (check Activity Monitor)
2. Try restarting the app (⌘Q then ⌘R)
3. Check that `LSUIElement` is set to `<true/>` in Info.plist

### Xcode Won't Open the Project

Try:
```bash
cd ~/Developer/PerchNotes
xed .
```

This forces Xcode to open in the current directory.

---

## What's Next?

### Customize It!

**Colors**: Edit `CustomColors.swift` to change the color scheme
**Window Sizes**: Edit `MenuBarManager.PopoverSize` dimensions
**Placeholder**: Edit `PerchNotesView.placeholderText`

### Add Features!

Some ideas:
- Export all notes to a folder
- Search functionality
- Note pinning
- Tags in addition to categories
- iCloud sync
- Hotkey to open (global shortcut)

---

## Need Help?

Check out the full `README.md` for:
- Complete architecture overview
- File structure explanation
- Data storage details
- Customization guide

---

**Enjoy PerchNotes! 🪶**

Made with ❤️ using extracted components from Athena.
