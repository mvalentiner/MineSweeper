//
//  Minefield.swift
//
//  Created by Michael Valentiner on 4/1/19.
//

import ReactiveSwift
import UIKit

//* Syntactic sugar around ReactiveSwift's MutableProperty to make it more apparent as to what's going on.
extension MutableProperty {
	func bind(action: @escaping ()->Void) {
		signal.observeValues { (value) in
			action()
		}
	}
}

//* The game engine that implements the Minesweeper game. It acts as the controller in the MVC pattern (not to be confused with UIViewController).
// It encapsulates the
// 	- game models (gameState and minefieldCellStates),
//	- state variables, and
//	- mutator functions that change the models.
class Minefield {
	enum PlayingLevel {
		case beginner
		case intermediate
		case expert
	}

	enum GameState {
		case playing
		case kaboom
		case win
	}

	enum CellState {
		case closed(numberOfAdjacentMines : Int)
		case opened(numberOfAdjacentMines : Int)
		case flagged(numberOfAdjacentMines : Int)
	}

	// ReactiveSwift properties that drive the UI.
	internal var gameState = MutableProperty<GameState>(.playing)
	internal var minefieldCellStates = MutableProperty<[[CellState]]>([])
	internal var playTime = MutableProperty<TimeInterval>(0.0)

	// Configuration state variables
	internal let playingLevel : PlayingLevel
	internal let dimension : Int

	// A Sets of unflagged mines and flaggedNonMineCells. These are used to determine the winning state.
	typealias IndexPathSet = Set<IndexPath>
	private var unsweptMineSet : IndexPathSet = []
	private var flaggedNonMineCells : IndexPathSet = []

	// Sentinel value used to indicate a mine in the minefield
	internal static let daBomb = -1

	init(forLevel level: PlayingLevel) {
		playingLevel = level
		dimension = {
			switch level {
			case .beginner:	//- Beginner: 8x8 grid - 10 mines
				return 8
			case .intermediate:	//- Intermediate: 16x16 grid - 40 mines
				return 16
			case .expert:	//- Expert: 32x32 grid - 99 mines
				return 32
			}
		}()
		
		// Initialize the mine field to all cells closed and counts of 0.
		minefieldCellStates = MutableProperty<[[CellState]]>(
			Array(repeating: Array(repeating: CellState.closed(numberOfAdjacentMines: 0), count: dimension), count: dimension))
		// Plant the mines.
		populateMinefield()
	}

	// Accessor returns the state of the cell.
	internal func cellState(atIndexPath indexPath: IndexPath) -> CellState {
		return minefieldCellStates.value[indexPath.row][indexPath.section]
	}

	// Mutator to flag a cell
	internal func flagCell(atIndexPath indexPath: IndexPath) {
		// aka single tap
		guard case gameState.value = GameState.playing else {
			// If a square containing a mine is opened, ... The grid should stop accepting taps.
			return
		}
		let cell = minefieldCellStates.value[indexPath.row][indexPath.section]
		switch cell {
		case .closed(let count):
			// .closed -> .flagged
			minefieldCellStates.value[indexPath.row][indexPath.section] = CellState.flagged(numberOfAdjacentMines: count)
			if count == Minefield.daBomb {
				unsweptMineSet.remove(indexPath)
			}
			else {
				flaggedNonMineCells.insert(indexPath)
			}
			break
		case .flagged(let count):
			// .flagged -> .closed (unflagged)
			minefieldCellStates.value[indexPath.row][indexPath.section] = CellState.closed(numberOfAdjacentMines: count)
			if count == Minefield.daBomb {
				unsweptMineSet.insert(indexPath)
			}
			else {
				flaggedNonMineCells.remove(indexPath)
			}
			break
		default:
			break
		}
		checkForWin()
	}

