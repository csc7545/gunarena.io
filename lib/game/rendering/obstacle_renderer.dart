import 'dart:ui';

import 'package:flame/components.dart';
import 'package:gun_arena_io/game/components/obstacle_component.dart';
import 'package:gun_arena_io/game/svg_sprites.dart';

class ObstacleRenderer extends Component {
  static final Paint _paint = Paint();

  late final Image _image;
  late final Rect _srcRect;
  late final Rect _dstRect;

  ObstacleComponent get _obstacle => parent as ObstacleComponent;

  @override
  Future<void> onLoad() async {
    _image = SvgSprites.image(_obstacle.spriteKey);
    _srcRect = Rect.fromLTWH(
      0,
      0,
      _image.width.toDouble(),
      _image.height.toDouble(),
    );
    _dstRect = Rect.fromLTWH(0, 0, _obstacle.size.x, _obstacle.size.y);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawImageRect(_image, _srcRect, _dstRect, _paint);
  }
}
