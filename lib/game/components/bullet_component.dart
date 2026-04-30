import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:gun_arena_io/game/components/impact_component.dart';
import 'package:gun_arena_io/game/components/map_component.dart';
import 'package:gun_arena_io/game/components/obstacle_component.dart';
import 'package:gun_arena_io/game/components/player_component.dart';
import 'package:gun_arena_io/game/gun_arena_game.dart';
import 'package:gun_arena_io/game/models/weapon_config.dart';
import 'package:gun_arena_io/game/rendering/bullet_renderer.dart';

class BulletComponent extends PositionComponent with CollisionCallbacks {
  static const double bulletRadius = 3.0;

  final String ownerId;
  final Vector2 direction;
  final double speed;
  final int damage;
  final double maxRange;
  double traveledDistance = 0;

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
        );

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
    await add(BulletRenderer());
  }

  @override
  void update(double dt) {
    super.update(dt);
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
