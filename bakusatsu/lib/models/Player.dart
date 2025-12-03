import 'CardModel.dart';

class Player {
  String name;
  bool isCpu;
  List<CardModel> hand;
  bool isEvade = false;
  bool isDead = false;

  Player(this.name,{this.isCpu = false}) : hand = [];

  //プレイヤーが所持している爆弾の数を数える（3個以上持ってたら死）
  int countBombs() {
    return hand.where((card) => card.id == 1 || card.id == 2 || card.id == 3).length;
  }

  int getBombPower(){
    int power = 0;
    for(var card in hand){
      if(card.id == 1){
        power += 5;
      }else if(card.id == 2){
        power += 3;
      }else if(card.id == 3){
        power += 1;
      }
    }
    return power;
  }
  
  void applyEscape() {
    isEvade = true;
    print("$name は1ターンの間回避状態になった！");
  }
  void ResetEvade() {
    isEvade = false; // ターン開始時に回避解除
  }

  void reset() {
    hand.clear();
    isEvade = false;
    isDead = false;
  }

}


