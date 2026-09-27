import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'core/theme/app_colors.dart';
import 'features/gpa_lab/game/gpa_physics_game.dart';

void main() {
  runApp(const GpaForgePreviewApp());
}

class GpaForgePreviewApp extends StatefulWidget {
  const GpaForgePreviewApp({super.key});

  @override
  State<GpaForgePreviewApp> createState() => _GpaForgePreviewAppState();
}

class _GpaForgePreviewAppState extends State<GpaForgePreviewApp> {
  late final GpaPhysicsGame game;

  @override
  void initState() {
    super.initState();
    game = GpaPhysicsGame();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Forge2D — Checkpoint 3',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                ValueListenableBuilder<String>(
                  valueListenable: game.status,
                  builder: (context, status, _) {
                    return Text(
                      status,
                      style: TextStyle(
                        color: status.startsWith('SNAPPED')
                            ? AppColors.success
                            : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      color: const Color(0xFF111113),
                      child: GameWidget(game: game),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
