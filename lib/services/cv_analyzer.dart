import '../models/career_goal.dart';
import '../models/cv_check.dart';

class CvAnalyzer {
  const CvAnalyzer();

  static String normalizeForMatching(String value) =>
      const CvAnalyzer()._normalize(value);

  static const _keywordsByCareer = <String, List<List<String>>>{
    'Business Analyst': [
      ['sql'],
      ['power bi', 'tableau', 'looker'],
      ['excel', 'spreadsheet'],
      ['phan tich', 'analytical', 'analysis'],
      ['yeu cau', 'requirement', 'brd', 'user story'],
      ['quy trinh', 'process', 'bpmn'],
      ['stakeholder', 'lien quan'],
      ['bao cao', 'report', 'dashboard'],
      ['giao tiep', 'communication'],
      ['uml', 'srs', 'document'],
    ],
    'Data Analyst': [
      ['sql'],
      ['python'],
      ['excel'],
      ['power bi', 'tableau', 'looker'],
      ['thong ke', 'statistics'],
      ['phan tich du lieu', 'data analysis'],
      ['truc quan', 'visualization'],
      ['dashboard', 'bao cao', 'report'],
      ['pandas', 'numpy'],
      ['cleaning', 'lam sach du lieu'],
    ],
    'Frontend Developer': [
      ['html'],
      ['css'],
      ['javascript'],
      ['react', 'vue', 'angular'],
      ['responsive'],
      ['git'],
      ['api', 'rest'],
      ['flutter'],
      ['ui', 'ux'],
      ['testing', 'kiem thu'],
    ],
    'Digital Marketing': [
      ['seo'],
      ['content', 'noi dung'],
      ['social media', 'mang xa hoi'],
      ['google analytics', 'analytics'],
      ['ads', 'quang cao'],
      ['campaign', 'chien dich'],
      ['email marketing'],
      ['conversion', 'chuyen doi'],
      ['branding', 'thuong hieu'],
      ['keyword', 'tu khoa'],
    ],
    'E-commerce Specialist': [
      ['e-commerce', 'ecommerce', 'thuong mai dien tu', 'tm dt'],
      ['shopee', 'lazada', 'tiktok shop', 'sendo'],
      ['excel'],
      ['order', 'don hang'],
      ['inventory', 'ton kho'],
      ['sales', 'ban hang'],
      ['customer service', 'cham soc khach hang'],
      ['digital marketing', 'marketing'],
      ['conversion', 'chuyen doi'],
      ['analytics', 'phan tich'],
    ],
    'Product Manager': [
      ['product', 'san pham'],
      ['agile', 'scrum'],
      ['roadmap'],
      ['user research', 'nghien cuu nguoi dung'],
      ['product thinking'],
      ['stakeholder', 'lien quan'],
      ['metrics', 'chi so'],
      ['analytics', 'phan tich du lieu'],
      ['prioritization', 'uu tien'],
      ['user story', 'requirement', 'yeu cau'],
    ],
  };

