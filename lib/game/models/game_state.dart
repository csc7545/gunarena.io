import 'package:gun_arena_io/game/models/player_state.dart';

enum GameStatus { waiting, playing, finished }

class GameState {
  final Map<String, PlayerState> playerMap;
  final GameStatus status;
  final int targetKills;
  final String? winnerId;

  const GameState({
    this.playerMap = const {},
    this.status = GameStatus.waiting,
    this.targetKills = 15,
    this.winnerId,
  });
}
