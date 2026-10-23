import '../models/student_job.dart';
import '../services/points_manager.dart';
import '../config/flashcard_skill_map.dart';

class JobMatchService {
  JobMatchService({int Function(String?)? levelForSkill})
    : _levelForSkill = levelForSkill ?? PointsManager.instance.level;

  final int Function(String?) _levelForSkill;

  int skillLevel(JobSkillRequirement requirement) {
    final skill = skillForDeck(requirement.skillKey);
    return _levelForSkill(skill ?? requirement.label);
  }

  double? matchPercent(StudentJob job) {
    if (job.requiredSkills.isEmpty) return null;
    final total = job.requiredSkills.fold<double>(0, (sum, required) {
      final level = skillLevel(required);
      return sum + (level / required.requiredLevel).clamp(0.0, 1.0).toDouble();
    });
    return total / job.requiredSkills.length * 100;
  }

  List<String> missingSkills(StudentJob job) {
    final missing =
        job.requiredSkills
            .map((required) {
              final level = skillLevel(required);
              final ratio = (level / required.requiredLevel)
                  .clamp(0.0, 1.0)
                  .toDouble();
              return (
                label: required.label,
                ratio: ratio,
                level: level,
                requiredLevel: required.requiredLevel,
              );
            })
            .where((item) => item.level < item.requiredLevel)
            .toList()
          ..sort((first, second) => first.ratio.compareTo(second.ratio));
    return missing.take(3).map((item) => item.label).toList(growable: false);
  }

  String? matchLabel(double? percent) {
    if (percent == null) return null;
    if (percent >= 70) return 'Rất hợp';
    if (percent >= 40) return 'Khá hợp';
    return 'Cần bổ sung';
  }
}

List<StudentJob> filterAndSortJobs(
  Iterable<StudentJob> jobs,
  JobFilterState state, {
  required double? Function(StudentJob job) matchPercent,
  bool Function(StudentJob job)? includeJob,
}) {
  final query = _normalize(state.query);
  final filtered = jobs.where((job) {
    if (includeJob != null && !includeJob(job)) return false;
    if (state.jobTypes.isNotEmpty && !state.jobTypes.contains(job.jobType)) {
      return false;
    }
    if (state.workModes.isNotEmpty && !state.workModes.contains(job.workMode)) {
      return false;
    }
    if (state.fieldId != null && state.fieldId != job.fieldId) return false;
    if (state.location == 'Remote' && job.workMode != JobWorkMode.remote) {
      return false;
    }
    if (state.location != 'Toàn quốc' &&
        state.location != 'Remote' &&
        state.location != job.location) {
      return false;
    }
    if (query.isEmpty) return true;
    final searchable = [
      job.title,
      job.company,
      job.location,
      ...job.requiredSkills.map((skill) => skill.label),
    ].map(_normalize).join(' ');
    return searchable.contains(query);
  }).toList();

  switch (state.sort) {
    case 'match':
      filtered.sort((first, second) {
        final firstMatch = matchPercent(first) ?? -1;
        final secondMatch = matchPercent(second) ?? -1;
        return secondMatch.compareTo(firstMatch);
      });
    case 'salary':
      filtered.sort(
        (first, second) => second.salaryMin.compareTo(first.salaryMin),
      );
    default:
      filtered.sort(
        (first, second) => second.postedAt.compareTo(first.postedAt),
      );
  }
  return filtered;
}

String _normalize(String value) => value
    .toLowerCase()
    .replaceAll(RegExp('[áàảãạăắằẳẵặâấầẩẫậ]'), 'a')
    .replaceAll(RegExp('[éèẻẽẹêếềểễệ]'), 'e')
    .replaceAll(RegExp('[íìỉĩị]'), 'i')
    .replaceAll(RegExp('[óòỏõọôốồổỗộơớờởỡợ]'), 'o')
    .replaceAll(RegExp('[úùủũụưứừửữự]'), 'u')
    .replaceAll(RegExp('[ýỳỷỹỵ]'), 'y')
    .replaceAll('đ', 'd')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
