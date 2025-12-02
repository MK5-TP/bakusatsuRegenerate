import 'package:flutter/material.dart';
import '../models/Player.dart';
import '../models/Deck.dart';
import '../models/CardModel.dart';
import '../logic/CardEffect.dart';
import '../logic/GameState.dart';
import 'dart:math';


class GameState extends ChangeNotifier {
  List<Player> players;
  late Deck deck;
  int currentPlayerIndex = 0;
  bool gameOver = false;
  List<Player> defeatedPlayers = [];

  String lastLog = "ゲーム開始";

  GameState(this.players) {
    deck = Deck();
  }

  Player get currentPlayer => players[currentPlayerIndex];

  List<Player> get allPlayers => players;

  Player getPlayer(int index) => players[index];

  void initGame() {
    for (var player in players) {
      for (int i = 0; i < 2; i++) {
        deck.drawCardForPlayer(player);
      }
    }
    startTurn();
    notifyListeners();
  }

  void addLog(String message) {
    lastLog = message;
    notifyListeners();
  }

  List<Player> getValidTargets(CardModel card, int cardtype) {
    if (cardtype == 1) {
      return players.where((p) => !p.isEvade && p != currentPlayer).toList();
    } else {
      //自分も対象にとれる効果
      return players.where((p) => !p.isEvade).toList();
    }
  }

  void startTurn() {
    if (gameOver) return;

    currentPlayer.ResetEvade(); //
    deck.drawCardForPlayer(currentPlayer);
    addLog("${currentPlayer.name}のターンです");
    if (checkHandBombOver()) {
      return;
    }

    if (deck.isEmpty()) {
      gameOver = true;
      addLog("山札がなくなりました！ゲーム終了！");
      notifyListeners();
      return;
    }

    notifyListeners();

    // CPUなら思考ルーチン
    if (currentPlayer.isCpu) {
      _runCpuTurn();
    }
  }

  void nextTurn() {
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
    print("現在のターンプレイヤー: P${currentPlayerIndex + 1}");
    startTurn();
  }

  bool checkHandBombOver() {
    //bool ischecked = false;
    if (currentPlayer.countBombs() >= 3) {
      addLog("${currentPlayer.name} は爆弾を3枚持って敗北！");

      playerDefeated(currentPlayer);

      if (!gameOver) {
        // インデックス調整済みなので、そのまま次の人のターンへ
        // ただし、playerDefeated内でインデックスがずれている可能性があるので注意
        // シンプルに再開
        startTurn();
      }
      return true; // 敗北した
    } 
    return false;// まだ負けてない
  }

  void playerDefeated(Player player) {
    int defeatedIndex = players.indexOf(player);
    // 配列から削除するとインデックスがずれるので注意
    defeatedPlayers.add(players.removeAt(defeatedIndex));

    if (players.length == 1) {
      gameOver = true;
      addLog("勝者が決定しました！: ${players.first.name}");
    } else {
      if (defeatedIndex < currentPlayerIndex) {
        currentPlayerIndex--;
      }
      if (currentPlayerIndex >= players.length) {
          currentPlayerIndex = 0;
      } else {  
          currentPlayerIndex = currentPlayerIndex % players.length;
      }
    }
    notifyListeners();
  }

  String getWinners() {
    if (players.length == 1) {
      // 残った1人が勝者
      return players.first.name;
    }

    // 残っているプレイヤーの爆弾コスト合計を計算
    List<Player> sortedPlayers = List.from(players);
    sortedPlayers.sort((a, b) => a.getBombPower().compareTo(b.getBombPower()));

    int lowestPower = sortedPlayers.first.getBombPower();
    List<Player> winners =
        sortedPlayers.where((p) => p.getBombPower() == lowestPower).toList();

    // 複数人いる場合は全員の名前を連結
    return winners.map((p) => p.name).join(" & ");
  }

