import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:gun_arena_io/game/components/obstacle_component.dart';

class MapComponent extends Component {
  static const double mapWidth = 1920.0;
  static const double mapHeight = 1024.0;

  final int seed;
  final List<Rect> obstacleRectList = [];

  MapComponent({required this.seed});

  @override
  Future<void> onLoad() async {
    _generateObstacles();
  }

  void _generateObstacles() {
    final Random random = Random(seed);
    final int count = 35 + random.nextInt(16); // 35-50

    for (int i = 0; i < count; i++) {
      final double width = 30.0 + random.nextDouble() * 70.0; // 30-100
      final double height = 30.0 + random.nextDouble() * 70.0;
      final double x = random.nextDouble() * (mapWidth - width);
      final double y = random.nextDouble() * (mapHeight - height);

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
      const Rect.fromLTWH(0, 0, mapWidth, mapHeight),
      Paint()..color = const Color(0xFF2D2D2D),
    );

    // Map border
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, mapWidth, mapHeight),
      Paint()
        ..color = const Color(0xFF555555)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Grid lines
    final Paint gridPaint = Paint()
      ..color = const Color(0xFF3A3A3A)
      ..strokeWidth = 0.5;

    for (double x = 0; x <= mapWidth; x += 64) {
      canvas.drawLine(Offset(x, 0), Offset(x, mapHeight), gridPaint);
    }
    for (double y = 0; y <= mapHeight; y += 64) {
      canvas.drawLine(Offset(0, y), Offset(mapWidth, y), gridPaint);
    }
  }
}
