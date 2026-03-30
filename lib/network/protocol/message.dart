enum MessageType {
  input, // client -> host: joystick + fire input
  state, // host -> client: full game state at 20Hz
  kill, // host -> client: kill event
  end, // host -> client: game over
  start, // host -> client: game start with map seed
  join, // host -> client: player joined
  leave, // host -> client: player left
}

class GameMessage {
  final MessageType type;
  final Map<String, dynamic> data;

  const GameMessage({required this.type, required this.data});

  factory GameMessage.fromJson(Map<String, dynamic> json) {
    return GameMessage(
      type: MessageType.values.firstWhere((e) => e.name == json['t']),
      data: json,
    );
  }

  Map<String, dynamic> toJson() => data;

  // Factory constructors for each message type

  factory GameMessage.input({
    required double dx,
    required double dy,
    required bool firing,
    required bool reloading,
  }) {
    return GameMessage(
      type: MessageType.input,
      data: {'t': 'input', 'x': dx, 'y': dy, 'f': firing, 'r': reloading},
    );
  }

  factory GameMessage.state({
    required List<Map<String, dynamic>> playerList,
    required List<Map<String, dynamic>> bulletList,
  }) {
    return GameMessage(
      type: MessageType.state,
      data: {'t': 'state', 'p': playerList, 'b': bulletList},
    );
  }

  factory GameMessage.kill({
    required String killerId,
    required String victimId,
  }) {
    return GameMessage(
      type: MessageType.kill,
      data: {'t': 'kill', 'k': killerId, 'd': victimId},
    );
  }

  factory GameMessage.end({
    required String winnerId,
    required List<Map<String, dynamic>> scoreList,
  }) {
    return GameMessage(
      type: MessageType.end,
      data: {'t': 'end', 'w': winnerId, 's': scoreList},
    );
  }

  factory GameMessage.start({required int mapSeed}) {
    return GameMessage(
      type: MessageType.start,
      data: {'t': 'start', 'seed': mapSeed},
    );
  }

  factory GameMessage.join({required String playerId, required String name}) {
    return GameMessage(
      type: MessageType.join,
      data: {'t': 'join', 'id': playerId, 'name': name},
    );
  }

  factory GameMessage.leave({required String playerId}) {
    return GameMessage(
      type: MessageType.leave,
      data: {'t': 'leave', 'id': playerId},
    );
  }
}
