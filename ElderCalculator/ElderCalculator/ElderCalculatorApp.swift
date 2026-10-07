import AppKit
import SwiftUI

@main
struct ElderCalculatorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

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

/// 窗口保障（适老底线：任何情况下窗口不得对用户不可见）
private final class AppDelegate: NSObject, NSApplicationDelegate {

    /// 显示器配置变化后，系统恢复的窗口位置可能落在当前屏幕之外——居中回主屏
    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.async {
            let visibleFrames = NSScreen.screens.map(\.visibleFrame)
            for window in NSApp.windows {
                let onAnyScreen = visibleFrames.contains { $0.intersects(window.frame) }
                if !onAnyScreen { window.center() }
            }
        }
    }

    /// 点击 Dock 图标时若无可见窗口，重新打开主窗口
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in sender.windows { window.makeKeyAndOrderFront(nil) }
        }
        return true
    }

    /// 激活时把窗口带到当前空间（macOS 可能把窗口留在其他 Mission Control 桌面，
    /// 对老年用户等同于"应用消失了"）
    func applicationDidBecomeActive(_ notification: Notification) {
        for window in NSApp.windows {
            window.collectionBehavior.insert(.moveToActiveSpace)
            window.makeKeyAndOrderFront(nil)
        }
    }
}
