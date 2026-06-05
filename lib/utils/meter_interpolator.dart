/// Linear interpolation utility for meter readings across month boundaries.
///
/// Solves the problem of sparse readings: when no reading exists exactly at
/// a month boundary, we linearly interpolate between the surrounding readings
/// to estimate the meter value at that exact point in time.
library;

class MeterInterpolator {
  MeterInterpolator._();

  /// Estimates the meter value at [at] using the surrounding readings.
  ///
  /// - Exact match at [at]: returns that value.
  /// - Readings on both sides: linear interpolation.
  /// - Only readings before [at]: returns the last known value (flat extension).
  /// - Only readings after [at]: returns null (can't back-extrapolate).
  /// - No readings: returns null.
  static double? interpolateAt(
    List<({double value, DateTime timestamp})> readings,
    DateTime at,
  ) {
    if (readings.isEmpty) return null;

    final sorted = [...readings]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Exact match
    for (final r in sorted) {
      if (r.timestamp == at) return r.value;
    }

    final before = sorted.where((r) => r.timestamp.isBefore(at)).toList();
    final after  = sorted.where((r) => r.timestamp.isAfter(at)).toList();

    if (before.isEmpty) return null; // All readings are in the future
    if (after.isEmpty)  return before.last.value; // Use last known value

    final r0 = before.last;
    final r1 = after.first;
    final t0  = r0.timestamp.millisecondsSinceEpoch.toDouble();
    final t1  = r1.timestamp.millisecondsSinceEpoch.toDouble();
    final tAt = at.millisecondsSinceEpoch.toDouble();

    if (t1 == t0) return r0.value;

    final fraction = (tAt - t0) / (t1 - t0);
    return r0.value + fraction * (r1.value - r0.value);
  }

  /// Returns estimated consumption for a calendar month.
  ///
  /// For **completed months**: interpolates meter values at both month
  /// boundaries (midnight of day 1 → midnight of day 1 of next month) and
  /// returns their difference.
  ///
  /// For the **current (incomplete) month**: interpolates the start boundary
  /// and uses the latest available reading as the end value.
  ///
  /// Returns null when there is insufficient data to make an estimate
  /// (e.g. no readings exist before the start of the month).
  /// Returns 0.0 when data exists but consumption calculates to zero or below.
  static double? monthConsumption(
    List<({double value, DateTime timestamp})> readings,
    int year,
    int month,
  ) {
    if (readings.isEmpty) return null;

    final now  = DateTime.now();
    final isCurrentMonth = year == now.year && month == now.month;

    // Month boundary: first moment of the month
    final monthStart = DateTime(year, month, 1);

    // Interpolated value at the start of the month.
    // If no reading exists before the month start (first ever month of data),
    // fall back to the first reading within the month as a partial-month anchor.
    final monthEnd = DateTime(year, month + 1, 1);
    double startValue;
    final interpolated = interpolateAt(readings, monthStart);
    if (interpolated != null) {
      startValue = interpolated;
    } else {
      final sorted = [...readings]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final firstInMonth = sorted.where((r) =>
          !r.timestamp.isBefore(monthStart) && r.timestamp.isBefore(monthEnd)).firstOrNull;
      if (firstInMonth == null) return null;
      startValue = firstInMonth.value;
    }

    double endValue;
    if (isCurrentMonth) {
      // Current month: use the latest reading up to now as end value
      final candidates = readings
          .where((r) => !r.timestamp.isAfter(now))
          .toList();
      if (candidates.isEmpty) return null;
      endValue = candidates
          .reduce((a, b) => a.timestamp.isAfter(b.timestamp) ? a : b)
          .value;
    } else {
      // Completed month: interpolate at the first moment of next month
      final endInterpolated = interpolateAt(readings, monthEnd);
      if (endInterpolated == null) return null;
      endValue = endInterpolated;
    }

    final consumption = endValue - startValue;
    return consumption < 0 ? 0.0 : consumption;
  }
}
