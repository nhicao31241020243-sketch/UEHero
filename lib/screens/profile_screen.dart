import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/career_goal.dart';
import '../models/character_data.dart';
import '../models/xp_entry.dart';
import '../services/points_manager.dart';
import 'xp_ledger_debug_screen.dart';
import '../widgets/career_goal_option_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _background = Color(0xFF100E19);
  static const _surface = Color(0xFF211D2B);
  static const _muted = Color(0xFFAAA5B8);
  static const _accent = Color(0xFFBFA8FF);

  final _xp = PointsManager.instance;
  CharacterData _companion = characterData.first;
  CareerGoal _selectedGoal = careerGoals.first;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _xp.addListener(_onXpChanged);
    _loadProfile();
  }

  void _onXpChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadProfile() async {
    final preferences = await SharedPreferences.getInstance();
    final savedCharacter = characterById(
      preferences.getString('selected_mascot'),
    );
    final savedGoal = careerGoalByTitle(preferences.getString('career_goal'));
    final mastery = jsonDecode(
      preferences.getString('career_map_skills') ?? '{}',
    );
    await _xp.initialize(preferences: preferences);
    await _xp.migrateInitialSkills(
      savedGoal?.skills ?? careerGoals.first.skills,
      savedMastery: mastery is Map<String, dynamic> ? mastery : const {},
      preferences: preferences,
    );
    if (!mounted) return;

    setState(() {
      _companion =
          savedCharacter ?? CharacterSelection.selected ?? characterData.first;
      CharacterSelection.selected = _companion;
      _selectedGoal = savedGoal ?? careerGoals.first;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _xp.removeListener(_onXpChanged);
    super.dispose();
  }

  Future<void> _changeCareerGoal() async {
    final selected = await showModalBottomSheet<CareerGoal>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: _background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) => _CareerGoalSheet(selectedGoal: _selectedGoal),
    );
    if (selected == null || !mounted) return;

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('career_goal', selected.title);
    if (!mounted) return;
    setState(() => _selectedGoal = selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Hồ sơ của bạn',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_background, Color(0xFF171326), _background],
          ),
        ),
        child: SafeArea(
          top: false,
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _accent))
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildMascotCard(),
                      const SizedBox(height: 18),
                      _buildSkillsCard(),
                      if (kDebugMode) ...[
                        const SizedBox(height: 12),
                        _buildXpDebugControls(),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildMascotCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF342A59), Color(0xFF211D38), Color(0xFF191726)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 260,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: RadialGradient(
                        center: const Alignment(0, 0.15),
                        radius: 0.8,
                        colors: [
                          _companion.primaryColor.withValues(alpha: 0.28),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 18,
                  left: 16,
                  child: _GreetingBubble(name: _companion.name),
                ),
                Positioned.fill(
                  top: 12,
                  child: ModelViewer(
                    key: ValueKey(_companion.modelPath),
                    src: _companion.modelPath,
                    alt: _companion.name,
                    autoPlay: true,
                    animationName: _companion.animationName,
                    autoRotate: true,
                    autoRotateDelay: 0,
                    cameraControls: true,
                    disableZoom: true,
                    backgroundColor: Colors.transparent,
                    debugLogging: false,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 17),
            child: Text(
              _companion.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.stars_rounded, color: _accent, size: 22),
              SizedBox(width: 9),
              Text(
                'Kỹ năng của bạn',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Mục tiêu: ${_selectedGoal.title}',
                  style: const TextStyle(
                    color: Color(0xFFE9E6F0),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: _changeCareerGoal,
                style: TextButton.styleFrom(
                  foregroundColor: _accent,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text(
                  'Đổi mục tiêu',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final skill in _selectedGoal.skills)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: _SkillRatingRow(
                key: ValueKey('${_selectedGoal.title}-${skill.name}'),
                skill: CareerSkill(skill.name, _xp.level(skill.name)),
              ),
            ),
          const SizedBox(height: 6),
          const Text(
            'Mức thành thạo mẫu — sẽ kết nối dữ liệu thật sau.',
            style: TextStyle(color: _muted, fontSize: 11, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildXpDebugControls() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addDebugXp,
            icon: const Icon(Icons.bolt_rounded, size: 17),
            label: const Text('+10 XP JavaScript'),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _addDebugBatchXp,
                icon: const Icon(Icons.auto_awesome_rounded, size: 17),
                label: const Text('+2 XP x5'),
              ),
            ),
            IconButton(
              tooltip: 'Mở XP ledger',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const XpLedgerDebugScreen(),
                ),
              ),
              icon: const Icon(Icons.receipt_long_rounded, color: _accent),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _addDebugXp() async {
    final added = await _xp.addXP(
      thanh: XpBar.thucChien,
      skill: 'JavaScript',
      luong: 10,
      nguon: 'debug',
      sourceRef: 'debug-${DateTime.now().microsecondsSinceEpoch}',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('+$added XP JavaScript')));
  }

  Future<void> _addDebugBatchXp() async {
    for (var index = 0; index < 5; index++) {
      await _xp.addXP(
        thanh: XpBar.thucChien,
        skill: 'JavaScript',
        luong: 2,
        nguon: 'debug',
        sourceRef: 'batch-${DateTime.now().microsecondsSinceEpoch}-$index',
      );
    }
  }
}

class _CareerGoalSheet extends StatelessWidget {
  const _CareerGoalSheet({required this.selectedGoal});

  final CareerGoal selectedGoal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF777181),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chọn mục tiêu nghề nghiệp',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            for (var index = 0; index < careerGoals.length; index++) ...[
              CareerGoalOptionCard(
                goal: careerGoals[index],
                selected: careerGoals[index] == selectedGoal,
                onTap: () => Navigator.of(context).pop(careerGoals[index]),
              ),
              if (index != careerGoals.length - 1) const SizedBox(height: 9),
            ],
          ],
        ),
      ),
    );
  }
}

class _GreetingBubble extends StatelessWidget {
  const _GreetingBubble({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 158),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xE6221D31),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        'Chào bạn! $name luôn đồng hành 🚀',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          height: 1.3,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SkillRatingRow extends StatelessWidget {
  const _SkillRatingRow({required this.skill, super.key});

  final CareerSkill skill;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          skill.name,
          style: const TextStyle(
            color: Color(0xFFE9E6F0),
            fontSize: 16,
            height: 1.25,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 9),
        LayoutBuilder(
          builder: (context, constraints) {
            final diameter = ((constraints.maxWidth - 36) / 10).clamp(
              18.0,
              26.0,
            );
            final gap = (constraints.maxWidth - diameter * 10) / 9;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: skill.level.toDouble()),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var index = 0; index < 10; index++)
                    Padding(
                      padding: EdgeInsets.only(right: index == 9 ? 0 : gap),
                      child: _SkillDot(
                        diameter: diameter,
                        fill: (value - index).clamp(0, 1).toDouble(),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SkillDot extends StatelessWidget {
  const _SkillDot({required this.diameter, required this.fill});

  final double diameter;
  final double fill;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: diameter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF777181).withValues(alpha: 0.38),
        ),
        child: FractionallySizedBox(
          widthFactor: fill,
          heightFactor: fill,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: fill > 0
                  ? const LinearGradient(
                      colors: [Color(0xFFB66DFF), Color(0xFF59C9F5)],
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
