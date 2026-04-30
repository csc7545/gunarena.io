import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:gun_arena_io/game/rendering/obstacle_renderer.dart';

class ObstacleComponent extends PositionComponent with CollisionCallbacks {
  final String spriteKey;

  ObstacleComponent({
    required Vector2 position,
    required Vector2 size,
    required this.spriteKey,
  }) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
    await add(ObstacleRenderer());
  }
}
