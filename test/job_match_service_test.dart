import 'package:flutter_test/flutter_test.dart';
import 'package:uehero/data/job_demo_data.dart';
import 'package:uehero/models/student_job.dart';
import 'package:uehero/services/job_match_service.dart';

StudentJob _job({
  String id = 'test-job',
  String fieldId = 'software-engineering',
  String location = 'TP. Hồ Chí Minh',
  JobType type = JobType.fulltime,
  JobWorkMode mode = JobWorkMode.hybrid,
  double salary = 10,
  int hoursAgo = 0,
  List<JobSkillRequirement>? skills,
}) => StudentJob(
  id: id,
  title: 'Lập trình viên',
  company: 'Công ty Mẫu',
  fieldId: fieldId,
  requiredSkills:
      skills ??
      const [
        JobSkillRequirement(
          skillKey: 'skill-sql',
          label: 'SQL',
          requiredLevel: 5,
        ),
      ],
  salaryLabel: '$salary triệu/tháng',
  salaryMin: salary,
  location: location,
  workMode: mode,
  jobType: type,
  postedAt: DateTime(2026, 10, 14).subtract(Duration(hours: hoursAgo)),
  description: 'Mô tả vị trí công việc mẫu.',
  isDemo: true,
);

void main() {
  group('JobMatchService', () {
    test('averages capped skill ratios', () {
      final service = JobMatchService(
        levelForSkill: (skill) => {'sql': 10, 'excel': 2}[skill] ?? 0,
      );
      final job = _job(
        skills: const [
          JobSkillRequirement(
            skillKey: 'skill-sql',
            label: 'SQL',
            requiredLevel: 5,
          ),
          JobSkillRequirement(
            skillKey: 'skill-excel',
            label: 'Excel',
            requiredLevel: 4,
          ),
        ],
      );

      expect(service.matchPercent(job), 75);
    });

    test('returns null when the job has no required skills', () {
      final service = JobMatchService(levelForSkill: (_) => 10);
      expect(service.matchPercent(_job(skills: const [])), isNull);
      expect(service.matchLabel(null), isNull);
    });

    test('returns up to three least-proficient missing skills', () {
      final service = JobMatchService(
        levelForSkill: (skill) =>
            {
              'sql': 0,
              'excel': 1,
              'python': 2,
              'power_bi': 3,
              'jira_confluence': 4,
            }[skill] ??
            0,
      );
      final job = _job(
        skills: const [
          JobSkillRequirement(
            skillKey: 'skill-sql',
            label: 'SQL',
            requiredLevel: 5,
          ),
          JobSkillRequirement(
            skillKey: 'skill-excel',
            label: 'Excel',
            requiredLevel: 5,
          ),
          JobSkillRequirement(
            skillKey: 'skill-python-data',
            label: 'Python',
            requiredLevel: 5,
          ),
          JobSkillRequirement(
            skillKey: 'skill-power-bi',
            label: 'Power BI',
            requiredLevel: 5,
          ),
          JobSkillRequirement(
            skillKey: 'skill-jira-confluence',
            label: 'Jira',
            requiredLevel: 5,
          ),
        ],
      );

      expect(service.missingSkills(job), ['SQL', 'Excel', 'Python']);
    });

    test('labels use the requested thresholds', () {
      final service = JobMatchService(levelForSkill: (_) => 0);
      expect(service.matchLabel(70), 'Rất hợp');
      expect(service.matchLabel(69.99), 'Khá hợp');
      expect(service.matchLabel(40), 'Khá hợp');
      expect(service.matchLabel(39.99), 'Cần bổ sung');
    });
  });

  group('filterAndSortJobs', () {
    final jobs = [
      _job(id: 'older-hcm', salary: 12, hoursAgo: 24),
      _job(
        id: 'new-hanoi',
        location: 'Hà Nội',
        fieldId: 'data-analytics',
        type: JobType.internship,
        mode: JobWorkMode.remote,
        salary: 18,
        hoursAgo: 2,
      ),
      _job(
        id: 'mid-hcm-parttime',
        type: JobType.parttime,
        salary: 22,
        hoursAgo: 7,
      ),
    ];
    final match = {
      'older-hcm': 50.0,
      'new-hanoi': 90.0,
      'mid-hcm-parttime': 30.0,
    };

    test('filters by chip, field, location and search text', () {
      final filtered = filterAndSortJobs(
        jobs,
        const JobFilterState(
          query: 'lap trinh',
          jobTypes: {JobType.internship},
          workModes: {JobWorkMode.remote},
          fieldId: 'data-analytics',
          location: 'Hà Nội',
        ),
        matchPercent: (job) => match[job.id],
      );
      expect(filtered.map((job) => job.id), ['new-hanoi']);
    });

    test('sorts by newest, match, and salary', () {
      List<String> ids(String sort) => filterAndSortJobs(
        jobs,
        JobFilterState(location: 'Toàn quốc', sort: sort),
        matchPercent: (job) => match[job.id],
      ).map((job) => job.id).toList();

      expect(ids('newest'), ['new-hanoi', 'mid-hcm-parttime', 'older-hcm']);
      expect(ids('match'), ['new-hanoi', 'older-hcm', 'mid-hcm-parttime']);
      expect(ids('salary'), ['mid-hcm-parttime', 'new-hanoi', 'older-hcm']);
    });

    test('returns an empty list when filters exclude every job', () {
      expect(
        filterAndSortJobs(
          jobs,
          const JobFilterState(fieldId: 'missing', location: 'Toàn quốc'),
          matchPercent: (_) => null,
        ),
        isEmpty,
      );
    });

    test('ships 24 demo jobs across at least twelve fields', () {
      expect(jobDemoData, hasLength(91));
      expect(jobDemoData.map((job) => job.fieldId).toSet(), hasLength(15));
      expect(jobDemoData.every((job) => job.isDemo), isTrue);
      expect(
        jobDemoData.every(
          (job) => job.requiredSkills.every(
            (skill) => {
              'skill-sql',
              'skill-power-bi',
              'skill-excel',
              'skill-python-data',
              'skill-jira-confluence',
              'skill-figma-wireframe',
              'skill-requirements',
              'skill-process-modeling',
              'skill-business-frameworks',
              'skill-agile-scrum',
              'skill-stakeholder-communication',
              'skill-interview',
              'skill-cv-email',
              'skill-english-jd',
            }.contains(skill.skillKey),
          ),
        ),
        isTrue,
      );
    });
  });
}
