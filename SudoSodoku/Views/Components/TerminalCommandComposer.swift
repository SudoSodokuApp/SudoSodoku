import SwiftUI

/// One selectable line in a `TerminalCommandComposer`'s tab-completion menu.
struct CommandOption: Identifiable {
    let id: String
    /// Both the row's headline and the text typed into the command line when picked.
    let label: String
    let detail: String
    let color: Color
}

/// A live terminal prompt whose command line "types itself" from a
/// tab-completion menu: picking an option animates it into the command,
/// the command "executes", and `onExecute` hands the pick back to the
/// caller (typically to navigate onward with the composed command as the
/// next screen's prefix). Shared by every screen that wants navigation to
/// read as one continuous, accumulating shell session instead of taps.
struct TerminalCommandComposer<Hero: View>: View {
    let awaitingComment: String
    let baseCommand: String
    let completionComment: String
    let options: [CommandOption]
    let hint: String?
    let onExecute: (CommandOption) -> Void
    @ViewBuilder var hero: () -> Hero

    @State private var typedSuffix = ""
    @State private var pickedOption: CommandOption?
    @State private var isComposing = false
    @State private var cursorVisible = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            commandSection
            hero()
            Spacer()
            completionSection
            Spacer()
            if let hint {
                Text(hint)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.6))
                    .padding(.bottom, 12)
            }
        }
        .padding(.horizontal)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                cursorVisible = false
            }
        }
    }

    // MARK: - Sections

    private var commandSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(awaitingComment)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.gray)
            HStack(spacing: 0) {
                Text("root@ios:~$ ").foregroundColor(.green)
                Text(baseCommand + " ").foregroundColor(.white)
                Text(typedSuffix).foregroundColor(pickedOption?.color ?? .green)
                Text("_")
                    .foregroundColor(.green)
                    .opacity(cursorVisible ? 1 : 0)
            }
            .font(.system(size: 17, weight: .bold, design: .monospaced))
        }
        .padding(.top, 24)
    }

    private var completionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(completionComment)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.gray)
            ForEach(options) { option in
                completionRow(option)
            }
        }
    }

    @ViewBuilder
    private func completionRow(_ option: CommandOption) -> some View {
        let isPicked = pickedOption?.id == option.id
        Button(action: { pick(option) }) {
            HStack {
                VStack(alignment: .leading) {
                    Text(option.label)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(option.color)
                    Text(option.detail)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "return")
                    .foregroundColor(option.color.opacity(isPicked ? 1 : 0.45))
            }
            .padding()
            .background(isPicked ? option.color.opacity(0.12) : Color.black.opacity(0.5))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(option.color.opacity(isPicked ? 1 : 0.5), lineWidth: 1)
            )
        }
        .disabled(isComposing)
    }

    // MARK: - Composing

    private func pick(_ option: CommandOption) {
        guard !isComposing else { return }
        isComposing = true
        pickedOption = option
        HapticManager.shared.noteModeToggled()

        let text = option.label
        Task {
            if reduceMotion {
                typedSuffix = text
                try? await Task.sleep(for: .milliseconds(250))
            } else {
                for count in 1...text.count {
                    typedSuffix = String(text.prefix(count))
                    HapticManager.shared.noteToggled()
                    try? await Task.sleep(for: .milliseconds(45))
                }
                try? await Task.sleep(for: .milliseconds(280))
            }
            HapticManager.shared.digitPlaced() // return key
            onExecute(option)
        }
    }
}
