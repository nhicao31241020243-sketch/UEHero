import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/character_data.dart';
import '../services/mascot_selection_store.dart';
import '../widgets/mascot_role_card.dart';
import '../home_widgets_screen.dart';
import 'mascot_carousel_screen.dart';

class MascotHubScreen extends StatefulWidget {
  const MascotHubScreen({
    this.careerGoal,
    this.onboarding = false,
    this.initialSelection,
    super.key,
  });

  final String? careerGoal;
  final bool onboarding;
  final MascotSelection? initialSelection;

  @override
  State<MascotHubScreen> createState() => _MascotHubScreenState();
}

class _MascotHubScreenState extends State<MascotHubScreen> {
  static const _background = Color(0xFF100E19);
  static const _accent = Color(0xFFBFA8FF);

  final _store = MascotSelectionStore.instance;
  late MascotSelection _original;
  late MascotSelection _draft;
  bool _loading = true;
  bool _saving = false;

  bool get _hasChanges =>
      _draft.primary?.id != _original.primary?.id ||
      _draft.aiCompanion?.id != _original.aiCompanion?.id;

  @override
  void initState() {
    super.initState();
    _loadSelection();
  }

  Future<void> _loadSelection() async {
    final selection = widget.initialSelection ?? await _store.read();
    if (!mounted) return;
    setState(() {
      _original = selection;
      _draft = selection;
      _loading = false;
    });
  }

  Future<void> _choose(MascotRole role) async {
    final characters = MascotSelectionStore.charactersFor(role);
    final current = role == MascotRole.primary
        ? _draft.primary
        : _draft.aiCompanion;
    final selected = await Navigator.of(context).push<CharacterData>(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/mascot-selector'),
        builder: (_) =>
            MascotCarouselScreen(role: role, initialCharacterId: current?.id),
      ),
    );
    if (!mounted || selected == null) return;
    if (!characters.any((character) => character.id == selected.id)) return;
    setState(() {
      _draft = role == MascotRole.primary
          ? MascotSelection(primary: selected, aiCompanion: _draft.aiCompanion)
          : MascotSelection(primary: _draft.primary, aiCompanion: selected);
    });
  }

  Future<void> _confirmLeave() async {
    if (!_hasChanges) {
      Navigator.of(context).maybePop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF211D2B),
        title: const Text(
          'Bỏ thay đổi?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Các lựa chọn chưa lưu sẽ bị bỏ.',
          style: TextStyle(color: Color(0xFFAAA5B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ở lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bỏ thay đổi'),
          ),
        ],
      ),
    );
    if (!mounted || discard != true) return;
    Navigator.of(context).maybePop();
  }

  Future<void> _save() async {
    if (!_draft.isComplete || _saving) return;
    setState(() => _saving = true);
    try {
      await _store.save(_draft);
      CharacterSelection.selected = _draft.primary;
      if (!mounted) return;
      if (widget.onboarding) {
        await _saveCareerGoal();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: '/home'),
            builder: (_) => const HomeWidgetsScreen(),
          ),
          (route) => false,
        );
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể lưu lựa chọn: $error')));
    }
  }

  Future<void> _saveCareerGoal() async {
    final careerGoal = widget.careerGoal;
    if (careerGoal == null) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('career_goal', careerGoal);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _accent))
              : Column(
                  children: [
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
                            sliver: SliverList.list(
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      tooltip: 'Quay lại',
                                      onPressed: _confirmLeave,
                                      icon: const Icon(
                                        Icons.arrow_back_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Expanded(
                                      child: Text(
                                        'Linh vật của bạn',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 23,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: Text(
                                    'Chọn nhân vật đồng hành cùng hành trình UEH Hero.',
                                    style: TextStyle(
                                      color: Color(0xFFAAA5B8),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 27),
                                MascotRoleCard(
                                  role: MascotRole.primary,
                                  character: _draft.primary,
                                  onTap: () => _choose(MascotRole.primary),
                                ),
                                Transform.translate(
                                  offset: const Offset(0, -15),
                                  child: MascotRoleCard(
                                    role: MascotRole.aiCompanion,
                                    character: _draft.aiCompanion,
                                    onTap: () =>
                                        _choose(MascotRole.aiCompanion),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton(
                          onPressed:
                              !_draft.isComplete ||
                                  _saving ||
                                  (!widget.onboarding && !_hasChanges)
                              ? null
                              : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: _background,
                            disabledBackgroundColor: const Color(0xFF393445),
                            disabledForegroundColor: const Color(0xFF777181),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  widget.onboarding
                                      ? 'Xác nhận'
                                      : 'Lưu thay đổi',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
