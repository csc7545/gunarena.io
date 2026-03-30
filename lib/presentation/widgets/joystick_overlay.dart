import 'package:flutter/material.dart';
import 'package:gun_arena_io/game/gun_arena_game.dart';

class JoystickOverlay extends StatefulWidget {
  final GunArenaGame game;
  const JoystickOverlay({super.key, required this.game});

  @override
  State<JoystickOverlay> createState() => _JoystickOverlayState();
}

class _JoystickOverlayState extends State<JoystickOverlay> {
  Offset _knobOffset = Offset.zero;
  bool _isDragging = false;
  static const double _baseRadius = 60.0;
  static const double _knobRadius = 25.0;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 30,
      bottom: 30,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: SizedBox(
          width: _baseRadius * 2,
          height: _baseRadius * 2,
          child: CustomPaint(
            painter: _JoystickPainter(
              knobOffset: _knobOffset,
              baseRadius: _baseRadius,
              knobRadius: _knobRadius,
              isDragging: _isDragging,
            ),
          ),
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    _isDragging = true;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final Offset center = const Offset(_baseRadius, _baseRadius);
    Offset delta = details.localPosition - center;
    final double distance = delta.distance;
    if (distance > _baseRadius) {
      delta = delta / distance * _baseRadius;
    }
    setState(() {
      _knobOffset = delta;
    });
    widget.game.onJoystickMove(delta.dx / _baseRadius, delta.dy / _baseRadius);
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _knobOffset = Offset.zero;
      _isDragging = false;
    });
    widget.game.onJoystickMove(0, 0);
  }
}

class _JoystickPainter extends CustomPainter {
  final Offset knobOffset;
  final double baseRadius;
  final double knobRadius;
  final bool isDragging;

  _JoystickPainter({
    required this.knobOffset,
    required this.baseRadius,
    required this.knobRadius,
    required this.isDragging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(baseRadius, baseRadius);

    canvas.drawCircle(
      center,
      baseRadius,
      Paint()..color = const Color(0x44FFFFFF),
    );
    canvas.drawCircle(
      center,
      baseRadius,
      Paint()
        ..color = const Color(0x66FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    canvas.drawCircle(
      center + knobOffset,
      knobRadius,
      Paint()..color = Color(isDragging ? 0xAAFFFFFF : 0x88FFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant _JoystickPainter oldDelegate) =>
      oldDelegate.knobOffset != knobOffset || oldDelegate.isDragging != isDragging;
}
