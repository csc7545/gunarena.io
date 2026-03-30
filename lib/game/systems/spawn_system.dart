import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:gun_arena_io/game/gun_arena_game.dart';
import 'package:gun_arena_io/game/components/player_component.dart';

class SpawnSystem extends Component with HasGameReference<GunArenaGame> {
  final Map<String, double> _respawnTimerMap = {};
  static const double respawnDelay = 5.0;

  void onPlayerDeath(PlayerComponent player) {
    _respawnTimerMap[player.playerId] = respawnDelay;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final List<String> toRespawnList = [];

    _respawnTimerMap.updateAll((id, timer) {
      final double newTimer = timer - dt;
      if (newTimer <= 0) toRespawnList.add(id);
      return newTimer;
    });

    for (final String id in toRespawnList) {
      _respawnTimerMap.remove(id);
      game.respawnPlayer(id);
    }
  }

  double? getRespawnTimer(String playerId) => _respawnTimerMap[playerId];

  Vector2 findSafeSpawnPosition() {
    final Random random = Random();
    for (int i = 0; i < 100; i++) {
      final double x = 50 + random.nextDouble() * (1024 - 100);
      final double y = 50 + random.nextDouble() * (1024 - 100);
      bool safe = true;
      for (final Rect rect in game.mapComponent.obstacleRectList) {
        if (rect.inflate(20).contains(Offset(x, y))) {
          safe = false;
          break;
        }
      }
      if (safe) return Vector2(x, y);
    }
    return Vector2(512, 512);
  }
}
