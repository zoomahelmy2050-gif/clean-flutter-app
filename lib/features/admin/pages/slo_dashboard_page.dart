import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clean_flutter/features/admin/services/slo_metrics_service.dart';

class SloDashboardPage extends StatelessWidget {
  const SloDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<SloMetricsService>();
    final kpis = svc.getOverviewKpis();
    final detLat = svc.getDetectionLatencySeries();
    final mttr = svc.getMttrSeries();
    final fpr = svc.getFalsePositiveRateSeries();
    final cov = svc.getCoverageSeries();

    return Scaffold(
      appBar: AppBar(title: const Text('SLO Observability')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(spacing: 12, runSpacing: 12, children: [
              _kpiCard('P50 Detection Latency', '${kpis.detectionLatencyP50Ms.toStringAsFixed(0)} ms', Icons.speed),
              _kpiCard('P95 Detection Latency', '${kpis.detectionLatencyP95Ms.toStringAsFixed(0)} ms', Icons.bolt),
              _kpiCard('MTTR', '${kpis.mttrMinutes.toStringAsFixed(1)} min', Icons.timer),
              _kpiCard('False Positive Rate', '${kpis.falsePositiveRatePct.toStringAsFixed(2)}%', Icons.report_problem),
              _kpiCard('Detection Coverage', '${kpis.coveragePct.toStringAsFixed(1)}%', Icons.shield),
            ]),
            const SizedBox(height: 16),
            _seriesCard('Detection Latency (ms)', detLat),
            _seriesCard('MTTR (minutes)', mttr),
            _seriesCard('False Positive Rate (%)', fpr),
            _seriesCard('Coverage (%)', cov),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _seriesCard(String title, List<SloTimeseriesPoint> series) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 140,
              child: CustomPaint(
                painter: _SparklinePainter(series),
                child: Container(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<SloTimeseriesPoint> series;
  _SparklinePainter(this.series);

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) return;
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final minV = series.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final maxV = series.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV) == 0 ? 1 : (maxV - minV);
    final stepX = size.width / (series.length - 1);

    final path = Path();
    for (int i = 0; i < series.length; i++) {
      final x = i * stepX;
      final norm = (series[i].value - minV) / range;
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
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) => false;
}


