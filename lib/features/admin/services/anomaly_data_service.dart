import 'dart:math';
import 'package:flutter/foundation.dart';

class AnomalyPoint {
  final DateTime time;
  final double value;
  const AnomalyPoint(this.time, this.value);
}

class AnomalySeries {
  final String key;
  final List<AnomalyPoint> points;
  final double baseline;
  final double current;
  final double zScore; // simple anomaly score
  const AnomalySeries({
    required this.key,
    required this.points,
    required this.baseline,
    required this.current,
    required this.zScore,
  });
}

class AnomalyDataService with ChangeNotifier {
  final Random _rng = Random(42);

  List<AnomalySeries> getTenantAnomalies({int hours = 24}) {
    return _generateSeries(keys: const ['tenant_a', 'tenant_b', 'tenant_c'], hours: hours);
  }

  List<AnomalySeries> getGeoAnomalies({int hours = 24}) {
    return _generateSeries(keys: const ['US', 'EU', 'APAC'], hours: hours);
  }

  List<AnomalySeries> getIpAnomalies({int hours = 24}) {
    return _generateSeries(keys: const ['10.0.0.0/24', '172.16.0.0/16', '203.0.113.0/24'], hours: hours);
  }

  List<AnomalySeries> _generateSeries({required List<String> keys, required int hours}) {
    final now = DateTime.now();
    return keys.map((k) {
      final base = 50 + _rng.nextInt(50);
      final pts = List<AnomalyPoint>.generate(hours, (i) {
        final t = now.subtract(Duration(hours: hours - i));
        final noise = _rng.nextDouble() * 10 - 5;
        final v = base + noise;
        return AnomalyPoint(t, v);
      });
      // inject a spike in the last few hours randomly
      final double spike = _rng.nextBool()
          ? (base + 25 + _rng.nextDouble() * 25)
          : (base + _rng.nextDouble() * 5);
      final double current = spike;
      final baseline = pts.map((e) => e.value).reduce((a, b) => a + b) / pts.length;
      final std = _stdDev(pts.map((e) => e.value).toList(), baseline);
      final double z = std == 0.0 ? 0.0 : (current - baseline) / std;
      final points = [...pts.take(pts.length - 1), AnomalyPoint(now, current)];
      return AnomalySeries(key: k, points: points, baseline: baseline, current: current, zScore: z);
    }).toList();
  }

  double _stdDev(List<double> xs, double mean) {
    if (xs.isEmpty) return 0;
    final variance = xs.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / xs.length;
    return sqrt(variance);
  }
}


