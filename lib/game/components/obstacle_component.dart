import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class ObstacleComponent extends PositionComponent with CollisionCallbacks {
  ObstacleComponent({
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      size.toRect(),
      Paint()..color = const Color(0xFF666666),
    );
    canvas.drawRect(
      size.toRect(),
      Paint()
        ..color = const Color(0xFF888888)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }
}
