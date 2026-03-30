import 'dart:async';
import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    _fireTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 30,
      bottom: 30,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reload button
          GestureDetector(
            onTap: () => widget.game.onReload(),
            child: Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x44FFFFFF),
                border: Border.all(color: const Color(0x66FFFFFF), width: 2),
              ),
              child: const Center(
                child: Icon(Icons.refresh, color: Color(0xAAFFFFFF), size: 24),
              ),
            ),
          ),
          // Fire button
          GestureDetector(
            onTapDown: (_) => _startFiring(),
            onTapUp: (_) => _stopFiring(),
            onTapCancel: _stopFiring,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(_isFiring ? 0x88F44336 : 0x44F44336),
                border: Border.all(
                  color: const Color(0xAAF44336),
                  width: 3,
                ),
              ),
              child: const Center(
                child: Icon(Icons.gps_fixed, color: Color(0xDDF44336), size: 36),
              ),
            ),
          ),
        ],
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
