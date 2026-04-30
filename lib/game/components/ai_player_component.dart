import 'package:gun_arena_io/game/components/player_component.dart';
import 'package:gun_arena_io/game/input/ai_input_controller.dart';

/// Thin wrapper that attaches an [AiInputController] to a regular
/// [PlayerComponent]. Kept as its own class so existing call sites
/// (e.g. main.dart spawn loop) don't have to change.
class AiPlayerComponent extends PlayerComponent {
  AiPlayerComponent({
    required super.playerId,
    required super.position,
    required super.color,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await add(AiInputController());
  }
}
