# Data Model: 适老友好计算器

**Date**: 2026-10-07 | **Feature**: [spec.md](spec.md)

本应用为无后端桌面工具，数据模型即内存中的计算会话状态与一项本地偏好。
无数据库、无网络存储。

## 实体一：计算会话（CalculatorState）

计算引擎的完整状态，由 `CalculatorEngine` 持有并推进。

| 字段 | 类型 | 说明 | 验证规则 |
|------|------|------|----------|
| `displayText` | String | 显示区当前文本（用户所见） | 初始为 "0"；数字部分最多 12 位（FR-010） |
| `accumulator` | Decimal? | 已确认的第一操作数 | 仅进入“已选运算符”状态后非空 |
| `pendingOperator` | Operator? | 待执行运算符（加/减/乘/除） | 与 accumulator 同时设置/清除 |
| `currentInput` | String | 正在输入的操作数原文（含小数点） | 最多一个小数点；最多 12 位有效数字 |
| `isEnteringNumber` | Bool | 是否处于“数字输入中” | 结果状态下输入新数字时为 false→true 且清空上下文（FR-009） |
| `error` | CalculationError? | 当前错误（除零/溢出） | 非空时 displayText 为通俗中文提示 |

### 按键事件（KeyEvent 枚举）

`digit(0-9)`、`decimalPoint`、`op(Operator)`、`equals`、`backspace`、`clear`

### 状态机与转移规则

```text
[初始/清除] displayText="0"
  ├─ digit → 输入第一操作数（currentInput 追加，"0" 被替换）
  ├─ decimalPoint → currentInput="0."
  └─ op → 忽略（无操作数）

[输入操作数中]
  ├─ digit → 追加（达 12 位则忽略）          FR-010
  ├─ decimalPoint → 无小数点时追加，有则忽略
  ├─ op → accumulator=currentInput，pendingOperator=op → [已选运算符]
  ├─ equals → 无 pendingOperator 时忽略
  ├─ backspace → 删除末位；删空则回 "0"      FR-006
  └─ clear → [初始]                          FR-006

[已选运算符]
  ├─ op → 替换 pendingOperator（不报错、不连算） FR-008
  ├─ digit/decimalPoint → 开始输入第二操作数
  ├─ equals → 用 accumulator 同时作两操作数求值（如 "5 + =" → 10）
  └─ clear → [初始]

[第二操作数就绪，equals]
  ├─ 除数为 0 → error=.divisionByZero，displayText="不能除以 0"  FR-007
  ├─ 结果溢出 → error=.overflow，displayText="数字太大了"        R1
  └─ 正常 → displayText=格式化结果（最多 8 位小数，去掉尾零）→ [已显示结果]

[已显示结果]
  ├─ digit → 清空上下文，开始全新计算         FR-009
  ├─ op → 以结果为新 accumulator 继续链式运算
  └─ clear → [初始]

[错误提示]
  └─ 任意 digit/clear → 清空，开始新输入（应用保持响应） FR-007
```

### 结果格式化规则

- 整数结果不显示小数点（`19` 而非 `19.0`）。
- 小数结果四舍五入至最多 8 位小数并去除尾部零（`1÷3` → `0.33333333`）。
- 结果重新参与链式计算时使用显示值（spec Edge Case 约定）。

## 实体二：用户偏好（UserPreferences）

| 字段 | 类型 | 存储 | 说明 |
|------|------|------|------|
| `isSpeechEnabled` | Bool | UserDefaults（@AppStorage） | 语音播报开关，默认 `false`，跨启动保持（FR-012） |

仅此项。无账户、无历史记录、无网络数据（FR-015）。

## 关系

```text
CalculatorEngine 1──1 CalculatorState   （持有并推进）
ContentView      1──1 CalculatorEngine  （@StateObject 观察）
ContentView      1──1 SpeechService     （依据 UserPreferences.isSpeechEnabled 启停）
```

## 跨启动状态保留

计算会话仅存在内存；窗口失焦/最小化恢复时状态保留（FR-013，SwiftUI 场景默认行为，
仅需不显式重置）。应用完全退出后不要求保留计算过程（spec 未要求，YAGNI）。
