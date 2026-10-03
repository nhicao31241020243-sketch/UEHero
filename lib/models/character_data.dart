import 'package:flutter/material.dart';

class CharacterData {
  const CharacterData({
    required this.id,
    required this.name,
    required this.description,
    required this.tags,
    required this.modelPath,
    required this.animationName,
    required this.group,
    required this.primaryColor,
    required this.emoji,
  });

  final String id;
  final String name;
  final String description;
  final List<String> tags;
  final String modelPath;
  final String animationName;
  final String group;
  final Color primaryColor;
  final String emoji;
}

class CharacterSelection {
  CharacterSelection._();

  static CharacterData? selected;
}

const List<CharacterData> characterData = [
  CharacterData(
    id: 'space-astronaut-rae',
    name: 'Phi Hành Gia Gấu Trúc',
    description: 'Rae dẫn đầu chuyến thám hiểm rìa Ngân Hà',
    tags: ['Phi hành gia', 'Khám phá vũ trụ'],
    modelPath: 'assets/3d/Space_Astronaut_RaeTheRedPanda.glb',
    animationName: 'Idle',
    group: 'blob',
    primaryColor: Color(0xFFD9D0F5),
    emoji: '👨‍🚀',
  ),
  CharacterData(
    id: 'space-astronaut-finn',
    name: 'Ếch Vũ Trụ Finn',
    description: 'Phi hành gia ếch nhảy xa giữa các tiểu hành tinh',
    tags: ['Trạm không gian', 'Nhà du hành'],
    modelPath: 'assets/3d/Space_Astronaut_FinnTheFrog.glb',
    animationName: 'Idle',
    group: 'blob',
    primaryColor: Color(0xFFC9E8D4),
    emoji: '🚀',
  ),
  CharacterData(
    id: 'space-astronaut-fernando',
    name: 'Hồng Hạc Du Hành',
    description: 'Fernando lướt qua tinh vân trên đôi cánh hồng',
    tags: ['Phi hành gia', 'Tinh vân xa xôi'],
    modelPath: 'assets/3d/Space_Astronaut_FernandoTheFlamingo.glb',
    animationName: 'Idle',
    group: 'blob',
    primaryColor: Color(0xFFF3D1E1),
    emoji: '🌌',
  ),
  CharacterData(
    id: 'space-astronaut-barbara',
    name: 'Ong Phi Hành',
    description: 'Barbara chăm chỉ khám phá những thế giới mới',
    tags: ['Galaxy', 'Phi hành gia ong'],
    modelPath: 'assets/3d/Space_Astronaut_BarbaraTheBee.glb',
    animationName: 'Idle',
    group: 'blob',
    primaryColor: Color(0xFFF7E5B8),
    emoji: '🛸',
  ),
  CharacterData(
    id: 'space-mech-rae',
    name: 'Space Mech Gấu Trúc',
    description: 'Bộ giáp cơ khí tối tân của thuyền trưởng Rae',
    tags: ['Robot chiến đấu', 'Trạm không gian'],
    modelPath: 'assets/3d/Space_Mech_RaeTheRedPanda.glb',
    animationName: 'Idle',
    group: 'blob',
    primaryColor: Color(0xFFC9D9F4),
    emoji: '🤖',
  ),
  CharacterData(
    id: 'space-mech-finn',
    name: 'Space Mech Ếch Xanh',
    description: 'Cỗ máy nhảy liên hành tinh của Finn',
    tags: ['Mech phi hành', 'Tuần tra quỹ đạo'],
    modelPath: 'assets/3d/Space_Mech_FinnTheFrog.glb',
    animationName: 'Idle',
    group: 'blob',
    primaryColor: Color(0xFFD5E9C8),
    emoji: '🪐',
  ),
  CharacterData(
    id: 'space-mech-fernando',
    name: 'Mech Hồng Hạc',
    description: 'Robot bay thanh thoát bảo vệ đội thám hiểm',
    tags: ['Giáp cơ khí', 'Bay xuyên thiên hà'],
    modelPath: 'assets/3d/Space_Mech_FernandoTheFlamingo.glb',
    animationName: 'Idle',
    group: 'blob',
    primaryColor: Color(0xFFF1D5E9),
    emoji: '🚀',
  ),
  CharacterData(
    id: 'space-mech-barbara',
    name: 'Robot Chiến Tạm Space Mech',
    description: 'Mech ong bọc thép sẵn sàng bảo vệ phi hành đoàn',
    tags: ['Robot chiến đấu', 'Bảo vệ phi hành đoàn'],
    modelPath: 'assets/3d/Space_Mech_BarbaraTheBee.glb',
    animationName: 'Idle',
    group: 'blob',
    primaryColor: Color(0xFFECE0B9),
    emoji: '🤖',
  ),
  CharacterData(
    id: 'space-enemy-extrasmall',
    name: 'UFO Tí Hon',
    description: 'Sinh vật bay bé xíu lén lút quanh trạm vũ trụ',
    tags: ['Sinh vật ngoài hành tinh', 'Bay quanh quỹ đạo'],
    modelPath: 'assets/3d/Space_Enemy_ExtraSmall.glb',
    animationName: 'Flying_Idle',
    group: 'blob',
    primaryColor: Color(0xFFD4E9F3),
    emoji: '🛸',
  ),
  CharacterData(
    id: 'space-enemy-small',
    name: 'Vệ Binh Sao Băng',
    description: 'Kẻ canh gác nhỏ nhanh nhẹn của vành đai thiên thạch',
    tags: ['Tuần tra thiên hà', 'Tốc độ ánh sáng'],
    modelPath: 'assets/3d/Space_Enemy_Small.glb',
    animationName: 'Flying_Idle',
    group: 'blob',
    primaryColor: Color(0xFFE0D8F2),
    emoji: '🌠',
  ),
  CharacterData(
    id: 'space-enemy-flying',
    name: 'Quái Bay Tinh Vân',
    description: 'Sinh vật bí ẩn lượn giữa những đám mây sao',
    tags: ['Quái vật vũ trụ', 'Ẩn mình trong tinh vân'],
    modelPath: 'assets/3d/Space_Enemy_Flying.glb',
    animationName: 'Flying_Idle',
    group: 'blob',
    primaryColor: Color(0xFFC6E5E9),
    emoji: '🌌',
  ),
  CharacterData(
    id: 'space-enemy-large',
    name: 'Khổng Lồ Hố Đen',
    description: 'Vệ thần khổng lồ canh giữ cổng không gian',
    tags: ['Boss thiên hà', 'Sức mạnh hố đen'],
    modelPath: 'assets/3d/Space_Enemy_Large.glb',
    animationName: 'Idle',
    group: 'blob',
    primaryColor: Color(0xFFD5D2E8),
    emoji: '🌑',
  ),
];