  CvAnalysis analyze({
    required String text,
    required CareerGoal career,
    CvCheckJob? job,
  }) {
    final lines = text.split('\n');
    final normalizedText = _normalize(text);
    final careerKeywordGroups =
        _keywordsByCareer[career.title] ?? _keywordsByCareer.values.first;
    final matchedKeywords = <String>[];
    for (final group in careerKeywordGroups) {
      final match = group.where((variant) {
        final normalized = _normalize(variant);
        return normalizedText.contains(normalized);
      });
      if (match.isNotEmpty) {
        matchedKeywords.add(group.first);
      }
    }

    final requiredSkills =
        job?.requirements ?? career.skills.map((skill) => skill.name).toList();
    final matchedRequirements = requiredSkills
        .where((skill) => normalizedText.contains(_normalize(skill)))
        .toList(growable: false);
    final missingRequirements = requiredSkills
        .where((skill) => !normalizedText.contains(_normalize(skill)))
        .toList(growable: false);

    final issues = <CvIssue>[];
    var offset = 0;
    var inExperienceSection = false;
    var inObjectiveSection = false;
    final sectionPresence = <String, bool>{
      'Học vấn': false,
      'Kinh nghiệm / Dự án': false,
      'Kỹ năng': false,
      'Liên hệ': false,
    };

    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      final normalizedLine = _normalize(line);
      if (_containsAny(normalizedLine, ['hoc van', 'education', 'academic'])) {
        sectionPresence['Học vấn'] = true;
      }
      if (_containsAny(normalizedLine, [
        'kinh nghiem',
        'experience',
        'du an',
        'project',
      ])) {
        sectionPresence['Kinh nghiệm / Dự án'] = true;
      }
      if (_containsAny(normalizedLine, ['ky nang', 'skills', 'competencies'])) {
        sectionPresence['Kỹ năng'] = true;
      }
      if (_containsAny(normalizedLine, [
        'lien he',
        'contact',
        '@',
        'phone',
        'dien thoai',
      ])) {
        sectionPresence['Liên hệ'] = true;
      }
      if (_containsAny(normalizedLine, [
        'kinh nghiem',
        'experience',
        'du an',
        'project',
      ])) {
        inExperienceSection = true;
      } else if (_isSectionHeading(normalizedLine) &&
          !_containsAny(normalizedLine, [
            'kinh nghiem',
            'experience',
            'du an',
            'project',
          ])) {
        inExperienceSection = false;
      }
      if (_containsAny(normalizedLine, [
        'muc tieu',
        'objective',
        'summary',
        'about me',
      ])) {
        inObjectiveSection = true;
      } else if (_isSectionHeading(normalizedLine)) {
        inObjectiveSection = false;
      }

      if (line.trim().isNotEmpty && line.length > 125) {
        issues.add(
          _issue(
            lineIndex: index,
            offset: offset,
            line: line,
            kind: CvIssueKind.longLine,
            severity: CvIssueSeverity.suggestion,
            title: 'Dòng hơi dài',
            explanation: 'Dòng này dài, nhà tuyển dụng khó quét nhanh ý chính.',
            fix: 'Tách thành các gạch đầu dòng ngắn, mỗi gạch một kết quả.',
            after: 'Rút gọn còn một ý chính, ưu tiên động từ và kết quả.',
          ),
        );
      }
      if (inExperienceSection &&
          _looksLikeExperienceLine(normalizedLine) &&
          !_hasMetric(line)) {
        issues.add(
          _issue(
            lineIndex: index,
            offset: offset,
            line: line,
            kind: CvIssueKind.noAchievementMetric,
            severity: CvIssueSeverity.warning,
            title: 'Thiếu số liệu',
            explanation:
                'Mô tả kinh nghiệm chưa cho thấy quy mô hoặc kết quả đo được.',
            fix: 'Bổ sung tỷ lệ, số lượng, thời gian hoặc tác động cụ thể.',
            after:
                'Tối ưu quy trình báo cáo, giúp giảm 20% thời gian tổng hợp.',
          ),
        );
      }
      if (_startsWithWeakVerb(normalizedLine)) {
        issues.add(
          _issue(
            lineIndex: index,
            offset: offset,
            line: line,
            kind: CvIssueKind.weakActionVerb,
            severity: CvIssueSeverity.warning,
            title: 'Đổi động từ mở đầu',
            explanation:
                'Cách mở đầu đang thiên về vai trò hơn hành động và kết quả.',
            fix:
                'Mở đầu bằng động từ chủ động, nêu rõ việc đã làm và tác động.',
            after: 'Phân tích dữ liệu bán hàng, đề xuất thay đổi giúp tăng 12% chuyển đổi.',
          ),
        );
      }
      if (inObjectiveSection &&
          (RegExp(r'[.!?]').allMatches(line).length > 3 ||
              normalizedLine.contains('mong muon hoc hoi'))) {
        issues.add(
          _issue(
            lineIndex: index,
            offset: offset,
            line: line,
            kind: CvIssueKind.vagueObjective,
            severity: CvIssueSeverity.warning,
            title: 'Mục tiêu chưa cụ thể',
            explanation: 'Mục tiêu dài hoặc chung chung nên chưa thể hiện hướng nghề rõ ràng.',
            fix: 'Giới hạn 1–2 câu, nêu vị trí, thế mạnh và giá trị có thể đóng góp.',
            after:
                'Ứng tuyển vị trí ${career.title}, vận dụng phân tích dữ liệu để cải thiện quyết định kinh doanh.',
          ),
        );
      }

      offset += line.length + 1;
    }

