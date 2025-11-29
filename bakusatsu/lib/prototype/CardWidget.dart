import 'package:flutter/material.dart';
import 'CardModel.dart';

class CardWidgetFront extends StatelessWidget {
  final CardModel card;
  CardWidgetFront(this.card);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        card.name,
        style: TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }
}

