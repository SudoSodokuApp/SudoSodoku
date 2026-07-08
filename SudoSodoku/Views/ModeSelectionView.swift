import SwiftUI

/// Difficulty selection as a live terminal: the command line up top awaits
/// its flag, the menu below is tab completion. Picking a flag types it into
/// the command, the command "executes", and the breach begins — flowing into
/// the loading log, which opens with this very command.
struct ModeSelectionView: View {
    @State private var typedFlag = ""
    @State private var pickedDifficulty: Difficulty?
    @State private var isComposing = false
    @State private var launchDifficulty: Difficulty?
    @State private var cursorVisible = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            TerminalBackground()
            VStack(alignment: .leading, spacing: 34) {
                commandLine
                completionMenu
                Spacer()
                Text("# hint: higher difficulty_index -> higher elo yield")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.6))
                    .padding(.bottom, 12)
            }
            .padding(.horizontal)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $launchDifficulty) { difficulty in
            GameView(difficulty: difficulty)
        }
        .onAppear {
            // Reset the composer when returning from a game.
            typedFlag = ""
            pickedDifficulty = nil
            isComposing = false
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                cursorVisible = false
            }
        }
    }

    // MARK: - Sections

    private var commandLine: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("# awaiting breach parameters")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.gray)
            HStack(spacing: 0) {
                Text("root@ios:~$ ").foregroundColor(.green)
                Text("sudo breach ").foregroundColor(.white)
                Text(typedFlag).foregroundColor(pickedDifficulty?.color ?? .green)
                Text("_")
                    .foregroundColor(.green)
                    .opacity(cursorVisible ? 1 : 0)
            }
            .font(.system(size: 17, weight: .bold, design: .monospaced))
        }
        .padding(.top, 24)
    }

    private var completionMenu: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("# tab_completion:")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.gray)
            ForEach(Difficulty.allCases) { difficulty in
                completionRow(difficulty)
            }
        }
    }

    @ViewBuilder
    private func completionRow(_ difficulty: Difficulty) -> some View {
        let isPicked = pickedDifficulty == difficulty
        Button(action: { pick(difficulty) }) {
            HStack {
                VStack(alignment: .leading) {
                    Text(difficulty.flag)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(difficulty.color)
                    Text("DIFFICULTY_INDEX: \(difficulty.scoreRange.lowerBound)-\(difficulty.scoreRange.upperBound)")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "return")
                    .foregroundColor(difficulty.color.opacity(isPicked ? 1 : 0.45))
            }
            .padding()
            .background(isPicked ? difficulty.color.opacity(0.12) : Color.black.opacity(0.5))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(difficulty.color.opacity(isPicked ? 1 : 0.5), lineWidth: 1)
            )
        }
        .disabled(isComposing)
    }

    // MARK: - Composing

    private func pick(_ difficulty: Difficulty) {
        guard !isComposing else { return }
        isComposing = true
        pickedDifficulty = difficulty
        HapticManager.shared.noteModeToggled()

        let flag = difficulty.flag
        Task {
            if reduceMotion {
                typedFlag = flag
                try? await Task.sleep(for: .milliseconds(250))
            } else {
                for count in 1...flag.count {
                    typedFlag = String(flag.prefix(count))
                    HapticManager.shared.noteToggled()
                    try? await Task.sleep(for: .milliseconds(45))
                }
                try? await Task.sleep(for: .milliseconds(280))
            }
            HapticManager.shared.digitPlaced() // return key
            launchDifficulty = difficulty
        }
    }
}
