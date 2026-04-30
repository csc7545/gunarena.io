import 'dart:ui';

import 'package:flame/components.dart';
import 'package:gun_arena_io/game/components/player_component.dart';

class HpBarRenderer extends Component {
  static const double width = PlayerComponent.playerRadius * 2;
  static const double height = 4.0;
  static const double yOffset = -8.0;

  static final Paint _bgPaint = Paint()..color = const Color(0xFF333333);
  static final Paint _greenPaint = Paint()..color = const Color(0xFF4CAF50);
  static final Paint _yellowPaint = Paint()..color = const Color(0xFFFFC107);
  static final Paint _redPaint = Paint()..color = const Color(0xFFF44336);

  PlayerComponent get _player => parent as PlayerComponent;

  @override
  void render(Canvas canvas) {
    if (!_player.alive) return;

    final double hpPercent = _player.hp / PlayerComponent.maxHp;
    final double x = (_player.size.x - width) / 2;

    canvas.drawRect(Rect.fromLTWH(x, yOffset, width, height), _bgPaint);
    canvas.drawRect(
      Rect.fromLTWH(x, yOffset, width * hpPercent, height),
      _fillPaint(hpPercent),
    );
  }

  static Paint _fillPaint(double pct) {
    if (pct > 0.5) return _greenPaint;
    if (pct > 0.25) return _yellowPaint;
    return _redPaint;
  }
}
