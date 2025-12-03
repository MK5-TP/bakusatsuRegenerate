import 'package:flutter/material.dart';
import 'screens/GameScreen.dart';
import 'package:flame/game.dart';
import 'FlameGame/AppGameArea.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import 'logic/GameState.dart';
import 'screens/GameScreen.dart';
import 'models/Player.dart';
import 'models/Deck.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final state = GameState([
            Player("あなた",isCpu: false),
            Player("CPU1",isCpu: true),
            Player("CPU2",isCpu: true),
            Player("CPU3",isCpu: true),
          ]);
          state.initGame();
          return state;
        })
      ],
      child: MaterialApp(
        title: 'BAKUSATSU',
        theme: ThemeData.dark(),
        home: Scaffold(
            backgroundColor: Colors.black87,
            body: Center(
                child: Container(
                    constraints: BoxConstraints(
                        maxWidth: kIsWeb ? 600 : double.infinity),
                    child: GameScreen()))),
      ),
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
