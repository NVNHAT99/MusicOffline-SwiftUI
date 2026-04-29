# Phase 02 - File Structure + DesignSystem

**Priority:** P0 | **Status:** ⬜ Todo | **Depends on:** Phase 01 | **Blocks:** Phase 03

## Context Links
- Ref: `/Users/nhat/Dev/IOS/EZTranslate/EZTranslate/DesignSystem/DesignToken.swift`
- Ref: `/Users/nhat/Dev/IOS/my-fax-app/EasyFax/EasyFax/Utilities/Fonts/AppFont.swift`
- Ref: `/Users/nhat/Dev/IOS/my-fax-app/EasyFax/EasyFax/Utilities/Extensions/Color+Ext.swift`

## Overview

Align file structure to match EasyFax/EZTranslate standards. Additive changes + cleanup — no logic changes.

**Issues found:**
- No `DesignSystem/` folder — font/spacing/color used inline throughout views
- No `AppFont.swift` — font sizes hardcoded everywhere (`font(.system(size: 24, weight: .semibold))`)
- Color extensions only cover UIKit (`UIColor+Ext.swift`), no SwiftUI `Color` equivalents
- `Commons/Router/AppRouter/AppRouter.swift` is entirely commented-out dead code
- `Commons/Router/Protocols/Routable.swift.backup` is a backup file
- `Commons/Extension/Demos/DemoDelayTouch.swift` + `Commons/Logger/LoggerExample.swift` are example/demo files
- `AppRoute.swift` is correctly located in `Core/Router/AppRoute.swift` ✅ (not in Commons)

## Requirements
- `DesignSystem/` folder with `DesignToken.swift` and `AppFont.swift`
- SwiftUI `Color` extensions alongside existing `UIColor+Ext.swift`
- Demo/backup files removed
- `AppRouter.swift` cleaned up or deleted

## Related Code Files

**Create:**
- `MusicApp/DesignSystem/DesignToken.swift`
- `MusicApp/DesignSystem/AppFont.swift`
- `MusicApp/Commons/Extension/Color+Ext.swift`

**Delete:**
- `MusicApp/Commons/Extension/Demos/DemoDelayTouch.swift`
- `MusicApp/Commons/Logger/LoggerExample.swift`
- `MusicApp/Commons/Router/Protocols/Routable.swift.backup`
- `MusicApp/Commons/Router/AppRouter/AppRouter.swift` (all commented-out, dead code)

**No file moves** — Xcode project file requires manual drag/drop; adding new files in existing folders is safe.

## Implementation Steps

1. **Create `DesignSystem/DesignToken.swift`**:
```swift
enum DesignToken {
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let full: CGFloat = 999
    }
    enum Animation {
        static let fast: Double = 0.15
        static let standard: Double = 0.3
        static let slow: Double = 0.5
    }
    enum Shadow {
        static let small: CGFloat = 4
        static let medium: CGFloat = 10
        static let large: CGFloat = 20
    }
}
```

2. **Create `DesignSystem/AppFont.swift`**:
```swift
import SwiftUI
enum AppFont {
    static func largeTitle() -> Font { .system(size: 28, weight: .bold, design: .rounded) }
    static func title() -> Font { .system(size: 22, weight: .semibold, design: .rounded) }
    static func headline() -> Font { .system(size: 18, weight: .semibold) }
    static func body() -> Font { .system(size: 16, weight: .regular) }
    static func callout() -> Font { .system(size: 14, weight: .regular) }
    static func caption() -> Font { .system(size: 12, weight: .regular) }
    static func tabLabel() -> Font { .system(size: 10, weight: .regular) }
}
```

3. **Create `Commons/Extension/Color+Ext.swift`**:
```swift
import SwiftUI
extension Color {
    init(hexString: String) { /* port from UIColor+Ext */ }
    static let backgroundColor = Color(hexString: "#1C1C1E")
    static let accentColor = Color(hexString: "#FF6B6B")
    static let secondaryText = Color.white.opacity(0.7)
    static let cardBackground = Color.white.opacity(0.05)
}
```

4. **Delete** 4 dead-code files listed above

5. **Add new files to Xcode project**: New `.swift` files must be added via Xcode or `xcodebuild` to be compiled. Run build to confirm:
   ```bash
   xcodebuild build -workspace MusicApp.xcworkspace -scheme MusicApp \
     -destination 'platform=iOS Simulator,name=iPhone 16'
   ```
   
   > **Note:** If new files aren't in `.xcodeproj`, they won't compile. Must add them in Xcode manually after creation, OR use a script.

## Todo List
- [ ] Create `DesignSystem/DesignToken.swift`
- [ ] Create `DesignSystem/AppFont.swift`
- [ ] Create `Commons/Extension/Color+Ext.swift` (SwiftUI version)
- [ ] Delete `Commons/Extension/Demos/DemoDelayTouch.swift`
- [ ] Delete `Commons/Logger/LoggerExample.swift`
- [ ] Delete `Commons/Router/Protocols/Routable.swift.backup`
- [ ] Delete `Commons/Router/AppRouter/AppRouter.swift`
- [ ] Add new files to Xcode project (or verify build picks them up)
- [ ] Build verify

## Success Criteria
- `DesignSystem/` folder exists with DesignToken + AppFont
- No demo/backup/dead files in codebase
- Build clean

## Risk Assessment
- **Low** — purely additive, no logic changes
- **Note** — Xcode requires files to be added to `.xcodeproj`; if build fails after file creation, the file needs to be added in Xcode manually
