class EventItem {
  final String title;
  final String organizer;
  final String? image; // để trống (null) nếu chưa có ảnh — sẽ hiện placeholder
  final String tag;
  final int trainingPoints; // điểm rèn luyện được cộng khi tham gia
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