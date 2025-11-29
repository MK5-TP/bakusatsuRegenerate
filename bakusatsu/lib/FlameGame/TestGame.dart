import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class AppGameAreaTest extends FlameGame {
  late final RectangleComponent _player;
  late final JoystickComponent _joystick;
  static const _moveSpeed = 10.0;
  

  @override
  Future<void> onLoad() async {

    super.onLoad();

    _player = RectangleComponent(
      position: Vector2(size.x * 0.5, size.y * 0.5),
      size: Vector2(100, 100),
      angle: 0.0,
      anchor: Anchor.center,
      paint: Paint()..color = const Color(0xFFffffff),
    );

    _joystick = JoystickComponent(
      // 操作ノブ
      knob: CircleComponent(
        radius: 20,
        paint: Paint()..color = const Color(0xFFffffff),
      ),
      // ノブの背景
      background: CircleComponent(
        radius: 50,
        paint: Paint()..color = const Color(0xFFffffff).withAlpha(100),
      ),
      // ノブの位置
      position: Vector2(size.x * 0.5, size.y * 0.8),
    );

    await add(_player);

    await add(_joystick);
    


    super.onLoad();
    
  }

  @override
  void update(double dt) {
    super.update(dt);

    _player.position += _joystick.delta * _moveSpeed * dt;
  }
  
}