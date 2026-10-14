class GoalCriterion {
  const GoalCriterion({
    required this.id,
    required this.label,
    required this.weight,
    required this.enabled,
  });

  final String id;
  final String label;
  final int weight;
  final bool enabled;
}

class CareerGoal {
  const CareerGoal({
    required this.id,
    required this.name,
    required this.deckIds,
    required this.criteria,
  });

  final String id;
  final String name;
  final List<String> deckIds;
  final List<GoalCriterion> criteria;
}

const dataBusinessCriteria = [
  GoalCriterion(id: 'flashcard', label: 'Flashcard', weight: 30, enabled: true),
  GoalCriterion(id: 'cv', label: 'CV Check', weight: 25, enabled: true),
  GoalCriterion(
    id: 'interview',
    label: 'Mock interview',
    weight: 20,
    enabled: false,
  ),
  GoalCriterion(id: 'contest', label: 'Cuộc thi', weight: 10, enabled: false),
  GoalCriterion(id: 'course', label: 'Khóa học', weight: 10, enabled: false),
  GoalCriterion(id: 'mentor', label: 'UEH Mentor', weight: 5, enabled: false),
];

const careerGoals = [
  CareerGoal(
    id: 'data-business-analyst',
    name: 'Data / Business Analyst',
    deckIds: [
      'skill-sql',
      'skill-power-bi',
      'skill-excel',
      'skill-python-data',
      'skill-requirements',
      'skill-process-modeling',
      'skill-business-frameworks',
      'skill-stakeholder-communication',
      'skill-jira-confluence',
      'skill-agile-scrum',
      'skill-figma-wireframe',
      'skill-interview',
      'skill-cv-email',
      'skill-english-jd',
    ],
    criteria: dataBusinessCriteria,
  ),
];

CareerGoal goalOf(String goalId) => careerGoals.firstWhere(
  (goal) => goal.id == goalId,
  orElse: () => careerGoals.first,
);

CareerGoal goalForStoredName(String? name) => careerGoals.firstWhere(
  (goal) => goal.name == name || goal.id == name,
  orElse: () => careerGoals.first,
);
