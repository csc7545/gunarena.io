import 'dart:math';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:gun_arena_io/game/components/bullet_component.dart';
import 'package:gun_arena_io/game/components/impact_component.dart';
import 'package:gun_arena_io/game/components/map_component.dart';
import 'package:gun_arena_io/game/components/player_component.dart';
import 'package:gun_arena_io/game/models/weapon_config.dart';
import 'package:gun_arena_io/game/svg_sprites.dart';
import 'package:gun_arena_io/game/systems/score_system.dart';
import 'package:gun_arena_io/game/systems/spawn_system.dart';

class GunArenaGame extends FlameGame with HasCollisionDetection, KeyboardEvents {
  late MapComponent mapComponent;
  late PlayerComponent localPlayer;
  late SpawnSystem spawnSystem;
  late ScoreSystem scoreSystem;

  final String localId;
  final int mapSeed;
  final VoidCallback? onReady;
  final Map<String, PlayerComponent> playerMap = {};
  bool gameEnded = false;
  double _elapsedTime = 0;

  // Keyboard input state
  final Set<LogicalKeyboardKey> pressedKeySet = {};
  bool _isSpaceFiring = false;
  double _fireAccumulator = 0;

  bool get isLocalFiring => _isSpaceFiring;

  static const List<Color> playerColorList = <Color>[
    Color(0xFF4CAF50),
    Color(0xFFF44336),
    Color(0xFF2196F3),
    Color(0xFFFF9800),
  ];

  static Color colorForPlayer(String playerId) {
    return playerColorList[playerId.hashCode.abs() % playerColorList.length];
  }

  GunArenaGame({String? localId, int? mapSeed, this.onReady})
      : localId = localId ?? 'local',
        mapSeed = mapSeed ?? Random().nextInt(999999);

  @override
  Future<void> onLoad() async {
    await SvgSprites.loadAll();

    mapComponent = MapComponent(seed: mapSeed);
    await world.add(mapComponent);

    spawnSystem = SpawnSystem();
    await world.add(spawnSystem);

    scoreSystem = ScoreSystem();
    await world.add(scoreSystem);

    final Vector2 spawnPos = _findSafeSpawnPosition();
    localPlayer = PlayerComponent(
      playerId: localId,
      position: spawnPos,
      color: colorForPlayer(localId),
    );
    await world.add(localPlayer);
    playerMap[localId] = localPlayer;

    camera.follow(localPlayer);
    onReady?.call();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsedTime += dt;
    _updateKeyboardInput(dt);
  }

  void _updateKeyboardInput(double dt) {
    if (gameEnded) return;

    // WASD movement
    double dx = 0;
    double dy = 0;
    if (pressedKeySet.contains(LogicalKeyboardKey.keyW) ||
        pressedKeySet.contains(LogicalKeyboardKey.arrowUp)) {
      dy -= 1;
    }
    if (pressedKeySet.contains(LogicalKeyboardKey.keyS) ||
        pressedKeySet.contains(LogicalKeyboardKey.arrowDown)) {
      dy += 1;
    }
    if (pressedKeySet.contains(LogicalKeyboardKey.keyA) ||
        pressedKeySet.contains(LogicalKeyboardKey.arrowLeft)) {
      dx -= 1;
    }
    if (pressedKeySet.contains(LogicalKeyboardKey.keyD) ||
        pressedKeySet.contains(LogicalKeyboardKey.arrowRight)) {
      dx += 1;
    }
    localPlayer.moveDirection = Vector2(dx, dy);

    // Space auto-fire
    if (_isSpaceFiring) {
      _fireAccumulator += dt;
      final double fireInterval = 1.0 / WeaponConfig.ar.fireRate;
      while (_fireAccumulator >= fireInterval) {
        _fireAccumulator -= fireInterval;
        shootBullet(localPlayer);
      }
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    pressedKeySet
      ..clear()
      ..addAll(keysPressed);

    // Space: fire
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.space &&
        !_isSpaceFiring) {
      _isSpaceFiring = true;
      _fireAccumulator = 0;
      shootBullet(localPlayer);
      return KeyEventResult.handled;
    }
    if (event is KeyUpEvent && event.logicalKey == LogicalKeyboardKey.space) {
      _isSpaceFiring = false;
      _fireAccumulator = 0;
      return KeyEventResult.handled;
    }

    // R: reload
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyR) {
      onReload();
      return KeyEventResult.handled;
    }

