import 'package:flutter/material.dart';

import '../data/job_demo_data.dart';
import '../models/student_job.dart';

class JobFilterSheet extends StatefulWidget {
  const JobFilterSheet({required this.initialState, super.key});

  final JobFilterState initialState;

  static Future<JobFilterState?> show(
    BuildContext context, {
    required JobFilterState initialState,
  }) => showModalBottomSheet<JobFilterState>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: const Color(0xFF211D2B),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) => JobFilterSheet(initialState: initialState),
  );

  @override
  State<JobFilterSheet> createState() => _JobFilterSheetState();
}

class _JobFilterSheetState extends State<JobFilterSheet> {
  static const _accent = Color(0xFFBFA8FF);
  late Set<JobType> _types;
  late Set<JobWorkMode> _modes;
  late String _fieldId;
  late String _location;

  @override
  void initState() {
    super.initState();
    _types = {...widget.initialState.jobTypes};
    _modes = {...widget.initialState.workModes};
    _fieldId = widget.initialState.fieldId ?? '';
    _location = widget.initialState.location;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Bộ lọc công việc',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                  ),
                ),
              ),
              TextButton(
                onPressed: _clear,
                child: const Text('Xóa lọc', style: TextStyle(color: _accent)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _sectionTitle('Loại việc'),
          Wrap(
            spacing: 8,
            children: [
              for (final type in JobType.values)
                FilterChip(
                  label: Text(type.label),
                  selected: _types.contains(type),
                  onSelected: (selected) => setState(
                    () => selected ? _types.add(type) : _types.remove(type),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _sectionTitle('Hình thức làm việc'),
          Wrap(
            spacing: 8,
            children: [
              for (final mode in JobWorkMode.values)
                FilterChip(
                  label: Text(mode.label),
                  selected: _modes.contains(mode),
                  onSelected: (selected) => setState(
                    () => selected ? _modes.add(mode) : _modes.remove(mode),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _sectionTitle('Ngành IT'),
          DropdownButtonFormField<String>(
            initialValue: _fieldId,
            dropdownColor: const Color(0xFF302A3B),
            decoration: _decoration(),
            style: const TextStyle(color: Colors.white),
            items: [
              const DropdownMenuItem(value: '', child: Text('Tất cả ngành')),
              for (final field in jobFields)
                DropdownMenuItem(value: field.id, child: Text(field.label)),
            ],
            onChanged: (value) => setState(() => _fieldId = value ?? ''),
          ),
          const SizedBox(height: 14),
          _sectionTitle('Địa điểm'),
          DropdownButtonFormField<String>(
            initialValue: _location,
            dropdownColor: const Color(0xFF302A3B),
            decoration: _decoration(),
            style: const TextStyle(color: Colors.white),
            items: const [
              DropdownMenuItem(
                value: 'TP. Hồ Chí Minh',
                child: Text('TP. Hồ Chí Minh'),
              ),
              DropdownMenuItem(value: 'Hà Nội', child: Text('Hà Nội')),
              DropdownMenuItem(value: 'Đà Nẵng', child: Text('Đà Nẵng')),
              DropdownMenuItem(value: 'Toàn quốc', child: Text('Toàn quốc')),
              DropdownMenuItem(value: 'Remote', child: Text('Remote')),
            ],
            onChanged: (value) =>
                setState(() => _location = value ?? 'Toàn quốc'),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clear,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Xóa lọc'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _apply,
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: const Color(0xFF171321),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Áp dụng'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFFAAA5B8),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  InputDecoration _decoration() => InputDecoration(
    filled: true,
    fillColor: Colors.white.withValues(alpha: .06),
    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: .1)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: .1)),
    ),
  );

  void _clear() {
    _types = {};
    _modes = {};
    _fieldId = '';
    _location = 'Toàn quốc';
    setState(() {});
    Navigator.pop(
      context,
      widget.initialState.copyWith(
        jobTypes: const {},
        workModes: const {},
        clearField: true,
        location: _location,
      ),
    );
  }

  void _apply() => Navigator.pop(
    context,
    widget.initialState.copyWith(
      jobTypes: _types,
      workModes: _modes,
      fieldId: _fieldId,
      clearField: _fieldId.isEmpty,
      location: _location,
    ),
  );
}
