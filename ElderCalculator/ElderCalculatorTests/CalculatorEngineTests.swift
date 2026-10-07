import XCTest
@testable import ElderCalculator

/// T008：US1 引擎行为测试（契约 C1/C2/C3/C7/C9/C11）
/// T015：US2 防错测试（契约 C4/C5/C6/C8/C10/C13）
final class CalculatorEngineTests: XCTestCase {

    private var engine: CalculatorEngine!

    override func setUp() {
        super.setUp()
        engine = CalculatorEngine()
    }

    private func send(_ events: KeyEvent...) {
        events.forEach { engine.send($0) }
    }

    // MARK: - US1

    // C1：初始状态
    func testInitialState() {
        XCTAssertEqual(engine.display.text, "0")
        XCTAssertFalse(engine.display.isError)
    }

    // C2：四则运算（US1 验收场景 1：12 + 7 = 19）
    func testBasicArithmetic() {
        send(.digit(1), .digit(2), .op(.add), .digit(7), .equals)
        XCTAssertEqual(engine.display.text, "19")

        send(.clear)
        send(.digit(2), .digit(0), .op(.subtract), .digit(8), .equals)
        XCTAssertEqual(engine.display.text, "12")

        send(.clear)
        send(.digit(3), .op(.multiply), .digit(4), .equals)
        XCTAssertEqual(engine.display.text, "12")

        send(.clear)
        send(.digit(8), .op(.divide), .digit(2), .equals)
        XCTAssertEqual(engine.display.text, "4")
    }

    // C3：同一事件序列结果一致（键盘与点击发送相同 KeyEvent）
    func testDeterministicForSameEventSequence() {
        let sequence: [KeyEvent] = [.digit(1), .digit(2), .op(.add), .digit(7), .equals]
        let a = CalculatorEngine()
        let b = CalculatorEngine()
        sequence.forEach { a.send($0); b.send($0) }
        XCTAssertEqual(a.display, b.display)
    }

    // C7：结果显示后直接输入数字，自动开始新计算（FR-009）
    func testDigitAfterResultStartsNewCalculation() {
        send(.digit(1), .digit(2), .op(.add), .digit(7), .equals)
        XCTAssertEqual(engine.display.text, "19")
        send(.digit(5))
        XCTAssertEqual(engine.display.text, "5")
    }

    // C9：结果格式化 —— 整数无小数点；1÷3 → 0.33333333（8 位四舍五入去尾零）
    func testResultFormatting() {
        send(.digit(1), .op(.divide), .digit(3), .equals)
        XCTAssertEqual(engine.display.text, "0.33333333")

        send(.clear)
        send(.digit(1), .op(.divide), .digit(4), .equals)
        XCTAssertEqual(engine.display.text, "0.25")
    }

    // 小数输入与 Decimal 精度（0.1 + 0.2 必须恰好 0.3，无浮点误差）
    func testDecimalPrecision() {
        send(.digit(0), .decimalPoint, .digit(1), .op(.add),
             .digit(0), .decimalPoint, .digit(2), .equals)
        XCTAssertEqual(engine.display.text, "0.3")
    }

    // C11：结果状态输入运算符，以结果继续链式运算
    func testChainedCalculationFromResult() {
        send(.digit(1), .digit(2), .op(.add), .digit(7), .equals)
        send(.op(.multiply), .digit(2), .equals)
        XCTAssertEqual(engine.display.text, "38")
    }

    // 小数点：重复输入被忽略；开头直接按小数点显示 "0."
    func testDecimalPointInput() {
        send(.decimalPoint)
        XCTAssertEqual(engine.display.text, "0.")
        send(.digit(5), .decimalPoint, .digit(2))
        XCTAssertEqual(engine.display.text, "0.52")
    }

    // MARK: - US2

    // C4：退格删除末位；删空回 "0"（FR-006）
    func testBackspace() {
        send(.digit(1), .digit(2), .digit(3))
        send(.backspace, .backspace)
        XCTAssertEqual(engine.display.text, "1")
        send(.backspace)
        XCTAssertEqual(engine.display.text, "0")
    }

