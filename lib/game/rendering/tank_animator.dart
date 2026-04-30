import 'dart:ui' as ui;

import 'package:gun_arena_io/game/rendering/animation_clip.dart';
import 'package:gun_arena_io/game/rendering/animator.dart';
import 'package:gun_arena_io/game/svg_sprites.dart';

enum _TankAnimState { idle, attacking, dying }

class TankAnimator {
  static final AnimationClip _idleClip = AnimationClip(
    keys: SvgSprites.tankIdleKeyList,
    frameDuration: 0.4,
    loop: true,
  );
  static final AnimationClip _attackClip = AnimationClip(
    keys: SvgSprites.tankAttackKeyList,
    frameDuration: 0.04,
  );
  static final AnimationClip _dieClip = AnimationClip(
    keys: SvgSprites.tankDieKeyList,
    frameDuration: 0.2,
  );

  final Animator _animator = Animator()..play(_idleClip);
  _TankAnimState _state = _TankAnimState.idle;
  int _lastSeenAttackCounter = 0;

  /// Drive the animator from observed parent state. No state copy:
  /// only `alive` and `attackCounter` are read; everything else (current
  /// clip, elapsed time, "are we attacking now") lives inside the animator.
  void update(
    double dt, {
    required bool alive,
    required int attackCounter,
  }) {
    if (!alive) {
      if (_state != _TankAnimState.dying) {
        _state = _TankAnimState.dying;
        _animator.play(_dieClip);
      }
    } else {
      // Self-detect respawn: alive flipped back to true while dying.
      if (_state == _TankAnimState.dying) {
        _state = _TankAnimState.idle;
        _lastSeenAttackCounter = attackCounter;
        _animator.play(_idleClip);
      } else if (attackCounter != _lastSeenAttackCounter) {
        _lastSeenAttackCounter = attackCounter;
        _state = _TankAnimState.attacking;
        _animator.play(_attackClip);
      } else if (_state == _TankAnimState.attacking && _animator.isDone) {
        _state = _TankAnimState.idle;
        _animator.play(_idleClip);
      }
    }
    _animator.tick(dt);
  }

  ui.Image? get frame => _animator.frame;
}
