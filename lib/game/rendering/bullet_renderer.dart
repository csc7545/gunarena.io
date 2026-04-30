import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:gun_arena_io/game/components/bullet_component.dart';
import 'package:gun_arena_io/game/rendering/animation_clip.dart';
import 'package:gun_arena_io/game/rendering/animator.dart';
import 'package:gun_arena_io/game/svg_sprites.dart';

class BulletRenderer extends PositionComponent {
  static const double visualSize = 28.0;

  static final AnimationClip _clip = AnimationClip(
    keys: SvgSprites.bulletKeyList,
    frameDuration: 0.05,
    loop: true,
  );
  static final Paint _paint = Paint();
  static final Rect _srcRect = Rect.fromLTWH(
    0,
    0,
    SvgSprites.bulletPx.toDouble(),
    SvgSprites.bulletPx.toDouble(),
  );
  static final Rect _dstRect =
      Rect.fromLTWH(0, 0, visualSize, visualSize);

  final Animator _animator = Animator()..play(_clip);

  BulletRenderer()
      : super(
          size: Vector2.all(visualSize),
          anchor: Anchor.center,
        );

  BulletComponent get _bullet => parent as BulletComponent;

  @override
  Future<void> onLoad() async {
    position = _bullet.size / 2;
    angle = atan2(_bullet.direction.y, _bullet.direction.x) + pi / 2;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animator.tick(dt);
  }

  @override
  void render(Canvas canvas) {
    final Image? img = _animator.frame;
    if (img == null) return;
    canvas.drawImageRect(img, _srcRect, _dstRect, _paint);
  }
}
