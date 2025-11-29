import 'package:flutter/material.dart';

class WinnerBanner extends StatelessWidget {
  final String winners;
  //final VoidCallback onReset;

  //const WinnerBanner({required this.winners, required this.onReset, Key? key}) : super(key: key);
  const WinnerBanner({required this.winners,  Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 100, // 画面上部に表示
      left: 20,
      right: 20,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "勝者: $winners",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
           // ElevatedButton(              onPressed: onReset,              child: Text("リスタート"),            ),
          ],
        ),
      ),
    );
  }
}
