import 'package:flutter/material.dart';
import 'package:clean_flutter/locator.dart';
import 'package:clean_flutter/features/admin/services/anomaly_data_service.dart';

class AnomalyDashboardPage extends StatefulWidget {
  const AnomalyDashboardPage({super.key});

  @override
  State<AnomalyDashboardPage> createState() => _AnomalyDashboardPageState();
}

class _AnomalyDashboardPageState extends State<AnomalyDashboardPage> {
  late final AnomalyDataService _svc;

  @override
  void initState() {
    super.initState();
    _svc = locator<AnomalyDataService>();
  }

  @override
  Widget build(BuildContext context) {
    final tenant = _svc.getTenantAnomalies();
    final geo = _svc.getGeoAnomalies();
    final ip = _svc.getIpAnomalies();
    return Scaffold(
      appBar: AppBar(title: const Text('Anomaly Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('By Tenant', tenant),
          const SizedBox(height: 16),
          _section('By Geography', geo),
          const SizedBox(height: 16),
          _section('By IP Range', ip),
        ],
      ),
    );
  }

  Widget _section(String title, List<AnomalySeries> series) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...series.map((s) => _seriesTile(s)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _seriesTile(AnomalySeries s) {
    final delta = s.current - s.baseline;
    final color = s.zScore >= 2 ? Colors.red : (s.zScore >= 1 ? Colors.orange : Colors.green);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(s.key),
      subtitle: Text('Baseline: ${s.baseline.toStringAsFixed(1)}  Current: ${s.current.toStringAsFixed(1)}  Δ ${delta.toStringAsFixed(1)}  z=${s.zScore.toStringAsFixed(2)}'),
      trailing: _sparkline(s, color),
    );
  }

  Widget _sparkline(AnomalySeries s, Color color) {
    // Simple sparkline using a custom painter to avoid extra deps
    return SizedBox(
      width: 120,
      height: 36,
      child: CustomPaint(
        painter: _SparklinePainter(s.points.map((e) => e.value).toList(), color: color),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  _SparklinePainter(this.values, {required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final span = (maxV - minV) == 0 ? 1 : (maxV - minV);
    final dx = size.width / (values.length - 1);
    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = i * dx;
      final norm = (values[i] - minV) / span;
      final y = size.height - norm * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}


