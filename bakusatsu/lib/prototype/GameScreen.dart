import 'package:flutter/material.dart';
import 'CardWidget.dart';
import 'Deck.dart';
import 'CardModel.dart';
import 'CardEffect.dart';
import 'Player.dart';
import 'GameState.dart';
import 'dart:async';
import 'WinnerBanner.dart';

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  CardModel? playedCard; // プレイしたカードを表示する用
  Deck deck = Deck();
  late GameState gameState;
  bool showBanner = false;

  @override
  void initState() {
    super.initState();
    gameState = GameState([
      Player("P1"),
      Player("P2"),
      Player("P3"),
      Player("P4"),
    ]);

    // 各プレイヤーに2枚ずつカードを配る
    for (var player in gameState.players) {
      deck.drawCardForPlayer(player);
      deck.drawCardForPlayer(player);
    }
    deck.drawCardForPlayer(gameState.currentPlayer);
    gameState.checkHandBombOver(deck);
  }

  void playCard(int index, Player? targetPlayer) async {
    Player currentPlayer = gameState.currentPlayer;
    CardModel selectedCard = currentPlayer.hand[index];
    int? selectedCardindex;
    if (targetPlayer != null) {
      print(
          "${currentPlayer.name}は，${targetPlayer.name}に，${selectedCard.name}を発動！！");

      if (selectedCard.id == 7 || (selectedCard.id == 9 && targetPlayer == currentPlayer)) {
        selectedCardindex = await selectCardDialog(index, targetPlayer);
        if(selectedCardindex < 0) return;
      }
    }
    setState(() {
    bool Effective = CardEffect.applyEffect(deck, selectedCard, currentPlayer,
        targetPlayer, gameState, selectedCardindex); // 選択したカードの効果発揮
        
      if (Effective) {
        playedCard = selectedCard; // 選択したカードをプレイ
        currentPlayer.hand.removeAt(index); // 手札から破棄
        if(gameState.gameOver){
          showBanner = true;
        }else{
          gameState.nextTurn(deck); //次のターンへ
        }
      }
    });
  }

  void onHandTapped(int index) {
    CardModel selectedCard = gameState.currentPlayer.hand[index];
    int cardType_targetornontarget = CardEffect.requiresTarget(selectedCard);
    // 効果対象をとるかどうかの判定
    if (cardType_targetornontarget == 1 || cardType_targetornontarget == 2) {
      // 対象選択ダイアログを表示
      showTargetSelectionDialog(
          selectedCard, index, cardType_targetornontarget);
    } else {
      // 対象が不要な場合は即プレイ
      playCard(index, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    Player currentPlayer = gameState.currentPlayer;

    return Scaffold(
      appBar: AppBar(title: Text("BAKUSATSU")),
      body: Stack(
        children: [
          Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("現在のプレイヤー: ${currentPlayer.name}",
                style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            Text("山札（残り  ${deck.deckSize}枚）:", style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                color: deck.deckSize == 0 ? Colors.black12 : Colors.redAccent,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            SizedBox(height: 10),
            Text("プレイしたカード:", style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            playedCard != null
                ? CardWidgetFront(playedCard!)
                : Text("まだカードをプレイしていません"),
            SizedBox(height: 40),
            Text("${currentPlayer.name}手札", style: TextStyle(fontSize: 20)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: currentPlayer.hand.asMap().entries.map((entry) {
                int index = entry.key;
                CardModel card = entry.value;
                return GestureDetector(
                  onTap: () => onHandTapped(index),
                  child: CardWidgetFront(card),
                );
              }).toList(),
            ),
          ],
        ),
         // 勝者バナー（gameOverなら表示）
        if(showBanner)
        WinnerBanner(
          winners: gameState.getWinners(),
          //onReset: 
        ),
        ]
      ),
    );
  }

// 対象player選択ダイアログ
  void showTargetSelectionDialog(CardModel card, int index, int cardtype) {
    List<Player> validTargets = gameState.getValidTargets(card, cardtype);

    if(validTargets.isNotEmpty){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("対象を選択"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: validTargets.map((player) {
              return ListTile(
                title: Text(player.name),
                onTap: () {
                  Navigator.pop(context);
                  playCard(index, player);
                },
              );
            }).toList(),
          ),
        );
      },
    );
    }else{
      playCard(index, null);
    }
  }
  //効果で自分のカードを選択するやつ
  Future<int> selectCardDialog(int playedCardIndex, Player targetPlayer) async {
    Player currentPlayer = gameState.currentPlayer;
    int selectedCardIndex = -1;
    selectedCardIndex = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("カードを選んでください"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: currentPlayer.hand
                .asMap()
                .entries
                .where((entry) => entry.key != playedCardIndex) // 交換カード以外
                .map((entry) => ListTile(
                      title: Text(entry.value.name),
                      onTap: () {
                        Navigator.pop(context, entry.key);
                      },
                    ))
                .toList(),
          ),
        );
      },
    )??-1;
    print("selectedCardIndex : $selectedCardIndex");
    return selectedCardIndex;
  }
  //勝者の表示
}
