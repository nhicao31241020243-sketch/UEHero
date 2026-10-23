import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/career_goal.dart';
import '../services/career_board_service.dart';
import '../widgets/book_cover.dart';

class SecondHandMarketScreen extends StatefulWidget {
  const SecondHandMarketScreen({super.key});

  @override
  State<SecondHandMarketScreen> createState() => _SecondHandMarketScreenState();
}

class _SecondHandMarketScreenState extends State<SecondHandMarketScreen> {
  static const _background = Color(0xFF100E19);
  static const _surface = Color(0xFF211D2B);
  static const _accent = Color(0xFFBFA8FF);
  static const _muted = Color(0xFFAAA5B8);

  static const _categories = ['Tất cả', 'Sách', 'Khóa học', 'Công cụ'];

  final _searchController = TextEditingController();
  List<LearningResource> _resources = [];
  Map<String, dynamic> _mastery = {};
  String? _careerGoal;
  String? _loadError;
  String _searchQuery = '';
  String _selectedCategory = _categories.first;
  String _skillFilter = '';
  String _levelFilter = '';
  String _languageFilter = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadResources() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final jsonString = await rootBundle.loadString(
        'assets/learning_resources.json',
      );
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
          'Learning resources must be a JSON object.',
        );
      }
      final resources = <LearningResource>[];
      for (final entry in decoded.entries) {
        if (entry.value is! List) {
          throw FormatException('Resources for ${entry.key} must be a list.');
        }
        for (final value in entry.value as List) {
          if (value is! Map<String, dynamic>) {
            throw FormatException('Invalid resource in ${entry.key}.');
          }
          resources.add(LearningResource.fromJson(entry.key, value));
        }
      }
      final preferences = await SharedPreferences.getInstance();
      final levels = _decodeSkillLevels(
        preferences.getString('career_map_skills'),
      );
      if (!mounted) return;
      setState(() {
        _resources = resources;
        _careerGoal = preferences.getString('career_goal');
        _mastery = levels;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString();
        _loading = false;
      });
    }
  }

  Map<String, dynamic> _decodeSkillLevels(String? source) {
    if (source == null) return {};
    try {
      final decoded = jsonDecode(source);
      return decoded is Map<String, dynamic> ? decoded : {};
    } on FormatException {
      return {};
    }
  }

  List<LearningResource> get _filteredResources {
    final query = _searchQuery.trim().toLowerCase();
    return _resources.where((resource) {
      final matchesCategory =
          _selectedCategory == 'Tất cả' ||
          resource.type == _categoryType(_selectedCategory);
      final matchesQuery =
          query.isEmpty ||
          '${resource.title} ${resource.author} ${resource.skill} ${resource.career}'
              .toLowerCase()
              .contains(query);
      return matchesCategory &&
          matchesQuery &&
          (_skillFilter.isEmpty || resource.skill == _skillFilter) &&
          (_levelFilter.isEmpty || resource.level == _levelFilter) &&
          (_languageFilter.isEmpty || resource.lang == _languageFilter);
    }).toList();
  }

  String get _filterCount {
    final count = [
      _skillFilter,
      _levelFilter,
      _languageFilter,
    ].where((value) => value.isNotEmpty).length;
    return count == 0 ? '' : '$count';
  }

  List<LearningResource> get _suggestions {
    final matchingGoal = _resources
        .where((resource) => resource.career == _careerGoal)
        .toList();
    final source = matchingGoal.isEmpty ? _resources : matchingGoal;
    source.sort((a, b) {
      final aLevel = _masteryFor(a);
      final bLevel = _masteryFor(b);
      final priority = aLevel.compareTo(bLevel);
      return priority != 0 ? priority : a.title.compareTo(b.title);
    });
    return source.take(5).toList();
  }

  double _masteryFor(LearningResource resource) {
    final skill = _matchingCareerSkill(resource.skill);
    if (skill == null) return double.infinity;
    final value = _mastery[skill.name];
    return value is num ? value.toDouble() : 0;
  }

  CareerSkill? _matchingCareerSkill(String resourceSkill) {
    final goal = careerGoalByTitle(_careerGoal);
    if (goal == null) return null;
    final normalized = _normalize(resourceSkill);
    for (final skill in goal.skills) {
      final candidate = _normalize(skill.name);
      if (normalized == candidate ||
          normalized.contains(candidate) ||
          candidate.contains(normalized)) {
        return skill;
      }
    }
    return null;
  }

  String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\u00C0-\u024F]'), '');

  String? _categoryType(String label) => switch (label) {
    'Sách' => 'book',
    'Khóa học' => 'course',
    'Công cụ' => 'tool',
    _ => null,
  };

  Future<void> _showFilters() async {
    var skill = _skillFilter;
    var level = _levelFilter;
    var language = _languageFilter;
    final skills = _resources.map((resource) => resource.skill).toSet().toList()
      ..sort();
    if (skill.isNotEmpty && !skills.contains(skill)) skill = '';
    final result = await showModalBottomSheet<_ResourceFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xE8142E52),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Lọc học liệu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              _filterDropdown(
                label: 'Kỹ năng',
                value: skill,
                options: ['', ...skills],
                labelFor: (value) => value.isEmpty ? 'Tất cả kỹ năng' : value,
                onChanged: (value) => setSheetState(() => skill = value),
              ),
              const SizedBox(height: 12),
              _filterDropdown(
                label: 'Mức độ',
                value: level,
                options: const ['', 'basic', 'advanced'],
                labelFor: (value) => switch (value) {
                  'basic' => 'Cơ bản',
                  'advanced' => 'Nâng cao',
                  _ => 'Tất cả mức độ',
                },
                onChanged: (value) => setSheetState(() => level = value),
              ),
              const SizedBox(height: 12),
              _filterDropdown(
                label: 'Ngôn ngữ',
                value: language,
                options: const ['', 'vi', 'en'],
                labelFor: (value) => switch (value) {
                  'vi' => 'Tiếng Việt',
                  'en' => 'Tiếng Anh',
                  _ => 'Tất cả ngôn ngữ',
                },
                onChanged: (value) => setSheetState(() => language = value),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(
                    context,
                    _ResourceFilters(
                      skill: skill,
                      level: level,
                      lang: language,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: _background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Áp dụng bộ lọc'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _skillFilter = result.skill;
        _levelFilter = result.level;
        _languageFilter = result.lang;
      });
    }
  }

  Widget _filterDropdown({
    required String label,
    required String value,
    required List<String> options,
    required String Function(String value) labelFor,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: _surface,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _muted),
        filled: true,
        fillColor: _surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      items: options
          .map(
            (option) => DropdownMenuItem(
              value: option,
              child: Text(labelFor(option), overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }

  void _showResourceDetails(LearningResource resource) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xE8142E52),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.92,
        child: _ResourceDetailsSheet(
          resource: resource,
          onOpen: () => _openResource(resource),
          onAddToPlan: () {
            // TODO(weekly-plan): connect this action to the weekly plan API.
            Navigator.pop(context);
            _showMessage('Thêm vào Kế hoạch tuần sẽ sớm khả dụng.');
          },
        ),
      ),
    );
  }

  Future<void> _openResource(LearningResource resource) async {
    final uri = resource.url.isNotEmpty
        ? Uri.tryParse(resource.url)
        : Uri.https('www.google.com', '/search', {
            'q': '${resource.title} ${resource.author}'.trim(),
          });
    if (uri == null) {
      _showMessage('Không mở được liên kết học liệu.');
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (launched) {
      unawaited(CareerBoardService.instance.reportLibraryOpened(resource.id));
    }
    if (!launched && mounted) _showMessage('Không mở được liên kết học liệu.');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Thư viện học liệu',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : _loadError != null
          ? _errorState()
          : _resourceContent(),
    );
  }

  Widget _resourceContent() {
    final resources = _filteredResources;
    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: SliverToBoxAdapter(child: _searchField()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          sliver: SliverToBoxAdapter(child: _suggestionSection()),
        ),
        SliverToBoxAdapter(child: _categorySelector()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Khám phá học liệu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Bộ lọc',
                  onPressed: _showFilters,
                  visualDensity: VisualDensity.compact,
                  icon: Badge(
                    isLabelVisible: _filterCount.isNotEmpty,
                    label: Text(_filterCount),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: _accent,
                      size: 21,
                    ),
                  ),
                ),
                Text(
                  '${resources.length}',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        if (resources.isEmpty)
          SliverFillRemaining(hasScrollBody: false, child: _emptyState())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
            sliver: SliverGrid.builder(
              itemCount: resources.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 326,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) => _ResourceCard(
                key: ValueKey('resource-card-${resources[index].id}'),
                resource: resources[index],
                onTap: () => _showResourceDetails(resources[index]),
              ),
            ),
          ),
      ],
    );
  }

  Widget _searchField() => TextField(
    controller: _searchController,
    onChanged: (value) => setState(() => _searchQuery = value),
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      hintText: 'Tìm sách, khóa học, tác giả, kỹ năng...',
      hintStyle: const TextStyle(color: _muted, fontSize: 13),
      prefixIcon: const Icon(Icons.search_rounded, color: _accent),
      suffixIcon: IconButton(
        tooltip: 'Mở bộ lọc',
        onPressed: _showFilters,
        icon: Badge(
          isLabelVisible: _filterCount.isNotEmpty,
          label: Text(_filterCount),
          child: const Icon(Icons.tune_rounded, color: _muted, size: 20),
        ),
      ),
      filled: true,
      fillColor: _surface,
      contentPadding: const EdgeInsets.symmetric(vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    ),
  );

  Widget _suggestionSection() {
    final suggestions = _suggestions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: _accent, size: 19),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _careerGoal == null
                    ? 'Gợi ý học liệu nổi bật'
                    : 'Gợi ý cho nghề mục tiêu',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        if (_careerGoal == null) ...[
          const SizedBox(height: 5),
          const Text(
            'Chọn nghề mục tiêu để nhận gợi ý phù hợp hơn. Bạn vẫn có thể xem toàn bộ thư viện.',
            style: TextStyle(color: _muted, height: 1.35, fontSize: 12),
          ),
        ] else ...[
          const SizedBox(height: 4),
          Text(
            _careerGoal!,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          height: 136,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: suggestions.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final resource = suggestions[index];
              return _SuggestionCard(
                resource: resource,
                mastery: _masteryFor(resource),
                onTap: () => _showResourceDetails(resource),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _categorySelector() => SizedBox(
    height: 58,
    child: ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      scrollDirection: Axis.horizontal,
      itemCount: _categories.length,
      separatorBuilder: (context, index) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final category = _categories[index];
        final selected = category == _selectedCategory;
        return ChoiceChip(
          label: Text(category),
          selected: selected,
          onSelected: (_) => setState(() => _selectedCategory = category),
          selectedColor: _accent,
          backgroundColor: _surface,
          labelStyle: TextStyle(
            color: selected ? _background : Colors.white70,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          side: BorderSide(
            color: selected ? _accent : Colors.white.withValues(alpha: 0.08),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          showCheckmark: false,
        );
      },
    ),
  );

  Widget _errorState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: _accent, size: 38),
          const SizedBox(height: 12),
          const Text(
            'Chưa tải được thư viện học liệu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _loadError ?? 'Đã xảy ra lỗi không xác định.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _loadResources, child: const Text('Thử lại')),
        ],
      ),
    ),
  );

  Widget _emptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, color: _muted, size: 38),
          const SizedBox(height: 10),
          const Text(
            'Không tìm thấy học liệu phù hợp',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          TextButton(
            onPressed: () => setState(() {
              _searchQuery = '';
              _searchController.clear();
              _skillFilter = '';
              _levelFilter = '';
              _languageFilter = '';
              _selectedCategory = _categories.first;
            }),
            child: const Text('Xóa tìm kiếm và bộ lọc'),
          ),
        ],
      ),
    ),
  );
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.resource,
    required this.mastery,
    required this.onTap,
  });

  final LearningResource resource;
  final double mastery;
  final VoidCallback onTap;

  static const _surface = Color(0xFF211D2B);
  static const _accent = Color(0xFFBFA8FF);
  static const _cyan = Color(0xFF70D8F2);

  @override
  Widget build(BuildContext context) => Material(
    color: _surface,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 258,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _accent.withValues(alpha: 0.24)),
          boxShadow: [
            BoxShadow(color: _accent.withValues(alpha: 0.08), blurRadius: 14),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 68,
              child: BookCover(
                key: ValueKey('cover-${resource.id}'),
                id: resource.id,
                title: resource.title,
                author: resource.author,
                isbn: resource.isbn,
                coverUrl: resource.coverUrl,
                              lookupOnline: resource.url.isEmpty,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _resourceTypeLabel(resource.type).toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _accent,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    resource.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      height: 1.2,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    resource.skill,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white60, fontSize: 10),
                  ),
                  if (mastery.isFinite) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Mức hiện tại: ${mastery.toStringAsFixed(mastery % 1 == 0 ? 0 : 1)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _cyan, fontSize: 9),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({super.key, required this.resource, required this.onTap});

  final LearningResource resource;
  final VoidCallback onTap;

  static const _surface = Color(0xFF211D2B);
  static const _accent = Color(0xFFBFA8FF);
  static const _muted = Color(0xFFAAA5B8);

  @override
  Widget build(BuildContext context) => Material(
    color: _surface,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: SizedBox(
                width: 122,
                child: BookCover(
                  key: ValueKey('cover-${resource.id}'),
                  id: resource.id,
                  title: resource.title,
                  author: resource.author,
                  isbn: resource.isbn,
                  coverUrl: resource.coverUrl,
                                  lookupOnline: resource.url.isEmpty,
                ),
              ),
            ),
            const SizedBox(height: 9),
            Text(
              resource.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              resource.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _muted, fontSize: 10),
            ),
            const Spacer(),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                _InfoChip(label: resource.skill, color: _accent),
                _InfoChip(
                  label: resource.level == 'basic' ? 'Cơ bản' : 'Nâng cao',
                  color: const Color(0xFF70D8F2),
                ),
                _InfoChip(
                  label: resource.lang.toUpperCase(),
                  color: const Color(0xFFFFC18E),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _ResourceDetailsSheet extends StatelessWidget {
  const _ResourceDetailsSheet({
    required this.resource,
    required this.onOpen,
    required this.onAddToPlan,
  });

  final LearningResource resource;
  final VoidCallback onOpen;
  final VoidCallback onAddToPlan;

  static const _accent = Color(0xFFBFA8FF);
  static const _muted = Color(0xFFAAA5B8);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: 180,
                child: BookCover(
                  id: resource.id,
                  title: resource.title,
                  author: resource.author,
                  isbn: resource.isbn,
                  coverUrl: resource.coverUrl,
                                  lookupOnline: resource.url.isEmpty,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              resource.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                height: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              resource.author.isEmpty ? resource.career : resource.author,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 7,
              runSpacing: 7,
              children: [
                _InfoChip(
                  label: _resourceTypeLabel(resource.type),
                  color: _accent,
                ),
                _InfoChip(
                  label: resource.skill,
                  color: const Color(0xFF70D8F2),
                ),
                _InfoChip(
                  label: resource.level == 'basic' ? 'Cơ bản' : 'Nâng cao',
                  color: const Color(0xFFFFC18E),
                ),
                _InfoChip(label: resource.lang.toUpperCase(), color: _accent),
              ],
            ),
            if (resource.isbn.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'ISBN: ${resource.isbn}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ],
            const SizedBox(height: 22),
            const Text(
              'Vì sao nên học/đọc',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              resource.why,
              style: const TextStyle(color: _muted, height: 1.5, fontSize: 13),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text(
                resource.url.isEmpty
                    ? 'Tìm mua / Tìm khóa học'
                    : 'Đến khóa học',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: const Color(0xFF100E19),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onAddToPlan,
              icon: const Icon(Icons.add_task_rounded),
              label: const Text('Thêm vào Kế hoạch tuần'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: _accent),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 128),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.25)),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700),
    ),
  );
}