    final firstTextLine = lines.indexWhere((line) => line.trim().isNotEmpty);
    for (final entry in sectionPresence.entries) {
      if (entry.value) continue;
      issues.add(
        CvIssue(
          lineIndex: firstTextLine < 0 ? 0 : firstTextLine,
          startOffset: firstTextLine < 0
              ? 0
              : _offsetOfLine(lines, firstTextLine),
          endOffset: firstTextLine < 0
              ? 0
              : _offsetOfLine(lines, firstTextLine) +
                    lines[firstTextLine].length,
          kind: CvIssueKind.missingSection,
          severity: CvIssueSeverity.heavy,
          title: 'Thiếu ${entry.key}',
          explanation:
              'CV chưa có mục ${entry.key} để nhà tuyển dụng đối chiếu.',
          fix: 'Thêm một mục ${entry.key} ngắn gọn với thông tin liên quan.',
          before: 'Chưa có mục ${entry.key}.',
          after:
              '${entry.key.toUpperCase()}\nBổ sung thông tin phù hợp tại đây.',
        ),
      );
    }

    final skillsIssueLine = firstTextLine < 0 ? 0 : firstTextLine;
    final skillsIssueStart = firstTextLine < 0
        ? 0
        : _offsetOfLine(lines, firstTextLine);
    for (final skill in missingRequirements.take(8)) {
      issues.add(
        CvIssue(
          lineIndex: skillsIssueLine,
          startOffset: skillsIssueStart,
          endOffset:
              skillsIssueStart +
              (firstTextLine < 0 ? 0 : lines[skillsIssueLine].length),
          kind: CvIssueKind.missingSkill,
          severity: CvIssueSeverity.heavy,
          title: 'Thiếu kỹ năng: $skill',
          explanation:
              'Chưa tìm thấy "$skill" trong CV${job == null ? ' cho mục tiêu ${career.title}' : ' so với yêu cầu ${job.title}'}.',
          fix: 'Nếu bạn thực sự có kỹ năng này, hãy thêm vào mục Kỹ năng hoặc minh họa bằng một dự án.',
          before: 'Kỹ năng liên quan chưa xuất hiện trong CV.',
          after: 'Kỹ năng: $skill — áp dụng trong dự án / công việc phù hợp.',
          skill: skill,
        ),
      );
    }

    final keywordScore =
        (matchedKeywords.length / careerKeywordGroups.length * 65).round();
    final sectionScore =
        sectionPresence.values.where((present) => present).length * 5;
    final metricScore = _hasMetric(text) ? 10 : 0;
    final contactScore = sectionPresence['Liên hệ']! ? 5 : 0;
    final score = (keywordScore + sectionScore + metricScore + contactScore)
        .clamp(0, 100);
    final suggestions = _makeSuggestions(
      career,
      missingRequirements,
      sectionPresence,
      _hasMetric(text),
    );

