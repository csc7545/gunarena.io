import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:gun_arena_io/game/svg_sprites.dart';

class ObstacleComponent extends PositionComponent with CollisionCallbacks {
  final String spriteKey;

  ObstacleComponent({
    required Vector2 position,
    required Vector2 size,
    required this.spriteKey,
  }) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    final Image img = SvgSprites.image(spriteKey);
    final Rect srcRect = Rect.fromLTWH(
      0,
      0,
      img.width.toDouble(),
      img.height.toDouble(),
    );
    final Rect dstRect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawImageRect(img, srcRect, dstRect, Paint());
  }
}
