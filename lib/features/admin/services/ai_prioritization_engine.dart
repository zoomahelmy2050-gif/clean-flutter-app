import 'dart:math';

class PrioritizationItem {
  final String id;
  final String type; // e.g., incident, action, task
  final Map<String, dynamic> attributes; // riskScore, impact, urgency, confidence, cost, slaMinutes

  PrioritizationItem({
    required this.id,
    required this.type,
    required this.attributes,
  });
}

class PrioritizedResult {
  final String id;
  final double score; // 0..100
  final String rationale; // compact explanation

  PrioritizedResult({required this.id, required this.score, required this.rationale});
}

class AIPrioritizationEngine {
  final Map<String, double> _weights;

  AIPrioritizationEngine({Map<String, double>? weights})
      : _weights = weights ?? const {
          'risk': 0.35,
          'impact': 0.25,
          'urgency': 0.20,
          'confidence': 0.10,
          'cost': -0.05, // negative reduces priority
          'sla': 0.15,
        };

  List<PrioritizedResult> prioritize(List<PrioritizationItem> items) {
    final results = <PrioritizedResult>[];
    for (final item in items) {
      final attrs = item.attributes;
      final risk = _clamp01(_toDouble(attrs['riskScore'] ?? attrs['risk'] ?? 0) / 100);
      final impact = _clamp01(_toDouble(attrs['impact'] ?? 0) / 100);
      final urgency = _clamp01(_toDouble(attrs['urgency'] ?? 0) / 100);
      final confidence = _clamp01(_toDouble(attrs['confidence'] ?? 75) / 100);
      final cost = _clamp01(_toDouble(attrs['cost'] ?? 0) / 100);
      final slaMinutes = _toDouble(attrs['slaMinutes'] ?? 0);
      final sla = _slaPressure(slaMinutes);

      double score = 0.0;
      score += _weights['risk']! * risk;
      score += _weights['impact']! * impact;
      score += _weights['urgency']! * urgency;
      score += _weights['confidence']! * confidence;
      score += _weights['cost']! * cost; // negative
      score += _weights['sla']! * sla;

      final normalized = (score * 100).clamp(0, 100).toDouble();
      final rationale = _buildRationale(risk, impact, urgency, confidence, cost, sla);
      results.add(PrioritizedResult(id: item.id, score: normalized, rationale: rationale));
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  double _slaPressure(double minutes) {
    if (minutes <= 0) return 0.0;
    // < 30 minutes left -> heavy pressure; 30..240 linear decay; > 240 minimal pressure
    if (minutes <= 30) return 1.0;
    if (minutes >= 240) return 0.1;
    final t = (240 - minutes) / (240 - 30);
    return t.clamp(0.1, 1.0).toDouble();
  }

  String _buildRationale(double risk, double impact, double urgency, double confidence, double cost, double sla) {
    final parts = <String>[];
    if (risk >= 0.6) parts.add('high risk');
    if (impact >= 0.5) parts.add('notable impact');
    if (urgency >= 0.5) parts.add('urgent');
    if (sla >= 0.5) parts.add('SLA pressure');
    if (confidence < 0.4) parts.add('low confidence');
    if (cost >= 0.6) parts.add('high cost');
    if (parts.isEmpty) parts.add('balanced');
    return parts.join(', ');
  }

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) {
      final parsed = double.tryParse(v);
      if (parsed != null) return parsed;
    }
    return 0.0;
  }

  double _clamp01(double x) => max(0.0, min(1.0, x));
}
