class EventItem {
  final String title;
  final String organizer;
  final String? image;
  final String tag;
  final int trainingPoints;
  final String description;

  const EventItem({
    required this.title,
    required this.organizer,
    this.image,
    required this.tag,
    required this.trainingPoints,
    this.description = '',
  });
}
