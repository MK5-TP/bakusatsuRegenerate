// lib/screens/GameScreen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/GameState.dart';
import '../models/Player.dart';
import '../models/CardModel.dart';
import '../logic/CardEffect.dart';

class GameScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Providerから今のゲーム状態を受け取る
    // listen: true なので、notifyListeners()が呼ばれるたびにここが再描画される
    final gameState = Provider.of<GameState>(context);
    final players = gameState.players;

    // プレイヤーの割り当て（固定）
    // P1: 自分, P2: 上の敵, P3: 左の敵, P4: 右の敵 と仮定して配置
    // ※実際はリストのインデックスで管理しますが、一旦UI確認用に固定します
    final myPlayer = players[0];
    final cpuTop = players.length > 1 ? players[1] : null;
    final cpuLeft = players.length > 2 ? players[2] : null;
    final cpuRight = players.length > 3 ? players[3] : null;

    return Scaffold(
      backgroundColor: Color(0xFF2C3E50), // HTML版と同じ背景色
      appBar: AppBar(
        title: Text("BAKUSATSU Web"),
        backgroundColor: Colors.black45,
        actions: [
          // デバッグ用：強制的にターンを進めるボタン
          IconButton(
            icon: Icon(Icons.skip_next),
            onPressed: () {
              // ※Deckが必要ですが、一旦UI確認用なのでnull安全は無視してます
              // gameState.nextTurn(gameState.deck);
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text("デバッグ: ターン進行はまだ未接続")));
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // --- 1. 対戦相手の配置 ---
          if (cpuTop != null)
            Align(
              alignment: Alignment.topCenter,
              child: OpponentWidget(player: cpuTop, position: "Top"),
            ),
          if (cpuLeft != null)
            Align(
              alignment: Alignment.centerLeft,
              child: OpponentWidget(player: cpuLeft, position: "Left"),
            ),
          if (cpuRight != null)
            Align(
              alignment: Alignment.centerRight,
              child: OpponentWidget(player: cpuRight, position: "Right"),
            ),

          // --- 2. 中央フィールド（山札・ログなど） ---
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ログ表示エリア
                Container(
                  padding: EdgeInsets.all(8),
                  color: Colors.black54,
                  child: Text(
                    gameState.lastLog,
                    style: TextStyle(color: Colors.yellowAccent),
                  ),
                ),
                SizedBox(height: 20),
                // 山札と捨て札
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDeckPlaceholder(),
                    SizedBox(width: 20),
                    _buildDiscardPlaceholder(),
                  ],
                ),
              ],
            ),
          ),

          // --- 3. 自分の手札エリア（画面下） ---
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 160,
              padding: EdgeInsets.only(bottom: 20),
              color: Colors.black26,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text("あなたの手札 (爆弾: ${myPlayer.countBombs()})",
                      style: TextStyle(color: Colors.white)),
                  SizedBox(height: 10),
                  // 横スクロール可能な手札リスト
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: myPlayer.hand.asMap().entries.map((entry) {
                        int index = entry.key; // カードのインデックス（捨てる処理などで必要になるかも）
                        CardModel card = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: HandCardWidget(
                            card: card,
                            onTap: () async {
                              await _handleCardPlay(
                                  context, gameState, myPlayer, card, index);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 山札の見た目
  Widget _buildDeckPlaceholder() {
    return Container(
      width: 60,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
          child: Text("山札",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
    );
  }

  // 捨て札の見た目
  Widget _buildDiscardPlaceholder() {
    return Container(
      width: 60,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.grey,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white54, width: 2),
      ),
      child: Center(child: Text("捨札", style: TextStyle(color: Colors.white))),
    );
  }

  // GameScreen クラス内に追加
  Future<void> _handleCardPlay(BuildContext context, GameState gameState,
      Player myPlayer, CardModel card, int cardIndex) async {
    // 1. 自分のターンか確認
    if (gameState.currentPlayer != myPlayer) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("まだあなたのターンではありません！")));
      return;
    }

    // 2. 対象選択が必要か確認
    // RequiresTarget: 0=不要, 1=他人, 2=任意
    int targetType = CardEffect.requiresTarget(card);
    Player? targetPlayer;

    if (targetType != 0) {
      List<Player> validTargets = gameState.getValidTargets(card, targetType);
      if (validTargets.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("対象がいません")));
        return;
      }


      targetPlayer = await showDialog<Player>(
        context: context,
        builder: (ctx) {
          return SimpleDialog(
            title: Text("${card.name} の対象を選択"),
            children: validTargets.map((p) {
              return SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, p),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(p.name, style: TextStyle(fontSize: 18)),
                ),
              );
            }).toList(),
          );
        },
      );

      // キャンセルなら処理中止
      if (targetPlayer == null) return;
    }

    // 3. 効果発動
    // GameStateが持っているDeckを渡す
    bool result = CardEffect.applyEffect(
        gameState.deck, card, myPlayer, targetPlayer, gameState, cardIndex);

    // 4. カード消費とターン経過
    if (myPlayer.hand.contains(card)) {
      myPlayer.hand.remove(card);
    }

    // ログ更新
    gameState.notifyListeners();

    // ターン終了 (次の人へ)
    // 演出のために少し待ってもいいですが、即時移行します
    if (!gameState.gameOver) {
      gameState.nextTurn();
    }
  }
}

class OpponentWidget extends StatelessWidget {
  final Player player;
  final String position;

  const OpponentWidget({required this.player, required this.position});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(10),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Color(0xFF34495E), // HTML版のplayer-bg色
        borderRadius: BorderRadius.circular(8),
        border:
            player.isEvade ? Border.all(color: Colors.blue, width: 3) : null,
      ),
      width: 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person, color: Colors.white, size: 30),
          Text(player.name,
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text("🎴 x ${player.hand.length}",
              style: TextStyle(color: Colors.white, fontSize: 16)),
          if (player.isEvade)
            Text("🛡️回避中",
                style: TextStyle(color: Colors.blueAccent, fontSize: 10)),
        ],
      ),
    );
  }
}

// 自分の手札カードWidget
class HandCardWidget extends StatefulWidget {
  final CardModel card;
  final VoidCallback onTap;

  const HandCardWidget({required this.card, required this.onTap});

  @override
  _HandCardWidgetState createState() => _HandCardWidgetState();
}

class _HandCardWidgetState extends State<HandCardWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    bool isBomb = widget.card.id <= 3;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _isHovered ? -20 : 0, 0),
          width: 80,
          height: 110,
          decoration: BoxDecoration(
            color: isBomb ? Color(0xFFE74C3C) : Color(0xFF3498DB),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: _isHovered ? 12 : 4,
                offset: _isHovered ? Offset(4, 8) : Offset(2, 2),
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.card.name,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
                textAlign: TextAlign.center,
              ),
              if (isBomb)
                Text("強さ:${_getBombPower(widget.card.id)}",
                    style: TextStyle(color: Colors.white70, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  int _getBombPower(int id) {
    if (id == 1) return 5;
    if (id == 2) return 3;
    if (id == 3) return 1;
    return 0;
  }
}
