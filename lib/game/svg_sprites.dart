import 'dart:ui' as ui;

import 'package:flutter_svg/flutter_svg.dart';

class SvgSprites {
  static final Map<String, ui.Image> _imageMap = {};
  static bool _loaded = false;

  static const int tankPx = 80;
  static const int bulletPx = 40;
  static const int impactPx = 40;
  static const int wallPx = 64;
  static const int groundPx = 64;

  static const List<String> tankIdleKeyList = ['tank_idle_1', 'tank_idle_2'];
  static const List<String> tankAttackKeyList = [
    'tank_attack_1',
    'tank_attack_2',
    'tank_attack_3',
  ];
  static const List<String> tankDieKeyList = [
    'tank_die_1',
    'tank_die_2',
    'tank_die_3',
  ];
  static const List<String> bulletKeyList = ['bullet_1', 'bullet_2'];
  static const List<String> impactKeyList = [
    'bullet_impact_1',
    'bullet_impact_2',
    'bullet_impact_3',
  ];
  static const List<String> wallKeyList = [
    'wall_concrete',
    'wall_sandbag',
    'wall_barrel',
    'wall_crate',
  ];
  // Variants safe for non-square (stretched) obstacles — drum is excluded
  // because its round silhouette deforms badly.
  static const List<String> wallNonRoundKeyList = [
    'wall_concrete',
    'wall_sandbag',
    'wall_crate',
  ];
  static const String groundKey = 'ground_concrete';

  static ui.Image image(String key) {
    final ui.Image? img = _imageMap[key];
    if (img == null) {
      throw StateError('SvgSprites not loaded or unknown key: $key');
    }
    return img;
  }

  /// Returns the current animation frame image for [keyList] given [elapsed]
  /// time and [frameDuration]. When [loop] is false, the index clamps to the
  /// last frame (useful for one-shot like attack/die). When true, it wraps.
  static ui.Image frameAt(
    List<String> keyList,
    double elapsed,
    double frameDuration, {
    bool loop = false,
  }) {
    final int raw = (elapsed / frameDuration).floor();
    final int idx =
        loop ? raw % keyList.length : raw.clamp(0, keyList.length - 1);
    return image(keyList[idx]);
  }

  static Future<void> loadAll() async {
    if (_loaded) return;

    final List<_LoadJob> jobList = <_LoadJob>[
      ...tankIdleKeyList.map((k) => _LoadJob(k, 'assets/svg/tank/$k.svg', tankPx)),
      ...tankAttackKeyList.map((k) => _LoadJob(k, 'assets/svg/tank/$k.svg', tankPx)),
      ...tankDieKeyList.map((k) => _LoadJob(k, 'assets/svg/tank/$k.svg', tankPx)),
      ...bulletKeyList.map((k) => _LoadJob(k, 'assets/svg/bullet/$k.svg', bulletPx)),
      ...impactKeyList.map((k) => _LoadJob(k, 'assets/svg/impact/$k.svg', impactPx)),
      ...wallKeyList.map((k) => _LoadJob(k, 'assets/svg/wall/$k.svg', wallPx)),
      _LoadJob(groundKey, 'assets/svg/ground/$groundKey.svg', groundPx),
    ];

    await Future.wait(jobList.map((job) async {
      _imageMap[job.key] = await _rasterize(job.path, job.sizePx);
    }));

    _loaded = true;
  }

  static Future<ui.Image> _rasterize(String assetPath, int sizePx) async {
    final SvgAssetLoader loader = SvgAssetLoader(assetPath);
    final PictureInfo info = await vg.loadPicture(loader, null);
    final ui.Picture picture = info.picture;
    try {
      final double srcW = info.size.width;
      final double srcH = info.size.height;
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder);
      canvas.scale(sizePx / srcW, sizePx / srcH);
      canvas.drawPicture(picture);
      final ui.Picture scaled = recorder.endRecording();
      final ui.Image image = await scaled.toImage(sizePx, sizePx);
      scaled.dispose();
      return image;
    } finally {
      picture.dispose();
    }
  }
}

class _LoadJob {
  final String key;
  final String path;
  final int sizePx;
  const _LoadJob(this.key, this.path, this.sizePx);
}
