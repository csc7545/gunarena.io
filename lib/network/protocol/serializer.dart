import 'dart:convert';
import 'package:gun_arena_io/network/protocol/message.dart';

class MessageSerializer {
  static String encode(GameMessage message) {
    return jsonEncode(message.toJson());
  }

  static GameMessage decode(String raw) {
    final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
    return GameMessage.fromJson(json);
  }
}
