import 'Player.dart';
import 'Deck.dart';
import 'CardModel.dart';

class GameState {
  List<Player> players;
  int currentPlayerIndex = 0;
  bool gameOver = false;
  List<Player> defeatedPlayers = [];

  GameState(this.players);

  Player get currentPlayer => players[currentPlayerIndex];

  Player getPlayer(int index) => players[index];

  List<Player> getValidTargets(CardModel card, int cardtype) {
    if (cardtype == 1) {
      return players.where((p) => !p.isEvade && p != currentPlayer).toList();
    } else {
      //自分も対象にとれる効果
      return players.where((p) => !p.isEvade).toList();
    }
  }

  void startTurn(Deck deck){
    currentPlayer.ResetEvade(); //
    deck.drawCardForPlayer(currentPlayer);
    checkHandBombOver(deck);

    if (deck.isEmpty()) gameOver = true;
  }

  void nextTurn(Deck deck) {
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
    print("現在のターンプレイヤー: P${currentPlayerIndex + 1}");
    startTurn(deck);
  }

  
  void checkHandBombOver(Deck deck) {
    //bool ischecked = false;
    if (currentPlayer.countBombs() >= 3) {
      print("${currentPlayer.name} は爆弾を3枚持って敗北！");

      defeatedPlayers
          .add(players.removeAt(currentPlayerIndex)); //敗北プレイヤーを除外し，負け組に追加
      print("${currentPlayer.name} が持っていたカード: ${currentPlayer.hand}");
      currentPlayerIndex = (currentPlayerIndex - 1) % players.length;
      print(currentPlayerIndex);

      //  残り1人ならゲーム終了
      if (players.length == 1) {
        gameOver = true;
        return;
      }
      //インデックス修正
      //currentPlayerIndex %= players.length;
      nextTurn(deck);
    }
  }

  void playerDefeated(Player player) {
    print("${player.name} は敗北！ザマァァァアアアWWWWW！！！！！");
    int defeatedIndex = players.indexOf(player);

    defeatedPlayers.add(players.removeAt(players.indexOf(player)));

    // 残り1人ならゲーム終了
    if (players.length == 1) {
      gameOver = true;
    }
    if (defeatedIndex > currentPlayerIndex) {
      currentPlayerIndex = currentPlayerIndex % players.length;
    } else if (defeatedIndex <= currentPlayerIndex) {
      currentPlayerIndex = (currentPlayerIndex - 1) % players.length;
    }
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
  List<Player> winners = sortedPlayers.where((p) => p.getBombPower() == lowestPower).toList();

  // 複数人いる場合は全員の名前を連結
  return winners.map((p) => p.name).join(" & ");
}
}
