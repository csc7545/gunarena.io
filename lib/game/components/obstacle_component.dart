import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:gun_arena_io/game/svg_sprites.dart';

class ObstacleComponent extends PositionComponent with CollisionCallbacks {
  static final Paint _paint = Paint();

  final String spriteKey;

  late final Image _image;
  late final Rect _srcRect;
  late final Rect _dstRect;

  ObstacleComponent({
    required Vector2 position,
    required Vector2 size,
    required this.spriteKey,
  }) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
    _image = SvgSprites.image(spriteKey);
    _srcRect = Rect.fromLTWH(
      0,
      0,
      _image.width.toDouble(),
      _image.height.toDouble(),
    );
    _dstRect = Rect.fromLTWH(0, 0, size.x, size.y);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawImageRect(_image, _srcRect, _dstRect, _paint);
  }
}
