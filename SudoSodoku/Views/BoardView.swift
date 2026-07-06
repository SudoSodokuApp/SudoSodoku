import SwiftUI

struct BoardView: View {
    @ObservedObject var game: SudokuGame

    var body: some View {
        GeometryReader { geometry in
            if game.board.count < 81 {
                Color.clear
            } else {
                let width = geometry.size.width
                let cellSize = width / 9
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellSize), spacing: 0), count: 9), spacing: 0) {
                    ForEach(0..<81) { index in
                        CellView(
                            cell: game.board[index],
                            cellSize: cellSize,
                            isSelected: game.selectedCellIndex == index,
                            isRelated: isRelated(index: index),
                            highlightNumber: getHighlightNumber(),
                            onTap: { game.selectCell(at: index) }
                        )
                    }
                }
                .overlay(GridLinesOverlay(width: width))
                .border(Color.gray, width: 2)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func isRelated(index: Int) -> Bool {
        guard let selected = game.selectedCellIndex,
              selected < game.board.count,
              index < game.board.count else { return false }
        let selectedCell = game.board[selected]
        let currentCell = game.board[index]
        return currentCell.row == selectedCell.row
            || currentCell.col == selectedCell.col
            || (currentCell.row / 3 == selectedCell.row / 3 && currentCell.col / 3 == selectedCell.col / 3)
    }

    private func getHighlightNumber() -> Int? {
        guard let index = game.selectedCellIndex,
              index < game.board.count,
              let value = game.board[index].value else { return nil }
        return value
    }
}
