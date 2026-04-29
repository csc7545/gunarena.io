import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gun_arena_io/application/room/room_cubit.dart';
import 'package:gun_arena_io/application/room/room_state.dart';
import 'package:gun_arena_io/presentation/screens/game_screen.dart';

class LobbyScreen extends StatelessWidget {
  final String roomId;
  final bool isHost;

  const LobbyScreen({
    super.key,
    required this.roomId,
    required this.isHost,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RoomCubit, RoomState>(
      listenWhen: (RoomState previous, RoomState current) {
        // Only navigate to game on the initial Waiting → Starting transition.
        if (current is RoomStarting) return previous is RoomWaiting;
        return true;
      },
      listener: (BuildContext context, RoomState state) {
        if (state is RoomStarting) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => GameScreen(
                roomId: state.roomId,
                isHost: state.isHost,
                mapSeed: state.mapSeed,
                signaling: context.read<RoomCubit>().signaling,
              ),
            ),
          );
        }
      },
      builder: (BuildContext context, RoomState state) {
        final List<RoomPlayer> playerList =
            state is RoomWaiting ? state.playerList : [];
        final String shareLink = '${Uri.base.origin}/#/room/$roomId';

        return Scaffold(
          backgroundColor: const Color(0xFF1A1A1A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF2D2D2D),
            title: const Text('Lobby', style: TextStyle(color: Color(0xFFFFFFFF))),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFFFFFFFF)),
              onPressed: () {
                context.read<RoomCubit>().leaveRoom();
                Navigator.of(context).pop();
              },
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Share link
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          shareLink,
                          style: const TextStyle(
                            color: Color(0xFF888888),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Color(0xFF4CAF50)),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: shareLink));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Link copied!')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Player list
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Players',
                    style: TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: playerList.length,
                    itemBuilder: (BuildContext context, int index) {
                      final RoomPlayer player = playerList[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D2D2D),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person, color: Color(0xFF4CAF50)),
                            const SizedBox(width: 12),
                            Text(
                              player.name,
                              style: const TextStyle(
                                color: Color(0xFFFFFFFF),
                                fontSize: 16,
                              ),
                            ),
                            if (index == 0)
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Text(
                                  'HOST',
                                  style: TextStyle(
                                    color: Color(0xFFFF9800),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Start button (host only)
                if (isHost)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: playerList.length >= 2
                          ? () => context.read<RoomCubit>().startGame()
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        disabledBackgroundColor: const Color(0xFF333333),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        playerList.length >= 2
                            ? 'Start Game'
                            : 'Waiting for players... (${playerList.length}/4)',
                        style: const TextStyle(fontSize: 18, color: Color(0xFFFFFFFF)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
