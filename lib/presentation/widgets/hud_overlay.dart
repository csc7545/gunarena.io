import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gun_arena_io/game/gun_arena_game.dart';
import 'package:gun_arena_io/game/components/player_component.dart';
import 'package:gun_arena_io/game/models/weapon_config.dart';
import 'package:gun_arena_io/game/systems/score_system.dart';

class HudOverlay extends StatefulWidget {
  final GunArenaGame game;

  const HudOverlay({super.key, required this.game});

  @override
  State<HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends State<HudOverlay> {
  Timer? _refreshTimer;

  GunArenaGame get game => widget.game;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(
      const Duration(milliseconds: 100),
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

  @override
  Widget build(BuildContext context) {
    final PlayerComponent player = game.localPlayer;
    final bool isDead = !player.alive;

    return SafeArea(
      child: Stack(
        children: [
          // Top left: HP bar
          Positioned(
            top: 12,
            left: 12,
            child: _buildHpBar(player),
          ),

          // Top right: Kill count
          Positioned(
            top: 12,
            right: 12,
            child: _buildKillCount(player),
          ),

          // Top center: Kill log
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: _buildKillLog(),
          ),

          // Bottom center-right: Ammo display
          Positioned(
            bottom: 24,
            right: 100,
            child: _buildAmmoDisplay(player),
          ),

          // Death overlay
          if (isDead) _buildDeathOverlay(player),
        ],
      ),
    );
  }

  Widget _buildHpBar(PlayerComponent player) {
    final double hpPercent = player.hp / PlayerComponent.maxHp;
    final bool isLowHp = hpPercent <= 0.3;
    final Color hpColor = isLowHp
        ? const Color(0xFFF44336)
        : hpPercent <= 0.6
            ? const Color(0xFFFFC107)
            : const Color(0xFF4CAF50);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xAA000000),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'HP ${player.hp} / ${PlayerComponent.maxHp}',
            style: TextStyle(
              color: isLowHp ? const Color(0xFFF44336) : const Color(0xFFFFFFFF),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 160,
            height: 12,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(color: const Color(0xFF333333)),
                  FractionallySizedBox(
                    widthFactor: hpPercent.clamp(0.0, 1.0),
                    child: Container(color: hpColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKillCount(PlayerComponent player) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xAA000000),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${player.kills} / ${ScoreSystem.targetKills}',
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildKillLog() {
    final List<KillEvent> recentKillEventList =
        game.scoreSystem.recentKillEventList;

    if (recentKillEventList.isEmpty) return const SizedBox.shrink();

    final double now = game.currentTime();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: recentKillEventList.reversed.take(3).map((KillEvent event) {
        final double age = now - event.timestamp;
        final double opacity = (1.0 - (age / 3.0)).clamp(0.0, 1.0);

        final String killerName = _playerDisplayName(event.killerId);
        final String victimName = _playerDisplayName(event.victimId);

        return Opacity(
          opacity: opacity,
          child: Container(
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0x88000000),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$killerName killed $victimName',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAmmoDisplay(PlayerComponent player) {
    final bool isReloading = player.isReloading;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xAA000000),
        borderRadius: BorderRadius.circular(8),
      ),
      child: isReloading
          ? const Text(
              'RELOADING',
              style: TextStyle(
                color: Color(0xFFFFC107),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            )
          : Text(
              '${player.ammo} / ${WeaponConfig.ar.magazineSize}',
              style: TextStyle(
                color: player.ammo <= 5
                    ? const Color(0xFFF44336)
                    : const Color(0xFFFFFFFF),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget _buildDeathOverlay(PlayerComponent player) {
    final double? respawnTimer =
        game.spawnSystem.getRespawnTimer(player.playerId);
    final String countdownText = respawnTimer != null
        ? respawnTimer.ceil().toString()
        : '...';

    return Positioned.fill(
      child: Container(
        color: const Color(0xBB000000),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'YOU DIED',
                style: TextStyle(
                  color: Color(0xFFF44336),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Respawn in $countdownText',
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _playerDisplayName(String playerId) {
    if (playerId == 'local') return 'You';
    return 'Player ${playerId.length > 4 ? playerId.substring(0, 4) : playerId}';
  }
}
