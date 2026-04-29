import 'package:equatable/equatable.dart';

class RoomPlayer {
  final String id;
  final String name;
  final bool ready;

  const RoomPlayer({required this.id, required this.name, this.ready = false});
}

abstract class RoomState extends Equatable {
  const RoomState();
}

class RoomInitial extends RoomState {
  @override
  List<Object?> get props => [];
}

class RoomCreating extends RoomState {
  @override
  List<Object?> get props => [];
}

class RoomWaiting extends RoomState {
  final String roomId;
  final bool isHost;
  final List<RoomPlayer> playerList;

  const RoomWaiting({
    required this.roomId,
    required this.isHost,
    required this.playerList,
  });

  @override
  List<Object?> get props => [roomId, isHost, playerList];
}

class RoomStarting extends RoomState {
  final String roomId;
  final bool isHost;
  final int mapSeed;

  const RoomStarting({
    required this.roomId,
    required this.isHost,
    required this.mapSeed,
  });

  @override
  List<Object?> get props => [roomId, isHost, mapSeed];
}

class RoomError extends RoomState {
  final String message;

  const RoomError(this.message);

  @override
  List<Object?> get props => [message];
}
