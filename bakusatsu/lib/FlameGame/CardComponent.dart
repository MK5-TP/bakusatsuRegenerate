import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class CardComponent extends PositionComponent with TapCallbacks, DragCallbacks {
  final Vector2 originalPosition;

  CardComponent({required Vector2 position})
      : originalPosition = position.clone(),
        super(position: position, size: Vector2(59, 86), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = Colors.white,
    ));
  }

  @override
  bool onTapDown(TapDownEvent info) {
    print("カードがタップされた！");
    return true;
  }

  @override
  void onDragStart(DragStartEvent event) {
    // ドラッグ開始時の処理（任意の処理があれば記述）
    print("ドラッグ開始！");
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    // ドラッグ中は指に合わせてカードの位置を更新
    position.add(event.localDelta);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    // 指を離したら元の位置に戻す
    print("ドラッグ終了。カードを元の位置に戻す");
    position.setFrom(originalPosition);
  }

}
