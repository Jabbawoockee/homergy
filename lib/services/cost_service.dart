class CostService {
  static const fallbackKwhPerM3 = 10.55;

  double calculateCost(
    double consumptionM3, {
    required double pricePerKwh,
    double monthlyBasePrice = 0,
    double brennwert = 0,
    double zustandszahl = 0,
  }) {
    final factor = (brennwert > 0 && zustandszahl > 0)
        ? brennwert * zustandszahl
        : fallbackKwhPerM3;
    return consumptionM3 * factor * pricePerKwh + monthlyBasePrice;
  }

  double kwhFromM3(double m3, {double brennwert = 0, double zustandszahl = 0}) {
    final factor = (brennwert > 0 && zustandszahl > 0)
        ? brennwert * zustandszahl
        : fallbackKwhPerM3;
    return m3 * factor;
  }
}
