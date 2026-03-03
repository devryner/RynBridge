# RynBridge iOS Playground

## Setup

1. **Build the web playground first:**
   ```bash
   cd <project-root>
   pnpm install && pnpm build
   bash scripts/copy-playground-assets.sh
   ```

2. **Create Xcode project:**
   - Open Xcode → File → New → Project → App (iOS)
   - Product Name: `RynBridgePlayground`
   - Organization Identifier: `io.rynbridge`
   - Interface: SwiftUI, Language: Swift
   - Save to `playground/ios/`

3. **Replace generated files** with the ones in `RynBridgePlayground/`:
   - `RynBridgePlaygroundApp.swift`
   - `ContentView.swift`
   - Add `BridgeWebView.swift` to the target

4. **Add RynBridge SDK as a local package dependency:**
   - File → Add Package Dependencies → Add Local → select `ios/` directory
   - Add all products: RynBridge, RynBridgeDevice, RynBridgeStorage, RynBridgeSecureStorage, RynBridgeUI

5. **Add web assets:**
   - Drag `RynBridgePlayground/Resources/` folder into the Xcode project
   - Ensure "Copy items if needed" is checked and "Create folder references" is selected

6. **Run** on iOS 17+ Simulator

## Debugging

- Safari → Develop → Simulator → Inspectable WebView
- `webView.isInspectable = true` is already set in `BridgeWebView.swift`
