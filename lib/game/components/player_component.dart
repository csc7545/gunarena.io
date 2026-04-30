import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:gun_arena_io/game/components/map_component.dart';
import 'package:gun_arena_io/game/components/obstacle_component.dart';
import 'package:gun_arena_io/game/models/weapon_config.dart';
import 'package:gun_arena_io/game/svg_sprites.dart';

class PlayerComponent extends PositionComponent with CollisionCallbacks {
  static const double playerSpeed = 200.0;
  static const double playerRadius = 16.0;
  static const double visualSize = 56.0;
  static const int maxHp = 100;

  static const double idleFrameDuration = 0.4;
  static const double attackFrameDuration = 0.04;
  static const double dieFrameDuration = 0.2;

  static final Rect _spriteSrcRect = Rect.fromLTWH(
    0,
    0,
    SvgSprites.tankPx.toDouble(),
    SvgSprites.tankPx.toDouble(),
  );

  static final Paint _hpBgPaint = Paint()..color = const Color(0xFF333333);
  static final Paint _hpGreenPaint = Paint()..color = const Color(0xFF4CAF50);
  static final Paint _hpYellowPaint = Paint()..color = const Color(0xFFFFC107);
  static final Paint _hpRedPaint = Paint()..color = const Color(0xFFF44336);

  final String playerId;
  final Color color;

  int hp = maxHp;
  bool alive = true;
  int kills = 0;
  int deaths = 0;
  int ammo = WeaponConfig.ar.magazineSize;
  bool isReloading = false;
  double reloadTimer = 0;
  double invincibleTimer = 0;
  bool isInvincible = false;

  Vector2 moveDirection = Vector2.zero();
  Vector2 facingDirection = Vector2(1, 0);

  double _idleClock = 0;
  double _attackElapsed = 0;
  bool _isAttacking = false;
  double _dieElapsed = 0;

  late final Paint _basePaint;
  late final Rect _spriteDstRect;

  PlayerComponent({
    required this.playerId,
    required Vector2 position,
    this.color = const Color(0xFF4CAF50),
  }) : super(
          position: position,
          size: Vector2.all(playerRadius * 2),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
    _basePaint = Paint()
      ..colorFilter = ColorFilter.mode(color, BlendMode.modulate);
    _spriteDstRect = Rect.fromCenter(
      center: Offset(size.x / 2, size.y / 2),
      width: visualSize,
      height: visualSize,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!alive) {
      _dieElapsed = (_dieElapsed + dt).clamp(
        0.0,
        dieFrameDuration * SvgSprites.tankDieKeyList.length - 0.001,
      );
      return;
    }

    if (isInvincible) {
      invincibleTimer -= dt;
      if (invincibleTimer <= 0) {
        isInvincible = false;
      }
    }

    if (isReloading) {
      reloadTimer -= dt;
      if (reloadTimer <= 0) {
        isReloading = false;
        ammo = WeaponConfig.ar.magazineSize;
      }
    }

    if (_isAttacking) {
      _attackElapsed += dt;
      if (_attackElapsed >=
          attackFrameDuration * SvgSprites.tankAttackKeyList.length) {
        _isAttacking = false;
      }
    } else {
      _idleClock += dt;
    }

    if (!moveDirection.isZero()) {
      final Vector2 normalized = moveDirection.normalized();
      facingDirection.setFrom(normalized);
      final Vector2 movement = normalized * playerSpeed * dt;
      final Vector2 newPos = position + movement;

      newPos.x = newPos.x.clamp(playerRadius, MapComponent.mapWidth - playerRadius);
      newPos.y = newPos.y.clamp(playerRadius, MapComponent.mapHeight - playerRadius);

      position.setFrom(newPos);
    }

    // SVG tank faces -y; default Flame angle 0 leaves it pointing up.
    // Add pi/2 so facing (1,0) rotates the barrel to +x.
    angle = atan2(facingDirection.y, facingDirection.x) + pi / 2;
  }

