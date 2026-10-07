import AppKit
import SwiftUI

/// 根布局（UI 契约 U1/U5）：显示区在上、键盘区在下单屏布局；
/// 按钮随窗口放大，但不小于适老底线
struct ContentView: View {
    @StateObject private var engine = CalculatorEngine()
    @AppStorage("isSpeechEnabled") private var isSpeechEnabled = false
    @State private var speech = SpeechService(synthesizer: AVSpeechSynthesizerAdapter())

    var body: some View {
        VStack(spacing: 0) {
            // U3：语音开关位于界面可见位置，状态即时可见（FR-012）
            HStack {
                Spacer()
                Toggle(String(localized: "speech.toggle.label"), isOn: $isSpeechEnabled)
                    .toggleStyle(.switch)
                    .font(.system(size: 20))
                    .foregroundStyle(AccessibilityMetrics.displayForeground)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .accessibilityIdentifier("speech.toggle")
            }
            .background(AccessibilityMetrics.displayBackground)

            DisplayView(display: engine.display)
            KeypadView(onKey: engine.send)
                .layoutPriority(1)
        }
        .frame(minWidth: AccessibilityMetrics.windowMinimumSize.width,
               minHeight: AccessibilityMetrics.windowMinimumSize.height)
        .background(AccessibilityMetrics.displayBackground)
        .onChange(of: engine.display) { newDisplay in
            announceResultChange(newDisplay)
            // FR-012：播报按键输入与结果；开关状态经 @AppStorage 跨启动保持
            speech.isEnabled = isSpeechEnabled
            speech.speak(newDisplay.speechText)
        }
    }

    /// U11：结果变化向 VoiceOver 发送通告
    private func announceResultChange(_ display: DisplayState) {
        guard let window = NSApp.mainWindow ?? NSApp.windows.first else { return }
        NSAccessibility.post(
            element: window as Any,
            notification: .announcementRequested,
            userInfo: [.announcement: display.text, .priority: NSAccessibilityPriorityLevel.high.rawValue])
    }
}
