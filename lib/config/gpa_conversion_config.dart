enum GpaGradeBand {
  a('A', 4.0, 8.5),
  bPlus('B+', 3.5, 8.0),
  b('B', 3.0, 7.0),
  cPlus('C+', 2.5, 6.5),
  c('C', 2.0, 5.5),
  dPlus('D+', 1.5, 5.0),
  d('D', 1.0, 4.0),
  f('F', 0.0, 0.0);

  const GpaGradeBand(this.label, this.points, this.minimumScore10);

  final String label;
  final double points;
  final double minimumScore10;
}

/// Assumed UEH-style conversion for planning only; verify against the current
/// official UEH grading regulation before using this as an official record.
const List<GpaGradeBand> gpaGradeBands = GpaGradeBand.values;

GpaGradeBand gradeBandForScore10(double score) {
  final clamped = score.clamp(0, 10);
  return gpaGradeBands.firstWhere(
    (band) => clamped >= band.minimumScore10,
    orElse: () => GpaGradeBand.f,
  );
}

GpaGradeBand gradeBandForLabel(String label) =>
    gpaGradeBands.firstWhere((band) => band.label == label);
