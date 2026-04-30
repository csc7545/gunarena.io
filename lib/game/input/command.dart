import 'package:flame/game.dart';
import 'package:gun_arena_io/game/components/player_component.dart';
import 'package:gun_arena_io/game/gun_arena_game.dart';

/// Game-Programming-Patterns style Command: a function-object that mutates
/// a player. State is intentionally allowed (e.g. MoveCommand carries the
/// direction); to avoid per-frame allocation, callers should hold a single
/// scratch instance and call set...() before execute().
abstract class PlayerCommand {
  const PlayerCommand();
  void execute(PlayerComponent player);
}

class MoveCommand extends PlayerCommand {
  double dx;
  double dy;

  MoveCommand([this.dx = 0, this.dy = 0]);

  void set(double dx, double dy) {
    this.dx = dx;
    this.dy = dy;
  }

  @override
  void execute(PlayerComponent player) {
    player.moveDirection.setValues(dx, dy);
  }
}

class AimCommand extends PlayerCommand {
  double x;
  double y;

  AimCommand([this.x = 1, this.y = 0]);

  void set(double x, double y) {
    this.x = x;
    this.y = y;
  }

  @override
  void execute(PlayerComponent player) {
    player.facingDirection.setValues(x, y);
  }
}

class FireCommand extends PlayerCommand {
  const FireCommand();

  @override
  void execute(PlayerComponent player) {
    // Cross-coupling to GunArenaGame is acknowledged here; Phase 4 (EventBus)
    // will replace this with a `BulletSpawnRequested` event.
    final FlameGame? game = player.findGame();
    if (game is GunArenaGame) {
      game.shootBullet(player);
    }
  }
}

class ReloadCommand extends PlayerCommand {
  const ReloadCommand();

  @override
  void execute(PlayerComponent player) {
    player.startReload();
  }
}
