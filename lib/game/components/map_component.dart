import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:gun_arena_io/game/components/obstacle_component.dart';
import 'package:gun_arena_io/game/svg_sprites.dart';

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

      final double aspect = width / height;
      final bool roundOk = aspect > 0.7 && aspect < 1.45;
      final List<String> options = roundOk
          ? SvgSprites.wallKeyList
          : const ['wall_concrete', 'wall_sandbag', 'wall_crate'];
      final String variant = options[random.nextInt(options.length)];

      add(ObstacleComponent(
        position: Vector2(x, y),
        size: Vector2(width, height),
        spriteKey: variant,
      ));
    }
  }

  @override
  void render(Canvas canvas) {
    // Tiled ground texture
    final Image groundImg = SvgSprites.image(SvgSprites.groundKey);
    final Float64List identity = Float64List(16)
      ..[0] = 1.0
      ..[5] = 1.0
      ..[10] = 1.0
      ..[15] = 1.0;
    final ImageShader shader = ImageShader(
      groundImg,
      TileMode.repeated,
      TileMode.repeated,
      identity,
    );
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, mapWidth, mapHeight),
      Paint()..shader = shader,
    );

    // Map border
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, mapWidth, mapHeight),
      Paint()
        ..color = const Color(0xFF555555)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }
}
