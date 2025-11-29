import 'package:flutter/material.dart';
import '../models/Player.dart';
import '../models/Deck.dart';
import '../models/CardModel.dart';

class GameState extends ChangeNotifier {
  List<Player> players;
  int currentPlayerIndex = 0;
  bool gameOver = false;
  List<Player> defeatedPlayers = [];

  String lastLog = "ゲーム開始";

  GameState(this.players);

  Player get currentPlayer => players[currentPlayerIndex];

  List<Player> get allPlayers => players;

  Player getPlayer(int index) => players[index];

  void addLog(String message) {
    lastLog = message;
    notifyListeners(); //画面更新
  }

  List<Player> getValidTargets(CardModel card, int cardtype) {
    if (cardtype == 1) {
      return players.where((p) => !p.isEvade && p != currentPlayer).toList();
    } else {
      //自分も対象にとれる効果
      return players.where((p) => !p.isEvade).toList();
    }
  }

  void startTurn(Deck deck) {
    currentPlayer.ResetEvade(); //
    deck.drawCardForPlayer(currentPlayer);
    addLog("${currentPlayer.name}のターンです");
    checkHandBombOver(deck);

    if (deck.isEmpty()) {
      gameOver = true;
      addLog("山札がなくなりました！ゲーム終了！");
      notifyListeners();
    }
  }

  void nextTurn(Deck deck) {
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
    print("現在のターンプレイヤー: P${currentPlayerIndex + 1}");
    startTurn(deck);
  }

  void checkHandBombOver(Deck deck) {
    //bool ischecked = false;
    if (currentPlayer.countBombs() >= 3) {
      addLog("${currentPlayer.name} は爆弾を3枚持って敗北！");

      playerDefeated(currentPlayer);

      if (!gameOver) {
        // インデックス調整済みなので、そのまま次の人のターンへ
        // ただし、playerDefeated内でインデックスがずれている可能性があるので注意
        // シンプルに再開
        startTurn(deck);
      }
    } else {
      notifyListeners();
    }
  }

  void playerDefeated(Player player) {
    int defeatedIndex = players.indexOf(player);
    defeatedPlayers.add(players.removeAt(defeatedIndex));

    if (players.length == 1) {
      gameOver = true;
      addLog("勝者が決定しました！: ${players.first.name}");
    } else {
      
      if (defeatedIndex < currentPlayerIndex) {
        currentPlayerIndex--;
      }
      
      currentPlayerIndex = currentPlayerIndex % players.length;
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
}
