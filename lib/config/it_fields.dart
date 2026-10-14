class ItField {
  const ItField({required this.id, required this.name});

  final String id;
  final String name;
}

const itFields = <ItField>[
  ItField(id: 'frontend', name: 'Frontend'),
  ItField(id: 'backend', name: 'Backend'),
  ItField(id: 'fullstack', name: 'Fullstack'),
  ItField(id: 'mobile', name: 'Mobile'),
  ItField(id: 'data_analyst', name: 'Data Analyst'),
  ItField(id: 'data_engineer', name: 'Data Engineer'),
  ItField(id: 'data_science_ai', name: 'Data Science / AI'),
  ItField(id: 'devops_cloud', name: 'DevOps / Cloud'),
  ItField(id: 'cybersecurity', name: 'An ninh mạng'),
  ItField(id: 'qa_testing', name: 'QA / Testing'),
  ItField(id: 'ui_ux', name: 'UI / UX'),
  ItField(id: 'product_manager', name: 'Product Manager'),
  ItField(id: 'business_analyst', name: 'Business Analyst'),
  ItField(id: 'project_manager', name: 'Project Manager'),
  ItField(id: 'game_dev', name: 'Game Development'),
  ItField(id: 'embedded_iot', name: 'Embedded / IoT'),
  ItField(id: 'erp_sap', name: 'ERP / SAP'),
];

const _goalFieldAliases = <String, String>{
  'business_analyst': 'business_analyst',
  'data_analyst': 'data_analyst',
  'frontend_developer': 'frontend',
  'frontend': 'frontend',
  'product_manager': 'product_manager',
  'backend_developer': 'backend',
  'fullstack_developer': 'fullstack',
  'mobile_developer': 'mobile',
  'data_engineer': 'data_engineer',
  'data_scientist': 'data_science_ai',
  'data_science_ai': 'data_science_ai',
  'devops_engineer': 'devops_cloud',
  'cloud_engineer': 'devops_cloud',
  'cybersecurity': 'cybersecurity',
  'qa_engineer': 'qa_testing',
  'ui_ux_designer': 'ui_ux',
  'project_manager': 'project_manager',
  'game_developer': 'game_dev',
  'embedded_engineer': 'embedded_iot',
  'erp_sap_consultant': 'erp_sap',
};

String? fieldIdForGoal(String? goalId) {
  final normalized = goalId
      ?.trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\s/-]+'), '_');
  if (normalized == null || normalized.isEmpty) return null;
  final direct = _goalFieldAliases[normalized];
  if (direct != null) return direct;
  for (final field in itFields) {
    if (field.id == normalized) return field.id;
  }
  for (final field in itFields) {
    if (field.name.toLowerCase().replaceAll(RegExp(r'[\s/-]+'), '_') ==
        normalized) {
      return field.id;
    }
  }
  return null;
}

String? itFieldName(String fieldId) {
  for (final field in itFields) {
    if (field.id == fieldId) return field.name;
  }
  return null;
}
