import XCTest
@testable import ElderCalculator

/// T006：适老设计常量合规断言（UI 契约 U6–U8，章程原则 I/V）
final class AccessibilityMetricsTests: XCTestCase {

    // U6：结果显示字号 —— 任何允许窗口尺寸下 ≥24pt，默认窗口下 ≥48pt
    func testDisplayFontSizeMeetsElderlyBaseline() {
        XCTAssertGreaterThanOrEqual(AccessibilityMetrics.displayFontSizeMinimum, 24,
            "结果字号底线必须 ≥24pt（FR-002）")
        XCTAssertGreaterThanOrEqual(AccessibilityMetrics.displayFontSizeDefault, 48,
            "默认窗口下结果字号应显著高于底线（research R5）")
    }

    // U7：按钮点击目标 —— 底线 44×44pt，默认 ≥64×64pt；间距 ≥12pt
    func testButtonTargetSizeMeetsElderlyBaseline() {
        XCTAssertGreaterThanOrEqual(AccessibilityMetrics.buttonMinimumSize, 44,
            "按钮点击目标底线必须 ≥44×44pt（FR-003）")
        XCTAssertGreaterThanOrEqual(AccessibilityMetrics.buttonDefaultSize, 64,
            "默认按钮尺寸应 ≥64×64pt（research R5）")
        XCTAssertGreaterThanOrEqual(AccessibilityMetrics.buttonSpacing, 12,
            "按钮间距必须 ≥12pt 防误触（FR-003）")
    }

    // U8：文本/背景对比度 ≥4.5:1（章程原则 I；实现取更高值）
    func testTextContrastMeetsWCAGAA() {
        let displayRatio = AccessibilityMetrics.contrastRatio(
            foreground: AccessibilityMetrics.displayForegroundNS,
            background: AccessibilityMetrics.displayBackgroundNS)
        XCTAssertGreaterThanOrEqual(displayRatio, 4.5,
            "显示区对比度必须 ≥4.5:1（FR-004），实测 \(displayRatio)")

        let buttonRatio = AccessibilityMetrics.contrastRatio(
            foreground: AccessibilityMetrics.buttonForegroundNS,
            background: AccessibilityMetrics.buttonBackgroundNS)
        XCTAssertGreaterThanOrEqual(buttonRatio, 4.5,
            "按钮文字对比度必须 ≥4.5:1（FR-004），实测 \(buttonRatio)")

        let errorRatio = AccessibilityMetrics.contrastRatio(
            foreground: AccessibilityMetrics.errorForegroundNS,
            background: AccessibilityMetrics.displayBackgroundNS)
        XCTAssertGreaterThanOrEqual(errorRatio, 4.5,
            "错误提示对比度必须 ≥4.5:1（T017），实测 \(errorRatio)")
    }

    // U4：窗口尺寸约束
    func testWindowSizeConstraints() {
        XCTAssertEqual(AccessibilityMetrics.windowMinimumSize.width, 480)
        XCTAssertEqual(AccessibilityMetrics.windowMinimumSize.height, 640)
        XCTAssertGreaterThanOrEqual(AccessibilityMetrics.windowDefaultSize.width,
            AccessibilityMetrics.windowMinimumSize.width)
        XCTAssertGreaterThanOrEqual(AccessibilityMetrics.windowDefaultSize.height,
            AccessibilityMetrics.windowMinimumSize.height)
    }
}