	// Mutator to open a cell
	internal func openCell(atIndexPath indexPath: IndexPath) {
		// aka double tap
		guard case gameState.value = GameState.playing else {
			// If a square containing a mine is opened, ... The grid should stop accepting taps.
			return
		}
		// If an opened square is adjacent to any mines, the number of mines in adjacent squares is displayed in the square.
		// If the number is 0, omit the number. Diagonals are considered adjacent.

		let cell = minefieldCellStates.value[indexPath.row][indexPath.section]
		switch cell {
		case .closed(let count):
			minefieldCellStates.value[indexPath.row][indexPath.section] = CellState.opened(numberOfAdjacentMines: count)
			guard count != Minefield.daBomb else {
				kaboom()
				return
			}
			guard count == 0 else {
				// If an opened square does not contain a mine, and is not adjacent to any mines, the square is opened, and all adjacent squares are opened.
				return
			}
			openNeighboringCells(atIndexPath: indexPath)
			checkForWin()
			break
		default:
			break
		}
	}

	// MARK: private initialization helper functions

	private func populateMinefield() {
		// Plant the mines
		let minesLeftToPlant : Int = {
			switch playingLevel {
			case .beginner:	//- Beginner: 8x8 grid - 10 mines
				return 10
			case .intermediate:	//- Intermediate: 16x16 grid - 40 mines
				return 40
			case .expert:	//- Expert: 32x32 grid - 99 mines
				return 99
			}
		}()
// This loop is O(n), where n is the number of mines to plant.
//		while minesLeftToPlant > 0 {
//			let randomRow = Int.random(in: 0..<dimension)
//			let randomColumn = Int.random(in: 0..<dimension)
//			guard case CellState.closed(0) = minefieldCellStates.value[randomRow][randomColumn] else {
//				// We have already assigned this cell, so choose another.
//				continue
//			}
//			// Assign a mine to the cell.
//			minefieldCellStates.value[randomRow][randomColumn] = CellState.closed(numberOfAdjacentMines: Minefield.daBomb)
//			// Add to the list of mines that have been planted.
//			let mineIndexPath = IndexPath(row: randomRow, section: randomColumn)
//			unsweptMineSet.insert(mineIndexPath)
//			minesLeftToPlant -= 1
//		}



		// The layout of mines on a board should be algorithmically distributed, not based on preset layouts (a completely random algorithm is OK).
		// Preference will be given to algorithms that give every square an equal probability of being a mine.
		// Put all the cells in a list
		var cellList : [IndexPath] = []
		for row in 0..<dimension {
			for col in 0..<dimension {
				cellList.append(IndexPath(row: row, section: col))			}
		}
		// Randomly shuffle them.
		cellList.shuffle()
		// Starting with the front of the list, assign mines till they are all assigned.
		for i in 0 ..< minesLeftToPlant {
			let indexPath = cellList[i]
			let row = indexPath.row
			let col = indexPath.section
			minefieldCellStates.value[row][col] = CellState.closed(numberOfAdjacentMines: Minefield.daBomb)
			// Add to the list of mines that have been planted.
			unsweptMineSet.insert(indexPath)
		}

		// Calculate cell counts. The complexity of these nested loop is O(n^2), where n is the dimension of the minefield.
		// The complexity of countNeighboringMines(forRow:col:) (== O(1)) doesn't change the complexity of the nested loops.
		for row in 0..<dimension {
			for col in 0..<dimension {
				minefieldCellStates.value[row][col] = CellState.closed(numberOfAdjacentMines: countNeighboringMines(forRow: row, col: col))
			}
		}
//		print1(self)
	}

	private func countNeighboringMines(forRow row: Int, col: Int) -> Int {
		if case CellState.closed(numberOfAdjacentMines: Minefield.daBomb) = minefieldCellStates.value[row][col] {
			// Don't count if cell(row, col) is daBomb
			return Minefield.daBomb
		}
		// The complexity of these nested loops is O(1). Worst case, it iterates over 9 cells.
		var count = 0
		for r in (row - 1)...(row + 1) {
			guard r >= 0 && r < dimension else {
				// Make sure we are in bounds
				continue
			}
			for c in (col - 1)...(col + 1) {
				guard c >= 0 && c < dimension else {
				// Make sure we are in bounds
					continue
				}
				guard r != row || c != col else {
					// Don't count this cell(row, col)
					continue
				}
				if case CellState.closed(numberOfAdjacentMines: Minefield.daBomb) = minefieldCellStates.value[r][c] {
					count += 1
				}
			}
		}

		return count
	}

