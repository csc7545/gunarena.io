import 'package:equatable/equatable.dart';

class PlayerState extends Equatable {
  final String id;
  final String name;
  final double x;
  final double y;
  final int hp;
  final int maxHp;
  final int kills;
  final int deaths;
  final bool alive;
  final int ammo;
  final int maxAmmo;

  const PlayerState({
    required this.id,
    required this.name,
    this.x = 0,
    this.y = 0,
    this.hp = 100,
    this.maxHp = 100,
    this.kills = 0,
    this.deaths = 0,
    this.alive = true,
    this.ammo = 30,
    this.maxAmmo = 30,
  });

  PlayerState copyWith({
    double? x,
    double? y,
    int? hp,
    int? kills,
    int? deaths,
    bool? alive,
    int? ammo,
  }) {
    return PlayerState(
      id: id,
      name: name,
      x: x ?? this.x,
      y: y ?? this.y,
      hp: hp ?? this.hp,
      maxHp: maxHp,
      kills: kills ?? this.kills,
      deaths: deaths ?? this.deaths,
      alive: alive ?? this.alive,
      ammo: ammo ?? this.ammo,
      maxAmmo: maxAmmo,
    );
  }

  @override
  List<Object?> get props => [id, name, x, y, hp, kills, deaths, alive, ammo];
}
