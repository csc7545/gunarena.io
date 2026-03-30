import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:gun_arena_io/game/components/player_component.dart';
import 'package:gun_arena_io/game/gun_arena_game.dart';
import 'package:gun_arena_io/network/signaling/firebase_signaling.dart';
import 'package:gun_arena_io/network/sync/state_sync.dart';
import 'package:gun_arena_io/network/webrtc/data_channel.dart';
import 'package:gun_arena_io/network/webrtc/rtc_manager.dart';
import 'package:gun_arena_io/presentation/widgets/fire_button_overlay.dart';
import 'package:gun_arena_io/presentation/widgets/hud_overlay.dart';
import 'package:gun_arena_io/presentation/widgets/joystick_overlay.dart';

class GameScreen extends StatefulWidget {
  final String roomId;
  final bool isHost;
  final FirebaseSignaling signaling;

  const GameScreen({
    super.key,
    required this.roomId,
    required this.isHost,
    required this.signaling,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GunArenaGame _game;
  late final RtcManager _rtcManager;
  StateSync? _stateSync;
  bool _initialized = false;

  static const List<Color> playerColorList = [
    Color(0xFF4CAF50),
    Color(0xFFF44336),
    Color(0xFF2196F3),
    Color(0xFFFF9800),
  ];

  @override
  void initState() {
    super.initState();
    _game = GunArenaGame();
    _rtcManager = RtcManager(
      signaling: widget.signaling,
      onChannelOpen: _onChannelOpen,
      onChannelClose: _onChannelClose,
      onMessage: _onMessage,
    );
    _setupMultiplayer();
  }

  Future<void> _setupMultiplayer() async {
    await _game.onLoad();
    await _rtcManager.startListening();

    _stateSync = StateSync(
      game: _game,
      rtcManager: _rtcManager,
      isHost: widget.isHost,
    );

    if (widget.isHost) {
      _stateSync!.start();
    }

    setState(() => _initialized = true);
  }

  void _onChannelOpen(String peerId, GameDataChannel channel) {
    if (widget.isHost) {
      final int playerIndex = _game.playerMap.length;
      final Color color = playerColorList[playerIndex % playerColorList.length];
      final Vector2 pos = _game.spawnSystem.findSafeSpawnPosition();

      final PlayerComponent remotePlayer = PlayerComponent(
        playerId: peerId,
        position: pos,
        color: color,
      );
      _game.addPlayer(remotePlayer);
    }
  }

  void _onChannelClose(String peerId) {
    if (widget.isHost) {
      final PlayerComponent? player = _game.findPlayer(peerId);
      if (player != null) {
        player.removeFromParent();
        _game.playerMap.remove(peerId);
      }
    }
  }

  void _onMessage(String peerId, String message) {
    _stateSync?.handleMessage(peerId, message);
  }

  @override
  void dispose() {
    _stateSync?.dispose();
    _rtcManager.dispose();
    widget.signaling.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A1A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
        ),
      );
    }

    return Scaffold(
      body: GameWidget(
        game: _game,
        overlayBuilderMap: {
          'joystick': (BuildContext context, GunArenaGame game) =>
              JoystickOverlay(game: game),
          'fireButton': (BuildContext context, GunArenaGame game) =>
              FireButtonOverlay(game: game),
          'hud': (BuildContext context, GunArenaGame game) =>
              HudOverlay(game: game),
          'gameEnd': (BuildContext context, GunArenaGame game) =>
              _buildGameEndOverlay(game),
        },
        initialActiveOverlays: const ['joystick', 'fireButton', 'hud'],
      ),
    );
  }

  Widget _buildGameEndOverlay(GunArenaGame game) {
    final String winnerId = game.scoreSystem.winnerId ?? '';
    final String localId = widget.signaling.localId ?? 'local';
    final bool isLocalWinner = winnerId == localId;

    return Positioned.fill(
      child: Container(
        color: const Color(0xCC000000),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isLocalWinner ? 'VICTORY!' : 'GAME OVER',
                style: TextStyle(
                  color: isLocalWinner
                      ? const Color(0xFFFFD700)
                      : const Color(0xFFF44336),
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                ),
                child: const Text(
                  'Leave',
                  style: TextStyle(fontSize: 18, color: Color(0xFFFFFFFF)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
