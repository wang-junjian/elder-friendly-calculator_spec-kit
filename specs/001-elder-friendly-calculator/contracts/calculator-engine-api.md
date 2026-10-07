# Contract: CalculatorEngine 公共 API

**Date**: 2026-10-07 | **Consumers**: SwiftUI 视图层、SpeechService、XCTest

计算引擎是本应用唯一的公共逻辑接口。UI 层不得包含任何计算分支逻辑。

## 类型定义

```swift
enum Operator { case add, subtract, multiply, divide }

enum KeyEvent {
    case digit(Int)        // 0...9；越界值由调用方保证不出现
    case decimalPoint
    case op(Operator)
    case equals
    case backspace
    case clear
}

enum CalculationError: Error {
    case divisionByZero    // 显示文案："不能除以 0"
    case overflow          // 显示文案："数字太大了"
}

struct DisplayState: Equatable {
    var text: String            // 显示区文本（数字或通俗中文提示）
    var isError: Bool           // 是否处于错误提示状态
    var speechText: String      // 供播报的中文口语形式（如 "12 加 7 等于 19"）
}
```

## 接口

```swift
final class CalculatorEngine: ObservableObject {
    @Published private(set) var display: DisplayState
    init()                                  // 初始 display.text == "0"
    func send(_ event: KeyEvent)            // 唯一状态推进入口
}
```

## 行为契约（对应功能需求）

| # | 契约 | 需求 |
|---|------|------|
| C1 | 初始状态 `text == "0"`，`isError == false` | FR-001 |
| C2 | 输入 `12 + 7 =` 后 `text == "19"` | US1 |
| C3 | 键盘与点击发送相同 `KeyEvent` 序列时结果完全一致 | FR-005 |
| C4 | `backspace` 删除当前输入末位；删空显示 "0"；`clear` 重置全部状态 | FR-006 |
| C5 | `8 ÷ 0 =` 后 `isError == true`，`text == "不能除以 0"`；随后输入数字即开始新计算 | FR-007 |
| C6 | 连续 `op` 事件以最后一个为准（`5 + × 3 =` → 15），不报错不连算 | FR-008 |
| C7 | 结果显示后直接输入 `digit` 自动开始新计算 | FR-009 |
| C8 | 单个操作数数字部分超过 12 位后的 `digit` 事件被忽略 | FR-010 |
| C9 | `1 ÷ 3 =` → `0.33333333`（8 位截断去尾零）；整数结果无小数点 | Edge Case |
| C10 | 运算溢出（如 999999999999 × 999999999999）→ `text == "数字太大了"` | R1 |
| C11 | 结果状态输入 `op` 则以结果为新第一操作数继续链式运算 | data-model |
| C12 | `speechText` 为完整中文口语句：数字逐位读、运算符读“加/减/乘/除”、
       小数点读“点”、负号读“负”、错误时读提示文案 | FR-012 |
| C13 | 任何事件序列都不会导致崩溃或未定义状态（状态机全分支有定义） | SC-005 |

## 不变式

- `display.text` 永不为空，永不包含技术性错误信息（英文、异常名、Inf/NaN）。
- `display.isError == true` 时，`op`/`equals`/`backspace` 不修改状态；
  `digit`/`clear` 恢复可操作。

## 非职责（明确排除）

- 不负责 UI 布局、字号、颜色（UI 契约）。
- 不负责发声（SpeechService 消费 `speechText` 后自行合成）。
- 不负责持久化（@AppStorage 由视图层持有）。
