import 'dart:math';

import 'package:flame/components.dart';
import 'package:gun_arena_io/game/components/player_component.dart';
import 'package:gun_arena_io/game/gun_arena_game.dart';

class AiPlayerComponent extends PlayerComponent
    with HasGameReference<GunArenaGame> {
  final Random _random = Random();

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
      moveDirection = Vector2(cos(angle), sin(angle));
    }
  }

  void _updateCombat(double dt) {
    _shootCooldown -= dt;

    final PlayerComponent? target = _findNearestAlivePlayer();
    if (target == null) return;

    final Vector2 dirToTarget =
        (target.position - position).normalized();

    facingDirection.setFrom(dirToTarget);

    if (_isAimingAt(dirToTarget) && _shootCooldown <= 0 && canShoot()) {
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

    final double dot = facingDirection.normalized().dot(dirToTarget.normalized());
    final double clampedDot = dot.clamp(-1.0, 1.0);
    final double angleDeg = acos(clampedDot) * 180 / pi;

    return angleDeg <= 30;
  }
}
