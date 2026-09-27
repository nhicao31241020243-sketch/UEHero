class GpaLabArt {
  const GpaLabArt._();

  static const String aiToken = 'assets/gpa_lab/3d/ai_token.png';

  static const String tiToken = 'assets/gpa_lab/3d/ti_token.png';

  static const String dockB = 'assets/gpa_lab/3d/dock_b.png';

  static const String dockBPlus = 'assets/gpa_lab/3d/dock_b_plus.png';

  static const String dockAMinus = 'assets/gpa_lab/3d/dock_a_minus.png';

  static const String dockA = 'assets/gpa_lab/3d/dock_a.png';

  static String tokenForCourse(String courseId) {
    switch (courseId) {
      case 'internship':
        return tiToken;

      case 'ai_project':
      default:
        return aiToken;
    }
  }

  static String dockForGrade(String gradeLabel) {
    switch (gradeLabel) {
      case 'B':
        return dockB;

      case 'B+':
        return dockBPlus;

      case 'A-':
        return dockAMinus;

      case 'A':
        return dockA;

      default:
        return dockB;
    }
  }
}
