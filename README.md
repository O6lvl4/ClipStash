# ClipStash

A lightweight clipboard history manager for macOS, built with pure Objective-C and the Cocoa/Carbon frameworks. No Electron, no Swift, no dependencies — just native code.

## Features

- Menu bar resident app (no Dock icon)
- Polls the system pasteboard and keeps the last 20 text entries
- Global hotkey **Cmd+Shift+V** pops up the history at the mouse cursor
- Selecting an entry pastes it directly into the active app
- Deduplicates entries automatically
- Launch at login support

## Build

```bash
make          # build
make run      # build & launch
make install  # copy to /Applications
make clean    # remove build artifacts
```

Requires Xcode Command Line Tools (tested with Xcode 14.3 / macOS 12+).

## Architecture

```
ClipStash/
├── main.m               App entry point
├── AppDelegate.h/m      Menu bar UI, hotkey registration, paste simulation
├── ClipboardMonitor.h/m NSPasteboard polling, history management
├── Info.plist            Bundle metadata (LSUIElement for menu-bar-only)
```

**~200 lines of Objective-C.** The entire app compiles in under a second with a single `clang` invocation.

## How It Works

`ClipboardMonitor` polls `NSPasteboard.generalPasteboard` every 0.5 seconds. When `changeCount` increments, the new string is pushed to the front of a bounded array.

`AppDelegate` registers a Carbon `EventHotKey` for Cmd+Shift+V. On trigger, it builds an `NSMenu` from the history and presents it at the current mouse location via `popUpMenuPositioningItem:atLocation:inView:`. Selection writes to the pasteboard and simulates Cmd+V via `CGEventPost`.

## License

MIT
