import SwiftUI

/// 结果显示区（UI 契约 U6/U8；T017 扩展错误态样式）
/// T027：字号由 ContentView 按窗口尺寸缩放传入；T028：输入上限提示
struct DisplayView: View {
    let display: DisplayState
    let fontSize: CGFloat

    var body: some View {
        VStack(alignment: .trailing, spacing: AccessibilityMetrics.verticalPadding) {
            Text(display.text)
                .font(.system(size: fontSize, weight: .medium))
                .foregroundStyle(display.isError
                    ? AccessibilityMetrics.errorForeground
                    : AccessibilityMetrics.displayForeground)
                // 数字过长时自适应缩小，但不低于 24pt 适老底线（U6）
                .minimumScaleFactor(AccessibilityMetrics.displayFontSizeMinimum / fontSize)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .accessibilityLabel(String(localized: "a11y.display.label"))
                .accessibilityValue(display.text)
                .accessibilityIdentifier("display.text")

            // T028：达 12 位上限时的轻微提示；恒占位（opacity 控制）避免布局跳动
            Text(String(localized: "hint.inputLimit"))
                .font(.system(size: AccessibilityMetrics.hintFontSize))
                .foregroundStyle(AccessibilityMetrics.errorForeground)
                .opacity(display.inputLimitReached ? 1 : 0)
                .accessibilityHidden(!display.inputLimitReached)
        }
        .frame(maxWidth: .infinity,
               minHeight: AccessibilityMetrics.displayAreaMinHeight)
        .padding(.horizontal, AccessibilityMetrics.horizontalPadding)
        .background(AccessibilityMetrics.displayBackground)
    }
}
