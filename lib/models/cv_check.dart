enum CvIssueSeverity { heavy, warning, suggestion }

enum CvIssueKind {
  missingSection,
  missingSkill,
  noAchievementMetric,
  weakActionVerb,
  vagueObjective,
  longLine,
}

class CvCheckJob {
  const CvCheckJob({
    required this.title,
    required this.company,
    required this.requirements,
  });

  final String title;
  final String company;
  final List<String> requirements;

  String get label => '$title · $company';
}

class CvIssue {
  const CvIssue({
    required this.lineIndex,
    required this.startOffset,
    required this.endOffset,
    required this.kind,
    required this.severity,
    required this.title,
    required this.explanation,
    required this.fix,
    required this.before,
    required this.after,
    this.skill,
  });

  final int lineIndex;
  final int startOffset;
  final int endOffset;
  final CvIssueKind kind;
  final CvIssueSeverity severity;
  final String title;
  final String explanation;
  final String fix;
  final String before;
  final String after;
  final String? skill;
}

class CvAnalysis {
  const CvAnalysis({
    required this.score,
    required this.matchedKeywords,
    required this.missingKeywords,
    required this.issues,
    required this.jobMatchCount,
    required this.jobRequirementCount,
    required this.suggestions,
  });

  final int score;
  final List<String> matchedKeywords;
  final List<String> missingKeywords;
  final List<CvIssue> issues;
  final int jobMatchCount;
  final int jobRequirementCount;
  final List<String> suggestions;

  int get heavyCount =>
      issues.where((issue) => issue.severity == CvIssueSeverity.heavy).length;

  int get warningCount =>
      issues.where((issue) => issue.severity == CvIssueSeverity.warning).length;
}

const sampleCvJobs = <CvCheckJob>[
  CvCheckJob(
    title: 'Business Analyst Intern',
    company: 'UEH Career Hub',
    requirements: ['SQL', 'Excel', 'Power BI', 'phân tích', 'giao tiếp'],
  ),
  CvCheckJob(
    title: 'Data Analyst Intern',
    company: 'UEH Career Hub',
    requirements: ['SQL', 'Python', 'Excel', 'Power BI', 'thống kê'],
  ),
  CvCheckJob(
    title: 'Frontend Developer Intern',
    company: 'UEH Career Hub',
    requirements: ['HTML', 'CSS', 'JavaScript', 'Git', 'responsive'],
  ),
  CvCheckJob(
    title: 'Digital Marketing Intern',
    company: 'UEH Career Hub',
    requirements: ['SEO', 'content', 'social media', 'analytics', 'quảng cáo'],
  ),
  CvCheckJob(
    title: 'E-commerce Specialist',
    company: 'UEH Career Hub',
    requirements: ['sàn thương mại điện tử', 'Excel', 'đơn hàng', 'bán hàng'],
  ),
  CvCheckJob(
    title: 'Associate Product Manager',
    company: 'UEH Career Hub',
    requirements: ['product', 'Agile', 'roadmap', 'nghiên cứu người dùng'],
  ),
];
