import 'dart:math';
import 'package:flutter/foundation.dart';

class SloTimeseriesPoint {
  final DateTime timestamp;
  final double value;
  SloTimeseriesPoint(this.timestamp, this.value);
}

class SloOverviewKpis {
  final double detectionLatencyP50Ms;
  final double detectionLatencyP95Ms;
  final double mttrMinutes;
  final double falsePositiveRatePct;
  final double coveragePct;
  SloOverviewKpis({
    required this.detectionLatencyP50Ms,
    required this.detectionLatencyP95Ms,
    required this.mttrMinutes,
    required this.falsePositiveRatePct,
    required this.coveragePct,
  });
}

class SloMetricsService with ChangeNotifier {
  final Random _rand = Random(42);

  SloOverviewKpis getOverviewKpis() {
    // Simulated KPIs; in real app, fetch from backend/telemetry
    return SloOverviewKpis(
      detectionLatencyP50Ms: 650.0 + _rand.nextInt(200).toDouble(),
      detectionLatencyP95Ms: 1800.0 + _rand.nextInt(400).toDouble(),
      mttrMinutes: 22.0 + _rand.nextInt(10).toDouble(),
      falsePositiveRatePct: 3.0 + _rand.nextDouble() * 2.0,
      coveragePct: 89.0 + _rand.nextDouble() * 6.0,
    );
  }

  List<SloTimeseriesPoint> getDetectionLatencySeries({int hours = 24}) {
    return _series(hours, base: 800, variance: 300, floor: 200, cap: 3000);
  }

  List<SloTimeseriesPoint> getMttrSeries({int days = 14}) {
    return _series(days, stepMinutes: 60 * 24, base: 25, variance: 8, floor: 5, cap: 90);
  }

  List<SloTimeseriesPoint> getFalsePositiveRateSeries({int days = 14}) {
    return _series(days, stepMinutes: 60 * 24, base: 3.5, variance: 1.5, floor: 0.5, cap: 10);
  }

  List<SloTimeseriesPoint> getCoverageSeries({int days = 14}) {
    return _series(days, stepMinutes: 60 * 24, base: 92, variance: 4, floor: 70, cap: 100);
  }

  List<SloTimeseriesPoint> _series(int points, {int stepMinutes = 60, required double base, required double variance, required double floor, required double cap}) {
    final List<SloTimeseriesPoint> list = [];
    DateTime t = DateTime.now().subtract(Duration(minutes: stepMinutes * points));
    for (int i = 0; i < points; i++) {
      final noise = (_rand.nextDouble() * 2 - 1) * variance;
      double v = base + noise + (sin(i / 3) * variance / 2);
      v = v.clamp(floor, cap);
      list.add(SloTimeseriesPoint(t, v.toDouble()));
      t = t.add(Duration(minutes: stepMinutes));
    }
    return list;
  }
}


