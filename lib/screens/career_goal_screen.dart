import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/debug_flags.dart';
import '../home_widgets_screen.dart';
import '../models/career_goal.dart';
import '../models/character_data.dart';
import '../services/mascot_selection_store.dart';
import '../widgets/career_goal_option_card.dart';
import 'mascot_hub_screen.dart';

class CareerGoalScreen extends StatefulWidget {
  const CareerGoalScreen({this.skipIfSavedUser = true, super.key});

  final bool skipIfSavedUser;

  @override
  State<CareerGoalScreen> createState() => _CareerGoalScreenState();
}

class _CareerGoalScreenState extends State<CareerGoalScreen> {
  static const _background = Color(0xFF100E19);
  static const _accent = Color(0xFFBFA8FF);
  static const _cyan = Color(0xFF70D8F2);

  CareerGoal? _selectedGoal;
  MascotSelection? _savedMascots;
  bool _checkingSavedUser = true;

  @override
  void initState() {
    super.initState();
    _loadSavedUser();
  }

  Future<void> _loadSavedUser() async {
    final preferences = await SharedPreferences.getInstance();
    final careerGoal = preferences.getString('career_goal');
    final mascots = await MascotSelectionStore.instance.read(
      preferences: preferences,
    );
    if (!mounted) return;

    final savedGoal = careerGoalByTitle(careerGoal);
    if (widget.skipIfSavedUser &&
        !(kForceFullOnboarding && kDebugMode) &&
        mascots.isComplete &&
        savedGoal != null) {
      CharacterSelection.selected = mascots.primary;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/home'),
          builder: (_) => const HomeWidgetsScreen(),
        ),
      );
      return;
    }

    setState(() {
      _selectedGoal = savedGoal;
      _savedMascots = mascots;
      _checkingSavedUser = false;
    });
  }

  void _continue() {
    final goal = _selectedGoal;
    if (goal == null) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/mascot-hub'),
        builder: (_) => MascotHubScreen(
          careerGoal: goal.title,
          onboarding: true,
          initialSelection: _savedMascots,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Stack(
        children: [
          const Positioned.fill(child: _Starfield()),
          Positioned(
            top: -80,
            right: -75,
            child: IgnorePointer(
              child: Image.asset(
                'assets/images/planets/neptune.png',
                width: 230,
                height: 230,
                fit: BoxFit.contain,
                opacity: const AlwaysStoppedAnimation(0.2),
              ),
            ),
          ),
          SafeArea(
            child: _checkingSavedUser
                ? const Center(child: CircularProgressIndicator(color: _accent))
                : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildTopBar(context),
                              const SizedBox(height: 28),
                              const Text(
                                'Mục tiêu nghề nghiệp\ncủa bạn là gì?',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 29,
                                  height: 1.18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Chọn hành tinh đích của bạn',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFFAAA5B8),
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 25),
                              for (
                                var index = 0;
                                index < careerGoals.length;
                                index++
                              ) ...[
                                CareerGoalOptionCard(
                                  goal: careerGoals[index],
                                  selected: _selectedGoal == careerGoals[index],
                                  onTap: () => setState(
                                    () => _selectedGoal = careerGoals[index],
                                  ),
                                ),
                                if (index != careerGoals.length - 1)
                                  const SizedBox(height: 10),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                        child: SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _selectedGoal == null ? null : _continue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              disabledBackgroundColor: const Color(0xFF393445),
                              foregroundColor: _background,
                              disabledForegroundColor: const Color(0xFF777181),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Tiếp tục',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Quay lại',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        const Spacer(),
        const Icon(Icons.auto_awesome_rounded, color: _cyan, size: 18),
        const SizedBox(width: 7),
        const Text(
          'UEH HERO',
          style: TextStyle(
            color: _accent,
            fontSize: 12,
            letterSpacing: 1.8,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 48),
      ],
    );
  }
}

class _Starfield extends StatelessWidget {
  const _Starfield();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StarfieldPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const stars = [
      Offset(0.08, 0.12),
      Offset(0.88, 0.2),
      Offset(0.17, 0.38),
      Offset(0.79, 0.47),
      Offset(0.93, 0.61),
      Offset(0.07, 0.73),
      Offset(0.67, 0.85),
      Offset(0.28, 0.93),
    ];
    final paint = Paint()
      ..color = const Color(0xFFBFA8FF).withValues(alpha: 0.5);
    for (var index = 0; index < stars.length; index++) {
      final star = stars[index];
      canvas.drawCircle(
        Offset(star.dx * size.width, star.dy * size.height),
        index.isEven ? 1.5 : 1,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
