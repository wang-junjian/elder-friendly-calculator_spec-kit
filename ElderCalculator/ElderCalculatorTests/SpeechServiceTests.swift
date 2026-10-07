import XCTest
@testable import ElderCalculator

/// T018：US3 语音播报测试（契约 C12、UI 契约 U14/U15）
final class SpeechServiceTests: XCTestCase {

    // MARK: - 替身

    private final class MockSynthesizer: SpeechSynthesizing {
        private(set) var calls: [(action: String, text: String)] = []
        func speak(_ text: String) { calls.append(("speak", text)) }
        func stop() { calls.append(("stop", "")) }
    }

    // MARK: - SpeechService 行为（U14/U15）

    // 开关关闭时不发起播报（U14：默认关闭）
    func testSpeakSuppressedWhenDisabled() {
        let mock = MockSynthesizer()
        let service = SpeechService(synthesizer: mock, isEnabled: false)
        service.speak("测试")
        XCTAssertTrue(mock.calls.isEmpty, "语音关闭时不得调用合成器")
    }

    // 开关开启时播报文本
    func testSpeakPassesTextWhenEnabled() {
        let mock = MockSynthesizer()
        let service = SpeechService(synthesizer: mock, isEnabled: true)
        service.speak("3 乘 4 等于 12")
        XCTAssertEqual(mock.calls.last?.text, "3 乘 4 等于 12")
    }

    // U15：新播报打断进行中的旧播报（先 stop 再 speak）
    func testNewSpeechInterruptsOngoing() {
        let mock = MockSynthesizer()
        let service = SpeechService(synthesizer: mock, isEnabled: true)
        service.speak("第一句")
        service.speak("第二句")
        let actions = mock.calls.map(\.action)
        XCTAssertEqual(actions, ["stop", "speak", "stop", "speak"],
            "每次播报必须先停止旧播报（打断策略）")
    }

    // MARK: - 引擎 speechText 口语句（C12）

    // 完整算式：「12 加 7 等于 19」
    func testSpeechTextForFullEquation() {
        let engine = CalculatorEngine()
        [KeyEvent.digit(1), .digit(2), .op(.add), .digit(7), .equals]
            .forEach { engine.send($0) }
        XCTAssertEqual(engine.display.speechText, "12 加 7 等于 19")
    }

    // 小数点读「点」：0.5 → 「0 点 5」
    func testSpeechTextForDecimal() {
        let engine = CalculatorEngine()
        [KeyEvent.digit(0), .decimalPoint, .digit(5)].forEach { engine.send($0) }
        XCTAssertEqual(engine.display.speechText, "0 点 5")
    }

    // 负号读「负」：5 − 8 = → 「5 减 8 等于 负 3」
    func testSpeechTextForNegativeResult() {
        let engine = CalculatorEngine()
        [KeyEvent.digit(5), .op(.subtract), .digit(8), .equals]
            .forEach { engine.send($0) }
        XCTAssertEqual(engine.display.speechText, "5 减 8 等于 负 3")
    }

    // 乘除口语词
    func testSpeechTextForMultiplyAndDivide() {
        let engine = CalculatorEngine()
        [KeyEvent.digit(3), .op(.multiply), .digit(4), .equals].forEach { engine.send($0) }
        XCTAssertEqual(engine.display.speechText, "3 乘 4 等于 12")

        let engine2 = CalculatorEngine()
        [KeyEvent.digit(8), .op(.divide), .digit(2), .equals].forEach { engine2.send($0) }
        XCTAssertEqual(engine2.display.speechText, "8 除 2 等于 4")
    }

    // 错误时读提示文案
    func testSpeechTextForError() {
        let engine = CalculatorEngine()
        [KeyEvent.digit(8), .op(.divide), .digit(0), .equals].forEach { engine.send($0) }
        XCTAssertEqual(engine.display.speechText, "不能除以 0")
    }
}
