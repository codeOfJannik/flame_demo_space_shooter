import 'dart:async';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const starshipSize = 96.0;

void main() {
  runApp(GameWidget(game: SpaceShooterGame()));
}

class SpaceShooterGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  SpaceShooterGame();

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();

    add(PlayerStarship(position: Vector2(size.x / 2, size.y - starshipSize)));

    add(TimerComponent(
        period: 1,
        onTick: () {
          add(Enemy(
              position:
                  Vector2(Random().nextInt(size.x.toInt()).toDouble(), 0)));
        },
        repeat: true,
        autoStart: true));
  }
}

class PlayerStarship extends SpriteAnimationComponent
    with HasGameRef<SpaceShooterGame>, KeyboardHandler, CollisionCallbacks {
  PlayerStarship({super.position})
      : super(size: Vector2.all(starshipSize), anchor: Anchor.center);

  final direction = Vector2.zero();
  final rotation = Vector2.zero();
  static const movingSpeed = 400;
  static const rotationSpeed = 10;

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();

    animation = await gameRef.loadSpriteAnimation(
      "starfighter_2.png",
      SpriteAnimationData.sequenced(
          amount: 4, stepTime: .1, textureSize: Vector2.all(48)),
    );

    add(RectangleHitbox());

    add(KeyboardListenerComponent(
      keyUp: {
        LogicalKeyboardKey.keyA: (_) {
          direction.x = 0;
          return false;
        },
        LogicalKeyboardKey.keyD: (_) {
          direction.x = 0;
          return false;
        },
        LogicalKeyboardKey.keyW: (_) {
          direction.y = 0;
          return false;
        },
        LogicalKeyboardKey.keyS: (_) {
          direction.y = 0;
          return false;
        },
        LogicalKeyboardKey.keyQ: (_) {
          rotation.x = 0;
          return false;
        },
        LogicalKeyboardKey.keyE: (_) {
          rotation.x = 0;
          return false;
        },
        LogicalKeyboardKey.space: (_) {
          gameRef.add(Shot(position: position.clone(), angle: angle));
          return false;
        }
      },
      keyDown: {
        LogicalKeyboardKey.keyA: (_) {
          direction.x = -1;
          return false;
        },
        LogicalKeyboardKey.keyD: (_) {
          direction.x = 1;
          return false;
        },
        LogicalKeyboardKey.keyW: (_) {
          direction.y = -1;
          return false;
        },
        LogicalKeyboardKey.keyS: (_) {
          direction.y = 1;
          return false;
        },
        LogicalKeyboardKey.keyQ: (_) {
          rotation.x = -1;
          return false;
        },
        LogicalKeyboardKey.keyE: (_) {
          rotation.x = 1;
          return false;
        },
        LogicalKeyboardKey.space: (_) => false
      },
    ));
  }

  @override
  void update(double dt) async {
    super.update(dt);

    final gameSize = await gameRef.size;

    angle += rotation.x * rotationSpeed * dt;

    position.x += direction.x * movingSpeed * dt;
    position.x = position.x.clamp(0, gameSize.x);

    position.y += direction.y * movingSpeed * dt;
    position.y = position.y.clamp(0, gameSize.y);
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Enemy) {
      removeFromParent();
      other.removeFromParent();

      gameRef.add(TextComponent(
        text: "Game Over!",
        position: gameRef.size / 2,
      ));
    }
  }
}

class Shot extends SpriteAnimationComponent with HasGameRef<SpaceShooterGame> {
  Shot({super.position, super.angle}) : super(size: Vector2.all(32));

  static const bulletSpeed = 400;

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();

    animation = await gameRef.loadSpriteAnimation(
      "shoot_2.png",
      SpriteAnimationData.sequenced(
          amount: 4, stepTime: .1, textureSize: Vector2.all(16)),
    );

    add(RectangleHitbox());
  }

  bool get _isOutside =>
      position.y < 0 ||
      position.y > gameRef.size.y ||
      position.x < 0 ||
      position.x > gameRef.size.x;

  @override
  void update(double dt) {
    super.update(dt);

    position.x += bulletSpeed * dt * sin(angle);
    position.y -= bulletSpeed * dt * cos(angle);

    if (_isOutside) removeFromParent();
  }
}

class Enemy extends SpriteAnimationComponent
    with HasGameRef<SpaceShooterGame>, CollisionCallbacks {
  Enemy({super.position, super.angle}) : super(size: Vector2.all(32));

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();

    animation = await gameRef.loadSpriteAnimation(
      "alien_1.png",
      SpriteAnimationData.sequenced(
          amount: 4, stepTime: .1, textureSize: Vector2.all(16)),
    );

    add(RectangleHitbox());
  }

  bool get _isOutside =>
      position.y < 0 ||
      position.y > gameRef.size.y ||
      position.x < 0 ||
      position.x > gameRef.size.x;

  @override
  void update(double dt) {
    super.update(dt);

    position.y += 200 * dt * cos(angle);
    position.x += 200 * dt * sin(angle);

    if (_isOutside) removeFromParent();
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Shot) {
      removeFromParent();
      other.removeFromParent();
    }
  }
}
