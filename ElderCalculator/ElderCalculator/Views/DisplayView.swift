import SwiftUI

/// 结果显示区（UI 契约 U6/U8；T017 扩展错误态样式）
struct DisplayView: View {
    let display: DisplayState

    var body: some View {
        Text(display.text)
            .font(.system(size: AccessibilityMetrics.displayFontSizeDefault, weight: .medium))
            .foregroundStyle(display.isError
                ? AccessibilityMetrics.errorForeground
                : AccessibilityMetrics.displayForeground)
            // 数字过长时自适应缩小，但不低于 24pt 适老底线（U6）
            .minimumScaleFactor(AccessibilityMetrics.displayFontSizeMinimum
                / AccessibilityMetrics.displayFontSizeDefault)
            .lineLimit(1)
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .trailing)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .background(AccessibilityMetrics.displayBackground)
            .accessibilityLabel(String(localized: "a11y.display.label"))
            .accessibilityValue(display.text)
            .accessibilityIdentifier("display.text")
    }
}
