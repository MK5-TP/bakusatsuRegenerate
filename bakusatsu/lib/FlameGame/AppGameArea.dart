import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'CardComponent.dart';
import 'BackGroundComponent.dart';

void main() {
  runApp(GameWidget(game: AppGameArea()));
}

class AppGameArea extends FlameGame with TapDetector {
  Future<void> onLoad() async {
    add(BackgroundComponent(size: size));
    add(CardComponent(position: Vector2(size.x / 2, size.y * 0.9)));
  }
}
