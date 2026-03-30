import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:gun_arena_io/game/components/obstacle_component.dart';
import 'package:gun_arena_io/game/models/weapon_config.dart';

class PlayerComponent extends PositionComponent with CollisionCallbacks {
  static const double playerSpeed = 200.0;
  static const double playerRadius = 16.0;
  static const int maxHp = 100;

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

    if (!alive) return;

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

    // Movement
    if (!moveDirection.isZero()) {
      final Vector2 normalized = moveDirection.normalized();
      facingDirection.setFrom(normalized);
      final Vector2 movement = normalized * playerSpeed * dt;
      final Vector2 newPos = position + movement;

      newPos.x = newPos.x.clamp(playerRadius, 1024.0 - playerRadius);
      newPos.y = newPos.y.clamp(playerRadius, 1024.0 - playerRadius);

      position.setFrom(newPos);
    }
  }

  @override
  void render(Canvas canvas) {
    if (!alive) return;

    final Paint bodyPaint = Paint()
      ..color = isInvincible
          ? color.withValues(alpha: (invincibleTimer * 5 % 1 > 0.5 ? 0.3 : 0.8))
          : color;

    canvas.drawCircle(
      Offset(playerRadius, playerRadius),
      playerRadius,
      bodyPaint,
    );

    // Direction indicator
    final Paint dirPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final Offset center = Offset(playerRadius, playerRadius);
    final Offset dirEnd = center +
        Offset(facingDirection.x, facingDirection.y) * playerRadius * 0.8;
    canvas.drawLine(center, dirEnd, dirPaint);

    // HP bar
    final double hpBarWidth = playerRadius * 2;
    final double hpPercent = hp / maxHp;
    final double hpBarY = -8.0;

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
    alive = false;
    deaths++;
  }

  void respawn(Vector2 pos) {
    position.setFrom(pos);
    hp = maxHp;
    alive = true;
    ammo = WeaponConfig.ar.magazineSize;
    isReloading = false;
    isInvincible = true;
    invincibleTimer = 2.0;
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
