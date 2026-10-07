import Combine
import Foundation

/// 计算引擎：纯逻辑状态机（research R1/R2，data-model.md 转移表）。
/// 不依赖 SwiftUI/AppKit，UI 层唯一的逻辑入口（contracts/calculator-engine-api.md）。
final class CalculatorEngine: ObservableObject {

    @Published private(set) var display = DisplayState(text: "0", isError: false, speechText: "0")

    // MARK: - 内部状态

    private var accumulator: Decimal?          // 已确认的第一操作数
    private var pendingOperator: Operator?     // 待执行运算符
    private var currentInput = "0"             // 正在输入的操作数原文
    private var isEnteringNumber = false       // 是否处于数字输入中
    private var showingResult = false          // 是否刚得出结果
    private var error: CalculationError?       // 当前错误（FR-007，C5/C10）
    private var equationSpeech = ""            // 最近一次算式的口语句（C12）
    private var limitHintPending = false       // T028：超限数字刚被忽略，下一次发布置提示标志

    /// FR-010：单操作数数字部分上限（C8）
    private static let maxInputDigits = 12

    /// C10：结果整数部分超过 12 位视为溢出（R1：999999999999² → 「数字太大了」）
    private static let overflowThreshold = Decimal(1_000_000_000_000)

    init() {}

    // MARK: - 事件入口（唯一状态推进方式）

    func send(_ event: KeyEvent) {
        if error != nil {
            // 错误状态：仅 digit / clear 可恢复（C5 不变式）
            switch event {
            case .digit(let d): reset(); inputDigit(d)
            case .clear: reset()
            default: break
            }
            publish()
            return
        }
        switch event {
        case .digit(let d):
            inputDigit(d)
        case .decimalPoint:
            inputDecimalPoint()
        case .op(let op):
            selectOperator(op)
        case .equals:
            evaluate()
        case .backspace:
            deleteLastDigit()
        case .clear:
            reset()
        }
        publish()
    }

    // MARK: - 数字与小数点

    private func inputDigit(_ d: Int) {
        precondition((0...9).contains(d), "digit 事件取值必须为 0...9")
        if showingResult { reset() }           // C7：结果后直接输入，开始新计算
        if !isEnteringNumber {
            currentInput = d == 0 ? "0" : String(d)
            isEnteringNumber = true
            return
        }
        if currentInput == "0" {
            currentInput = String(d)           // 前导零替换（"0" 后按 5 → "5"）
            return
        }
        guard currentInput.filter(\.isNumber).count < Self.maxInputDigits else {
            limitHintPending = true              // T028：超限忽略须给出可感知提示
            return
        } // C8
        currentInput.append(String(d))
    }

    private func inputDecimalPoint() {
        if showingResult {
            reset()
            currentInput = "0."
            isEnteringNumber = true
            return
        }
        if !isEnteringNumber {
            currentInput = "0."
            isEnteringNumber = true
            return
        }
        if !currentInput.contains(".") {
            currentInput.append(".")
        }
    }

    // MARK: - 退格与清除（C4，FR-006）

    private func deleteLastDigit() {
        guard isEnteringNumber else { return }  // 结果/运算符待输入状态下退格无效
        currentInput.removeLast()
        if currentInput.isEmpty || currentInput == "-" {
            currentInput = "0"
            isEnteringNumber = false
        }
    }

    private func reset() {
        accumulator = nil
        pendingOperator = nil
        currentInput = "0"
        isEnteringNumber = false
        showingResult = false
        error = nil
    }

    // MARK: - 运算符与求值

    private func selectOperator(_ op: Operator) {
        if isEnteringNumber || showingResult {
            accumulator = Decimal(string: currentInput) ?? 0
            pendingOperator = op
            isEnteringNumber = false
            showingResult = false
        } else if pendingOperator != nil {
            pendingOperator = op               // 连续运算符：以最后按下为准（C6，FR-008）
        }
    }

    private func evaluate() {
        guard let op = pendingOperator, let acc = accumulator else { return }
        // 未输入第二操作数时复用第一操作数（data-model：「5 + =」→ 10）
        let second = isEnteringNumber ? (Decimal(string: currentInput) ?? 0) : acc
        if op == .divide && second == 0 {
            enterError(.divisionByZero)        // C5，FR-007
            return
        }
        let result: Decimal
        switch op {
        case .add: result = acc + second
        case .subtract: result = acc - second
        case .multiply: result = acc * second
        case .divide: result = acc / second
        }
        if result >= Self.overflowThreshold || result <= -Self.overflowThreshold {
            enterError(.overflow)              // C10，R1
            return
        }
        currentInput = Self.format(result)
        // C12：算式口语句，如「12 加 7 等于 19」
        equationSpeech = "\(Self.spoken(Self.format(acc))) \(Self.operatorWord(op)) "
            + "\(Self.spoken(Self.format(second))) "
            + "\(String(localized: "speech.equals", defaultValue: "等于")) "
            + "\(Self.spoken(currentInput))"
        accumulator = nil
        pendingOperator = nil
        isEnteringNumber = false
        showingResult = true
    }

    private func enterError(_ e: CalculationError) {
        accumulator = nil
        pendingOperator = nil
        isEnteringNumber = false
        showingResult = false
        error = e
    }

    // MARK: - 显示

    private func publish() {
        // T028：提示标志仅跟随本次发布，消费后复位
        let limitHint = limitHintPending
        limitHintPending = false
        if let error {
            let message: String
            switch error {
            case .divisionByZero:
                message = String(localized: "error.divisionByZero", defaultValue: "不能除以 0")
            case .overflow:
                message = String(localized: "error.overflow", defaultValue: "数字太大了")
            }
            display = DisplayState(text: message, isError: true, speechText: message,
                                   inputLimitReached: limitHint)
        } else {
            // C12：结果状态播报完整算式；输入过程播报当前数字的口语形式
            let speech = showingResult ? equationSpeech : Self.spoken(currentInput)
            display = DisplayState(text: currentInput, isError: false, speechText: speech,
                                   inputLimitReached: limitHint)
        }
    }

    // MARK: - 口语化（C12）

    /// 数字文本 → 中文口语形式：小数点读「点」、负号读「负」（T018）
    static func spoken(_ text: String) -> String {
        var s = text
        var prefix = ""
        if s.hasPrefix("-") {
            prefix = String(localized: "speech.negative", defaultValue: "负") + " "
            s.removeFirst()
        }
        let point = " " + String(localized: "speech.point", defaultValue: "点") + " "
        return prefix + s.replacingOccurrences(of: ".", with: point)
    }

    static func operatorWord(_ op: Operator) -> String {
        switch op {
        case .add: return String(localized: "speech.add", defaultValue: "加")
        case .subtract: return String(localized: "speech.subtract", defaultValue: "减")
        case .multiply: return String(localized: "speech.multiply", defaultValue: "乘")
        case .divide: return String(localized: "speech.divide", defaultValue: "除")
        }
    }

    /// C9：四舍五入至最多 8 位小数并去除尾零；整数结果无小数点（research R1）
    static func format(_ value: Decimal) -> String {
        var input = value
        var rounded = Decimal()
        NSDecimalRound(&rounded, &input, 8, .plain)
        var s = NSDecimalNumber(decimal: rounded).stringValue
        if s.contains(".") {
            while s.hasSuffix("0") { s.removeLast() }
            if s.hasSuffix(".") { s.removeLast() }
        }
        if s == "-0" { s = "0" }
        return s
    }
}
