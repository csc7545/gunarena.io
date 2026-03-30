import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:gun_arena_io/game/components/obstacle_component.dart';

class MapComponent extends Component {
  static const double mapSize = 1024.0;

  final int seed;
  final List<Rect> obstacleRectList = [];

  MapComponent({required this.seed});

  @override
  Future<void> onLoad() async {
    _generateObstacles();
  }

  void _generateObstacles() {
    final Random random = Random(seed);
    final int count = 20 + random.nextInt(11); // 20-30

    for (int i = 0; i < count; i++) {
      final double width = 30.0 + random.nextDouble() * 70.0; // 30-100
      final double height = 30.0 + random.nextDouble() * 70.0;
      final double x = random.nextDouble() * (mapSize - width);
      final double y = random.nextDouble() * (mapSize - height);

      final Rect rect = Rect.fromLTWH(x, y, width, height);
      obstacleRectList.add(rect);

      add(ObstacleComponent(
        position: Vector2(x, y),
        size: Vector2(width, height),
      ));
    }
  }

  @override
  void render(Canvas canvas) {
    // Map background
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, mapSize, mapSize),
      Paint()..color = const Color(0xFF2D2D2D),
    );

    // Map border
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, mapSize, mapSize),
      Paint()
        ..color = const Color(0xFF555555)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Grid lines
    final Paint gridPaint = Paint()
      ..color = const Color(0xFF3A3A3A)
      ..strokeWidth = 0.5;

    for (double i = 0; i <= mapSize; i += 64) {
      canvas.drawLine(Offset(i, 0), Offset(i, mapSize), gridPaint);
      canvas.drawLine(Offset(0, i), Offset(mapSize, i), gridPaint);
    }
  }
}
