import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

class FlappyBird extends FlameGame with TapDetector, HasCollisionDetection {
  late Bird bird;
  late TextComponent scoreText;
  Timer pipeGenerator = Timer(2, repeat: true);
  int score = 0;
  bool isPlaying = true;
  late Ground ground;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add background
    add(
      SpriteComponent(
        sprite: await loadSprite('background.png'),
        size: size,
        priority: -1,
      ),
    );

    // Add ground
    ground = Ground();
    add(ground);

    // Add bird
    bird = Bird();
    add(bird);

    // Add score text
    scoreText = TextComponent(
      text: 'Score: 0',
      position: Vector2(20, 20),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(scoreText);

    // Start generating pipes
    pipeGenerator.onTick = () => generatePipes();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isPlaying) {
      pipeGenerator.update(dt);
    }
  }

  void generatePipes() {
    if (!isPlaying) return;

    const pipeGap = 850.0;
    const groundHeight = 100;
    const minDistanceFromEdge = 100;
    final random = Random();
    final heightRange = size.y - groundHeight - 2 * minDistanceFromEdge - pipeGap; // 100 is min distance from edge
    final centerY = minDistanceFromEdge + random.nextDouble() * heightRange; //+ 100 + pipeGap / 2;

    add(Pipe(position: Vector2(size.x, centerY - pipeGap / 2), isTop: true));
    add(Pipe(position: Vector2(size.x, centerY + pipeGap / 2), isTop: false));
  }

  @override
  void onTap() {
    if (isPlaying) {
      bird.jump();
    }
  }

  void gameOver() {
    isPlaying = false;
    overlays.add('gameOver');
  }

  void reset() {
    isPlaying = true;
    score = 0;
    scoreText.text = 'Score: 0';
    bird.reset();
    removeWhere((component) => component is Pipe);
    overlays.remove('gameOver');
  }

  void increaseScore() {
    score++;
    scoreText.text = 'Score: $score';
  }
}

class Bird extends SpriteComponent with CollisionCallbacks, HasGameRef<FlappyBird> {
  static final Vector2 initialPosition = Vector2(100, 200);
  static const double jumpForce = -350;
  static const double gravity = 900;

  double velocity = 0;

  Bird() : super(size: Vector2(50, 40)) {
    position = initialPosition;
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite('bird.png');
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameRef.isPlaying) {
      velocity += gravity * dt;
      position.y += velocity * dt;

      // Rotate bird based on velocity
      angle = (velocity / 500).clamp(-0.5, 0.5);
    }
  }

  void jump() {
    velocity = jumpForce;
  }

  void reset() {
    position = initialPosition;
    velocity = 0;
    angle = 0;
  }

  @override
  void onCollision(Set<Vector2> points, PositionComponent other) {
    super.onCollision(points, other);
    if (other is Pipe) {
      gameRef.gameOver();
    }
  }
}

class Pipe extends SpriteComponent with CollisionCallbacks, HasGameRef<FlappyBird> {
  static const double speed = 200;
  final bool isTop;

  Pipe({required Vector2 position, required this.isTop})
      : super(size: Vector2(70, 700)) {
    this.position = position;
    anchor = isTop ? Anchor.bottomLeft : Anchor.topLeft;
  }

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite('pipe.png');
    if (isTop) {
      flipVertically();
    }
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameRef.isPlaying) {
      position.x -= speed * dt;

      if (position.x + size.x < 0) {
        removeFromParent();
        if (isTop) {
          gameRef.increaseScore();
        }
      }
    }
  }
}

class Ground extends PositionComponent with HasGameRef<FlappyBird> {
  static const double speed = 200;
  static const double groundHeight = 100;
  static const double groundWidth = 320;
  late List<GroundSegment> groundSegments;

  Ground() : super(size: Vector2.zero()) {
    groundSegments = [];
  }

  @override
  Future<void> onLoad() async {
    // Set the position and size of the ground container
    position = Vector2(0, gameRef.size.y - groundHeight);
    size = Vector2(gameRef.size.x, groundHeight);

    // Create multiple ground segments
    for (int i = 0; i < 3; i++) {
      final groundSegment = GroundSegment(
        position: Vector2(i * groundWidth, 0), // Position relative to the ground component
      );
      add(groundSegment);
      groundSegments.add(groundSegment);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameRef.isPlaying) {
      // Move the ground segments to the left
      for (var segment in groundSegments) {
        segment.position.x -= speed * dt;

        // If the segment has moved off-screen, reset its position to the right
        if (segment.position.x + segment.size.x < 0) {
          segment.position.x = groundSegments.last.position.x + groundWidth;
          groundSegments.add(groundSegments.removeAt(0)); // Move segment to the end
        }
      }
    }
  }
}

class GroundSegment extends SpriteComponent with CollisionCallbacks, HasGameRef<FlappyBird> {
  GroundSegment({required Vector2 position}) : super(size: Vector2(320, 100)) {
    this.position = position;
  }

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite('ground.png');
    add(RectangleHitbox());
  }

  @override
  void onCollision(Set<Vector2> points, PositionComponent other) {
    super.onCollision(points, other);
    if (other is Bird) {
      gameRef.gameOver();
    }
  }
}