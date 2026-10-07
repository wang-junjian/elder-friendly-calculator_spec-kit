---

description: "Task list for 适老友好计算器 implementation"
---

# Tasks: 适老友好计算器（macOS 原生应用）

**Input**: Design documents from `/specs/001-elder-friendly-calculator/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: 已包含——用户在计划输入中明确要求 TDD，且章程原则 III（测试先行）为
NON-NEGOTIABLE。每个用户故事的测试任务 MUST 先于实现任务执行，并确认测试失败（Red）
后再实现（Green）。

**Organization**: 按用户故事分组。注意：本项目引擎与视图文件被多个故事共享
（CalculatorEngine.swift、ContentView.swift），因此故事间按 P1→P2→P3 顺序执行，
不跨故事并行（详见 Dependencies）。

## Format: `[ID] [P?] [Story] Description`

- **[P]**: 可并行（不同文件、无未完成依赖）
- **[Story]**: 所属用户故事（US1/US2/US3，对应 spec.md 优先级 P1/P2/P3）
- 所有路径基于仓库根目录

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Xcode 工程初始化与基础结构

- [X] T001 创建 Xcode 工程 `ElderCalculator/ElderCalculator.xcodeproj`：单 App target（ElderCalculator）+ 单测 target（ElderCalculatorTests）+ 可选 UI 测试 target（ElderCalculatorUITests）；部署目标 macOS 13.0；Swift 6 语言模式并开启严格并发检查
- [X] T002 [P] 按 plan.md 结构创建源码目录：`ElderCalculator/ElderCalculator/Engine/`、`Speech/`、`Views/`、`Resources/zh-Hans.lproj/` 及 `ElderCalculator/ElderCalculatorTests/`
- [X] T003 [P] 创建 Xcode 专用 `.gitignore`（DerivedData/、xcuserdata/、*.xcuserstate 等）

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: 全部用户故事共享的基础类型、文案与设计常量

**⚠️ CRITICAL**: 本阶段完成前不得开始任何用户故事工作

- [X] T004 [P] 定义引擎公共类型于 `ElderCalculator/ElderCalculator/Engine/CalculatorState.swift`：`Operator`（add/subtract/multiply/divide）、`KeyEvent`（digit(0-9)/decimalPoint/op/equals/backspace/clear）、`CalculationError`（divisionByZero/overflow）、`DisplayState`（text/isError/speechText，Equatable）——签名严格遵循 contracts/calculator-engine-api.md
- [X] T005 [P] 在 `ElderCalculator/ElderCalculator/Resources/zh-Hans.lproj/Localizable.strings` 写入全部用户可见文案（research R7：代码内禁止硬编码文案）：错误提示「不能除以 0」「数字太大了」、按钮标签「退格」「清除」、全部 accessibilityLabel/Hint（如「数字 7」「加号」「双击输入 7」）、语音播报模板（「{a} 加 {b} 等于 {c}」等）
- [X] T006 [P] 编写失败测试 `ElderCalculator/ElderCalculatorTests/AccessibilityMetricsTests.swift`：断言设计常量满足 UI 契约硬线——结果显示字号 ≥24pt 且默认窗口下 ≥48pt（U6）、按钮点击目标 ≥44×44pt 且默认 ≥64×64pt（U7）、按钮间距 ≥12pt（U7）、文本/背景色组合对比度 ≥4.5:1（U8，需实现 RGB 亮度对比度计算辅助函数）
- [X] T007 实现 `ElderCalculator/ElderCalculator/Views/AccessibilityMetrics.swift` 设计常量（research R5 数值），使 T006 测试通过；后续所有 UI 任务 MUST 引用本文件常量，禁止散落魔法数字

**Checkpoint**: 基础类型、文案、度量常量就绪——用户故事可按优先级顺序开始

---

## Phase 3: User Story 1 - 大字号界面完成基础四则运算 (Priority: P1) 🎯 MVP

**Goal**: 用户通过鼠标或键盘完成加减乘除，结果以大字号清晰显示

**Independent Test**: 启动应用 → 输入 12 + 7 = → 显示 19（quickstart V1）

### Tests for User Story 1 ⚠️

> **NOTE: 先写测试，确认失败后再实现（红-绿-重构）**

- [X] T008 [P] [US1] 编写失败测试 `ElderCalculator/ElderCalculatorTests/CalculatorEngineTests.swift`（US1 部分）：C1 初始显示 "0"；C2 四则运算各至少 2 例（12+7=19、20-8=12、3×4=12、8÷2=4）；C3 同一 KeyEvent 序列结果一致；C7 结果显示后直接输入 digit 自动开始新计算；C9 格式化（整数结果无小数点；1÷3 → 0.33333333，8 位四舍五入去尾零）；C11 结果状态输入 op 以结果继续链式运算；小数输入（0.5+0.25=0.75，验证 Decimal 无浮点误差）

### Implementation for User Story 1

- [X] T009 [US1] 实现 `ElderCalculator/ElderCalculator/Engine/CalculatorEngine.swift` 状态机（依据 data-model.md 转移表 US1 相关分支 + research R1/R2）：`final class CalculatorEngine: ObservableObject`，`@Published private(set) var display: DisplayState`，`init()` 初始 text 为 "0"，`send(_ event: KeyEvent)` 唯一入口；内部运算使用 `Decimal`，结果格式化为最多 8 位小数并去除尾零；使 T008 全部通过
- [X] T010 [P] [US1] 实现 `ElderCalculator/ElderCalculator/Views/DisplayView.swift` 结果显示区：引用 AccessibilityMetrics 字号常量（默认 ≥48pt），数字右对齐，文本随显示长度自适应缩小但不低于 24pt 底线
- [X] T011 [US1] 实现 `ElderCalculator/ElderCalculator/Views/KeypadView.swift` 键盘网格：数字 0–9、小数点、加、减、乘、除、等于、退格、清除按钮（U2），尺寸/间距引用 AccessibilityMetrics（U7），按下态即时高亮反馈（U9）；用 `keyboardShortcut` 映射 0–9、.、+、-、*、/、Return、Delete、Escape（research R3，macOS 13 兼容）
- [X] T012 [US1] 实现 `ElderCalculator/ElderCalculator/Views/ContentView.swift` 根布局：显示区在上、键盘区在下单屏布局（U1），`@StateObject` 持有 CalculatorEngine，按钮事件转发为 KeyEvent；GeometryReader 使按钮随窗口放大（U5）
- [X] T013 [US1] 配置 `ElderCalculator/ElderCalculator/ElderCalculatorApp.swift`：窗口默认 560×760pt、最小 480×640pt（U4），窗口标题「计算器」，单窗口场景
- [X] T014 [US1] 为全部按钮添加 `accessibilityLabel`/`accessibilityHint`（文案取自 T005 字符串资源，U10），显示区结果变化时发送 VoiceOver 通告（`NSAccessibilityAnnouncementRequested`，U11）

**Checkpoint**: US1 完整可用——运行 quickstart V1 全部通过，可作为 MVP 演示

---

## Phase 4: User Story 2 - 误操作纠正与防错保护 (Priority: P2)

**Goal**: 退格/清除纠错；除零、连续运算符、超长输入、溢出均以通俗提示安全处理

**Independent Test**: 输入 8 ÷ 0 = → 显示「不能除以 0」且不崩溃 → 按清除 → 重新计算成功
（quickstart V2）

### Tests for User Story 2 ⚠️

> **NOTE: 先写测试，确认失败后再实现**

- [X] T015 [P] [US2] 在 `ElderCalculator/ElderCalculatorTests/CalculatorEngineTests.swift` 追加失败测试（US2 部分）：C4 退格删除末位、删空回 "0"、clear 完全重置；C5 `8÷0=` 后 isError=true、text=「不能除以 0」，随后 digit 恢复新输入；C6 `5+×3=` → 15（运算符替换，不报错不连算）；C8 单操作数数字部分超 12 位后的 digit 被忽略（FR-010 上限「12 位」）；C10 999999999999×999999999999 → 「数字太大了」；C13 随机 KeyEvent 序列（≥1000 组属性式测试）不崩溃且 display.text 永不为空、永不包含英文/Inf/NaN

### Implementation for User Story 2

- [X] T016 [US2] 扩展 `ElderCalculator/ElderCalculator/Engine/CalculatorEngine.swift` 防错转移规则（data-model.md 转移表 US2 分支）：backspace/clear 全状态行为、除零与溢出进入错误状态、错误状态下仅 digit/clear 可恢复、运算符替换、12 位输入上限；使 T015 全部通过
- [X] T017 [US2] 调整 `ElderCalculator/ElderCalculator/Views/DisplayView.swift` 错误态呈现：isError 时以高对比样式显示通俗提示文案（取自 T005 字符串资源），保证错误提示字号同样 ≥24pt

**Checkpoint**: US1 + US2 均独立可用——quickstart V1、V2 全部通过

---

## Phase 5: User Story 3 - 操作反馈与语音播报 (Priority: P3)

**Goal**: 可开关的中文语音播报，按键与结果播报口语句，偏好跨启动保持

**Independent Test**: 开启语音开关 → 输入 3 × 4 = → 听到「3 乘 4 等于 12」（quickstart V3）

### Tests for User Story 3 ⚠️

> **NOTE: 先写测试，确认失败后再实现**

- [X] T018 [P] [US3] 编写失败测试 `ElderCalculator/ElderCalculatorTests/SpeechServiceTests.swift`：以协议替身（mock synthesizer）验证——C12 speechText 口语转换（「12 加 7 等于 19」；小数点读「点」，如 0.5 → 「0 点 5」；负号读「负」；错误时读提示文案「不能除以 0」）；开关关闭时不发起播报（U14）；新播报到达时打断进行中的旧播报（U15）

### Implementation for User Story 3

- [X] T019 [P] [US3] 实现 `ElderCalculator/ElderCalculator/Speech/SpeechService.swift`：定义 `SpeechSynthesizing` 协议隔离 AVSpeechSynthesizer；播报速率设为系统默认约 0.85 倍（research R4）；`speak(_:)` 前停止当前播报；声音选用 zh-CN
- [X] T020 [US3] 在 `ElderCalculator/ElderCalculator/Engine/CalculatorEngine.swift` 实现 `DisplayState.speechText` 中文口语句生成（C12）：数字、运算符（加/减/乘/除）、小数点（点）、负号（负）、错误文案映射；使 T018 文案断言通过
- [X] T021 [US3] 在 `ElderCalculator/ElderCalculator/Views/ContentView.swift` 接入语音：可见开关控件（U3，标签取自 T005），`@AppStorage` 持久化 `isSpeechEnabled`（默认 false，FR-012）；按键与结果变化时经 SpeechService 播报对应 speechText

**Checkpoint**: 三个用户故事全部独立可用——quickstart V1–V3 通过

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: 跨故事的质量收尾

- [X] T022 [P] 响应系统辅助功能设置：「增大对比度」切换高对比配色、「减弱动态效果」关闭按下动画（U12），涉及 `ElderCalculator/ElderCalculator/Views/ContentView.swift` 与 `DisplayView.swift`
- [X] T023 [P] 添加可选 UI 冒烟测试 `ElderCalculator/ElderCalculatorUITests/ElderCalculatorUITests.swift`：覆盖 quickstart V1 关键路径（启动 → 12+7= → 断言显示 19）
- [X] T024 [P] 性能验证与优化：冷启动至可交互 ≤2 秒、按键至视觉反馈 <100 毫秒（SC-004），必要时用 Instruments 定位
- [ ] T025 运行 quickstart.md V1–V4 全量人工验证并记录结果（含窗口最小尺寸 U4、VoiceOver U10/U11、位数上限、溢出提示）
- [X] T026 代码清理：Swift 6 严格并发告警清零、无硬编码文案残留（对照 research R7）、无魔法数字（对照 T007）

---

## Phase 7: Convergence

**Purpose**: 收敛核查发现的剩余差距（规格/计划/契约 vs 当前代码）

- [X] T027 实现窗口放大时按钮尺寸与字号按比例缩放（U5）：引入 GeometryReader 按窗口尺寸缩放 KeypadView 按钮高度与 DisplayView/按钮字号，缩小时不低于 AccessibilityMetrics 底线（24pt/64pt），窗口最小时布局不退化 per U5（partial）
- [X] T028 在单操作数输入达到 12 位上限时给出轻微视觉提示（如显示区短暂高亮；尊重「减弱动态效果」设置），当前超限输入仅静默忽略 per spec Edge Case（超长输入）（partial）
- [X] T029 清除残留魔法数字并迁移至 AccessibilityMetrics：DisplayView.swift 硬编码 `minHeight: 96`、ContentView.swift 硬编码字号 20 与 padding 24/8，使 T026「无魔法数字」声明真正成立 per T007（contradicts）

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: 无依赖，立即开始
- **Foundational (Phase 2)**: 依赖 Setup 完成——**阻断**所有用户故事
- **User Stories (Phase 3–5)**: 依赖 Foundational 完成
- **Polish (Phase 6)**: 依赖全部目标故事完成

### User Story Dependencies

- **US1 (P1)**: 仅依赖 Foundational
- **US2 (P2)**: 依赖 US1——扩展同一文件 `CalculatorEngine.swift` 与 `DisplayView.swift`（同一测试文件亦共享）
- **US3 (P3)**: 依赖 US1——修改同一文件 `ContentView.swift`、`CalculatorEngine.swift`

> ⚠️ 与标准模板不同：本项目三个故事共享引擎与视图文件，**故事间不可并行**，
> 严格按 P1 → P2 → P3 顺序执行。这也符合 MVP 增量交付策略。

### Within Each User Story

- 测试任务（T008/T015/T018）MUST 先写并确认失败，再执行实现任务
- 引擎/模型先于视图；核心实现先于集成

### Parallel Opportunities

- Phase 1：T002、T003 可并行（T001 工程创建先行）
- Phase 2：T004、T005、T006 可并行（三个不同文件）；T007 依赖 T006
- US1：T008 测试先行；实现中 T010 可与 T011 并行（不同文件）；T012 依赖 T010/T011
- US2：T016 依赖 T015；T017 依赖 T016（isError 状态）
- US3：T018 先行；T019 与 T020 可并行；T021 依赖 T019/T020
- Phase 6：T022、T023、T024 可并行

---

## Parallel Example: Foundational Phase

```bash
# 三个基础任务文件互不依赖，可并行推进：
Task: "定义引擎公共类型于 Engine/CalculatorState.swift"
Task: "写入 zh-Hans.lproj/Localizable.strings 全部文案"
Task: "编写失败测试 AccessibilityMetricsTests.swift"
```

## Parallel Example: User Story 3

```bash
# T018 测试确认失败后，两个实现任务文件独立：
Task: "实现 Speech/SpeechService.swift（协议隔离合成器）"
Task: "实现 CalculatorEngine.swift 的 speechText 口语句生成"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. 完成 Phase 1: Setup
2. 完成 Phase 2: Foundational（阻断项）
3. 完成 Phase 3: User Story 1（T008 测试先行 → T009–T014）
4. **STOP and VALIDATE**: 运行 quickstart V1 独立验证
5. 即可演示 MVP：大字号四则运算 + 键盘操作 + 无障碍基础

### Incremental Delivery

1. Setup + Foundational → 基础就绪
2. + US1 → quickstart V1 验证 → MVP 演示
3. + US2 → quickstart V2 验证 → 防错完整版
4. + US3 → quickstart V3 验证 → 语音增强版
5. + Polish → quickstart V4 与性能验证 → 发布候选

---

## Notes

- [P] 标记 = 不同文件、无未完成依赖
- [US1/2/3] 标签对应 spec.md 用户故事优先级 P1/P2/P3
- 每个任务或逻辑组完成后提交一次
- 验证测试失败（Red）是 TDD 硬性要求，禁止跳过
- 实现中引用设计常量 MUST 使用 `AccessibilityMetrics`，文案 MUST 使用字符串资源
