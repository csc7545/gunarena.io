import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gun_arena_io/game/gun_arena_game.dart';

class KeyBindingsOverlay extends StatefulWidget {
  final GunArenaGame game;

  const KeyBindingsOverlay({super.key, required this.game});

  @override
  State<KeyBindingsOverlay> createState() => _KeyBindingsOverlayState();
}

class _KeyBindingsOverlayState extends State<KeyBindingsOverlay> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  bool _isPressed(LogicalKeyboardKey key) {
    return widget.game.pressedKeySet.contains(key);
  }

  @override
  Widget build(BuildContext context) {
    final bool wPressed = _isPressed(LogicalKeyboardKey.keyW) ||
        _isPressed(LogicalKeyboardKey.arrowUp);
    final bool aPressed = _isPressed(LogicalKeyboardKey.keyA) ||
        _isPressed(LogicalKeyboardKey.arrowLeft);
    final bool sPressed = _isPressed(LogicalKeyboardKey.keyS) ||
        _isPressed(LogicalKeyboardKey.arrowDown);
    final bool dPressed = _isPressed(LogicalKeyboardKey.keyD) ||
        _isPressed(LogicalKeyboardKey.arrowRight);
    final bool spacePressed = _isPressed(LogicalKeyboardKey.space);
    final bool rPressed = _isPressed(LogicalKeyboardKey.keyR);

    return Positioned(
      bottom: 24,
      left: 24,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xAA000000),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // W key
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildKey('W', wPressed),
              ],
            ),
            const SizedBox(height: 4),
            // A S D keys
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildKey('A', aPressed),
                const SizedBox(width: 4),
                _buildKey('S', sPressed),
                const SizedBox(width: 4),
                _buildKey('D', dPressed),
              ],
            ),
            const SizedBox(height: 8),
            // Space bar
            _buildKey('SPACE', spacePressed, width: 120),
            const SizedBox(height: 4),
            // R key
            _buildKey('R', rPressed),
          ],
        ),
      ),
    );
  }

  Widget _buildKey(String label, bool pressed, {double? width}) {
    return Container(
      width: width ?? 36,
      height: 36,
      decoration: BoxDecoration(
        color: pressed ? const Color(0xFF4CAF50) : const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: pressed ? const Color(0xFF66BB6A) : const Color(0x55FFFFFF),
          width: pressed ? 2 : 1,
        ),
        boxShadow: pressed
            ? [
                const BoxShadow(
                  color: Color(0x664CAF50),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: pressed ? const Color(0xFFFFFFFF) : const Color(0x99FFFFFF),
            fontSize: label.length > 1 ? 10 : 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}
