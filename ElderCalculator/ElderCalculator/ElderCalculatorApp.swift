import SwiftUI

@main
struct ElderCalculatorApp: App {
    var body: some Scene {
        WindowGroup("计算器") {
            ContentView()
        }
        // U4：默认 560×760；内容最小尺寸即窗口最小尺寸（480×640，U5）
        .defaultSize(width: AccessibilityMetrics.windowDefaultSize.width,
                     height: AccessibilityMetrics.windowDefaultSize.height)
        .windowResizability(.contentMinSize)
    }
}