class _ResourceFilters {
  const _ResourceFilters({
    required this.skill,
    required this.level,
    required this.lang,
  });

  final String skill;
  final String level;
  final String lang;
}

class LearningResource {
  const LearningResource({
    required this.career,
    required this.id,
    required this.title,
    required this.author,
    required this.isbn,
    required this.type,
    required this.skill,
    required this.level,
    required this.why,
    required this.lang,
    required this.url,
    this.coverUrl,
  });

  final String career;
  final String id;
  final String title;
  final String author;
  final String isbn;
  final String type;
  final String skill;
  final String level;
  final String why;
  final String lang;
  final String url;
  final String? coverUrl;

  factory LearningResource.fromJson(String career, Map<String, dynamic> json) =>
      LearningResource(
        career: career,
        id: json['id'] as String,
        title: json['title'] as String,
        author: json['author'] as String? ?? '',
        isbn: json['isbn'] as String? ?? '',
        type: json['type'] as String,
        skill: json['skill'] as String,
        level: json['level'] as String,
        why: json['why'] as String,
        lang: json['lang'] as String,
        url: json['url'] as String? ?? '',
        coverUrl: json['coverUrl'] as String?,
      );
}

String _resourceTypeLabel(String type) => switch (type) {
  'book' => 'Sách',
  'course' => 'Khóa học',
  'tool' => 'Công cụ',
  _ => 'Học liệu',
};
