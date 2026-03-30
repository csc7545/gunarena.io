import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:gun_arena_io/game/components/bullet_component.dart';
import 'package:gun_arena_io/game/components/map_component.dart';
import 'package:gun_arena_io/game/components/player_component.dart';
import 'package:gun_arena_io/game/systems/score_system.dart';
import 'package:gun_arena_io/game/systems/spawn_system.dart';

class GunArenaGame extends FlameGame with HasCollisionDetection {
  late MapComponent mapComponent;
  late PlayerComponent localPlayer;
  late SpawnSystem spawnSystem;
  late ScoreSystem scoreSystem;

  final int mapSeed;
  final Map<String, PlayerComponent> playerMap = {};
  bool gameEnded = false;
  double _elapsedTime = 0;

  GunArenaGame({int? mapSeed}) : mapSeed = mapSeed ?? Random().nextInt(999999);

  @override
  Future<void> onLoad() async {
    mapComponent = MapComponent(seed: mapSeed);
    await add(mapComponent);

    spawnSystem = SpawnSystem();
    await add(spawnSystem);

    scoreSystem = ScoreSystem();
    await add(scoreSystem);

    final Vector2 spawnPos = _findSafeSpawnPosition();
    localPlayer = PlayerComponent(
      playerId: 'local',
      position: spawnPos,
      color: const Color(0xFF4CAF50),
    );
    await add(localPlayer);
    playerMap['local'] = localPlayer;

    camera.follow(localPlayer);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsedTime += dt;
  }

  @override
  double currentTime() => _elapsedTime;

  Vector2 _findSafeSpawnPosition() {
    final Random random = Random();
    for (int i = 0; i < 100; i++) {
      final double x = 50 + random.nextDouble() * (1024 - 100);
      final double y = 50 + random.nextDouble() * (1024 - 100);
      bool safe = true;
      for (final Rect rect in mapComponent.obstacleRectList) {
        if (rect.inflate(20).contains(Offset(x, y))) {
          safe = false;
          break;
        }
      }
      if (safe) return Vector2(x, y);
    }
    return Vector2(512, 512);
  }

  void shootBullet(PlayerComponent player) {
    if (!player.canShoot() || gameEnded) return;
    player.consumeAmmo();

    final Vector2 bulletPos = player.position +
        player.facingDirection.normalized() * PlayerComponent.playerRadius * 1.5;

    final BulletComponent bullet = BulletComponent(
      ownerId: player.playerId,
      position: bulletPos.clone(),
      direction: player.facingDirection.normalized(),
    );
    add(bullet);
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
    add(player);
  }
}
