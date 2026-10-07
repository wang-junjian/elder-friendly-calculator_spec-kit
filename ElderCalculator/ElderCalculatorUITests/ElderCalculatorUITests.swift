import XCTest

/// T023：P1 关键路径 UI 冒烟测试（quickstart V1：12 + 7 = → 19）
final class ElderCalculatorUITests: XCTestCase {

    @MainActor
    func testBasicAdditionSmoke() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["key.1"].click()
        app.buttons["key.2"].click()
        app.buttons["key.add"].click()
        app.buttons["key.7"].click()
        app.buttons["key.equals"].click()

        let display = app.staticTexts["display.text"]
        XCTAssertEqual(display.value as? String ?? display.title, "19")
    }

    /// T024：冷启动性能（SC-004：启动至可交互 ≤2 秒）
    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
