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

    final allParticipants = [
      ...gameState.players,
      ...gameState.defeatedPlayers
    ];

    Player? findByName(String name) {
      try {
        return allParticipants.firstWhere((p) => p.name == name);
      } catch (e) {
        return null;
      }
    }

    final myPlayer = findByName("あなた")!;
    final cpu1 = findByName("CPU1");
    final cpu2 = findByName("CPU2");
    final cpu3 = findByName("CPU3");

    // 対戦相手リスト
    //final opponents = gameState.allPlayers.where((p) => p != myPlayer).toList();

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
      body: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: 600,
            height: 800,
            child: Stack(
              children: [
                // CPU1 は常に「左」
                if (cpu1 != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OpponentWidget(
                      player: cpu1,
                      position: "Left",
                      isTurn: gameState.currentPlayer == cpu1,
                      isGameOver: gameState.gameOver,
                    ),
                  ),

                // CPU2 は常に「上」
                if (cpu2 != null)
                  Align(
                    alignment: Alignment.topCenter,
                    child: OpponentWidget(
                      player: cpu2,
                      position: "Top",
                      isTurn: gameState.currentPlayer == cpu2,
                      isGameOver: gameState.gameOver,
                    ),
                  ),

                // CPU3 は常に「右」
                if (cpu3 != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: OpponentWidget(
                      player: cpu3,
                      position: "Right",
                      isTurn: gameState.currentPlayer == cpu3,
                      isGameOver: gameState.gameOver,
                    ),
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2.0),
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
                    height: 220,
                    padding: EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.black26, // 元の背景色
                      // 自分のターンなら上部に黄色いボーダーを表示
                      border: (gameState.currentPlayer == myPlayer)
                          ? Border(
                              top: BorderSide(
                                  color: Colors.yellowAccent, width: 4))
                          : null,
                      // 自分のターンなら全体がほんのり光る
                      boxShadow: (gameState.currentPlayer == myPlayer)
                          ? [
                              BoxShadow(
                                  color: Colors.yellowAccent.withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 5)
                            ]
                          : [],
                    ),
                    // 死んでいたらDeadUI、生きていればHandUI
                    child: myPlayer.isDead
                        ? _buildDeadStateUI(myPlayer)
                        : _buildHandUI(myPlayer, context, gameState),
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
          ),
        ),
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

  // ★追加: 手札からカードを1枚選ぶダイアログ
  Future<int?> _showCardSelectDialog(
      BuildContext context, Player player, String title) async {
    return await showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8),
              itemCount: player.hand.length,
              itemBuilder: (context, index) {
                final c = player.hand[index];
                bool isBomb = c.id <= 3;
                return GestureDetector(
                  onTap: () => Navigator.pop(ctx, index), // 選んだインデックスを返す
                  child: Container(
                    decoration: BoxDecoration(
                      color: isBomb ? Colors.redAccent : Colors.blueAccent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white),
                    ),
                    child: Center(
                      child: Text(
                        c.name,
                        style: TextStyle(color: Colors.white, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: Text("キャンセル")),
          ],
        );
      },
    );
  }

  // ★修正: カードプレイ処理のロジック更新
  Future<void> _handleCardPlay(BuildContext context, GameState gameState,
      Player myPlayer, CardModel card, int cardIndex) async {
    if (gameState.currentPlayer != myPlayer) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("まだあなたのターンではありません！")));
      return;
    }

    // --- 1. まず使用したカードを手札から取り除く（「場に出す」イメージ） ---
    // これを先にやらないと、「交換」や「解除」で自分自身を選んでしまう可能性があるため
    myPlayer.hand.removeAt(cardIndex);
    gameState.discardPile.add(card); // 捨て札へ
    gameState.notifyListeners(); // 画面更新(手札が減る)

    // キャンセル時の復元用関数
    void cancelPlay() {
      myPlayer.hand.insert(cardIndex, card); // 手札に戻す
      gameState.discardPile.removeLast(); // 捨て札から消す
      gameState.notifyListeners();
    }

    // --- 2. ターゲット選択 ---
    int targetType = CardEffect.requiresTarget(card);
    Player? targetPlayer;

    if (targetType != 0) {
      List<Player> validTargets = gameState.getValidTargets(card, targetType);
      if (validTargets.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("対象がいません")));
        cancelPlay(); // キャンセル復元
        return;
      }

      targetPlayer = await showDialog<Player>(
        context: context,
        builder: (ctx) {
          return SimpleDialog(
            title: Text("${card.name} の対象を選択"),
            children: validTargets.map((p) {
              String status = "";
              if (p == myPlayer) status += " (自分)";
              if (p.isEvade) status += " 🛡️回避中";
              return SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, p),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(p.name + status,
                      style: TextStyle(
                          fontSize: 18,
                          color: p.isEvade ? Colors.black : Colors.white)),
                ),
              );
            }).toList(),
          );
        },
      );

      if (targetPlayer == null) {
        cancelPlay(); // キャンセル復元
        return;
      }
    }

    // --- 3. 追加のカード選択（交換・解除用） ---
    int? secondaryCardIndex;

    // ★交換(ID:7): 相手に渡すカードを自分の手札から選ぶ
    if (card.id == 7) {
      if (myPlayer.hand.isEmpty) {
        // 交換カードを出したら手札がなくなった場合（ありえないが念のため）
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("渡せるカードがありません")));
        cancelPlay();
        return;
      }

      secondaryCardIndex =
          await _showCardSelectDialog(context, myPlayer, "相手に押し付けるカードを選択");

      if (secondaryCardIndex == null) {
        cancelPlay();
        return;
      }
    }

    // ★解除(ID:9): 対象が自分なら、戻すカードを選ぶ。他人ならランダム(nullのまま)
    if (card.id == 9 && targetPlayer == myPlayer) {
      secondaryCardIndex =
          await _showCardSelectDialog(context, myPlayer, "山札に戻すカードを選択");

      if (secondaryCardIndex == null) {
        cancelPlay();
        return;
      }
    }

    // --- 4. 効果発動 ---

    CardEffect.applyEffect(gameState.deck, card, myPlayer, targetPlayer,
        gameState, secondaryCardIndex);

    // ログ更新など
    gameState.notifyListeners();

    if (gameState.gameOver) {
      //なんにもせんよ
    } else if (myPlayer.isDead) {
      gameState.startTurn();
    } else {
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
                _buildCardInfo("💣 爆弾 (計5枚)",
                    "プレイ不可。持っているだけで危険。\nA(強さ5)x1, B(強さ3)x2, C(強さ1)x2"),
                _buildCardInfo("💥 起爆 (3枚)", "相手の手札を1枚指定。それが爆弾なら相手は即敗北。"),
                _buildCardInfo(
                    "⚖️ 投下 (3枚)", "相手と「爆弾の強さ合計」を比較。\n合計値が【低い方】が敗北する（自爆注意！）。"),
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
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.blueAccent)),
        SizedBox(height: 8),
        ...contents
            .map((text) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text("・$text", style: TextStyle(fontSize: 14)),
                ))
            .toList(),
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
          SizedBox(
              width: 100,
              child: Text(name, style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              child: Text(desc,
                  style: TextStyle(fontSize: 13, color: Colors.white70))),
        ],
      ),
    );
  }

  // 敗北時のUI
  Widget _buildDeadStateUI(Player myPlayer) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("💀", style: TextStyle(fontSize: 40)),
              SizedBox(width: 10),
              Text("敗北しました...",
                  style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          Text("手札（爆弾計: ${myPlayer.getBombPower()}）",
              style: TextStyle(color: Colors.white70)),

          // 敗北時，自分の手札を表示
          SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: myPlayer.hand.map((card) {
                bool isBomb = card.id <= 3;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Opacity(
                    opacity: 0.8, // 少し暗くする
                    child: HandCardWidget(
                      card: card,
                      onTap: () {}, //なにもうごかない
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ★追加: 通常時の手札UI（元々のコードを切り出したもの）
  Widget _buildHandUI(
      Player myPlayer, BuildContext context, GameState gameState) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text("あなたの手札 (爆弾: ${myPlayer.countBombs()})",
            style: TextStyle(color: Colors.white)),
        SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: myPlayer.hand.asMap().entries.map((entry) {
              int index = entry.key;
              CardModel card = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: HandCardWidget(
                  card: card,
                  onTap: () {
                    _handleCardPlay(context, gameState, myPlayer, card, index);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class OpponentWidget extends StatelessWidget {
  final Player player;
  final String position;
  final bool isTurn;
  final bool isGameOver;

  const OpponentWidget(
      {required this.player,
      required this.position,
      required this.isTurn,
      required this.isGameOver});

  @override
  Widget build(BuildContext context) {
    bool isDead = player.isDead;
    int handSize = player.hand.length;
    bool showFaceUp = isDead || isGameOver;

    Widget buildCardBack(int index) {
      // HandCardWidget(80x110)の半分くらいのサイズ感で作成
      double width = 40;
      double height = 55;
      // 少しずつ右にずらすための計算
      double overlapOffset = 15.0;

      return Positioned(
        left: index * overlapOffset,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: isDead ? Colors.grey[800] : Color(0xFF8D6E63),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
                color: isDead ? Colors.white30 : Colors.white70, width: 1),
            boxShadow: [
              if (!isDead)
                BoxShadow(
                    color: Colors.black38, blurRadius: 2, offset: Offset(1, 1))
            ],
          ),
          child: Center(
              child: Icon(Icons.help_outline, color: Colors.white24, size: 20)),
        ),
      );
    }

    Widget buildCardFront(int index) {
      // 範囲外アクセス防止
      if (index >= player.hand.length) return SizedBox();

      CardModel card = player.hand[index];
      bool isBomb = card.id <= 3;

      double width = 40;
      double height = 55;
      double overlapOffset = 20.0; // 表面は見たいので少し間隔を広げる

      return Positioned(
        left: index * overlapOffset,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            // 爆弾なら赤、魔法なら青
            color: isBomb ? Color(0xFFE74C3C) : Color(0xFF3498DB),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white, width: 1),
            boxShadow: [
              BoxShadow(
                  color: Colors.black45, blurRadius: 2, offset: Offset(1, 1))
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 文字サイズを小さくして無理やり入れる
                Text(
                  card.name,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                ),
                if (isBomb)
                  Text("強${_getBombPower(card.id)}",
                      style: TextStyle(color: Colors.white70, fontSize: 6)),
              ],
            ),
          ),
        ),
      );
    }

    Color borderColor = Colors.transparent;
    double borderWidth = 0;
    List<BoxShadow> shadows = [];

    if (isTurn) {
      borderColor = Colors.yellowAccent;
      borderWidth = 3;
      shadows = [
        BoxShadow(
          color: Colors.yellowAccent.withOpacity(0.6),
          blurRadius: 15,
          spreadRadius: 2,
        )
      ];
    } else if (player.isEvade) {
      borderColor = Colors.blueAccent;
      borderWidth = 3;
    }

    return Container(
      margin: EdgeInsets.all(10),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDead ? Colors.black45 : Color(0xFF34495E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: borderColor, width: borderWidth == 0 ? 0 : borderWidth),
        boxShadow: shadows,
      ),
      width: 140 + (handSize * 5).toDouble(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          isDead
              ? Text("💀", style: TextStyle(fontSize: 30))
              : Icon(Icons.person, color: Colors.white, size: 30),
          Text(
            player.name,
            style: TextStyle(
              color: isDead ? Colors.grey : Colors.white,
              fontWeight: FontWeight.bold,
              decoration: isDead ? TextDecoration.lineThrough : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8),
          if (handSize > 0)
            Container(
              height: 60, // カードの高さ＋少しの余白
              width: double.infinity,
              // Stackを使ってカードを重ねて表示
              child: Stack(
                alignment: Alignment.centerLeft,
                children: List.generate(handSize, (index) {
                  // 最大表示枚数を制限（例: 10枚まで）して、はみ出しすぎるのを防ぐ
                  if (index >= 10) return SizedBox();
                  return showFaceUp
                      ? buildCardFront(index)
                      : buildCardBack(index);
                }),
              ),
            )
          else
            // 手札が0枚の場合
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text("手札なし",
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
            ),
          //Text("🎴 x ${player.hand.length}", style: TextStyle(color: Colors.white, fontSize: 16)),
          if (player.isEvade && !isDead)
            Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text("🛡️回避中",
                    style: TextStyle(color: Colors.blueAccent, fontSize: 10))),

          if (showFaceUp && handSize > 0)
            Text("爆弾計: ${player.getBombPower()}",
                style: TextStyle(
                    color: Colors.yellowAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
        ],
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
