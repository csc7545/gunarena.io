import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:gun_arena_io/game/components/player_component.dart';
import 'package:gun_arena_io/game/rendering/tank_animator.dart';
import 'package:gun_arena_io/game/svg_sprites.dart';

class TankRenderer extends PositionComponent {
  static const double visualSize = 56.0;

  static final Rect _srcRect = Rect.fromLTWH(
    0,
    0,
    SvgSprites.tankPx.toDouble(),
    SvgSprites.tankPx.toDouble(),
  );
  static final Rect _dstRect =
      Rect.fromLTWH(0, 0, visualSize, visualSize);

  final TankAnimator _animator = TankAnimator();
  late final Paint _basePaint;

  TankRenderer()
      : super(
          size: Vector2.all(visualSize),
          anchor: Anchor.center,
        );

  PlayerComponent get _player => parent as PlayerComponent;

  @override
  Future<void> onLoad() async {
    position = _player.size / 2;
    _basePaint = Paint()
      ..colorFilter = ColorFilter.mode(_player.color, BlendMode.modulate);
  }

  @override
  void update(double dt) {
    super.update(dt);
    angle = atan2(_player.facingDirection.y, _player.facingDirection.x) +
        pi / 2;
    _animator.update(
      dt,
      alive: _player.alive,
      attackCounter: _player.attackCounter,
    );
  }

  @override
  void render(Canvas canvas) {
    final Image? img = _animator.frame;
    if (img == null) return;

    final Paint paint;
    if (_player.isInvincible) {
      final double alpha =
          _player.invincibleTimer * 5 % 1 > 0.5 ? 0.3 : 0.8;
      paint = Paint()
        ..colorFilter = ColorFilter.mode(
          _player.color.withValues(alpha: alpha),
          BlendMode.modulate,
        );
    } else {
      paint = _basePaint;
    }

    canvas.drawImageRect(img, _srcRect, _dstRect, paint);
  }
}
