import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Snake Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SnakeGame(),
    );
  }
}

class SnakeGame extends StatefulWidget {
  @override
  _SnakeGameState createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGame> {
  final int squaresPerRow = 20;
  final int squaresPerCol = 40;
  final int snakeStartLength = 5;
  Duration gameSpeed = const Duration(milliseconds: 200);
  List<int> snake = [];
  int food = -1;
  String direction = 'down';
  Timer? gameTimer;
  FocusNode focusNode = FocusNode();
  // Declare a score variable
  int score = 0;
  Duration elapsedTime = Duration.zero;
  Timer? timeTimer;
  Color backgroundColor = Colors.black;
  Timer? backgroundTimer;

  @override
  void initState() {
    super.initState();
    focusNode.requestFocus();
    startGame();
    // Timer to update the elapsed time
    timeTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        elapsedTime += Duration(seconds: 1);
      });
    });
    // Timer to change background color
    backgroundTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      setState(() {
        // Toggle background color
        backgroundColor = backgroundColor == Colors.black ? Colors.blueGrey : Colors.black;
      });
    });
  }

  @override
  void dispose() {
    focusNode.dispose();
    // Dispose timers
    gameTimer?.cancel();
    timeTimer?.cancel();
    backgroundTimer?.cancel();
    super.dispose();
  }

  void startGame() {
    snake = List.generate(snakeStartLength, (index) => index);
    direction = 'down';
    generateNewFood();
    gameTimer = Timer.periodic(gameSpeed, (Timer timer) {
      updateGame();
    });
  }

  void generateNewFood() {
    food = Random().nextInt(squaresPerRow * squaresPerCol);
    if (snake.contains(food)) {
      generateNewFood();
    }
  }

  void updateGameSpeed(int milliseconds) {
    setState(() {
      gameSpeed = Duration(milliseconds: milliseconds);
      gameTimer?.cancel();
      gameTimer = Timer.periodic(gameSpeed, (Timer timer) => updateGame());
    });
  }


  void checkLevelUp() {
    if (score % 10 == 0) {  // Level up every 10 points
      int newSpeed = max(100, gameSpeed.inMilliseconds - 20);
      updateGameSpeed(newSpeed);
    }
  }


  void updateGame() {
    setState(() {
      // Calculate the new head position based on the current direction
      int newHead;
      switch (direction) {
        case 'down':
          newHead = snake.first + squaresPerRow;
          break;
        case 'up':
          newHead = snake.first - squaresPerRow;
          break;
        case 'left':
          newHead = snake.first - 1;
          break;
        case 'right':
          newHead = snake.first + 1;
          break;
        default:
          newHead = snake.first;
      }

      // Check if snake has hit the wall or itself
      if (snake.contains(newHead) || newHead < 0 || newHead >= squaresPerRow * squaresPerCol ||
          (direction == 'left' && newHead % squaresPerRow == squaresPerRow - 1) ||
          (direction == 'right' && newHead % squaresPerRow == 0)) {
        // Inside the game over condition in updateGame
        gameTimer?.cancel();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Game Over'),
              content: Text('Your score: ${snake.length - snakeStartLength}'),
              actions: <Widget>[
                TextButton(
                  child: Text('Restart'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    startGame();
                  },
                ),
              ],
            );
          },
        );
        return;
      }

      // Move the snake
      snake.insert(0, newHead);
      if (newHead == food) {
        generateNewFood();
        score++;
        checkLevelUp();
      } else {
        snake.removeLast();
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Snakelo:- Score: $score || Time: ${elapsedTime.inMinutes}:${(elapsedTime.inSeconds % 60).toString().padLeft(2, '0')}'),
        // Rest of AppBar properties...
      ),
      backgroundColor: backgroundColor,
      body: RawKeyboardListener(
      focusNode: focusNode,
      onKey: (event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown && direction != 'up') {
            setState(() => direction = 'down');
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp && direction != 'down') {
            setState(() => direction = 'up');
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft && direction != 'right') {
            setState(() => direction = 'left');
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight && direction != 'left') {
            setState(() => direction = 'right');
          }
        }
      },
      child: GestureDetector(
        onTap: () => focusNode.requestFocus(),
        onVerticalDragUpdate: (details) {
          if (direction != 'up' && details.delta.dy > 0) {
            direction = 'down';
          } else if (direction != 'down' && details.delta.dy < 0) {
            direction = 'up';
          }
        },
        onHorizontalDragUpdate: (details) {
          if (direction != 'left' && details.delta.dx > 0) {
            direction = 'right';
          } else if (direction != 'right' && details.delta.dx < 0) {
            direction = 'left';
          }
        },
        child: GridView.builder(
          physics: NeverScrollableScrollPhysics(),
          itemCount: squaresPerRow * squaresPerCol,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: squaresPerRow,
          ),
          itemBuilder: (BuildContext context, int index) {
            var color;
            if (snake.contains(index)) {
              color = index == snake.first ? Colors.green[700] : Colors.green[500]; // Darker color for the head
            } else if (index == food) {
              color = Colors.red[500];
            } else {
              color = Colors.grey[800];
            }
            return Container(
              margin: EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.rectangle,
              ),
            );
          },
        ),
      ),
      ),
    );
  }
}
