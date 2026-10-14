enum JobWorkMode { onsite, hybrid, remote }

enum JobType { fulltime, parttime, internship }

enum JobApplicationStatus {
  saved('Đã lưu'),
  applied('Đã ứng tuyển'),
  interview('Phỏng vấn'),
  result('Kết quả');

  const JobApplicationStatus(this.label);

  final String label;

  static JobApplicationStatus fromName(String? name) =>
      JobApplicationStatus.values.firstWhere(
        (status) => status.name == name,
        orElse: () => JobApplicationStatus.saved,
      );
}

class JobSkillRequirement {
  const JobSkillRequirement({
    required this.skillKey,
    required this.label,
    required this.requiredLevel,
  });

  final String skillKey;
  final String label;
  final int requiredLevel;
}

class StudentJob {
  const StudentJob({
    required this.id,
    required this.title,
    required this.company,
    required this.fieldId,
    required this.requiredSkills,
    required this.salaryLabel,
    required this.salaryMin,
    required this.location,
    required this.workMode,
    required this.jobType,
    required this.postedAt,
    required this.description,
    required this.isDemo,
    this.applyUrl,
  });

  final String id;
  final String title;
  final String company;
  final String fieldId;
  final List<JobSkillRequirement> requiredSkills;
  final String salaryLabel;
  final double salaryMin;
  final String location;
  final JobWorkMode workMode;
  final JobType jobType;
  final DateTime postedAt;
  final String description;
  final String? applyUrl;
  final bool isDemo;

  String get logoLetter => company.isEmpty ? '?' : company[0].toUpperCase();
}

extension JobWorkModeLabel on JobWorkMode {
  String get label => switch (this) {
    JobWorkMode.onsite => 'Onsite',
    JobWorkMode.hybrid => 'Hybrid',
    JobWorkMode.remote => 'Remote',
  };
}

extension JobTypeLabel on JobType {
  String get label => switch (this) {
    JobType.fulltime => 'Toàn thời gian',
    JobType.parttime => 'Part-time',
    JobType.internship => 'Thực tập',
  };
}

class JobFilterState {
  const JobFilterState({
    this.query = '',
    this.jobTypes = const {},
    this.workModes = const {},
    this.fieldId,
    this.location = 'TP. Hồ Chí Minh',
    this.sort = 'newest',
  });

  final String query;
  final Set<JobType> jobTypes;
  final Set<JobWorkMode> workModes;
  final String? fieldId;
  final String location;
  final String sort;

  int get activeFilterCount =>
      jobTypes.length +
      workModes.length +
      (fieldId == null ? 0 : 1) +
      (location == 'Toàn quốc' ? 0 : 1);

  JobFilterState copyWith({
    String? query,
    Set<JobType>? jobTypes,
    Set<JobWorkMode>? workModes,
    String? fieldId,
    bool clearField = false,
    String? location,
    String? sort,
  }) => JobFilterState(
    query: query ?? this.query,
    jobTypes: jobTypes ?? this.jobTypes,
    workModes: workModes ?? this.workModes,
    fieldId: clearField ? null : fieldId ?? this.fieldId,
    location: location ?? this.location,
    sort: sort ?? this.sort,
  );

  JobFilterState clearFilters() => JobFilterState(
    query: query,
    location: 'Toàn quốc',
    sort: sort,
  );
}
