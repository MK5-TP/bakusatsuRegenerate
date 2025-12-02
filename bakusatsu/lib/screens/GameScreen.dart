// lib/screens/GameScreen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/GameState.dart';
import '../models/Player.dart';
import '../models/CardModel.dart';
import '../logic/CardEffect.dart';
import '../widgets/WinnerBanner.dart'; 

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
          IconButton(
            icon: Icon(Icons.help_outline),
            tooltip: 'ルール説明',
            onPressed: () {
              _showRuleDialog(context);
            },
          ),
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
                  width: 300,
                  height: 150,
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: ListView.builder(
                      itemCount: gameState.gameLogs.length,
                      itemBuilder: (context, index) {
                        // 最新のログほど文字を大きく/明るくする演出
                        final log = gameState.gameLogs[index];
                        final isLatest = index == 0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            log,
                            style: TextStyle(
                              color: isLatest
                                  ? Colors.yellowAccent
                                  : Colors.white70,
                              fontWeight: isLatest
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: isLatest ? 14 : 12,
                            ),
                          ),
                        );
                      }),
                ),
                SizedBox(height: 20),
                // 山札と捨て札
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDeckPlaceholder(gameState),
                    SizedBox(width: 20),
                    _buildDiscardPlaceholder(context, gameState),
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
          //リセットはゲーム終了後表示
          if (gameState.gameOver)
            WinnerBanner(
              winners: gameState.getWinners(),
              onReset: () {
                gameState.resetGame(); 
              },
            ),
        ],
      ),
    );
  }

  // 山札の見た目
  Widget _buildDeckPlaceholder(GameState gameState) {
    return Container(
      width: 60,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
          child: Text("山札\n${gameState.deck.deckSize}枚",
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
    );
  }

  // 捨て札の見た目
  Widget _buildDiscardPlaceholder(BuildContext context, GameState gameState) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: Text("捨て札一覧 (${gameState.discardPile.length}枚)"),
              content: Container(
                width: double.maxFinite,
                height: 300,
                child: gameState.discardPile.isEmpty
                    ? Center(child: Text("まだ捨て札はありません"))
                    : ListView.builder(
                        itemCount: gameState.discardPile.length,
                        itemBuilder: (context, index) {
                          final card = gameState.discardPile[index];
                          return ListTile(
                            leading: Icon(Icons.description,
                                color: card.id <= 3 ? Colors.red : Colors.blue),
                            title: Text(card.name),
                            subtitle: Text(card.effect),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text("閉じる"),
                ),
              ],
            );
          },
        );
      },
      child: Container(
        width: 60,
        height: 90,
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white54, width: 2),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("捨札", style: TextStyle(color: Colors.white)),
              SizedBox(height: 4),
              Text("${gameState.discardPile.length}枚",
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ),
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
      gameState.discardPile.add(card);
    }

    // ログ更新
    gameState.notifyListeners();

    // ターン終了 (次の人へ)
    // 演出のために少し待ってもいいですが、即時移行します
    if (!gameState.gameOver) {
      gameState.nextTurn();
    }
  }

  void _showRuleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text("📜 ルール説明"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRuleSection("基本ルール", [
                  "初期手札2枚。ターン開始時に1枚引き、3枚の中から1枚プレイしてターン終了。",
                  "手札に「爆弾」が3枚揃った時点で即敗北。",
                  "山札がなくなった時、手持ちの「爆弾の強さ合計」が【最も高い】プレイヤーが敗北（低い人が勝利）。",
                ]),
                Divider(),
                _buildRuleSection("カードの効果", []),
                _buildCardInfo("💣 爆弾 (計5枚)", "プレイ不可。持っているだけで危険。\nA(強さ5)x1, B(強さ3)x2, C(強さ1)x2"),
                _buildCardInfo("💥 起爆 (3枚)", "相手の手札を1枚指定。それが爆弾なら相手は即敗北。"),
                _buildCardInfo("⚖️ 投下 (3枚)", "相手と「爆弾の強さ合計」を比較。\n合計値が【低い方】が敗北する（自爆注意！）。"),
                _buildCardInfo("👁 透視 (3枚)", "相手の手札をすべて見る。"),
                _buildCardInfo("🔄 交換 (2枚)", "相手と手札を1枚ずつ交換。"),
                _buildCardInfo("🛡 回避 (2枚)", "次の自分の番まで、自分への効果を無効化。"),
                _buildCardInfo("🔓 解除 (2枚)", "手札を1枚山札の下に戻し、1枚引く。\n（爆弾処理に有効）"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("閉じる"),
            ),
          ],
        );
      },
    );
  }

  // ルールの見出し用ヘルパー
  Widget _buildRuleSection(String title, List<String> contents) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueAccent)),
        SizedBox(height: 8),
        ...contents.map((text) => Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Text("・$text", style: TextStyle(fontSize: 14)),
        )).toList(),
        SizedBox(height: 8),
      ],
    );
  }

  // カード説明用ヘルパー
  Widget _buildCardInfo(String name, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(name, style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(desc, style: TextStyle(fontSize: 13, color: Colors.white70))),
        ],
      ),
    );
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
