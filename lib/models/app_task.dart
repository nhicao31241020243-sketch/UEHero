import 'xp_entry.dart';

enum TaskStatus { pending, completed }

class AppTask {
  const AppTask({
    required this.id,
    required this.nguon,
    required this.noiDung,
    required this.trangThai,
    this.han,
    this.thanh,
    this.luongXp,
    this.coGio = false,
    this.isDemo = false,
  }) : assert(
         (thanh == null && luongXp == null) ||
             (thanh != null && luongXp != null && luongXp > 0),
       );

  final String id;
  final String nguon;
  final String noiDung;
  final DateTime? han;
  final TaskStatus trangThai;
  final XpBar? thanh;
  final int? luongXp;
  final bool coGio;
  final bool isDemo;

  bool get hasXp => thanh != null && luongXp != null;

  AppTask copyWith({TaskStatus? trangThai}) => AppTask(
    id: id,
    nguon: nguon,
    noiDung: noiDung,
    han: han,
    trangThai: trangThai ?? this.trangThai,
    thanh: thanh,
    luongXp: luongXp,
    coGio: coGio,
    isDemo: isDemo,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'nguon': nguon,
    'noiDung': noiDung,
    'han': han?.toIso8601String(),
    'trangThai': trangThai.name,
    'thanh': thanh?.storageName,
    'luongXp': luongXp,
    'coGio': coGio,
    'isDemo': isDemo,
  };

  factory AppTask.fromJson(Map<String, dynamic> json) => AppTask(
    id: json['id'] as String,
    nguon: json['nguon'] as String,
    noiDung: json['noiDung'] as String,
    han: json['han'] == null ? null : DateTime.parse(json['han'] as String),
    trangThai: TaskStatus.values.byName(json['trangThai'] as String),
    thanh: json['thanh'] == null
        ? null
        : XpBar.values.byName(json['thanh'] as String),
    luongXp: (json['luongXp'] as num?)?.toInt(),
    coGio: json['coGio'] as bool? ?? false,
    isDemo: json['isDemo'] as bool? ?? false,
  );
}
