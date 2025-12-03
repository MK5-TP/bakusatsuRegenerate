import 'GameState.dart';
import '../models/CardModel.dart';
import '../models/Player.dart';
import "../models/Deck.dart";
import 'dart:math';

//カードの関数メソッドがいっぱいあるクラス
class CardEffect {
  static int requiresTarget(CardModel card) {
    int id = card.id;
    if (id == 4 || id == 5 || id == 6 || id == 7) {
      //いずれかの相手を選択するカード
      return 1;
    } else if (id == 9) {
      // 任意のプレイヤー（自分も可）を選択するカード
      return 2;
    } else {
      return 0; //選択なしで発動するカード
    }
  }

  static bool applyEffect(Deck deck, CardModel card, Player currentPlayer,
      Player? targetPlayer, GameState gameState, int? selectedCardIndex) {
    switch (card.id) {
      case 1:
        effectBombA();
        return false;
      case 2:
        effectBombB();
        return false;
      case 3:
        effectBombC();
        return false;
      case 4:
        if (targetPlayer != null) {
          effectDetonate(targetPlayer, gameState);
        } else {
          print("対象をとれる相手がいなかった...");
        }
        return true;
      case 5:
        if (targetPlayer != null) {
          effectDrop(currentPlayer, targetPlayer, gameState);
        } else {
          print("対象をとれる相手がいなかった...");
        }
        return true;
      case 6:
        if (targetPlayer != null) {
          effectVision(currentPlayer, targetPlayer, gameState);
        } else {
          print("対象をとれる相手がいなかった...");
        }
        return true;
      case 7:
        if (targetPlayer != null) {
          effectSwap(currentPlayer, targetPlayer, selectedCardIndex!,gameState);
        } else {
          print("対象をとれる相手がいなかった...");
        }
        return true;
      case 8:
        effectEvade(currentPlayer);
        return true;
      case 9:
        if (targetPlayer != null) {
          effectDisarm(deck, targetPlayer, selectedCardIndex);
        } else {
          print("対象をとれる相手がいなかった...");
        }
        return true;
      default:
        print("何それしらん");
        return false;
    }
  }

  static void effectBombA() {
    // TODO: 爆弾Aの処理
    print("このカードはプレイできません！");
  }

  static void effectBombB() {
    // TODO: 爆弾Bの処理
    print("このカードはプレイできません！");
  }

  static void effectBombC() {
    // TODO: 爆弾Cの処理
    print("このカードはプレイできません！");
  }

  static void effectDetonate(Player targetPlayer, GameState gameState) {
    //回避チェック
    if (targetPlayer.isEvade) {
      gameState.addLog("🛡️ ${targetPlayer.name} は回避中で効果を受けなかった！");
      return; // 何もせず終了
    }

    // TODO: 起爆の処理
    if (targetPlayer.hand.isEmpty) return;

    int randomIndex = Random().nextInt(targetPlayer.hand.length);
    CardModel selectedCard = targetPlayer.hand[randomIndex];

    print("${targetPlayer.name} のカードを選択: ${selectedCard.name}");

    if (selectedCard.id == 1 || selectedCard.id == 2 || selectedCard.id == 3) {
      print("${targetPlayer.name} の爆弾が起爆！ザマァァァアアア！！！！");
      gameState.playerDefeated(targetPlayer);
    } else {
      print("${targetPlayer.name} は無事だった！");
    }
  }

  static void effectDrop(
      Player currentPlayer, Player targetPlayer, GameState gameState) {
    //回避チェック
    if (targetPlayer.isEvade) {
      gameState.addLog("🛡️ ${targetPlayer.name} は回避中で効果を受けなかった！");
      return;
    }
    // TODO: 投下の処理

    int currentPlayerBombPower = currentPlayer.getBombPower(); // 爆弾の合計値を取得
    int targetPlayerBombPower = targetPlayer.getBombPower();
    print(
        "${currentPlayer.name}の手札${currentPlayer.hand}（値:$currentPlayerBombPower） VS ${targetPlayer.name}の手札${targetPlayer.hand}（値:$targetPlayerBombPower）");

    if (currentPlayerBombPower < targetPlayerBombPower) {
      gameState.playerDefeated(currentPlayer);
    } else if (currentPlayerBombPower > targetPlayerBombPower) {
      gameState.playerDefeated(targetPlayer);
    } else {
      print("合計値は同じだったか．．．");
    }
  }

  static void effectVision(
      Player currentPlayer, Player targetPlayer, GameState gameState) {
    // 回避チェック
    if (targetPlayer.isEvade) {
      gameState.addLog("🛡️ ${targetPlayer.name} は回避中で中身が見えない！");
      return;
    }

    if (!currentPlayer.isCpu) {
      String handContent =
          targetPlayer.hand.map((c) => "【${c.name}】").join(" ");
      gameState.addLog("👁 透視結果: ${targetPlayer.name}の手札は $handContent です");
    } else {
      // CPUが使った場合：ログには事実だけ表示し、中身は隠す
      gameState
          .addLog("👁 ${currentPlayer.name} は ${targetPlayer.name} の手札を透視した！");
    }
  }

  static void effectSwap(Player currentPlayer, Player targetPlayer,
      int selectedCardIndex, GameState gameState) {
    if (targetPlayer.isEvade) {
      gameState.addLog("🛡️ ${targetPlayer.name} は回避中で効果を受けなかった！");
      return;
    }
    // TODO: 交換の処理
    CardModel MyPassedCard =
        currentPlayer.hand.removeAt(selectedCardIndex); //相手に渡すカード
    int randomIndex = Random().nextInt(targetPlayer.hand.length);
    CardModel targetCard =
        targetPlayer.hand.removeAt(randomIndex); //相手のカードを見ずに(ランダムに)選択

    //交換
    currentPlayer.hand.add(targetCard);
    print("${currentPlayer.name}の手札");
    for (var card in currentPlayer.hand) {
      print("🔍 ${card.name}");
    }

    targetPlayer.hand.add(MyPassedCard);
    print("${targetPlayer.name}の手札");
    for (var card in targetPlayer.hand) {
      print("🔍 ${card.name}");
    }
  }

  static void effectEvade(Player player) {
    // TODO: 回避の処理
    player.applyEscape();
  }

  static void effectDisarm(
      Deck deck, Player targetPlayer, int? selectedCardIndex) {
    // TODO: 解除の処理
    if (selectedCardIndex != null) {
      //選択したカードがある→自分に効果を使った
      CardModel removedMyCard = targetPlayer.hand.removeAt(selectedCardIndex);
      deck.returnCard(removedMyCard);
      print("${targetPlayer.name}は，${removedMyCard.name}を山札に戻した！");
    } else {
      //選択したカードがない→自分以外に使った．ランダムで戻すカード選択
      int randomIndex = Random().nextInt(targetPlayer.hand.length);
      CardModel targetCard = targetPlayer.hand.removeAt(randomIndex);
      deck.returnCard(targetCard);
      print("${targetPlayer.name}は，${targetCard.name}を山札に戻した！");
    }
    deck.drawCardForPlayer(targetPlayer);
  }
}
