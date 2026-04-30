import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:gun_arena_io/game/components/impact_component.dart';
import 'package:gun_arena_io/game/components/map_component.dart';
import 'package:gun_arena_io/game/components/obstacle_component.dart';
import 'package:gun_arena_io/game/components/player_component.dart';
import 'package:gun_arena_io/game/gun_arena_game.dart';
import 'package:gun_arena_io/game/models/weapon_config.dart';
import 'package:gun_arena_io/game/svg_sprites.dart';

class BulletComponent extends PositionComponent with CollisionCallbacks {
  static const double bulletRadius = 3.0;
  static const double visualSize = 28.0;
  static const double frameDuration = 0.05;

  final String ownerId;
  final Vector2 direction;
  final double speed;
  final int damage;
  final double maxRange;
  double traveledDistance = 0;
  double _animClock = 0;

  BulletComponent({
    required this.ownerId,
    required Vector2 position,
    required this.direction,
    double? speed,
    int? damage,
    double? maxRange,
  })  : speed = speed ?? WeaponConfig.ar.bulletSpeed,
        damage = damage ?? WeaponConfig.ar.damage,
        maxRange = maxRange ?? WeaponConfig.ar.range,
        super(
          position: position,
          size: Vector2.all(bulletRadius * 2),
          anchor: Anchor.center,
        ) {
    angle = atan2(direction.y, direction.x) + pi / 2;
  }

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animClock += dt;
    final Vector2 movement = direction * speed * dt;
    position.add(movement);
    traveledDistance += movement.length;

    if (traveledDistance >= maxRange ||
        position.x < 0 ||
        position.x > MapComponent.mapWidth ||
        position.y < 0 ||
        position.y > MapComponent.mapHeight) {
      _spawnImpact();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final int idx = (_animClock / frameDuration).floor() %
        SvgSprites.bulletKeyList.length;
    final Image img = SvgSprites.image(SvgSprites.bulletKeyList[idx]);

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
    canvas.drawImageRect(img, srcRect, dstRect, Paint());
  }

  void _spawnImpact() {
    final ImpactComponent impact = ImpactComponent(position: position.clone());
    parent?.add(impact);
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is ObstacleComponent) {
      _spawnImpact();
      removeFromParent();
      return;
    }

    if (other is PlayerComponent &&
        other.playerId != ownerId &&
        other.alive &&
        !other.isInvincible) {
      other.takeDamage(damage);
      if (!other.alive) {
        final GunArenaGame game = findGame()! as GunArenaGame;
        game.onPlayerKill(ownerId, other.playerId);
      }
      _spawnImpact();
      removeFromParent();
    }
  }
}
