import AVFoundation
import Foundation

/// 语音合成抽象（便于测试替身隔离，research R4）
protocol SpeechSynthesizing {
    func speak(_ text: String)
    func stop()
}

/// 系统 AVSpeechSynthesizer 适配器：zh-CN 中文声音，语速偏慢（适老，约 0.85 倍）
final class AVSpeechSynthesizerAdapter: SpeechSynthesizing {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.85
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

/// 语音播报服务（FR-012）：开关控制；新播报打断旧播报（U15）
final class SpeechService {
    private let synthesizer: SpeechSynthesizing
    var isEnabled: Bool

    init(synthesizer: SpeechSynthesizing, isEnabled: Bool = false) {
        self.synthesizer = synthesizer
        self.isEnabled = isEnabled
    }

    func speak(_ text: String) {
        guard isEnabled else { return }
        synthesizer.stop()          // U15：打断进行中的播报
        synthesizer.speak(text)
    }
}
