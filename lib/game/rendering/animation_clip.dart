class AnimationClip {
  final List<String> keys;
  final double frameDuration;
  final bool loop;

  const AnimationClip({
    required this.keys,
    required this.frameDuration,
    this.loop = false,
  });

  double get totalDuration => frameDuration * keys.length;
}
