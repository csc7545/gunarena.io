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
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!alive) {
      _dieElapsed = (_dieElapsed + dt)
          .clamp(0.0, dieFrameDuration * SvgSprites.tankDieKeyList.length - 0.001);
      return;
    }

    // Invincibility timer
    if (isInvincible) {
      invincibleTimer -= dt;
      if (invincibleTimer <= 0) {
        isInvincible = false;
      }
    }

    // Reload timer
    if (isReloading) {
      reloadTimer -= dt;
      if (reloadTimer <= 0) {
        isReloading = false;
        ammo = WeaponConfig.ar.magazineSize;
      }
    }

    // Animation clocks
    if (_isAttacking) {
      _attackElapsed += dt;
      if (_attackElapsed >=
          attackFrameDuration * SvgSprites.tankAttackKeyList.length) {
        _isAttacking = false;
      }
    } else {
      _idleClock += dt;
    }

    // Movement
    if (!moveDirection.isZero()) {
      final Vector2 normalized = moveDirection.normalized();
      facingDirection.setFrom(normalized);
      final Vector2 movement = normalized * playerSpeed * dt;
      final Vector2 newPos = position + movement;

      newPos.x = newPos.x.clamp(playerRadius, MapComponent.mapWidth - playerRadius);
      newPos.y = newPos.y.clamp(playerRadius, MapComponent.mapHeight - playerRadius);

      position.setFrom(newPos);
    }

    // Sync sprite rotation to facing direction.
    // SVG tank faces -y (up). Default Flame angle 0 = unrotated SVG.
    // facing (1,0) → angle = pi/2 (rotate so barrel points +x).
    angle = atan2(facingDirection.y, facingDirection.x) + pi / 2;
  }

  @override
  void render(Canvas canvas) {
    final String key = _currentSpriteKey();
    final Image img = SvgSprites.image(key);

    final double alpha = isInvincible
        ? (invincibleTimer * 5 % 1 > 0.5 ? 0.3 : 0.8)
        : 1.0;

    final Paint paint = Paint()
      ..colorFilter = ColorFilter.mode(
        color.withValues(alpha: alpha),
        BlendMode.modulate,
      );

    final Rect srcRect = Rect.fromLTWH(
      0,
      0,
      img.width.toDouble(),
      img.height.toDouble(),
    );
    final Rect dstRect = Rect.fromCenter(
      center: Offset(size.x / 2, size.y / 2),
      width: visualSize,
      height: visualSize,
    );
    canvas.drawImageRect(img, srcRect, dstRect, paint);

    if (!alive) return;

    // HP bar (drawn unrotated by reversing parent rotation locally is complex;
    // for top-down feel we render in component-local space — bar will rotate.
    // Acceptable for this prototype; can be moved to a HUD overlay later.)
    final double hpBarWidth = playerRadius * 2;
    final double hpPercent = hp / maxHp;
    final double hpBarY = -8.0;

    canvas.save();
    // Counter-rotate so the HP bar stays screen-aligned regardless of facing.
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(-angle);
    canvas.translate(-hpBarWidth / 2, -size.y / 2);

    canvas.drawRect(
      Rect.fromLTWH(0, hpBarY, hpBarWidth, 4),
      Paint()..color = const Color(0xFF333333),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, hpBarY, hpBarWidth * hpPercent, 4),
      Paint()
        ..color = hpPercent > 0.5
            ? const Color(0xFF4CAF50)
            : hpPercent > 0.25
                ? const Color(0xFFFFC107)
                : const Color(0xFFF44336),
    );
    canvas.restore();
  }

  String _currentSpriteKey() {
    if (!alive) {
      final int idx = (_dieElapsed / dieFrameDuration)
          .floor()
          .clamp(0, SvgSprites.tankDieKeyList.length - 1);
      return SvgSprites.tankDieKeyList[idx];
    }
    if (_isAttacking) {
      final int idx = (_attackElapsed / attackFrameDuration)
          .floor()
          .clamp(0, SvgSprites.tankAttackKeyList.length - 1);
      return SvgSprites.tankAttackKeyList[idx];
    }
    final int idx = (_idleClock / idleFrameDuration).floor() %
        SvgSprites.tankIdleKeyList.length;
    return SvgSprites.tankIdleKeyList[idx];
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
