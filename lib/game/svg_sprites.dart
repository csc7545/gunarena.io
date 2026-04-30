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
  static const String groundKey = 'ground_concrete';

  static ui.Image image(String key) {
    final ui.Image? img = _imageMap[key];
    if (img == null) {
      throw StateError('SvgSprites not loaded or unknown key: $key');
    }
    return img;
  }

  static Future<void> loadAll() async {
    if (_loaded) return;

    for (final String key in tankIdleKeyList) {
      _imageMap[key] = await _rasterize('assets/svg/tank/$key.svg', tankPx);
    }
    for (final String key in tankAttackKeyList) {
      _imageMap[key] = await _rasterize('assets/svg/tank/$key.svg', tankPx);
    }
    for (final String key in tankDieKeyList) {
      _imageMap[key] = await _rasterize('assets/svg/tank/$key.svg', tankPx);
    }
    for (final String key in bulletKeyList) {
      _imageMap[key] = await _rasterize('assets/svg/bullet/$key.svg', bulletPx);
    }
    for (final String key in impactKeyList) {
      _imageMap[key] = await _rasterize('assets/svg/impact/$key.svg', impactPx);
    }
    for (final String key in wallKeyList) {
      _imageMap[key] = await _rasterize('assets/svg/wall/$key.svg', wallPx);
    }
    _imageMap[groundKey] =
        await _rasterize('assets/svg/ground/$groundKey.svg', groundPx);

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
