import Foundation

/// 四则运算符。契约：contracts/calculator-engine-api.md
enum Operator: Equatable {
    case add, subtract, multiply, divide
}

/// 按键事件——鼠标点击与键盘输入统一映射为该枚举（FR-005）
enum KeyEvent: Equatable {
    case digit(Int)        // 0...9
    case decimalPoint
    case op(Operator)
    case equals
    case backspace
    case clear
}

/// 计算错误，显示文案为通俗中文（FR-007）
enum CalculationError: Error, Equatable {
    case divisionByZero    // 「不能除以 0」
    case overflow          // 「数字太大了」
}

/// 显示区状态：用户所见文本 + 错误标志 + 语音播报文本
struct DisplayState: Equatable {
    var text: String
    var isError: Bool
    var speechText: String
    /// T028：输入达 12 位上限后数字被忽略时为 true（spec Edge Case：轻微提示）
    var inputLimitReached: Bool = false
}
