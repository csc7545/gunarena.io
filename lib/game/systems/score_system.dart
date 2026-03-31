import 'package:flame/components.dart';
import 'package:gun_arena_io/game/gun_arena_game.dart';
import 'package:gun_arena_io/game/components/player_component.dart';

class KillEvent {
  final String killerId;
  final String victimId;
  final double timestamp;

  const KillEvent({
    required this.killerId,
    required this.victimId,
    required this.timestamp,
  });
}

class ScoreSystem extends Component with HasGameReference<GunArenaGame> {
  static const int targetKills = 10;
  final List<KillEvent> killEventList = [];
  String? winnerId;

  void onKill(String killerId, String victimId) {
    killEventList.add(KillEvent(
      killerId: killerId,
      victimId: victimId,
      timestamp: game.currentTime(),
    ));

    final PlayerComponent? killer = game.findPlayer(killerId);
    if (killer != null && killer.kills >= targetKills) {
      winnerId = killerId;
      game.onGameEnd(killerId);
    }
  }

  List<KillEvent> get recentKillEventList {
    final double now = game.currentTime();
    return killEventList
        .where((e) => now - e.timestamp < 3.0)
        .toList();
  }
}
