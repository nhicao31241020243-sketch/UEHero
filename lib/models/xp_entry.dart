enum XpBar { kienThuc, hoSo, thucChien }

extension XpBarStorage on XpBar {
  String get storageName => switch (this) {
    XpBar.kienThuc => 'kienThuc',
    XpBar.hoSo => 'hoSo',
    XpBar.thucChien => 'thucChien',
  };

  String get legacyName => switch (this) {
    XpBar.kienThuc => 'knowledge',
    XpBar.hoSo => 'profile',
    XpBar.thucChien => 'practice',
  };
}

class XpEntry {
  const XpEntry({
    required this.id,
    required this.user,
    required this.thanh,
    required this.luong,
    required this.nguon,
    required this.thoiGian,
    this.skill,
    this.sourceRef,
  });

  final String id;
  final String user;
  final XpBar thanh;
  final int luong;
  final String nguon;
  final DateTime thoiGian;
  final String? skill;
  final String? sourceRef;

  String get userId => user;
  String get bar => thanh.legacyName;
  int get amount => luong;
  String get source => nguon;
  DateTime get createdAt => thoiGian;

  Map<String, dynamic> toJson() => {
    'id': id,
    'user': user,
    'thanh': thanh.storageName,
    'luong': luong,
    'nguon': nguon,
    'thoiGian': thoiGian.toIso8601String(),
    if (skill != null) 'skill': skill,
    if (sourceRef != null) 'sourceRef': sourceRef,
  };

  factory XpEntry.fromJson(Map<String, dynamic> json) {
    final rawBar = json['thanh'] ?? json['bar'];
    final bar = switch (rawBar) {
      'kienThuc' || 'knowledge' => XpBar.kienThuc,
      'hoSo' || 'profile' => XpBar.hoSo,
      'thucChien' || 'practice' => XpBar.thucChien,
      _ => throw FormatException('Unknown XP bar: $rawBar'),
    };
    return XpEntry(
      id: json['id'] as String,
      user: json['user'] as String? ?? json['userId'] as String? ?? 'local',
      thanh: bar,
      luong: ((json['luong'] ?? json['amount']) as num).toInt(),
      nguon: (json['nguon'] ?? json['source']) as String,
      thoiGian: DateTime.parse(
        (json['thoiGian'] ?? json['createdAt']) as String,
      ),
      skill: json['skill'] as String?,
      sourceRef: json['sourceRef'] as String?,
    );
  }
}
