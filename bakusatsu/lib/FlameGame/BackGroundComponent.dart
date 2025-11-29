import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class BackgroundComponent extends PositionComponent {
  BackgroundComponent({required Vector2 size}) : super(size: size);
  
  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          Colors.greenAccent, // 中央（明るめの緑）
          Colors.green[800]!, // 外周（暗めの緑）
        ],
      ).createShader(rect);

    canvas.drawRect(rect, paint);
  }
}