    // Movement keys handled
    final Set<LogicalKeyboardKey> movementKeySet = {
      LogicalKeyboardKey.keyW,
      LogicalKeyboardKey.keyA,
      LogicalKeyboardKey.keyS,
      LogicalKeyboardKey.keyD,
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowRight,
    };
    if (movementKeySet.contains(event.logicalKey)) {
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  double currentTime() => _elapsedTime;

  Vector2 _findSafeSpawnPosition() {
    final Random random = Random();
    for (int i = 0; i < 100; i++) {
      final double x = 50 + random.nextDouble() * (MapComponent.mapWidth - 100);
      final double y = 50 + random.nextDouble() * (MapComponent.mapHeight - 100);
      bool safe = true;
      for (final Rect rect in mapComponent.obstacleRectList) {
        if (rect.inflate(20).contains(Offset(x, y))) {
          safe = false;
          break;
        }
      }
      if (safe) return Vector2(x, y);
    }
    return Vector2(MapComponent.mapWidth / 2, MapComponent.mapHeight / 2);
  }

  void shootBullet(PlayerComponent player) {
    if (!player.canShoot() || gameEnded) return;
    player.consumeAmmo();
    player.triggerAttack();

    final Vector2 facing = player.facingDirection.normalized();
    final Vector2 bulletPos =
        player.position + facing * PlayerComponent.playerRadius * 1.5;

    final Vector2? blockedAt = _findSegmentBlocker(player.position, bulletPos);
    if (blockedAt != null) {
      world.add(ImpactComponent(position: blockedAt));
      return;
    }

    final BulletComponent bullet = BulletComponent(
      ownerId: player.playerId,
      position: bulletPos.clone(),
      direction: facing,
    );
    world.add(bullet);
  }

  Vector2? _findSegmentBlocker(Vector2 from, Vector2 to) {
    Vector2? closest;
    double minT = double.infinity;
    for (final Rect rect in mapComponent.obstacleRectList) {
      final double? t = _segmentAabbT(from, to, rect);
      if (t != null && t < minT) {
        minT = t;
        closest = from + (to - from) * t;
      }
    }
    return closest;
  }

  // Returns the [0, 1] parameter t at which segment from→to enters rect, or
  // null if no intersection. If `from` is already inside, returns 0.
  double? _segmentAabbT(Vector2 from, Vector2 to, Rect rect) {
    final double dx = to.x - from.x;
    final double dy = to.y - from.y;
    double tMin = 0.0;
    double tMax = 1.0;

    if (dx.abs() < 1e-9) {
      if (from.x < rect.left || from.x > rect.right) return null;
    } else {
      final double t1 = (rect.left - from.x) / dx;
      final double t2 = (rect.right - from.x) / dx;
      final double tEnter = t1 < t2 ? t1 : t2;
      final double tExit = t1 < t2 ? t2 : t1;
      if (tEnter > tMin) tMin = tEnter;
      if (tExit < tMax) tMax = tExit;
      if (tMin > tMax) return null;
    }

    if (dy.abs() < 1e-9) {
      if (from.y < rect.top || from.y > rect.bottom) return null;
    } else {
      final double t1 = (rect.top - from.y) / dy;
      final double t2 = (rect.bottom - from.y) / dy;
      final double tEnter = t1 < t2 ? t1 : t2;
      final double tExit = t1 < t2 ? t2 : t1;
      if (tEnter > tMin) tMin = tEnter;
      if (tExit < tMax) tMax = tExit;
      if (tMin > tMax) return null;
    }

    return tMin;
  }

  void onJoystickMove(double dx, double dy) {
    if (gameEnded) return;
    localPlayer.moveDirection = Vector2(dx, dy);
  }

  void onFire() {
    if (gameEnded) return;
    shootBullet(localPlayer);
  }

  void onReload() {
    if (gameEnded) return;
    localPlayer.startReload();
  }

  void onPlayerKill(String killerId, String victimId) {
    final PlayerComponent? killer = findPlayer(killerId);
    final PlayerComponent? victim = findPlayer(victimId);

    if (killer != null) killer.kills++;
    if (victim != null) {
      // die() already called by takeDamage, just schedule respawn
      spawnSystem.onPlayerDeath(victim);
    }

    scoreSystem.onKill(killerId, victimId);
  }

  void respawnPlayer(String playerId) {
    final PlayerComponent? player = findPlayer(playerId);
    if (player == null) return;
    final Vector2 pos = spawnSystem.findSafeSpawnPosition();
    player.respawn(pos);
  }

  PlayerComponent? findPlayer(String playerId) => playerMap[playerId];

  void onGameEnd(String winnerId) {
    gameEnded = true;
    overlays.add('gameEnd');
  }

  void addPlayer(PlayerComponent player) {
    playerMap[player.playerId] = player;
    world.add(player);
  }
}
