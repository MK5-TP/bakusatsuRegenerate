import 'package:flutter/material.dart';
import 'prototype/GameScreen.dart';
import 'package:flame/game.dart';
import 'FlameGame/AppGameArea.dart';


void main() {
  runApp(const MyGame());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: GameScreen(),
    );
  }
}

class MyGame extends StatelessWidget {
  const MyGame({super.key});

  @override
  Widget build(BuildContext context) {
    return GameWidget(game: AppGameArea());
  }
}





