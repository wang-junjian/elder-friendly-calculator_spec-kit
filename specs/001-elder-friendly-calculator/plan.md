# Implementation Plan: 适老友好计算器（macOS 原生应用）

**Branch**: `001-elder-friendly-calculator` | **Date**: 2026-10-07 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-elder-friendly-calculator/spec.md`

## Summary

为 60 岁以上中文用户开发一款 macOS 原生计算器：单窗口大字号界面，支持加减乘除、
退格/清除防错、完整键盘操作与可选中文语音播报。技术方案：Swift 6 + SwiftUI，
计算引擎作为无 UI 依赖的纯 Swift 状态机模块（TDD 先行，XCTest 覆盖），UI 层
保持极薄；语音使用系统 AVSpeechSynthesizer（zh-CN）；语音开关偏好经
UserDefaults（@AppStorage）本地持久化。零第三方依赖，完全离线。

## Technical Context

**Language/Version**: Swift 6（严格并发模式开启）

**Primary Dependencies**: SwiftUI、AppKit（仅窗口配置）、AVFoundation（AVSpeechSynthesizer）、XCTest

**Storage**: UserDefaults（仅语音播报开关一项偏好）；无其他持久化

**Testing**: XCTest（单元测试为主，计算引擎 100% 分支覆盖目标；关键路径 UI 测试可选）

**Target Platform**: macOS 13 Ventura 及以上（桌面，Apple Silicon + Intel）

**Project Type**: desktop-app（macOS 原生单窗口应用）

**Performance Goals**: 冷启动至可交互 < 2 秒；按键到视觉反馈 < 100 毫秒（SC-004）

**Constraints**: 零第三方依赖；完全离线运行、不收集任何数据（FR-015）；结果区字号 ≥24pt、
点击目标 ≥44×44pt、文本对比度 ≥4.5:1（章程原则 I/V）；窗口设最小尺寸（FR-014）

**Scale/Scope**: 单应用 target + 标准 XCTest 测试 target；约 10 个源文件；3 个用户故事
（P1 四则运算 / P2 防错 / P3 语音播报）

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| 章程原则 | 计划符合性 | 状态 |
|----------|-----------|------|
| I. 适老性优先（字号 ≥24px、对比度 4.5:1、目标 ≥44×44、防误触间距） | 设计常量集中定义（`AccessibilityMetrics`），UI 层强制引用；窗口最小尺寸保证底线 | ✅ PASS |
| II. 简洁至上（仅四则运算、单屏、YAGNI） | 功能严格对齐 spec FR-001；单 target、约 10 个源文件、无第三方依赖 | ✅ PASS |
| III. 测试先行（TDD，红-绿-重构） | 计算引擎为纯逻辑状态机，先于 UI 开发；tasks 阶段将测试任务排在实现任务之前 | ✅ PASS |
| IV. 防错设计与清晰反馈（除零通俗提示、连续运算符、即时反馈 <100ms） | 引擎状态机内建防错规则（FR-007/008/009/010）；错误以本地化中文文案返回；SwiftUI 按键按下态即时反馈 | ✅ PASS |
| V. 可访问性合规（WCAG 2.1 AA、屏幕阅读器标签、全键盘可达） | 全部按钮声明 accessibilityLabel/Hint；键盘映射经 hidden Button + keyboardShortcut 全覆盖；对比度常量达标 | ✅ PASS |

**结论**：无违规项，无需 Complexity Tracking。Phase 1 设计后复核结论不变（见文末）。

## Project Structure

### Documentation (this feature)

```text
specs/001-elder-friendly-calculator/
├── plan.md              # 本文件（/speckit-plan 输出）
├── research.md          # Phase 0 输出
├── data-model.md        # Phase 1 输出
├── quickstart.md        # Phase 1 输出
├── contracts/           # Phase 1 输出
│   ├── calculator-engine-api.md
│   └── ui-contract.md
└── tasks.md             # Phase 2 输出（/speckit-tasks，非本命令产物）
```

### Source Code (repository root)

```text
ElderCalculator/
├── ElderCalculator.xcodeproj/        # Xcode 工程（单应用 target）
├── ElderCalculator/                  # 应用 target
│   ├── ElderCalculatorApp.swift      # @main 入口，窗口最小尺寸配置
│   ├── Engine/                       # 纯逻辑计算引擎（无 SwiftUI/AppKit 依赖，TDD 先行）
│   │   ├── CalculatorEngine.swift    # 状态机：处理输入、产出显示状态
│   │   ├── CalculatorState.swift     # 状态与按键事件模型
│   │   └── CalculationError.swift    # 通俗中文错误文案
│   ├── Speech/
│   │   └── SpeechService.swift       # AVSpeechSynthesizer 封装（zh-CN，可开关）
│   ├── Views/
│   │   ├── ContentView.swift         # 根布局：显示区 + 键盘区
│   │   ├── DisplayView.swift         # 大字号结果显示区
│   │   ├── KeypadView.swift          # 大按钮键盘网格（含键盘快捷键映射）
│   │   └── AccessibilityMetrics.swift# 字号/对比度/目标尺寸设计常量
│   ├── Resources/
│   │   └── zh-Hans.lproj/            # 中文文案（错误提示、播报语句、无障碍标签）
│   └── Assets.xcassets/
├── ElderCalculatorTests/             # 单元测试 target（XCTest）
│   ├── CalculatorEngineTests.swift   # 引擎全分支覆盖（P1+P2 验收场景）
│   ├── SpeechServiceTests.swift      # 播报文案生成（合成器以协议替身隔离）
│   └── AccessibilityMetricsTests.swift # 设计常量合规断言（≥24pt、≥44pt、对比度）
└── ElderCalculatorUITests/           # 可选 UI 测试（P1 关键路径冒烟）
```

**Structure Decision**: 单 Xcode 工程、单应用 target（遵循用户约束与章程原则 II）。
`ElderCalculatorTests` 为 Xcode 运行 XCTest 所必需的标准配套 target，不构成额外的
产品 target。`Engine/` 目录不 import SwiftUI/AppKit，保证可脱离 UI 独立测试（TDD 前提）。

## Complexity Tracking

> 无章程违规项，本表留空。

## Post-Design Constitution Re-Check

Phase 1 产物（research.md / data-model.md / contracts/ / quickstart.md）完成后复核：

- 引擎 API 契约包含全部防错规则（原则 IV）✅
- UI 契约将字号、对比度、点击目标、无障碍标签、键盘映射列为验收项（原则 I、V）✅
- quickstart.md 的验证场景直接映射 spec 验收场景与 SC 指标（原则 III）✅
- 无任何新增功能或依赖引入（原则 II）✅

**最终结论**：全部通过 ✅
