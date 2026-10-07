import SwiftUI

/// 键盘网格（UI 契约 U2/U7/U9；research R3：keyboardShortcut 方案兼容 macOS 13）
struct KeypadView: View {
    let onKey: (KeyEvent) -> Void

    // U12：尊重系统「减弱动态效果」「增大对比度」设置
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    var body: some View {
        VStack(spacing: AccessibilityMetrics.buttonSpacing) {
            row([
                key(title: String(localized: "button.clear"), event: .clear,
                    shortcut: .escape, id: "key.clear",
                    label: String(localized: "a11y.clear.label"),
                    hint: String(localized: "a11y.clear.hint")),
                key(title: String(localized: "button.backspace"), event: .backspace,
                    shortcut: .delete, id: "key.backspace",
                    label: String(localized: "a11y.backspace.label"),
                    hint: String(localized: "a11y.backspace.hint")),
                opKey("÷", .divide, "/")
            ])
            row([digitKey(7), digitKey(8), digitKey(9), opKey("×", .multiply, "*")])
            row([digitKey(4), digitKey(5), digitKey(6), opKey("−", .subtract, "-")])
            row([digitKey(1), digitKey(2), digitKey(3), opKey("+", .add, "+")])
            row([
                digitKey(0),
                key(title: ".", event: .decimalPoint, shortcut: KeyEquivalent("."),
                    id: "key.decimal",
                    label: String(localized: "a11y.decimal.label"),
                    hint: String(localized: "a11y.decimal.hint")),
                key(title: "=", event: .equals, shortcut: .return, id: "key.equals",
                    label: String(localized: "a11y.equals.label"),
                    hint: String(localized: "a11y.equals.hint"),
                    isOperator: true)
            ])
        }
        .padding(AccessibilityMetrics.buttonSpacing)
        .background(AccessibilityMetrics.displayBackground)
    }

    // MARK: - 行与按钮构造

    @ViewBuilder
    private func row(_ buttons: [CalculatorKey]) -> some View {
        HStack(spacing: AccessibilityMetrics.buttonSpacing) {
            ForEach(buttons) { button in
                Button {
                    onKey(button.event)
                } label: {
                    Text(button.title)
                        .font(.system(size: AccessibilityMetrics.buttonFontSize, weight: .semibold))
                        .foregroundStyle(AccessibilityMetrics.buttonForeground)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: AccessibilityMetrics.buttonDefaultSize)
                        .background(button.isOperator
                            ? AccessibilityMetrics.operatorBackground
                            : AccessibilityMetrics.buttonBackground)
                        .clipShape(RoundedRectangle(
                            cornerRadius: AccessibilityMetrics.buttonCornerRadius))
                        // U12：增大对比度模式下为按钮加白色描边，强化边界
                        .overlay {
                            if colorSchemeContrast == .increased {
                                RoundedRectangle(cornerRadius: AccessibilityMetrics.buttonCornerRadius)
                                    .stroke(AccessibilityMetrics.buttonForeground, lineWidth: 2)
                            }
                        }
                }
                .buttonStyle(ElderButtonStyle(reduceMotion: reduceMotion))
                .keyboardShortcut(button.shortcut, modifiers: [])
                .accessibilityLabel(button.label)
                .accessibilityHint(button.hint)
                .accessibilityIdentifier(button.id)
            }
        }
    }

    private func digitKey(_ d: Int) -> CalculatorKey {
        key(title: String(d), event: .digit(d), shortcut: KeyEquivalent(Character(String(d))),
            id: "key.\(d)",
            label: String(format: String(localized: "a11y.digit.label"), d),
            hint: String(format: String(localized: "a11y.digit.hint"), d))
    }

    private func opKey(_ symbol: String, _ op: Operator, _ keyChar: String) -> CalculatorKey {
        let labelKey: String = {
            switch op {
            case .add: return "a11y.add.label"
            case .subtract: return "a11y.subtract.label"
            case .multiply: return "a11y.multiply.label"
            case .divide: return "a11y.divide.label"
            }
        }()
        return key(title: symbol, event: .op(op), shortcut: KeyEquivalent(Character(keyChar)),
                   id: "key.\(op)", label: String(localized: String.LocalizationValue(labelKey)),
                   hint: String(localized: "a11y.operator.hint"), isOperator: true)
    }

    private func key(title: String, event: KeyEvent, shortcut: KeyEquivalent, id: String,
                     label: String, hint: String, isOperator: Bool = false) -> CalculatorKey {
        CalculatorKey(title: title, event: event, shortcut: shortcut, id: id,
                      label: label, hint: hint, isOperator: isOperator)
    }
}

/// 按键描述模型
private struct CalculatorKey: Identifiable {
    let title: String
    let event: KeyEvent
    let shortcut: KeyEquivalent
    let id: String
    let label: String
    let hint: String
    let isOperator: Bool
}

/// 按下态即时视觉反馈（U9：<100ms 高亮；U12：「减弱动态效果」时禁用缩放动画）
private struct ElderButtonStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .scaleEffect(!reduceMotion && configuration.isPressed ? 0.96 : 1.0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.08),
                       value: configuration.isPressed)
    }
}
