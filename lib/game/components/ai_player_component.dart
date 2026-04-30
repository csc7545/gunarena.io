import 'dart:math';

import 'package:flame/components.dart';
import 'package:gun_arena_io/game/components/player_component.dart';
import 'package:gun_arena_io/game/gun_arena_game.dart';

class AiPlayerComponent extends PlayerComponent
    with HasGameReference<GunArenaGame> {
  final Random _random = Random();

  // Per-instance scratch for aim direction. NEVER static.
  final Vector2 _dirScratch = Vector2.zero();

  double _directionChangeTimer = 0;
  double _nextDirectionChange = 1.0;
  double _shootCooldown = 0;

  AiPlayerComponent({
    required super.playerId,
    required super.position,
    required super.color,
  });

  @override
  void update(double dt) {
    super.update(dt);

    if (!alive) return;

    _updateMovement(dt);
    _updateCombat(dt);
  }

  void _updateMovement(double dt) {
    _directionChangeTimer += dt;

    if (_directionChangeTimer >= _nextDirectionChange) {
      _directionChangeTimer = 0;
      _nextDirectionChange = 1.0 + _random.nextDouble() * 2.0;

      final double angle = _random.nextDouble() * 2 * pi;
      moveDirection.setValues(cos(angle), sin(angle));
    }
  }

  void _updateCombat(double dt) {
    _shootCooldown -= dt;

    final PlayerComponent? target = _findNearestAlivePlayer();
    if (target == null) return;

    _dirScratch
      ..setFrom(target.position)
      ..sub(position);
    if (_dirScratch.length2 == 0) return;
    _dirScratch.normalize();

    facingDirection.setFrom(_dirScratch);

    if (_isAimingAt(_dirScratch) && _shootCooldown <= 0 && canShoot()) {
      game.shootBullet(this);
      _shootCooldown = 0.3;
    }

    if (isReloading == false && ammo <= 0) {
      startReload();
    }
  }

  PlayerComponent? _findNearestAlivePlayer() {
    PlayerComponent? nearest;
    double nearestDist = double.infinity;

    for (final PlayerComponent player in game.playerMap.values) {
      if (player == this || !player.alive) continue;

      final double dist = position.distanceTo(player.position);
      if (dist < nearestDist) {
        nearestDist = dist;
        nearest = player;
      }
    }

    return nearest;
  }

  bool _isAimingAt(Vector2 dirToTarget) {
    if (facingDirection.isZero() || dirToTarget.isZero()) return false;
    // Both vectors are guaranteed unit length here:
    //   - facingDirection is set from a normalized scratch in Player.update or
    //     from this method's _dirScratch (already normalized).
    //   - dirToTarget == _dirScratch, normalized just above the call site.
    final double dot =
        facingDirection.dot(dirToTarget).clamp(-1.0, 1.0);
    final double angleDeg = acos(dot) * 180 / pi;
    return angleDeg <= 30;
  }
}
