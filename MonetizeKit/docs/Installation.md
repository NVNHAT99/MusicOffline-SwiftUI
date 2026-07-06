# Installation

MonetizeKit can be integrated into your iOS project using Swift Package Manager.

## Requirements

Before installing MonetizeKit, ensure your project meets these requirements:

- **iOS 15.0** or later
- **Swift 5.7** or later
- **Xcode 14.0** or later

## Swift Package Manager

### Using Xcode

1. In Xcode, open your project and navigate to **File** → **Add Package Dependencies...**

2. Enter the MonetizeKit repository URL:
   ```
   https://github.com/phuongddx/MonetizeKit
   ```

3. Choose the version rule:
   - **Up to Next Major Version**: `1.0.0` < `2.0.0`
   - **Up to Next Minor Version**: `1.0.0` < `1.1.0`
   - **Exact Version**: `1.0.0`
   - **Branch**: `main`
   - **Commit**: Specific commit hash

4. Click **Add Package**

5. Select the products you want to add to your targets:
   - **MonetizeKit** - The main library
   
6. Click **Add Package**

### Using Package.swift

If you're using Swift Package Manager through a `Package.swift` file, add MonetizeKit as a dependency:

```swift
// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "YourProject",
    platforms: [
        .iOS(.v15)
    ],
    dependencies: [
        .package(
            url: "https://github.com/phuongddx/MonetizeKit", 
            from: "1.0.0"
        )
    ],
    targets: [
        .target(
            name: "YourTarget",
            dependencies: ["MonetizeKit"]
        )
    ]
)
```

Then run:
```bash
swift package resolve
```

## Import MonetizeKit

Once installed, import MonetizeKit in your Swift files:

```swift
import MonetizeKit
```

## App Store Connect Configuration

Before using MonetizeKit, ensure you have:

1. **Created In-App Purchase products** in App Store Connect
2. **Signed the Paid Applications Agreement** in App Store Connect
3. **Added the In-App Purchase capability** to your app in Xcode:
   - Select your project in Xcode
   - Select your app target
   - Go to **Signing & Capabilities**
   - Click **+ Capability**
   - Add **In-App Purchase**

## Verify Installation

To verify MonetizeKit is properly installed, try initializing the IAPManager:

```swift
import MonetizeKit

// In your app's initialization code
Task {
    await IAPManager.shared.configure(
        productIds: ["com.yourapp.testproduct"]
    )
    print("MonetizeKit configured successfully!")
}
```

## Troubleshooting

### Package Resolution Failed

If you encounter package resolution issues:

1. Clean your build folder: **Product** → **Clean Build Folder** (⇧⌘K)
2. Reset package caches: **File** → **Packages** → **Reset Package Caches**
3. Update to latest version: **File** → **Packages** → **Update to Latest Package Versions**

### Import Error

If you get "No such module 'MonetizeKit'" error:

1. Ensure the package is added to your target
2. Build the project once (⌘B)
3. Check that your deployment target is iOS 15.0 or later

### StoreKit Configuration

For testing in the simulator:

1. Create a StoreKit Configuration file:
   - **File** → **New** → **File**
   - Choose **StoreKit Configuration File**
   - Add your test products

2. Enable the configuration:
   - Edit your scheme
   - Go to **Run** → **Options**
   - Select your StoreKit Configuration file

## Next Steps

- Continue to the [Quick Start Guide](Quick-Start)
- Learn about [Configuration](Configuration)
- Explore [Code Examples](Examples)
