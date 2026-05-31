# AGENTS.md

## Project Shape
- iOS 17 Swift app plus custom keyboard extension; `project.yml` is the XcodeGen source of truth.
- App target sources live in `SmartKeyboardApp/`; keyboard extension sources live in `SmartKeyboardKeyboard/`.
- Code shared by both targets lives in `SmartKeyboardShared/`; add it to both target source lists in `project.yml`.
- App/extension shared settings rely on the App Group `group.com.leogeng.smartkeyboard`, declared in both entitlements files and `project.yml`.
- The app entrypoint is `SmartKeyboardApp/SmartKeyboardApp.swift`; the current SwiftUI UI is concentrated in `SmartKeyboardApp/RootView.swift`.
- The real keyboard button behavior is in `SmartKeyboardKeyboard/KeyboardViewController.swift`, especially `handleTap(_:)`.

## Commands
- Regenerate the Xcode project after changing `project.yml`: `xcodegen generate`.
- List schemes: `xcodebuild -list -project "SmartKeyboard.xcodeproj"`.
- Verified build command: `xcodebuild -project "SmartKeyboard.xcodeproj" -scheme "SmartKeyboardKeyboard" -destination 'generic/platform=iOS Simulator' build`.
- There are currently no test targets or test schemes in `project.yml`.

## Current Implementation Gotchas
- API settings and preferences are stored through `SmartKeyboardShared/SharedSettings.swift`; this currently uses shared `UserDefaults`, not Keychain.
- `SmartKeyboardKeyboard/KeyboardViewController.swift` calls an OpenAI-compatible `/chat/completions` endpoint when API settings exist, then falls back to `LocalCandidateGenerator` on missing config or request failure.
- Candidate selection replaces `textDocumentProxy.documentContextBeforeInput`; be careful with cursor/context assumptions before changing replacement behavior.
- Preference controls in `RootView.swift` are persisted through `SharedSettings`; action ordering and demo keyboard panels are still prototype UI only.
- Home status rows are conservative text only and do not query real system keyboard or Full Access state.

## Product Docs
- `PRD.md` and `UI_DESIGN.md` describe intended behavior, not necessarily implemented behavior; verify against Swift source before relying on them.
