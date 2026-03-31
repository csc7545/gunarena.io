import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gun_arena_io/game/gun_arena_game.dart';
import 'package:gun_arena_io/game/models/weapon_config.dart';

class FireButtonOverlay extends StatefulWidget {
  final GunArenaGame game;
  const FireButtonOverlay({super.key, required this.game});

  @override
  State<FireButtonOverlay> createState() => _FireButtonOverlayState();
}

class _FireButtonOverlayState extends State<FireButtonOverlay> {
  bool _isFiring = false;
  Timer? _fireTimer;
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
    _fireTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  bool _isKeyPressed(LogicalKeyboardKey key) {
    return widget.game.pressedKeySet.contains(key);
  }

  @override
  Widget build(BuildContext context) {
    final bool spacePressed = _isKeyPressed(LogicalKeyboardKey.space);
    final bool rPressed = _isKeyPressed(LogicalKeyboardKey.keyR);

    return Positioned(
      right: 30,
      bottom: 30,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reload button + R key indicator
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildKeyIndicator('R', rPressed),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => widget.game.onReload(),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: rPressed
                        ? const Color(0x88FFC107)
                        : const Color(0x44FFFFFF),
                    border: Border.all(
                      color: rPressed
                          ? const Color(0xAAFFC107)
                          : const Color(0x66FFFFFF),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child:
                        Icon(Icons.refresh, color: Color(0xAAFFFFFF), size: 24),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Fire button + Space key indicator
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildKeyIndicator('SPACE', spacePressed, width: 50),
              const SizedBox(width: 8),
              GestureDetector(
                onTapDown: (_) => _startFiring(),
                onTapUp: (_) => _stopFiring(),
                onTapCancel: _stopFiring,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(
                        _isFiring || spacePressed ? 0x88F44336 : 0x44F44336),
                    border: Border.all(
                      color: const Color(0xAAF44336),
                      width: 3,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.gps_fixed,
                        color: Color(0xDDF44336), size: 36),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyIndicator(String label, bool pressed, {double? width}) {
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
            fontSize: label.length > 2 ? 9 : 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }

  void _startFiring() {
    setState(() => _isFiring = true);
    widget.game.onFire();
    final int intervalMs = (1000 / WeaponConfig.ar.fireRate).round();
    _fireTimer = Timer.periodic(
      Duration(milliseconds: intervalMs),
      (_) => widget.game.onFire(),
    );
  }

  void _stopFiring() {
    setState(() => _isFiring = false);
    _fireTimer?.cancel();
    _fireTimer = null;
  }
}
