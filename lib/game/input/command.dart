import 'package:flame/game.dart';
import 'package:gun_arena_io/game/components/player_component.dart';
import 'package:gun_arena_io/game/gun_arena_game.dart';

/// Game-Programming-Patterns style Command: a function-object that mutates
/// a player.
///
/// **Mutable-scratch policy** — Move/Aim subclasses carry their data as
/// non-final fields and are intended to be reused across frames by the
/// caller (a single scratch instance per controller). This trades the
/// classical Command pattern's queue/replay/serialize abilities for zero
/// per-frame allocation, which matters at 60 fps.
///
/// As a consequence, mutable commands are **immediate-execute only**:
///   - DO NOT queue them (next frame's `set()` overwrites the field).
///   - DO NOT keep references for replay (same reason).
///   - DO NOT send them over the network (serialize/use can race).
/// Stateless commands (Fire/Reload) are `const` and free to share.
abstract class PlayerCommand {
  const PlayerCommand();
  void execute(PlayerComponent player);
}

/// Mutable scratch — see PlayerCommand docs. Immediate-execute only.
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

/// Mutable scratch — see PlayerCommand docs. Immediate-execute only.
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
