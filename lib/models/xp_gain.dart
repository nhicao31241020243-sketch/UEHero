class XpGain {
  const XpGain({
    required this.amount,
    required this.skill,
    required this.bar,
    required this.leveledUp,
    required this.at,
  });

  final int amount;
  final String? skill;
  final String bar;
  final bool leveledUp;
  final DateTime at;
}
