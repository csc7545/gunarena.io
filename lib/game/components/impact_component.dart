import 'dart:ui';

import 'package:flame/components.dart';
import 'package:gun_arena_io/game/svg_sprites.dart';

class ImpactComponent extends PositionComponent {
  static const double frameDuration = 0.05;
  static const double visualSize = 36.0;

  double _elapsed = 0;

  ImpactComponent({required Vector2 position})
      : super(
          position: position,
          size: Vector2.all(visualSize),
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    final double total =
        frameDuration * SvgSprites.impactKeyList.length;
    if (_elapsed >= total) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final int idx = (_elapsed / frameDuration)
        .floor()
        .clamp(0, SvgSprites.impactKeyList.length - 1);
    final Image img = SvgSprites.image(SvgSprites.impactKeyList[idx]);

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
