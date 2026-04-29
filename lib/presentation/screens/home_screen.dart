import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gun_arena_io/application/room/room_cubit.dart';
import 'package:gun_arena_io/application/room/room_state.dart';
import 'package:gun_arena_io/network/signaling/firebase_signaling.dart';
import 'package:gun_arena_io/presentation/screens/lobby_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? joinRoomId;
  const HomeScreen({super.key, this.joinRoomId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = 'Player';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RoomCubit(signaling: FirebaseSignaling()),
      child: BlocConsumer<RoomCubit, RoomState>(
        listenWhen: (RoomState previous, RoomState current) {
          // Only navigate to lobby on the initial entry (Creating → Waiting),
          // not on subsequent player-list updates that re-emit RoomWaiting.
          if (current is RoomWaiting) return previous is RoomCreating;
          return true;
        },
        listener: (BuildContext context, RoomState state) {
          if (state is RoomWaiting) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<RoomCubit>(),
                  child: LobbyScreen(
                    roomId: state.roomId,
                    isHost: state.isHost,
                  ),
                ),
              ),
            );
          }
          if (state is RoomError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (BuildContext context, RoomState state) {
          final bool isLoading = state is RoomCreating;

          return Scaffold(
            backgroundColor: const Color(0xFF1A1A1A),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'GunArena.io',
                      style: TextStyle(
                        color: Color(0xFFFF5722),
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Fast-paced multiplayer top-down shooter',
                      style: TextStyle(color: Color(0xFF888888), fontSize: 14),
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: 300,
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Color(0xFFFFFFFF)),
                        decoration: InputDecoration(
                          labelText: 'Nickname',
                          labelStyle: const TextStyle(color: Color(0xFF888888)),
                          filled: true,
                          fillColor: const Color(0xFF2D2D2D),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 300,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                final String name = _nameController.text.trim();
                                if (name.isEmpty) return;
                                context.read<RoomCubit>().createRoom(name);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Color(0xFFFFFFFF))
                            : const Text(
                                'Create Room',
                                style: TextStyle(fontSize: 18, color: Color(0xFFFFFFFF)),
                              ),
                      ),
                    ),
                    if (widget.joinRoomId != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 300,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  final String name = _nameController.text.trim();
                                  if (name.isEmpty) return;
                                  context.read<RoomCubit>().joinRoom(
                                        widget.joinRoomId!,
                                        name,
                                      );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Join Room',
                            style: TextStyle(fontSize: 18, color: Color(0xFFFFFFFF)),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    const Divider(color: Color(0xFF444444), indent: 50, endIndent: 50),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 300,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/play');
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF888888)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Play Solo (vs Bots)',
                          style: TextStyle(fontSize: 16, color: Color(0xFF888888)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
