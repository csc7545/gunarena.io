import 'dart:math';

import 'package:flame/components.dart';
import 'package:gun_arena_io/game/components/player_component.dart';
import 'package:gun_arena_io/game/gun_arena_game.dart';
import 'package:gun_arena_io/game/input/command.dart';

/// AI brain attached as a child of a [PlayerComponent]. Reads parent state
/// each frame and emits Commands; doesn't mutate the player directly.
class AiInputController extends Component
    with HasGameReference<GunArenaGame> {
  final Random _random = Random();
  final Vector2 _dirScratch = Vector2.zero();

  final MoveCommand _moveCmd = MoveCommand();
  final AimCommand _aimCmd = AimCommand();
  static const FireCommand _fireCmd = FireCommand();
  static const ReloadCommand _reloadCmd = ReloadCommand();

  double _directionChangeTimer = 0;
  double _nextDirectionChange = 1.0;
  double _shootCooldown = 0;

  PlayerComponent get _player => parent! as PlayerComponent;

  @override
  void update(double dt) {
    super.update(dt);
    if (!_player.alive) return;

    _updateMovement(dt);
    _updateCombat(dt);
  }

  void _updateMovement(double dt) {
    _directionChangeTimer += dt;
    if (_directionChangeTimer < _nextDirectionChange) return;

    _directionChangeTimer = 0;
    _nextDirectionChange = 1.0 + _random.nextDouble() * 2.0;
    final double angle = _random.nextDouble() * 2 * pi;
    _moveCmd.set(cos(angle), sin(angle));
    _moveCmd.execute(_player);
  }

  void _updateCombat(double dt) {
    _shootCooldown -= dt;

    final PlayerComponent? target = _findNearestAlivePlayer();
    if (target == null) return;

    _dirScratch
      ..setFrom(target.position)
      ..sub(_player.position);
    if (_dirScratch.length2 == 0) return;
    _dirScratch.normalize();

    _aimCmd.set(_dirScratch.x, _dirScratch.y);
    _aimCmd.execute(_player);

    if (_isAimingAt(_dirScratch) &&
        _shootCooldown <= 0 &&
        _player.canShoot()) {
      _fireCmd.execute(_player);
      _shootCooldown = 0.3;
    }

    if (!_player.isReloading && _player.ammo <= 0) {
      _reloadCmd.execute(_player);
    }
  }

  PlayerComponent? _findNearestAlivePlayer() {
    PlayerComponent? nearest;
    double nearestDist = double.infinity;
    for (final PlayerComponent p in game.playerMap.values) {
      if (p == _player || !p.alive) continue;
      final double dist = _player.position.distanceTo(p.position);
      if (dist < nearestDist) {
        nearestDist = dist;
        nearest = p;
      }
    }
    return nearest;
  }

  bool _isAimingAt(Vector2 dirToTarget) {
    if (_player.facingDirection.isZero() || dirToTarget.isZero()) return false;
    // Both vectors are unit length here:
    //   - facingDirection was just set from _dirScratch (normalized).
    //   - dirToTarget == _dirScratch.
    final double dot =
        _player.facingDirection.dot(dirToTarget).clamp(-1.0, 1.0);
    final double angleDeg = acos(dot) * 180 / pi;
    return angleDeg <= 30;
  }
}
