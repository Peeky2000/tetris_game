import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tetris_game/widgets/piece.dart';
import 'package:tetris_game/widgets/pixel.dart';
import 'package:tetris_game/widgets/values.dart';

/*
GAME BOARD

This is a 2x2 grid with null representing an empty space.
A non empty space will have the color to represent the landed pieces

 */

// create game board
List<List<Tetromino?>> gameBoard = List.generate(
  colLength,
  (i) => List.generate(
    rowLength,
    (j) => null,
  ),
);

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  int currentScore = 0;
  bool gameOver = false;

  ///Current tetris piece
  Piece currentPiece = Piece(type: Tetromino.L);

  @override
  void initState() {
    //start game when app start
    startGame();
    super.initState();
  }

  void startGame() {
    currentPiece.initializePiece();

    //frame refresh rate
    Duration frameRate = const Duration(milliseconds: 800);
    gameLoop(frameRate);
  }

  void gameLoop(Duration frameRate) {
    Timer.periodic(
      frameRate,
      (timer) {
        setState(() {
          //clear lines
          clearLines();

          //check landing
          checkLanding();

          //check if game is over
          if (gameOver == true) {
            timer.cancel();
            showGameOverMessageDialog();
          }

          //move current piece down
          currentPiece.movePiece(Direction.down);
        });
      },
    );
  }

  //game over message dialog
  void showGameOverMessageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Game Over'),
        content: Text('Your score is: $currentScore'),
        actions: [
          TextButton(
            onPressed: () {
              //reset the game
              resetGame();
              Navigator.pop(context);
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  void resetGame() {
    //clear the game board
    gameBoard = List.generate(
      colLength,
      (i) => List.generate(
        rowLength,
        (j) => null,
      ),
    );

    //new game
    gameOver = false;
    currentScore = 0;

    //create new piece
    createNewPiece();

    //start new game
    startGame();
  }

  // check for collision in a future position
  // return true => there is a collision
  // return false => there is no collision
  bool checkCollision(Direction direction) {
    //loop through each position of the current piece
    for (int i = 0; i < currentPiece.position.length; i++) {
      //calculate the row and column of the current position
      int row = (currentPiece.position[i] / rowLength).floor();
      int col = currentPiece.position[i] % rowLength;

      //adjust the row and col based on the direction
      if (direction == Direction.left) {
        col -= 1;
      } else if (direction == Direction.right) {
        col += 1;
      } else if (direction == Direction.down) {
        row += 1;
      }

      //check if the piece is out of bounds (either too low or too far to the left or right)
      if (row >= colLength || col < 0 || col >= rowLength) {
        return true;
      }

      //check if the current position is already occupied by another piece in the game board
      if (row >= 0 && col >= 0) {
        if (gameBoard[row][col] != null) {
          return true;
        }
      }
    }
    //if no collisions are detected, return false
    return false;
  }

  void checkLanding() {
    //if going down is occupied
    if (checkCollision(Direction.down)) {
      //mark position as occupied on the game board
      for (int i = 0; i < currentPiece.position.length; i++) {
        int row = (currentPiece.position[i] / rowLength).floor();
        int col = currentPiece.position[i] % rowLength;

        if (row >= 0 && col >= 0) {
          gameBoard[row][col] = currentPiece.type;
        }
      }
      //once landed, create the next piece
      createNewPiece();
    }
  }

  void createNewPiece() {
    //create a random object to generate random tetromino types
    Random random = Random();

    //create a random piece with random type
    Tetromino randomType =
        Tetromino.values[random.nextInt(Tetromino.values.length)];
    currentPiece = Piece(type: randomType);
    currentPiece.initializePiece();
    if (isGameOver()) {
      gameOver = true;
    }
  }

  //move left
  void moveLeft() {
    //make sure the move is valid before moving there
    if (!checkCollision(Direction.left)) {
      setState(() {
        currentPiece.movePiece(Direction.left);
      });
    }
  }

  //rotate
  void rotatePiece() {
    setState(() {
      currentPiece.rotatePiece();
    });
  }

  //move right
  void moveRight() {
    //make sure the move is valid before moving there
    if (!checkCollision(Direction.right)) {
      setState(() {
        currentPiece.movePiece(Direction.right);
      });
    }
  }

  //clear lines
  void clearLines() {
    //s1: Loop through each row of the game board from the bottom to top
    for (int row = colLength - 1; row >= 0; row--) {
      //s2: Initialize a variable to track if the row is full
      bool rowIsFull = true;

      //s3: Check if the row if full (all columns in the row are filled with pieces
      for (int col = 0; col < rowLength; col++) {
        //if there's an empty column, set row is full to false and break the loop
        if (gameBoard[row][col] == null) {
          rowIsFull = false;
          break;
        }
      }
      //s4: If the row is full, clear the row and shift rows down
      if (rowIsFull) {
        //s5: move all the rows above the cleared row down by one position
        for (int r = row; r > 0; r--) {
          //copy the above row to the current row
          gameBoard[r] = List.from(gameBoard[r - 1]);
        }

        //s6: set the top row to empty
        gameBoard[0] = List.generate(row, (index) => null);

        //s7: increase the score
        currentScore++;
      }
    }
  }

  //Game over
  bool isGameOver() {
    //check if any columns in the top row are filled
    for (int col = 0; col < rowLength; col++) {
      if (gameBoard[0][col] != null) {
        return true;
      }
    }

    //if the top row is empty, the game is not over
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          //GAME GRID
          Expanded(
            child: GridView.builder(
              itemCount: rowLength * colLength,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: rowLength,
              ),
              itemBuilder: (BuildContext context, int index) {
                //get row and col of each index
                int row = (index / rowLength).floor();
                int col = index % rowLength;

                //current piece
                if (currentPiece.position.contains(index)) {
                  return Center(
                    child: Pixel(
                      color: currentPiece.color,
                    ),
                  );
                }

                //landed pieces
                else if (gameBoard[row][col] != null) {
                  final Tetromino? tetrominoType = gameBoard[row][col];
                  return Pixel(
                    color: tetrominoColors[tetrominoType],
                  );
                }

                //blank pixel
                else {
                  return Center(
                    child: Pixel(
                      color: Colors.grey[900],
                    ),
                  );
                }
              },
            ),
          ),

          //SCORE
          Text(
            'Score: $currentScore',
            style: const TextStyle(
              color: Colors.white,
            ),
          ),

          // GAME CONTROLS
          Padding(
            padding: const EdgeInsets.only(
              bottom: 50.0,
              top: 50.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: moveLeft,
                  color: Colors.white,
                  icon: const Icon(Icons.arrow_back_ios),
                ),
                IconButton(
                  onPressed: rotatePiece,
                  color: Colors.white,
                  icon: const Icon(Icons.rotate_right),
                ),
                IconButton(
                  onPressed: moveRight,
                  color: Colors.white,
                  icon: const Icon(Icons.arrow_forward_ios),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