	// MARK: private action functions

	private func openNeighboringCells(atIndexPath indexPath: IndexPath) {
		// Any opened adjacent squares also not adjacent to any mines are also opened. This process repeats until the opened
		//		area is bounded by the board dimensions, or mines.
		// The complexity of these nested loops is O(1) as in worse case, it iterates over 9 cells, BUT! it recursively calls itself, so
		//		it is dependent on the on the number of adjacent open cells in the minefield.  Worst case the number approaches n * n,
		//		where n is the dimension of the minefield.  In actuality, the number is a lot less due to the random distribution of mines.
		let row = indexPath.row
		let col = indexPath.section
		for r in (row - 1)...(row + 1) {
			guard r >= 0 && r < dimension else {
				// Make sure we are in bounds
				continue
			}
			for c in (col - 1)...(col + 1) {
				guard c >= 0 && c < dimension else {
				// Make sure we are in bounds
					continue
				}
				guard r != row || c != col else {
					// Don't open this cell(row, col)
					continue
				}
				if case CellState.closed(let count) = minefieldCellStates.value[r][c], count != 0 {
					// This handle the cases where
					//	1) also not adjacent to any mines are also opened (count > 0) and
					//	2) cell.count == daBomb
					continue
				}
				openCell(atIndexPath: IndexPath(row: r, section: c))
			}
		}
	}

	private func kaboom() {
		// If a square containing a mine is opened, the board must open completely to show the location of all mines using a "bomb" emoji (💣), ending the game.
		// The grid should stop accepting taps. Do not worry about how to restart the game; killing the app and relaunching is OK.

		gameState.value = .kaboom
		openAllCells()
	}

	private func checkForWin() {
		// Since a winning criteria was not given in the README.md, I choose to use "when all mines are flagged (swept)".
		// By maintaining a set of unswept mines, it is easy to determine when all mines have been swept. O(1) to perfom
		// this operation and worse case it may be performed O(n^2) times.
		// This is more efficient than searching all the cells and counting flagged mines everytime we need to check. The
		// cost (tradeoff) of using a Set is the memory (space) it takes up (realtively small compared to the minefield cell)
		// and the need to track insertions and removals (simple to do in a loaclized place, flagCell()).
		if unsweptMineSet.isEmpty && flaggedNonMineCells.isEmpty {
			gameState.value = GameState.win
			openAllCells()
		}
	}

	private func openAllCells() {
		// Open all cells - these nested loops have complexity O(n^2)
		for row in 0..<dimension {
			for col in 0..<dimension {
				if case CellState.closed(let count) = minefieldCellStates.value[row][col] {
					minefieldCellStates.value[row][col] = CellState.opened(numberOfAdjacentMines: count)
				}
				else if case CellState.flagged(let count) = minefieldCellStates.value[row][col] {
					minefieldCellStates.value[row][col] = CellState.opened(numberOfAdjacentMines: count)
				}
			}
		}
	}

	// MARK: private debugging functions
	// These are examples of tools I wrote to verify my code as I went along.

	private func print1(_ minefield : Minefield) {
		for row in 0..<minefield.dimension {
			print("row == \(row)")
			var colStr = ""
			for col in 0..<minefield.dimension {
				colStr = colStr + asString(minefieldCellStates.value[row][col]) + "  "
			}
			print(colStr)
		}
	}
	
	private func asString(_ cellState : CellState) -> String {
		switch cellState {
		case .closed(let count):
			return String(count)
		case .flagged(let count):
			return String(count)
		case .opened(let count):
			return String(count)
		}
	}
}
