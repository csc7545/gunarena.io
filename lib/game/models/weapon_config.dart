class WeaponConfig {
  final int damage;
  final double fireRate;
  final double bulletSpeed;
  final double range;
  final int magazineSize;
  final double reloadTime;

  const WeaponConfig({
    required this.damage,
    required this.fireRate,
    required this.bulletSpeed,
    required this.range,
    required this.magazineSize,
    required this.reloadTime,
  });

  static const WeaponConfig ar = WeaponConfig(
    damage: 15,
    fireRate: 3.0,
    bulletSpeed: 400.0,
    range: 300.0,
    magazineSize: 30,
    reloadTime: 2.0,
  );
}
