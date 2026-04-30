import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/geometry.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:gun_arena_io/game/components/bullet_component.dart';
import 'package:gun_arena_io/game/components/impact_component.dart';
import 'package:gun_arena_io/game/components/map_component.dart';
import 'package:gun_arena_io/game/components/obstacle_component.dart';
import 'package:gun_arena_io/game/components/player_component.dart';
import 'package:gun_arena_io/game/input/local_input_controller.dart';
import 'package:gun_arena_io/game/models/weapon_config.dart';
import 'package:gun_arena_io/game/svg_sprites.dart';
import 'package:gun_arena_io/game/systems/score_system.dart';
import 'package:gun_arena_io/game/systems/spawn_system.dart';

class GunArenaGame extends FlameGame with HasCollisionDetection, KeyboardEvents {
  late MapComponent mapComponent;
  late PlayerComponent localPlayer;
  late LocalInputController localInput;
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

  // Authority fire-rate gate. shootBullet() is the single chokepoint for
  // every fire path (local input, network input, AI), so enforcing the
  // weapon's fire interval here means a held Space on a client cannot
  // shoot faster than weapon.fireRate even if the client streams
  // firing=true at the network tick rate.
  final Map<String, double> _lastFireTimeMap = {};

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
    localInput = LocalInputController();
    await localPlayer.add(localInput);
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
    localInput.setMove(dx, dy);

    if (_isSpaceFiring) {
      _fireAccumulator += dt;
      final double fireInterval = 1.0 / WeaponConfig.ar.fireRate;
      while (_fireAccumulator >= fireInterval) {
        _fireAccumulator -= fireInterval;
        localInput.fire();
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
      localInput.fire();
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

    final double now = currentTime();
    final double interval = 1.0 / WeaponConfig.ar.fireRate;
    final double last = _lastFireTimeMap[player.playerId] ?? -interval;
    if (now - last < interval) return;
    _lastFireTimeMap[player.playerId] = now;

    player.consumeAmmo();
    player.triggerAttack();

    final Vector2 facing = player.facingDirection.normalized();
    final Vector2 bulletPos =
        player.position + facing * PlayerComponent.playerRadius * 1.5;

    final RaycastResult<ShapeHitbox>? hit = collisionDetection.raycast(
      Ray2(origin: player.position.clone(), direction: facing),
      maxDistance: PlayerComponent.playerRadius * 1.5,
      hitboxFilter: (h) => h.parent is ObstacleComponent,
    );
    final Vector2? blockedAt = hit?.intersectionPoint;
    if (blockedAt != null) {
      world.add(ImpactComponent(position: blockedAt.clone()));
      return;
    }

    final BulletComponent bullet = BulletComponent(
      ownerId: player.playerId,
      position: bulletPos.clone(),
      direction: facing,
    );
    world.add(bullet);
  }

  void onJoystickMove(double dx, double dy) {
    if (gameEnded) return;
    localInput.setMove(dx, dy);
  }

  void onFire() {
    if (gameEnded) return;
    localInput.fire();
  }

  void onReload() {
    if (gameEnded) return;
    localInput.reload();
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
