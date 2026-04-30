import 'dart:ui' as ui;

import 'package:gun_arena_io/game/rendering/animation_clip.dart';
import 'package:gun_arena_io/game/svg_sprites.dart';

class Animator {
  AnimationClip? _current;
  double _elapsed = 0;

  AnimationClip? get current => _current;

  void play(AnimationClip clip) {
    _current = clip;
    _elapsed = 0;
  }

  void tick(double dt) {
    if (_current == null) return;
    _elapsed += dt;
    if (!_current!.loop && _elapsed > _current!.totalDuration) {
      _elapsed = _current!.totalDuration;
    }
  }

  bool get isDone {
    final AnimationClip? c = _current;
    if (c == null || c.loop) return false;
    return _elapsed >= c.totalDuration;
  }

  ui.Image? get frame {
    final AnimationClip? c = _current;
    if (c == null) return null;
    return SvgSprites.frameAt(c.keys, _elapsed, c.frameDuration, loop: c.loop);
  }
}
