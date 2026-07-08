import SwiftUI

/// Static readout of a command that already "executed" — the terminal
/// breadcrumb a screen was navigated in with, echoed at the top so the
/// whole session still reads as one continuous shell trace.
struct ExecutedCommandLine: View {
    let command: String

    var body: some View {
        HStack(spacing: 0) {
            Text("root@ios:~$ ").foregroundColor(.green)
            Text(command).foregroundColor(.white)
        }
        .font(.system(size: 14, weight: .bold, design: .monospaced))
    }
}
