import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gun_arena_io/application/room/room_state.dart';
import 'package:gun_arena_io/network/signaling/firebase_signaling.dart';

class RoomCubit extends Cubit<RoomState> {
  final FirebaseSignaling signaling;
  StreamSubscription<dynamic>? _playerSubscription;
  StreamSubscription<dynamic>? _roomSubscription;

  RoomCubit({required this.signaling}) : super(RoomInitial());

  String _generatePlayerId() {
    const String chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final Random random = Random();
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> createRoom(String playerName) async {
    emit(RoomCreating());

    try {
      final String playerId = _generatePlayerId();
      final String roomId = await signaling.createRoom(
        hostId: playerId,
        hostName: playerName,
      );

      _listenToPlayers(roomId, true);
      _listenToRoom();
    } catch (e) {
      emit(RoomError('Failed to create room: $e'));
    }
  }

  Future<void> joinRoom(String roomId, String playerName) async {
    emit(RoomCreating());

    try {
      final String playerId = _generatePlayerId();
      final int playerCount = await signaling.getPlayerCount();

      if (playerCount >= 4) {
        emit(const RoomError('Room is full (max 4 players)'));
        return;
      }

      await signaling.joinRoom(
        roomId: roomId,
        playerId: playerId,
        playerName: playerName,
      );

      _listenToPlayers(roomId, false);
      _listenToRoom();
    } catch (e) {
      emit(RoomError('Failed to join room: $e'));
    }
  }

  void _listenToPlayers(String roomId, bool isHost) {
    _playerSubscription = signaling.onPlayersChanged((List<Map<String, dynamic>> playerList) {
      final List<RoomPlayer> roomPlayerList = playerList
          .map((Map<String, dynamic> p) => RoomPlayer(
                id: p['id'] as String,
                name: p['name'] as String,
                ready: p['ready'] as bool? ?? false,
              ))
          .toList();

      emit(RoomWaiting(
        roomId: roomId,
        isHost: isHost,
        playerList: roomPlayerList,
      ));
    });
  }

  void _listenToRoom() {
    _roomSubscription = signaling.onRoomChanged((Map<String, dynamic>? data) {
      if (data == null) return;
      final String status = data['status'] as String? ?? 'waiting';

      if (status == 'playing') {
        final RoomState currentState = state;
        if (currentState is RoomWaiting) {
          final int mapSeed = (data['mapSeed'] as num?)?.toInt() ?? 0;
          emit(RoomStarting(
            roomId: currentState.roomId,
            isHost: currentState.isHost,
            mapSeed: mapSeed,
          ));
        }
      }
    });
  }

  Future<void> startGame() async {
    final int seed = Random().nextInt(999999);
    await signaling.updateRoomStatus('playing', mapSeed: seed);
  }

  Future<void> leaveRoom() async {
    _playerSubscription?.cancel();
    _roomSubscription?.cancel();
    await signaling.leaveRoom();
    signaling.dispose();
    emit(RoomInitial());
  }

  @override
  Future<void> close() async {
    _playerSubscription?.cancel();
    _roomSubscription?.cancel();
    signaling.dispose();
    return super.close();
  }
}
