import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:testing_flutter/flappy_bird.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlappyBird game = FlappyBird();
  runApp(
    GameWidget(
      game: game,
      overlayBuilderMap: {
        'gameOver': (context, game) => Center(
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Game Over',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (game is FlappyBird) {
                      game.reset();
                    }
                  },
                  child: const Text('Play Again'),
                ),
              ],
            ),
          ),
        ),
      },
    ),
  );
}