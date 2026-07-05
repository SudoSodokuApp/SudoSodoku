import SwiftUI

struct CellView: View {
    let cell: SudokuCell
    let cellSize: CGFloat
    let isSelected: Bool
    let isRelated: Bool
    let highlightNumber: Int?
    var onTap: () -> Void

    @State private var animateTrigger = false

    var body: some View {
        ZStack {
            Rectangle().fill(bg).border(Color.white.opacity(0.1), width: 0.5)
            if isSelected { Rectangle().stroke(Color.green, lineWidth: 2).zIndex(10) }

            if cell.value == nil && !cell.notes.isEmpty {
                NoteGridView(notes: cell.notes, size: cellSize)
            }

            if let val = cell.value {
                Text("\(val)")
                    .font(.system(size: cellSize * 0.6, weight: cell.isGiven ? .bold : .regular, design: .monospaced))
                    .foregroundColor(txt)
            }
        }
        .frame(width: cellSize, height: cellSize)
        .contentShape(Rectangle())
        .scaleEffect(animateTrigger ? 0.92 : 1.0)
        .onTapGesture {
            HapticManager.shared.lightImpact()
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { animateTrigger = true }
            onTap()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { animateTrigger = false }
            }
        }
    }

    private var bg: Color {
        if isSelected { return Color.green.opacity(0.2) }
        if let value = cell.value, value == highlightNumber { return Color.green.opacity(0.4) }
        if isRelated { return Color.white.opacity(0.05) }
        return Color.clear
    }

    private var txt: Color {
        if cell.isGiven { return .white }
        if cell.isError { return .red }
        return .green
    }
}
