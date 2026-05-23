import SwiftUI
import Combine

struct FocusModeView: View {
    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    let item: TodoItem

    @State private var secondsRemaining: Int = 25 * 60
    @State private var isRunning: Bool = false
    @State private var cancellable: AnyCancellable? = nil
    private var taskName: String { loc.presetName(for: item) }

    private var minutes: Int { secondsRemaining / 60 }
    private var secs: Int { secondsRemaining % 60 }

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { } // absorb clicks

            // Focus card
            VStack(spacing: 32) {
                Text(loc.t("focus_title"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text(taskName)
                    .font(.system(size: 24, weight: .bold, design: .default))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                // Timer ring
                ZStack {
                    Circle()
                        .stroke(.quaternary, lineWidth: 6)
                        .frame(width: 160, height: 160)

                    Circle()
                        .trim(from: 0, to: CGFloat(1500 - secondsRemaining) / 1500.0)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: secondsRemaining)

                    Text(String(format: "%02d:%02d", minutes, secs))
                        .font(.system(size: 38, weight: .thin, design: .monospaced))
                        .foregroundStyle(.primary)
                }

                // Controls
                HStack(spacing: 20) {
                    Button(action: toggleTimer) {
                        Label(
                            isRunning ? loc.t("focus_pause") : loc.t("focus_start"),
                            systemImage: isRunning ? "pause.circle.fill" : "play.circle.fill"
                        )
                        .font(.system(size: 16, weight: .medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button(action: resetTimer) {
                        Label(loc.t("focus_reset"), systemImage: "arrow.counterclockwise.circle.fill")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Button(action: { stopTimer(); dismiss() }) {
                        Label(loc.t("focus_exit"), systemImage: "xmark.circle.fill")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(40)
            .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 24))
            .frame(width: 400)
        }
        .onDisappear { stopTimer() }
    }

    private func toggleTimer() {
        if isRunning {
            stopTimer()
        } else {
            startTimer()
        }
    }

    private func startTimer() {
        isRunning = true
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if secondsRemaining > 0 {
                    secondsRemaining -= 1
                } else {
                    stopTimer()
                }
            }
    }

    private func stopTimer() {
        isRunning = false
        cancellable?.cancel()
        cancellable = nil
    }

    private func resetTimer() {
        stopTimer()
        secondsRemaining = 25 * 60
    }
}
