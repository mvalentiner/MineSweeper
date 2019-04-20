# MineSweeper README

I was given a coding assignment by a company I interviewed with to write the classic MineSweeper game. https://en.wikipedia.org/wiki/Minesweeper_(video_game)
I cranked this out and here's the result.  A little crude in the UI, but it works and was fun to write.

To build, make sure to run
	```carthage update --platform iOS```

I used Xcode 10.2.1 and Swift 5.

Your obective is to flag all the mines. To play,
	• single click to flag a cell contianing a mine,
	• double-click to sweep (open the cell).

Sorry, there's no "Replay" button.  You have to kill the app and relaunch.

## MineSweeper

Write an iOS implementation of the greatest contribution to software Microsoft has ever made -- Minesweeper! You may use whatever tools you like, but preference will be given to solutions that use standard UIKit components, over third-party components.

## Required Features

- Must be able to select game-difficulty level, controlling more-or-less mine-density for the board. The UI for this is already provided via a `UIAlertController`, but the action handlers are not wired up.
The layout of mines on a board should be algorithmically distributed, not based on preset layouts (a completely random algorithm is OK). Preference will be given to algorithms that give every square an equal probability of being a mine.
  - Beginner: 8x8 grid - 10 mines
  - Intermediate: 16x16 grid - 40 mines
  - Expert: 32x32 grid - 99 mines
- Single-tap must toggle the “Flag” emoji (🚩) indicating the presence of a mine under the square.
- Double-Tap must open a square.
- If an opened square is adjacent to any mines, the number of mines in adjacent squares is displayed in the square. If the number is 0, omit the number. Diagonals are considered adjacent.
- If an opened square does not contain a mine, and is not adjacent to any mines, the square is opened, and all adjacent squares are opened. Any opened adjacent squares also not adjacent to any mines are also opened. This process repeats until the opened area is bounded by the board dimensions, or mines.
- Opened squares should have a `UIColor.darkGray` background, while closed squares should remain `UIColor.black`.
- If a square containing a mine is opened, the board must open completely to show the location of all mines using a "bomb" emoji (💣), ending the game. The grid should stop accepting taps. Do not worry about how to restart the game; killing the app and relaunching is OK.

## Rubric

Successful submissions typically have the following characteristics:

- Clean, readable code (consistent style, well-chosen variable names, reasonable minimization of duplicated code)
- A working implementation of all required features
- Efficient algorithms (big-O notation)
- Leverages existing UIKit APIs where applicable, rather than reinventing the wheel
- Good data modeling habits
