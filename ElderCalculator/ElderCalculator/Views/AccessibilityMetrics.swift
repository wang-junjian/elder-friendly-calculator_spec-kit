import AppKit
import SwiftUI

/// 适老设计常量（research R5；UI 契约 U4–U8）。
/// 所有 UI 组件 MUST 引用本文件常量，禁止散落魔法数字（章程原则 I）。
enum AccessibilityMetrics {

    // MARK: 字号（U6：底线 ≥24pt，默认 ≥48pt）
    static let displayFontSizeDefault: CGFloat = 48
    static let displayFontSizeMinimum: CGFloat = 24
    static let buttonFontSize: CGFloat = 28

    // MARK: 点击目标与间距（U7：底线 44pt，默认 64pt，间距 ≥12pt）
    static let buttonMinimumSize: CGFloat = 44
    static let buttonDefaultSize: CGFloat = 64
    static let buttonSpacing: CGFloat = 12
    static let buttonCornerRadius: CGFloat = 14

    // MARK: 窗口（U4：默认 560×760，最小 480×640）
    static let windowDefaultSize = CGSize(width: 560, height: 760)
    static let windowMinimumSize = CGSize(width: 480, height: 640)

    // MARK: 配色（U8：对比度 ≥4.5:1，实现取更高）
    static let displayForegroundNS = NSColor.white
    static let displayBackgroundNS = NSColor.black
    static let buttonForegroundNS = NSColor.white
    static let buttonBackgroundNS = NSColor(white: 0.20, alpha: 1)   // 深灰，对比度约 12.6:1
    static let operatorBackgroundNS = NSColor(white: 0.35, alpha: 1) // 运算符按钮略浅，对比度约 7.0:1
    static let errorForegroundNS = NSColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1) // 亮黄，对比度约 15:1

    static var displayForeground: Color { Color(nsColor: displayForegroundNS) }
    static var displayBackground: Color { Color(nsColor: displayBackgroundNS) }
    static var buttonForeground: Color { Color(nsColor: buttonForegroundNS) }
    static var buttonBackground: Color { Color(nsColor: buttonBackgroundNS) }
    static var operatorBackground: Color { Color(nsColor: operatorBackgroundNS) }
    static var errorForeground: Color { Color(nsColor: errorForegroundNS) }

    // MARK: 对比度计算（WCAG 2.1 相对亮度公式）
    static func contrastRatio(foreground: NSColor, background: NSColor) -> Double {
        let l1 = relativeLuminance(foreground)
        let l2 = relativeLuminance(background)
        let (hi, lo) = (max(l1, l2), min(l1, l2))
        return (hi + 0.05) / (lo + 0.05)
    }

    private static func relativeLuminance(_ color: NSColor) -> Double {
        guard let rgb = color.usingColorSpace(.sRGB) else { return 0 }
        func channel(_ v: CGFloat) -> Double {
            v <= 0.03928 ? Double(v) / 12.92 : pow((Double(v) + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(rgb.redComponent)
             + 0.7152 * channel(rgb.greenComponent)
             + 0.0722 * channel(rgb.blueComponent)
    }
}
