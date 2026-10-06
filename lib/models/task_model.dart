enum TaskType { mentee, exam, work }

class TaskModel {
  const TaskModel({
    required this.title,
    required this.time,
    required this.date,
    required this.type,
    this.isCompleted = false,
  });

  final String title;
  final String time;
  final DateTime date;
  final TaskType type;
  final bool isCompleted;

  TaskModel copyWith({bool? isCompleted}) => TaskModel(
    title: title,
    time: time,
    date: date,
    type: type,
    isCompleted: isCompleted ?? this.isCompleted,
  );
}
