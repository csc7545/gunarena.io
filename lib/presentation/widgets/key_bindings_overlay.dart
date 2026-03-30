import 'package:flutter/material.dart';
import 'package:gun_arena_io/game/gun_arena_game.dart';

class KeyBindingsOverlay extends StatefulWidget {
  final GunArenaGame game;

  const KeyBindingsOverlay({super.key, required this.game});

  @override
  State<KeyBindingsOverlay> createState() => _KeyBindingsOverlayState();
}

class _KeyBindingsOverlayState extends State<KeyBindingsOverlay> {
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    // 5초 후 자동으로 숨김
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 120,
      left: 12,
      child: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 500),
        child: GestureDetector(
          onTap: () => setState(() => _visible = !_visible),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xCC000000),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'CONTROLS',
                  style: TextStyle(
                    color: Color(0xFFFFC107),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 8),
                _buildKeyRow('W A S D', 'Move'),
                _buildKeyRow('Arrow Keys', 'Move'),
                _buildKeyRow('Space', 'Fire'),
                _buildKeyRow('R', 'Reload'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyRow(String key, String action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0x44FFFFFF),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0x66FFFFFF)),
            ),
            child: Text(
              key,
              style: const TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            action,
            style: const TextStyle(
              color: Color(0xAAFFFFFF),
              fontSize: 11,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}
