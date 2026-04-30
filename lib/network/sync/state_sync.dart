import 'dart:async';

import 'package:flame/components.dart' show Vector2;
import 'package:gun_arena_io/game/components/player_component.dart';
import 'package:gun_arena_io/game/gun_arena_game.dart';
import 'package:gun_arena_io/network/protocol/message.dart';
import 'package:gun_arena_io/network/protocol/serializer.dart';
import 'package:gun_arena_io/network/webrtc/rtc_manager.dart';

class StateSync {
  final GunArenaGame game;
  final RtcManager rtcManager;
  final bool isHost;

  Timer? _broadcastTimer;
  static const int tickRate = 20; // 20Hz

  StateSync({
    required this.game,
    required this.rtcManager,
    required this.isHost,
  });

  void start() {
    final int intervalMs = (1000 / tickRate).round();
    if (isHost) {
      _broadcastTimer = Timer.periodic(
        Duration(milliseconds: intervalMs),
        (_) => _broadcastGameState(),
      );
    } else {
      _broadcastTimer = Timer.periodic(
        Duration(milliseconds: intervalMs),
        (_) => _sendLocalInput(),
      );
    }
  }

  void _sendLocalInput() {
    final PlayerComponent p = game.localPlayer;
    sendInput(
      dx: p.moveDirection.x,
      dy: p.moveDirection.y,
      firing: game.isLocalFiring,
      reloading: false,
    );
  }

  void _broadcastGameState() {
    final List<Map<String, dynamic>> playerList = [];
    for (final PlayerComponent player in game.playerMap.values) {
      playerList.add({
        'id': player.playerId,
        'x': player.position.x,
        'y': player.position.y,
        'hp': player.hp,
        'k': player.kills,
        'd': player.deaths,
        'a': player.alive,
        'am': player.ammo,
        'rl': player.isReloading,
        'iv': player.isInvincible,
        'fx': player.facingDirection.x,
        'fy': player.facingDirection.y,
      });
    }

    final GameMessage message = GameMessage.state(
      playerList: playerList,
      bulletList: const [],
    );

    rtcManager.sendToAll(MessageSerializer.encode(message));
  }

  void handleMessage(String peerId, String raw) {
    final GameMessage message = MessageSerializer.decode(raw);

    switch (message.type) {
      case MessageType.input:
        if (isHost) _handleClientInput(peerId, message);
        break;
      case MessageType.state:
        if (!isHost) _handleHostState(message);
        break;
      case MessageType.kill:
        if (!isHost) _handleKillEvent(message);
        break;
      case MessageType.end:
        if (!isHost) _handleGameEnd(message);
        break;
      case MessageType.start:
        break;
      case MessageType.join:
        break;
      case MessageType.leave:
        break;
    }
  }

  void _handleClientInput(String peerId, GameMessage message) {
    final Map<String, dynamic> data = message.data;
    final double dx = (data['x'] as num).toDouble();
    final double dy = (data['y'] as num).toDouble();
    final bool firing = data['f'] as bool;
    final bool reloading = data['r'] as bool;

    final PlayerComponent? player = game.findPlayer(peerId);
    if (player == null || !player.alive) return;

    player.moveDirection.setValues(dx, dy);

    if (firing) {
      game.shootBullet(player);
    }

    if (reloading) {
      player.startReload();
    }
  }

  void _handleHostState(GameMessage message) {
    final List<dynamic> playerList = message.data['p'] as List<dynamic>;

    for (final dynamic playerData in playerList) {
      final Map<String, dynamic> p = playerData as Map<String, dynamic>;
      final String id = p['id'] as String;
      final double x = (p['x'] as num).toDouble();
      final double y = (p['y'] as num).toDouble();
      final double fx = (p['fx'] as num).toDouble();
      final double fy = (p['fy'] as num).toDouble();

      PlayerComponent? player = game.findPlayer(id);

      if (player == null) {
        // Spawn unknown remote player from host state.
        player = PlayerComponent(
          playerId: id,
          position: Vector2(x, y),
          color: GunArenaGame.colorForPlayer(id),
        );
        game.addPlayer(player);
      }

      if (id == game.localId) {
        // Authoritative reconcile for own avatar (rubber-banding tolerated
        // at low latency; see Phase 5+ for client-side prediction).
        player.position.setValues(x, y);
        player.facingDirection.setValues(fx, fy);
      } else {
        // Remote avatar — let PlayerComponent.update lerp toward target.
        player.setRemoteTarget(x, y, fx, fy);
      }

      player.hp = p['hp'] as int;
      player.kills = p['k'] as int;
      player.deaths = p['d'] as int;
      player.alive = p['a'] as bool;
      player.ammo = p['am'] as int;
      player.isReloading = p['rl'] as bool;
      player.isInvincible = p['iv'] as bool;
    }
  }

  void _handleKillEvent(GameMessage message) {
    final String killerId = message.data['k'] as String;
    final String victimId = message.data['d'] as String;
    game.scoreSystem.onKill(killerId, victimId);
  }

  void _handleGameEnd(GameMessage message) {
    final String winnerId = message.data['w'] as String;
    game.onGameEnd(winnerId);
  }

  // Client: send input to host
  void sendInput({
    required double dx,
    required double dy,
    required bool firing,
    required bool reloading,
  }) {
    if (isHost) return;

    final GameMessage message = GameMessage.input(
      dx: dx,
      dy: dy,
      firing: firing,
      reloading: reloading,
    );
    rtcManager.sendToAll(MessageSerializer.encode(message));
  }

  // Host: broadcast kill event
  void broadcastKill(String killerId, String victimId) {
    if (!isHost) return;

    final GameMessage message = GameMessage.kill(
      killerId: killerId,
      victimId: victimId,
    );
    rtcManager.sendToAll(MessageSerializer.encode(message));
  }

  // Host: broadcast game end
  void broadcastGameEnd(String winnerId) {
    if (!isHost) return;

    final GameMessage message = GameMessage.end(
      winnerId: winnerId,
      scoreList: game.playerMap.values.map((PlayerComponent p) => {
        'id': p.playerId,
        'k': p.kills,
        'd': p.deaths,
      }).toList(),
    );
    rtcManager.sendToAll(MessageSerializer.encode(message));
  }

  void dispose() {
    _broadcastTimer?.cancel();
  }
}
