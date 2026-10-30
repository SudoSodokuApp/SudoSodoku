import Foundation

struct CellChange {
    let index: Int
    let oldCell: SudokuCell
    let newCell: SudokuCell
}

/// One undoable move. A single player action can touch several cells
/// (placing a number also clears that digit from peer notes), so a move
/// is a list of cell changes applied and reverted together.
struct MoveHistory {
    let changes: [CellChange]

    init(changes: [CellChange]) {
        self.changes = changes
    }

    init(index: Int, oldCell: SudokuCell, newCell: SudokuCell) {
        self.changes = [CellChange(index: index, oldCell: oldCell, newCell: newCell)]
    }
}
