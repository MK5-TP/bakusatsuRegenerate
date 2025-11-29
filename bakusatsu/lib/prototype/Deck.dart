import 'dart:math';
import 'CardModel.dart';
import 'Player.dart';

class Deck {
  List<CardModel> _cards = [];

  Deck() {
    _initializeDeck();
    shuffle();
  }

  void _initializeDeck() {
    _cards = [
      //爆弾Aは1枚
      CardModel(id: 1, name: "爆弾A", effect: "手札に3枚そろった時点で敗北.強さ5"),
      //爆弾Bは2枚
      CardModel(id: 2, name: "爆弾B", effect: "手札に3枚そろった時点で敗北.強さ3"),
      CardModel(id: 2, name: "爆弾B", effect: "手札に3枚そろった時点で敗北.強さ3"),
      //爆弾Cは2枚
      CardModel(id: 3, name: "爆弾C", effect: "手札に3枚そろった時点で敗北.強さ1"),
      CardModel(id: 3, name: "爆弾C", effect: "手札に3枚そろった時点で敗北.強さ1"),

      //「起爆」は3枚
      CardModel(id: 4, name: "起爆", effect: "いずれかの相手の手札を1枚ランダムに選び、それが爆弾なら相手は敗北"),
      CardModel(id: 4, name: "起爆", effect: "いずれかの相手の手札を1枚ランダムに選び、それが爆弾なら相手は敗北"),
      CardModel(id: 4, name: "起爆", effect: "いずれかの相手の手札を1枚ランダムに選び、それが爆弾なら相手は敗北"),
      //「投下」は3枚
      CardModel(
          id: 5,
          name: "投下",
          effect: "いずれかの相手プレイヤーを選択し，お互いが所持している爆弾の合計値を比較し，低い方のプレイヤーが敗北"),
      CardModel(
          id: 5,
          name: "投下",
          effect: "いずれかの相手プレイヤーを選択し，お互いが所持している爆弾の合計値を比較し，低い方のプレイヤーが敗北"),
      CardModel(
          id: 5,
          name: "投下",
          effect: "いずれかの相手プレイヤーを選択し，お互いが所持している爆弾の合計値を比較し，低い方のプレイヤーが敗北"),
      //「透視」は3枚
      CardModel(id: 6, name: "透視", effect: "いずれかの相手プレイヤーの手札をすべて見る"),
      CardModel(id: 6, name: "透視", effect: "いずれかの相手プレイヤーの手札をすべて見る"),
      CardModel(id: 6, name: "透視", effect: "いずれかの相手プレイヤーの手札をすべて見る"),
      //「交換」は2枚
      CardModel(id: 7, name: "交換", effect: "いずれかの相手プレイヤーと手札を1枚ずつ交換"),
      CardModel(id: 7, name: "交換", effect: "いずれかの相手プレイヤーと手札を1枚ずつ交換"),
      //「回避」は2枚
      CardModel(id: 8, name: "回避", effect: "次の自分の番まで，自分への効果を無効化"),
      CardModel(id: 8, name: "回避", effect: "次の自分の番まで，自分への効果を無効化"),
      
      //「解除」は2枚
      CardModel(id: 9, name: "解除", effect: "任意のプレイヤー（自分も可）は手札を1枚山札の下に戻し，1枚引く"),
      CardModel(id: 9, name: "解除", effect: "任意のプレイヤー（自分も可）は手札を1枚山札の下に戻し，1枚引く"),
    ];
  }

  void shuffle() {
    _cards.shuffle(Random());
  }

  CardModel? drawCard() {
    if (_cards.isEmpty) return null; // 山札が空ならnullを返す
    return _cards.removeAt(0);
  }

  void drawCardForPlayer(Player player) {
    CardModel? drawnCard = drawCard();
    if (drawnCard != null) {
      player.hand.add(drawnCard);
      print("${player.name}が引いたカード: ${drawnCard.name}");
    } else {
      print("山札が空です！");
    }
  }

  void returnCard(CardModel card) {
    _cards.add(card); // 山札の下にカードを戻す．
  }

  bool isEmpty() {
    if (_cards.isEmpty) {
      return true;
    } else {
      return false;
    }
  }

  int get deckSize => _cards.length;
}
