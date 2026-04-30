import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:gun_arena_io/game/components/map_component.dart';
import 'package:gun_arena_io/game/components/obstacle_component.dart';
import 'package:gun_arena_io/game/models/weapon_config.dart';
import 'package:gun_arena_io/game/rendering/hp_bar_renderer.dart';
import 'package:gun_arena_io/game/rendering/tank_renderer.dart';

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

  int _attackCounter = 0;
  int get attackCounter => _attackCounter;

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
    await addAll([TankRenderer(), HpBarRenderer()]);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!alive) return;

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

    if (!moveDirection.isZero()) {
      final Vector2 normalized = moveDirection.normalized();
      facingDirection.setFrom(normalized);
      final Vector2 movement = normalized * playerSpeed * dt;
      final Vector2 newPos = position + movement;
      newPos.x = newPos.x.clamp(playerRadius, MapComponent.mapWidth - playerRadius);
      newPos.y = newPos.y.clamp(playerRadius, MapComponent.mapHeight - playerRadius);
      position.setFrom(newPos);
    }
  }

  void triggerAttack() {
    _attackCounter++;
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