  Future<void> _runCpuTurn() async {
    // 演出として少し待つ (1.5秒)
    await Future.delayed(Duration(milliseconds: 1500));

    if (gameOver) return; // 待ち時間に終わっていたら中断

    Player cpu = currentPlayer;

    // 1. 戦略:「解除(ID:9)」を持っていて、かつ「爆弾(ID:1-3)」がある場合、最優先で解除する
    int disarmIndex = cpu.hand.indexWhere((c) => c.id == 9);
    int bombIndex = cpu.hand.indexWhere((c) => c.id <= 3);

    if (disarmIndex != -1 && bombIndex != -1) {
      // 解除カードを使用
      CardModel card = cpu.hand[disarmIndex];

      // カードプレイ処理 (対象: 自分, 戻すカード: 爆弾)
      // CardEffect.applyEffect の仕様に合わせて引数を準備
      // 解除(ID9)は、targetPlayer=自分, selectedCardIndex=爆弾のインデックス

      // 注意: 先に手札から「解除」カード自体を取り除く必要があるか、CardEffectの仕様による
      // ここでは GameScreen と同じく「効果適用 -> 手札から使用カード削除」の流れにします

      addLog("${cpu.name}は爆弾処理を優先しました！");

      // 爆弾のインデックスがずれないように注意（解除カードより後ろにある場合など）
      // CardEffect.effectDisarm は hand.removeAt を行うため、ここで正確なインデックスが必要
      // ここではシンプルに「プレイするカード」と「効果対象のカード」を扱います

      // まずプレイするカードを消費
      cpu.hand.removeAt(disarmIndex);

      // removeしたことでbombIndexがずれる可能性を補正
      if (bombIndex > disarmIndex) bombIndex--;

      // 効果発動（戻す対象として bombIndex を指定）
      CardEffect.applyEffect(deck, card, cpu, cpu, this, bombIndex);
    } else {
      // 2. 通常戦略: プレイ可能なカード（爆弾以外）からランダムに選ぶ
      List<int> playableIndices = [];
      for (int i = 0; i < cpu.hand.length; i++) {
        if (cpu.hand[i].id > 3) {
          // 爆弾(1-3)以外
          playableIndices.add(i);
        }
      }

      if (playableIndices.isEmpty) {
        // 出せるカードがない（爆弾のみなど）→ 何もしないでターン終了
        addLog("${cpu.name}は何もできませんでした...");
      } else {
        // ランダムに選択
        int playIndex =
            playableIndices[Random().nextInt(playableIndices.length)];
        CardModel card = cpu.hand[playIndex];

        // ターゲット決定
        int targetType = CardEffect.requiresTarget(card);
        Player? target;
        int? secondaryIndex; // 交換や解除で使う「2つ目の選択」

        if (targetType != 0) {
          List<Player> targets = getValidTargets(card, targetType);
          if (targets.isNotEmpty) {
            target = targets[Random().nextInt(targets.length)];
          }
        }

        // 「交換(ID:7)」の場合、渡すカード(secondaryIndex)を選ぶ必要がある
        if (card.id == 7) {
          // 適当に一番左のカードを渡す（プレイするカード自体はこの後消えるので、それ以外のインデックス）
          // 簡易的に 0番目とするが、playIndexと同じならずらす
          secondaryIndex = 0;
          if (playIndex == 0 && cpu.hand.length > 1) secondaryIndex = 1;
        }

        // カード効果発動
        // 先にプレイするカードを手札から消す（CardEffect内で消すカード以外）
        // effectSwap(交換)などは内部でremoveAtしていないようなのでここで消す
        // effectDisarm(解除)などはCardEffect内で処理される

        bool handledInternal = (card.id == 9); // ID9は特殊処理

        if (!handledInternal) {
          cpu.hand.removeAt(playIndex);
          // 交換の場合、secondaryIndexがずれる可能性があるので補正が必要だが、
          // 今回はCPUなので厳密でなくてもエラー落ちしなければOK
          if (secondaryIndex != null && secondaryIndex > playIndex)
            secondaryIndex--;
        }

        addLog("${cpu.name}が ${card.name} を使用！");
        if (target != null) {
          // 対象がいる場合
          CardEffect.applyEffect(deck, card, cpu, target, this, secondaryIndex);
        } else if (targetType == 0) {
          // 対象不要の場合（回避など）
          CardEffect.applyEffect(deck, card, cpu, null, this, null);
        } else {
          addLog("しかし対象がいなかった！");
        }
      }
    }

    notifyListeners();
    nextTurn();
  }
}
