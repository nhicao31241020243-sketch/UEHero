import 'package:flutter/material.dart';

import '../models/xp_entry.dart';
import '../services/points_manager.dart';

class XpLedgerDebugScreen extends StatelessWidget {
  const XpLedgerDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = PointsManager.instance.entries.reversed.toList();
    return Scaffold(
      backgroundColor: const Color(0xFF100E19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF100E19),
        foregroundColor: Colors.white,
        title: const Text('XP Ledger Debug'),
      ),
      body: entries.isEmpty
          ? const Center(
              child: Text(
                'Chưa có XP',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: entries.length,
              itemBuilder: (context, index) =>
                  _EntryTile(entry: entries[index]),
            ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});

  final XpEntry entry;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    title: Text(
      '+${entry.amount} XP · ${entry.skill ?? entry.bar}',
      style: const TextStyle(color: Colors.white),
    ),
    subtitle: Text(
      '${entry.source}${entry.sourceRef == null ? '' : ' · ${entry.sourceRef}'}\n'
      '${entry.createdAt.toLocal()}',
      style: const TextStyle(color: Colors.white60, fontSize: 11),
    ),
  );
}