    // C4：清除完全重置（FR-006）
    func testClear() {
        send(.digit(5), .op(.add), .digit(3))
        send(.clear)
        XCTAssertEqual(engine.display.text, "0")
        send(.digit(9), .equals)
        XCTAssertEqual(engine.display.text, "9", "清除后无待决运算，equals 应保持当前输入不变")
    }

    // C5：除零 → 通俗提示「不能除以 0」，isError=true；随后输入数字恢复（FR-007）
    func testDivisionByZero() {
        send(.digit(8), .op(.divide), .digit(0), .equals)
        XCTAssertTrue(engine.display.isError)
        XCTAssertEqual(engine.display.text, "不能除以 0")
        send(.digit(9))
        XCTAssertFalse(engine.display.isError)
        XCTAssertEqual(engine.display.text, "9")
    }

    // C5：错误状态下运算符/退格/等于不改变状态；clear 恢复
    func testErrorStateRecovery() {
        send(.digit(8), .op(.divide), .digit(0), .equals)
        XCTAssertTrue(engine.display.isError)
        send(.backspace, .op(.add), .equals)
        XCTAssertTrue(engine.display.isError, "错误状态下 backspace/op/equals 不得修改状态")
        send(.clear)
        XCTAssertFalse(engine.display.isError)
        XCTAssertEqual(engine.display.text, "0")
    }

    // C6：连续运算符以最后按下为准（FR-008：5 + × 3 = → 15）
    func testOperatorReplacement() {
        send(.digit(5), .op(.add), .op(.multiply), .digit(3), .equals)
        XCTAssertEqual(engine.display.text, "15")
    }

    // C8：单操作数数字部分超 12 位后的 digit 被忽略（FR-010）
    func testInputDigitLimit() {
        for _ in 0..<15 { send(.digit(9)) }
        XCTAssertEqual(engine.display.text, "999999999999", "最多允许 12 位数字")
        // 小数位同样受 12 位总量限制
        send(.clear)
        send(.digit(1), .decimalPoint)
        for _ in 0..<15 { send(.digit(3)) }
        XCTAssertEqual(engine.display.text.filter(\.isNumber).count, 12)
    }

    // C10：结果整数部分超 12 位 → 「数字太大了」（C10/R1）
    func testOverflow() {
        for _ in 0..<12 { send(.digit(9)) }
        send(.op(.multiply))
        for _ in 0..<12 { send(.digit(9)) }
        send(.equals)
        XCTAssertTrue(engine.display.isError)
        XCTAssertEqual(engine.display.text, "数字太大了")
    }

    // MARK: - Convergence（Phase 7）

    // T028：达 12 位上限后给出可感知提示（spec Edge Case：轻微提示，不得静默忽略）
    func testInputLimitHint() {
        for _ in 0..<12 { send(.digit(9)) }
        XCTAssertFalse(engine.display.inputLimitReached, "未超限时不得提示")
        send(.digit(9))  // 第 13 位被忽略
        XCTAssertTrue(engine.display.inputLimitReached, "超限输入被忽略时必须置提示标志")
        XCTAssertEqual(engine.display.text, "999999999999")
        send(.backspace)
        XCTAssertFalse(engine.display.inputLimitReached, "恢复有效操作后提示标志须复位")
    }

    // C13：任意事件序列不崩溃；display.text 永不为空、永不包含英文/Inf/NaN（SC-005）
    func testRandomEventSequencesNeverCrash() {
        let allEvents: [KeyEvent] = (0...9).map { .digit($0) } + [
            .decimalPoint, .op(.add), .op(.subtract), .op(.multiply), .op(.divide),
            .equals, .backspace, .clear
        ]
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<1000 {
            let fresh = CalculatorEngine()
            let length = Int.random(in: 1...20, using: &rng)
            for _ in 0..<length {
                fresh.send(allEvents.randomElement(using: &rng)!)
                XCTAssertFalse(fresh.display.text.isEmpty)
                XCTAssertFalse(fresh.display.text.contains("Inf"))
                XCTAssertFalse(fresh.display.text.lowercased().contains("nan"))
            }
        }
    }
}
