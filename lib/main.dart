import 'package:firebase_core/firebase_core.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:gun_arena_io/firebase_options.dart';
import 'package:gun_arena_io/game/components/ai_player_component.dart';
import 'package:gun_arena_io/game/gun_arena_game.dart';
import 'package:gun_arena_io/presentation/screens/home_screen.dart';
import 'package:gun_arena_io/presentation/widgets/fire_button_overlay.dart';
import 'package:gun_arena_io/presentation/widgets/hud_overlay.dart';
import 'package:gun_arena_io/presentation/widgets/key_bindings_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
      ),
      initialRoute: '/',
      onGenerateRoute: (RouteSettings settings) {
        final Uri uri = Uri.parse(settings.name ?? '/');

        // Handle /#/room/{roomId} for joining
        if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'room') {
          final String roomId = uri.pathSegments[1];
          return MaterialPageRoute(
            builder: (_) => HomeScreen(joinRoomId: roomId),
          );
        }

        // Handle /play for singleplayer (with AI bots)
        if (uri.path == '/play') {
          return MaterialPageRoute(
            builder: (_) => const SinglePlayerScreen(),
          );
        }

        // Default: home
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );
      },
    );
  }
}

/// Standalone singleplayer mode with AI bots (for testing)
class SinglePlayerScreen extends StatefulWidget {
  const SinglePlayerScreen({super.key});

  @override
  State<SinglePlayerScreen> createState() => _SinglePlayerScreenState();
}

class _SinglePlayerScreenState extends State<SinglePlayerScreen> {
  late final GunArenaGame _game;

  static const List<Color> aiColorList = [
    Color(0xFFF44336),
    Color(0xFF2196F3),
    Color(0xFFFF9800),
  ];

  @override
  void initState() {
    super.initState();
    _game = GunArenaGame(onReady: _spawnAiPlayers);
  }

  void _spawnAiPlayers() {
    for (int i = 0; i < 3; i++) {
      final AiPlayerComponent ai = AiPlayerComponent(
        playerId: 'ai_$i',
        position: _game.spawnSystem.findSafeSpawnPosition(),
        color: aiColorList[i],
      );
      _game.addPlayer(ai);
    }
  }

  @override
  void dispose() {
    _game.pauseEngine();
    _game.removeAll(_game.children);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: _game,
        overlayBuilderMap: {
          'fireButton': (BuildContext context, GunArenaGame game) =>
              FireButtonOverlay(game: game),
          'hud': (BuildContext context, GunArenaGame game) =>
              HudOverlay(game: game),
          'keyBindings': (BuildContext context, GunArenaGame game) =>
              KeyBindingsOverlay(game: game),
          'gameEnd': (BuildContext context, GunArenaGame game) =>
              _buildGameEndOverlay(game),
        },
        initialActiveOverlays: const [
          'fireButton',
          'hud',
          'keyBindings',
        ],
      ),
    );
  }

  Widget _buildGameEndOverlay(GunArenaGame game) {
    final String winnerId = game.scoreSystem.winnerId ?? '';
    final bool isLocalWinner = winnerId == 'local';

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
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                ),
                child: const Text(
                  'Back to Home',
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
