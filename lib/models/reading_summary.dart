class ReadingSummary {
  final double consumption; // m³
  final double cost; // €
  final String period; // e.g. "Mai 2026"
  final DateTime from;
  final DateTime to;

  const ReadingSummary({
    required this.consumption,
    required this.cost,
    required this.period,
    required this.from,
    required this.to,
  });
}
