import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:diacritic/diacritic.dart';

import 'event_item.dart';

class TechEvent {
  const TechEvent({
    required this.id,
    required this.name,
    required this.category,
    required this.organizer,
    required this.timeline,
    required this.description,
    this.rawData = const {},
  });

  final String id;
  final String name;
  final String category;
  final String organizer;
  final String timeline;
  final String description;
  final Map<String, dynamic> rawData;

  factory TechEvent.fromDoc(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? const <String, dynamic>{};
    String text(String key) {
      final value = data[key];
      return value is String ? value.trim() : '';
    }

    return TechEvent(
      id: text('id').isNotEmpty ? text('id') : document.id,
      name: text('name').isNotEmpty ? text('name') : text('title'),
      category: text('category').isNotEmpty ? text('category') : text('type'),
      organizer: text('organizer'),
      timeline: text('timeline'),
      description: text('description'),
      rawData: Map.unmodifiable(data),
    );
  }

  EventItem toEventItem() => EventItem.fromFirestore(id, {
    ...rawData,
    'id': id,
    'name': name,
    'category': category,
    'organizer': organizer,
    'timeline': timeline,
    'description': description,
  });
}

enum TechEventGroup { hackathon, competition, workshop, program }

extension TechEventGroupPresentation on TechEventGroup {
  String get label => switch (this) {
    TechEventGroup.hackathon => 'Hackathon',
    TechEventGroup.competition => 'Cuộc thi',
    TechEventGroup.workshop => 'Workshop',
    TechEventGroup.program => 'Chương trình',
  };

  IconData get icon => switch (this) {
    TechEventGroup.hackathon => Icons.terminal_rounded,
    TechEventGroup.competition => Icons.emoji_events_rounded,
    TechEventGroup.workshop => Icons.handyman_rounded,
    TechEventGroup.program => Icons.rocket_launch_rounded,
  };

  List<Color> get colors => switch (this) {
    TechEventGroup.hackathon => const [Color(0xFF44336F), Color(0xFF241A43)],
    TechEventGroup.competition => const [Color(0xFF813D59), Color(0xFF46243F)],
    TechEventGroup.workshop => const [Color(0xFF315F8D), Color(0xFF1B345C)],
    TechEventGroup.program => const [Color(0xFF34704C), Color(0xFF1C3D3A)],
  };
}

TechEventGroup techEventGroup(String name, String category) {
  final value = removeDiacritics('$name $category').toLowerCase();
  if (value.contains('hackathon') || value.contains('game jam')) {
    return TechEventGroup.hackathon;
  }
  const competitions = [
    'cuoc thi',
    'contest',
    'challenge',
    'competition',
    'competitive',
    'cup',
    'league',
    'olympiad',
    'code war',
    'ctf',
    'grand prix',
    'battle',
  ];
  if (competitions.any(value.contains)) return TechEventGroup.competition;
  const programs = ['talent', 'career', 'startup', 'trainee', 'camp', 'fair'];
  if (programs.any(value.contains)) return TechEventGroup.program;
  return TechEventGroup.workshop;
}
