const Map<String, String> flashcardSkillMap = {
  'skill-sql': 'sql',
  'skill-power-bi': 'power_bi',
  'skill-excel': 'excel',
  'skill-python-data': 'python',
  'skill-jira-confluence': 'jira_confluence',
  'skill-figma-wireframe': 'figma_wireframe',
  'skill-requirements': 'requirements',
  'skill-process-modeling': 'process_modeling',
  'skill-business-frameworks': 'business_frameworks',
  'skill-agile-scrum': 'agile_scrum',
  'skill-stakeholder-communication': 'stakeholder_communication',
  'skill-interview': 'interview',
  'skill-cv-email': 'cv_email',
  'skill-english-jd': 'english_jd',
};

String? skillForDeck(String deckId) => flashcardSkillMap[deckId];
