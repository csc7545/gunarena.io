import 'package:flame/components.dart';
import 'package:gun_arena_io/game/components/player_component.dart';
import 'package:gun_arena_io/game/input/command.dart';

/// Receives input from keyboard / joystick / on-screen overlays via the
/// game and forwards it to the parent player as Commands.
///
/// Move command is a single mutable instance reused every event to keep
/// allocation off the hot path.
class LocalInputController extends Component {
  final MoveCommand _moveCmd = MoveCommand();
  static const FireCommand _fireCmd = FireCommand();
  static const ReloadCommand _reloadCmd = ReloadCommand();

  PlayerComponent get _player => parent! as PlayerComponent;

  void setMove(double dx, double dy) {
    _moveCmd.set(dx, dy);
    _moveCmd.execute(_player);
  }

  void fire() => _fireCmd.execute(_player);

  void reload() => _reloadCmd.execute(_player);
}