    return CvAnalysis(
      score: score,
      matchedKeywords: matchedKeywords,
      missingKeywords: missingRequirements,
      issues: issues,
      jobMatchCount: matchedRequirements.length,
      jobRequirementCount: requiredSkills.length,
      suggestions: suggestions,
    );
  }

  CvIssue _issue({
    required int lineIndex,
    required int offset,
    required String line,
    required CvIssueKind kind,
    required CvIssueSeverity severity,
    required String title,
    required String explanation,
    required String fix,
    required String after,
  }) {
    return CvIssue(
      lineIndex: lineIndex,
      startOffset: offset,
      endOffset: offset + line.length,
      kind: kind,
      severity: severity,
      title: title,
      explanation: explanation,
      fix: fix,
      before: line,
      after: after,
    );
  }

  List<String> _makeSuggestions(
    CareerGoal career,
    List<String> missingSkills,
    Map<String, bool> sections,
    bool hasMetric,
  ) {
    final suggestions = <String>[
      if (!sections['Kinh nghiệm / Dự án']!)
        'Thêm một dự án liên quan đến ${career.title} để chứng minh kỹ năng bằng sản phẩm cụ thể.',
      if (!hasMetric)
        'Bổ sung số liệu trước–sau, quy mô hoặc thời gian để làm rõ tác động.',
      if (missingSkills.isNotEmpty) 'Đối chiếu yêu cầu tuyển dụng và chỉ thêm kỹ năng bạn thực sự đã sử dụng.',
      if (!sections['Học vấn']!)
        'Nêu ngành học, trường và thời gian học trong mục Học vấn.',
      'Đưa thông tin liên hệ và vị trí ứng tuyển lên đầu CV để dễ tìm.',
    ];
    return suggestions.take(5).toList(growable: false);
  }

  bool _hasMetric(String text) =>
      RegExp(r'(\d+([.,]\d+)?\s*%|\b\d+\b)').hasMatch(text);

  bool _looksLikeExperienceLine(String normalizedLine) =>
      normalizedLine.length > 24 &&
      !_isSectionHeading(normalizedLine) &&
      !normalizedLine.startsWith('cv ');

  bool _startsWithWeakVerb(String line) => RegExp(
    r'^(tham gia|ho tro|phu trach|toi|assisted|responsible for|participated in)\b',
  ).hasMatch(line.trim());

  bool _isSectionHeading(String line) => RegExp(
    r'^(hoc van|education|academic|kinh nghiem|experience|du an|project|ky nang|skills|lien he|contact|muc tieu|objective|summary)\b',
  ).hasMatch(line.trim());

  bool _containsAny(String text, List<String> terms) =>
      terms.any((term) => text.contains(term));

  String _normalize(String value) {
    var result = value.toLowerCase();
    const replacements = {
      'á': 'a',
      'à': 'a',
      'ả': 'a',
      'ã': 'a',
      'ạ': 'a',
      'ă': 'a',
      'ắ': 'a',
      'ằ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'ặ': 'a',
      'â': 'a',
      'ấ': 'a',
      'ầ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'ậ': 'a',
      'é': 'e',
      'è': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ẹ': 'e',
      'ê': 'e',
      'ế': 'e',
      'ề': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ệ': 'e',
      'í': 'i',
      'ì': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ị': 'i',
      'ó': 'o',
      'ò': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ọ': 'o',
      'ô': 'o',
      'ố': 'o',
      'ồ': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ộ': 'o',
      'ơ': 'o',
      'ớ': 'o',
      'ờ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ợ': 'o',
      'ú': 'u',
      'ù': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ụ': 'u',
      'ư': 'u',
      'ứ': 'u',
      'ừ': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ự': 'u',
      'ý': 'y',
      'ỳ': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'ỵ': 'y',
      'đ': 'd',
    };
    for (final entry in replacements.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  int _offsetOfLine(List<String> lines, int lineIndex) {
    var offset = 0;
    for (var index = 0; index < lineIndex; index++) {
      offset += lines[index].length + 1;
    }
    return offset;
  }
}
