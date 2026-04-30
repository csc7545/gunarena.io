import 'dart:ui';

import 'package:flame/components.dart';
import 'package:gun_arena_io/game/svg_sprites.dart';

class ImpactComponent extends PositionComponent {
  static const double frameDuration = 0.05;
  static const double visualSize = 36.0;

  static final Paint _paint = Paint();
  static final Rect _srcRect = Rect.fromLTWH(
    0,
    0,
    SvgSprites.impactPx.toDouble(),
    SvgSprites.impactPx.toDouble(),
  );
  static final Rect _dstRect =
      Rect.fromLTWH(0, 0, visualSize, visualSize);

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
    if (_elapsed >= frameDuration * SvgSprites.impactKeyList.length) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final Image img = SvgSprites.frameAt(
      SvgSprites.impactKeyList,
      _elapsed,
      frameDuration,
    );
    canvas.drawImageRect(img, _srcRect, _dstRect, _paint);
  }
}
