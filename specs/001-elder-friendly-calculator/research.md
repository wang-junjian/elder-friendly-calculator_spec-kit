# Research: 适老友好计算器

**Date**: 2026-10-07 | **Feature**: [spec.md](spec.md)

技术上下文中无 NEEDS CLARIFICATION 项（用户已明确 Swift 6 / SwiftUI / macOS 13 /
AVSpeechSynthesizer / XCTest / 零三方依赖）。以下为关键实现决策的研究结论。

## R1: 数值表示与精度策略

- **Decision**: 计算引擎内部使用 Swift `Decimal`（基于 NSDecimalNumber 的十进制运算），
  显示层四舍五入至最多 8 位小数。
- **Rationale**: `Double` 存在二进制浮点误差（0.1 + 0.2 = 0.30000000000000004），
  对老年用户显示这种结果是严重信任破坏（章程原则 IV）。`Decimal` 提供精确十进制
  加减乘除，满足计算器“结果必须永远正确”的定位（章程原则 III 理由）。
- **Alternatives considered**:
  - `Double` + 显示时格式化 —— 拒绝：误差在参与后续运算时累积，边界情况不可控。
  - 引入第三方 BigDecimal 库 —— 拒绝：违反零三方依赖约束。
- **溢出处理**: `Decimal` 运算溢出（极大数）时引擎返回“数字太大了”通俗提示
  （对应 spec Edge Case），不显示乱码或 Inf。

## R2: 计算引擎架构

- **Decision**: 纯 Swift 状态机（enum 状态 + 按键事件输入），不 import
  SwiftUI/AppKit/AVFoundation。
- **Rationale**: TDD 前提（章程原则 III）——引擎可在 XCTest 中无 UI 环境全分支测试；
  所有防错规则（FR-007/008/009/010）在状态转移中一次性定义，UI 层无需任何分支逻辑，
  保持“UI 极薄”。
- **状态**: `输入第一操作数` / `已选运算符` / `输入第二操作数` / `已显示结果` /
  `错误提示`（除零、溢出）。
- **Alternatives considered**: 表达式树/逆波兰求值 —— 拒绝：当前仅支持二元四则运算，
  状态机是最简方案（章程原则 II，YAGNI）。

## R3: macOS 13 键盘输入方案

- **Decision**: 使用不可见（透明、零尺寸框架内）`Button` + `.keyboardShortcut` 为每个
  物理按键建立映射（0–9、.、+、-、*、/、Return、Delete、Escape）。
- **Rationale**: SwiftUI 的 `.onKeyPress` 需要 macOS 14+，不满足最低 macOS 13 约束；
  `keyboardShortcut` 自 macOS 11 起可用，且天然与辅助功能系统集成（章程原则 V）。
- **Alternatives considered**:
  - `NSViewRepresentable` 包装 NSView 拦截 keyDown —— 拒绝：引入 AppKit 桥接复杂度，
    且焦点管理容易出错。
  - 提升最低版本到 macOS 14 用 `.onKeyPress` —— 拒绝：用户已明确最低 macOS 13。

## R4: 语音播报

- **Decision**: `SpeechService` 封装 `AVSpeechSynthesizer`；播报前将显示内容转换为
  中文口语文本（“12 加 7 等于 19”，负号读“负”，小数点读“点”）；语速设置为系统
  默认的约 0.85 倍（偏慢，适老）；新播报打断旧播报；开关状态存 `@AppStorage`。
- **Rationale**: 系统合成器完全离线（FR-015），自带 zh-CN 声音；封装为协议便于在
  XCTest 中以替身验证“生成了正确的播报文本”而不真实发声（TDD）。
- **Alternatives considered**: 在线 TTS 服务 —— 拒绝：违反离线约束与隐私章程。

## R5: 适老 UI 度量与窗口行为

- **Decision**: 集中定义 `AccessibilityMetrics` 常量：结果字号 ≥48pt（默认窗口下，
  远高于 24pt 底线）、按钮字号 ≥28pt、按钮最小 64×64pt、间距 ≥12pt、对比度组合
  黑底白字（21:1）/ 深灰底白字（≥7:1）；窗口最小尺寸约 480×640pt，默认 560×760pt；
  按钮尺寸随窗口按比例放大（GeometryReader 分配），但不允许小于最小值。
- **Rationale**: 底线值来自章程原则 I 与 spec FR-002/003/004/014；默认显著高于底线
  以提升 SC-002（100% 受试者确认可读）达成率。集中常量使
  `AccessibilityMetricsTests` 可对合规性做自动化断言（防回归）。
- **Alternatives considered**: 跟随系统“辅助功能-显示”动态缩放 —— 部分采纳：
  尊重系统增大对比度/降低透明度设置，但基础尺寸不依赖 Dynamic Type
  （macOS 上桌面场景按固定大字号设计更可控）。

## R6: 可访问性

- **Decision**: 每个按钮声明 `accessibilityLabel`（如“数字 7”“加号”“等于”）与
  `accessibilityHint`（如“双击输入 7”）；显示区声明 `accessibilityLiveRegion` 等效
  行为（macOS 上使用 `NSAccessibilityAnnouncementRequested` 通知播报结果变化，
  供 VoiceOver 用户感知）；尊重系统“增大对比度”“减弱动态效果”设置。
- **Rationale**: 章程原则 V（WCAG 2.1 AA、屏幕阅读器可用）。
- **Alternatives considered**: 仅依赖视觉设计 —— 拒绝：违反章程。

## R7: 本地化

- **Decision**: 全部用户可见文本（按钮标签、错误提示、播报语句、无障碍标签）集中在
  `zh-Hans` 字符串资源中，代码内不出现硬编码文案。
- **Rationale**: 保证错误提示与播报用语统一通俗（章程原则 IV）；未来如需繁体/英文
  可低成本扩展。

**结论**: 所有技术决策已确定，无遗留 NEEDS CLARIFICATION。