  @override
  void render(Canvas canvas) {
    final Image img = _currentSpriteImage();
    final Paint paint;
    if (isInvincible) {
      final double alpha = invincibleTimer * 5 % 1 > 0.5 ? 0.3 : 0.8;
      paint = Paint()
        ..colorFilter = ColorFilter.mode(
          color.withValues(alpha: alpha),
          BlendMode.modulate,
        );
    } else {
      paint = _basePaint;
    }
    canvas.drawImageRect(img, _spriteSrcRect, _spriteDstRect, paint);

    if (!alive) return;

    final double hpBarWidth = playerRadius * 2;
    final double hpPercent = hp / maxHp;
    const double hpBarY = -8.0;

    // Counter-rotate so the HP bar stays screen-aligned regardless of facing.
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(-angle);
    canvas.translate(-hpBarWidth / 2, -size.y / 2);
    canvas.drawRect(
      Rect.fromLTWH(0, hpBarY, hpBarWidth, 4),
      _hpBgPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, hpBarY, hpBarWidth * hpPercent, 4),
      _hpFillPaint(hpPercent),
    );
    canvas.restore();
  }

  static Paint _hpFillPaint(double pct) {
    if (pct > 0.5) return _hpGreenPaint;
    if (pct > 0.25) return _hpYellowPaint;
    return _hpRedPaint;
  }

  Image _currentSpriteImage() {
    if (!alive) {
      return SvgSprites.frameAt(
        SvgSprites.tankDieKeyList,
        _dieElapsed,
        dieFrameDuration,
      );
    }
    if (_isAttacking) {
      return SvgSprites.frameAt(
        SvgSprites.tankAttackKeyList,
        _attackElapsed,
        attackFrameDuration,
      );
    }
    return SvgSprites.frameAt(
      SvgSprites.tankIdleKeyList,
      _idleClock,
      idleFrameDuration,
      loop: true,
    );
  }

  void triggerAttack() {
    _isAttacking = true;
    _attackElapsed = 0;
  }

  void takeDamage(int damage) {
    if (!alive || isInvincible) return;
    hp -= damage;
    if (hp <= 0) {
      hp = 0;
      die();
    }
  }

  void die() {
    if (!alive) return;
    alive = false;
    deaths++;
    _dieElapsed = 0;
    _isAttacking = false;
  }

  void respawn(Vector2 pos) {
    position.setFrom(pos);
    hp = maxHp;
    alive = true;
    ammo = WeaponConfig.ar.magazineSize;
    isReloading = false;
    isInvincible = true;
    invincibleTimer = 2.0;
    _isAttacking = false;
    _attackElapsed = 0;
    _dieElapsed = 0;
  }

  void startReload() {
    if (isReloading || ammo == WeaponConfig.ar.magazineSize) return;
    isReloading = true;
    reloadTimer = WeaponConfig.ar.reloadTime;
  }

  bool canShoot() {
    return alive && !isReloading && ammo > 0;
  }

  void consumeAmmo() {
    ammo--;
    if (ammo <= 0) {
      startReload();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is ObstacleComponent) {
      _resolveObstacleCollision(other);
    }
  }

  void _resolveObstacleCollision(ObstacleComponent obstacle) {
    final Vector2 playerCenter = position;
    final Vector2 obstacleCenter = obstacle.position + obstacle.size / 2;

    final double halfW = obstacle.size.x / 2;
    final double halfH = obstacle.size.y / 2;

    final double dx = playerCenter.x - obstacleCenter.x;
    final double dy = playerCenter.y - obstacleCenter.y;

    final double closestX = dx.clamp(-halfW, halfW);
    final double closestY = dy.clamp(-halfH, halfH);

    final double distX = dx - closestX;
    final double distY = dy - closestY;

    final Vector2 pushVec = Vector2(distX, distY);
    final double dist = pushVec.length;

    if (dist < playerRadius && dist > 0) {
      final Vector2 pushDir = pushVec.normalized();
      final double overlap = playerRadius - dist;
      position.add(pushDir * (overlap + 0.5));
    }
  }
}
