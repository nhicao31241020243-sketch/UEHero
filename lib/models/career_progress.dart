enum ProgressEventType {
  flashcardCompleted,
  skillDrillCompleted,
  cvFirstCheck,
  cvScoreImproved,
  weeklyTaskCompleted,
  mockInterviewCompleted,
  jobApplied,
  mentorBooked,
  mentorCompleted,
  eventRegistered,
  eventCheckedIn,
  gpaUpdated,
  profileCompleted,
  debugGrant,
}

class ProgressLedgerEntry {
  const ProgressLedgerEntry({
    required this.eventType,
    required this.points,
    required this.timestamp,
    this.refId,
    this.metadata = const {},
  });

  final ProgressEventType eventType;
  final int points;
  final DateTime timestamp;
  final String? refId;
  final Map<String, Object?> metadata;

  Map<String, Object?> toJson() => {
        'eventType': eventType.name,
        'points': points,
        'timestamp': timestamp.toIso8601String(),
        if (refId != null) 'refId': refId,
        'metadata': metadata,
      };

  factory ProgressLedgerEntry.fromJson(Map<String, dynamic> json) {
    final eventType = ProgressEventType.values.byName(
      json['eventType'] as String,
    );
    final rawMetadata = json['metadata'];
    return ProgressLedgerEntry(
      eventType: eventType,
      points: (json['points'] as num).toInt(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      refId: json['refId'] as String?,
      metadata: rawMetadata is Map
          ? Map<String, Object?>.from(rawMetadata)
          : const {},
    );
  }
}
