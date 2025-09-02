import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:math';
import 'package:clean_flutter/core/services/real_time_analytics_service.dart';
import 'package:clean_flutter/locator.dart';

class AdvancedThreatVisualization extends StatefulWidget {
  const AdvancedThreatVisualization({super.key});

  @override
  State<AdvancedThreatVisualization> createState() => _AdvancedThreatVisualizationState();
}

class _AdvancedThreatVisualizationState extends State<AdvancedThreatVisualization>
    with TickerProviderStateMixin {
  final RealTimeAnalyticsService _analyticsService = locator<RealTimeAnalyticsService>();
  
  late AnimationController _radarController;
  late AnimationController _pulseController;
  late Animation<double> _radarAnimation;
  late Animation<double> _pulseAnimation;

  List<ThreatEvent> _threatData = [];
  List<SecurityMetrics> _metricsData = [];
  StreamSubscription<ThreatEvent>? _threatSubscription;
  StreamSubscription<SecurityMetrics>? _metricsSubscription;

  String _selectedVisualizationType = 'radar';
  String _selectedSeverityFilter = 'all';
  bool _isRealTimeMode = true;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _radarAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(_radarController);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initializeStreams();
    _loadInitialData();
  }

  @override
  void dispose() {
    _radarController.dispose();
    _pulseController.dispose();
    _threatSubscription?.cancel();
    _metricsSubscription?.cancel();
    super.dispose();
  }

  void _initializeStreams() {
    if (_isRealTimeMode) {
      _threatSubscription = _analyticsService.threatStream.listen((threat) {
        setState(() {
          _threatData.add(threat);
          if (_threatData.length > 100) _threatData.removeAt(0);
        });
      });

      _metricsSubscription = _analyticsService.metricsStream.listen((metrics) {
        setState(() {
          _metricsData.add(metrics);
          if (_metricsData.length > 50) _metricsData.removeAt(0);
        });
      });
    }
  }

  void _loadInitialData() {
    setState(() {
      _threatData = _analyticsService.getThreatHistory(period: const Duration(hours: 24));
      _metricsData = _analyticsService.getMetricsHistory(period: const Duration(hours: 24));
    });
  }

  List<ThreatEvent> get _filteredThreats {
    if (_selectedSeverityFilter == 'all') return _threatData;
    return _threatData.where((threat) => 
      threat.severity.toLowerCase() == _selectedSeverityFilter.toLowerCase()
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E27),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildControlPanel(),
          const SizedBox(height: 20),
          Expanded(
            child: _buildVisualization(),
          ),
          const SizedBox(height: 20),
          _buildThreatLegend(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isRealTimeMode ? _pulseAnimation.value : 1.0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _isRealTimeMode ? Colors.red : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 12),
        const Text(
          'Advanced Threat Visualization',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red),
          ),
          child: Text(
            '${_filteredThreats.length} Active Threats',
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Text(
            'Visualization:',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          ...['radar', 'heatmap', 'network', 'timeline'].map((type) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(type.toUpperCase()),
                selected: _selectedVisualizationType == type,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedVisualizationType = type;
                    });
                  }
                },
                selectedColor: const Color(0xFF00D4AA),
                backgroundColor: const Color(0xFF2A2F4A),
                labelStyle: TextStyle(
                  color: _selectedVisualizationType == type ? Colors.black : Colors.white,
                  fontSize: 10,
                ),
              ),
            );
          }).toList(),
          const SizedBox(width: 20),
          const Text(
            'Severity:',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          ...['all', 'critical', 'high', 'medium', 'low'].map((severity) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(severity.toUpperCase()),
                selected: _selectedSeverityFilter == severity,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedSeverityFilter = severity;
                    });
                  }
                },
                selectedColor: _getSeverityColor(severity),
                backgroundColor: const Color(0xFF2A2F4A),
                labelStyle: TextStyle(
                  color: _selectedSeverityFilter == severity ? Colors.black : Colors.white,
                  fontSize: 10,
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildVisualization() {
    switch (_selectedVisualizationType) {
      case 'radar':
        return _buildRadarVisualization();
      case 'heatmap':
        return _buildHeatmapVisualization();
      case 'network':
        return _buildNetworkVisualization();
      case 'timeline':
        return _buildTimelineVisualization();
      default:
        return _buildRadarVisualization();
    }
  }

  Widget _buildRadarVisualization() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Radar background
          CustomPaint(
            size: Size.infinite,
            painter: RadarBackgroundPainter(),
          ),
          // Animated radar sweep
          AnimatedBuilder(
            animation: _radarAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: RadarSweepPainter(_radarAnimation.value),
              );
            },
          ),
          // Threat points
          CustomPaint(
            size: Size.infinite,
            painter: ThreatPointsPainter(_filteredThreats),
          ),
          // Threat details overlay
          ..._buildThreatOverlays(),
        ],
      ),
    );
  }

  Widget _buildHeatmapVisualization() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomPaint(
        size: Size.infinite,
        painter: ThreatHeatmapPainter(_filteredThreats),
      ),
    );
  }

  Widget _buildNetworkVisualization() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomPaint(
        size: Size.infinite,
        painter: ThreatNetworkPainter(_filteredThreats),
      ),
    );
  }

  Widget _buildTimelineVisualization() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 1,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.white.withOpacity(0.1),
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.white.withOpacity(0.1),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}h',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  );
                },
                reservedSize: 42,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          minX: 0,
          maxX: 24,
          minY: 0,
          maxY: 10,
          lineBarsData: [
            LineChartBarData(
              spots: _generateTimelineSpots(),
              isCurved: true,
              gradient: LinearGradient(
                colors: [Colors.red.withOpacity(0.8), Colors.orange.withOpacity(0.8)],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.red,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.red.withOpacity(0.3),
                    Colors.red.withOpacity(0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _generateTimelineSpots() {
    final spots = <FlSpot>[];
    final now = DateTime.now();
    
    for (int i = 0; i < 24; i++) {
      final hourStart = now.subtract(Duration(hours: 23 - i));
      final hourEnd = hourStart.add(const Duration(hours: 1));
      
      final threatsInHour = _filteredThreats.where((threat) =>
        threat.timestamp.isAfter(hourStart) && threat.timestamp.isBefore(hourEnd)
      ).length;
      
      spots.add(FlSpot(i.toDouble(), threatsInHour.toDouble()));
    }
    
    return spots;
  }

  List<Widget> _buildThreatOverlays() {
    return _filteredThreats.take(10).map((threat) {
      final random = Random(threat.id.hashCode);
      final x = random.nextDouble() * 0.8 + 0.1;
      final y = random.nextDouble() * 0.8 + 0.1;
      
      return Positioned(
        left: x * 400,
        top: y * 400,
        child: GestureDetector(
          onTap: () => _showThreatDetails(threat),
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getSeverityColor(threat.severity),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getSeverityColor(threat.severity).withOpacity(0.6),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    }).toList();
  }

  void _showThreatDetails(ThreatEvent threat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: Text(
          threat.type,
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Severity', threat.severity, _getSeverityColor(threat.severity)),
            _buildDetailRow('Risk Score', threat.riskScore.toStringAsFixed(1), Colors.orange),
            _buildDetailRow('Source', threat.source, Colors.blue),
            _buildDetailRow('Target', threat.targetAsset, Colors.green),
            _buildDetailRow('Status', threat.status, Colors.purple),
            const SizedBox(height: 12),
            const Text(
              'Description:',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              threat.description,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildThreatLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem('Critical', Colors.red),
          _buildLegendItem('High', Colors.orange),
          _buildLegendItem('Medium', Colors.yellow),
          _buildLegendItem('Low', Colors.green),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    final count = _threatData.where((t) => t.severity.toLowerCase() == label.toLowerCase()).length;
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label ($count)',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

// Custom Painters for advanced visualizations
class RadarBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) / 2 - 20;

    // Draw concentric circles
    for (int i = 1; i <= 5; i++) {
      canvas.drawCircle(center, maxRadius * i / 5, paint);
    }

    // Draw radial lines
    for (int i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      final endPoint = Offset(
        center.dx + maxRadius * cos(angle),
        center.dy + maxRadius * sin(angle),
      );
      canvas.drawLine(center, endPoint, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RadarSweepPainter extends CustomPainter {
  final double sweepAngle;

  RadarSweepPainter(this.sweepAngle);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) / 2 - 20;

    final gradient = SweepGradient(
      startAngle: sweepAngle,
      endAngle: sweepAngle + pi / 3,
      colors: [
        Colors.green.withOpacity(0.0),
        Colors.green.withOpacity(0.3),
        Colors.green.withOpacity(0.0),
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: maxRadius));

    canvas.drawCircle(center, maxRadius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ThreatPointsPainter extends CustomPainter {
  final List<ThreatEvent> threats;

  ThreatPointsPainter(this.threats);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) / 2 - 20;

    for (final threat in threats.take(20)) {
      final random = Random(threat.id.hashCode);
      final angle = random.nextDouble() * 2 * pi;
      final distance = random.nextDouble() * maxRadius;
      
      final position = Offset(
        center.dx + distance * cos(angle),
        center.dy + distance * sin(angle),
      );

      final paint = Paint()
        ..color = _getThreatColor(threat.severity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(position, threat.riskScore, paint);
    }
  }

  Color _getThreatColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ThreatHeatmapPainter extends CustomPainter {
  final List<ThreatEvent> threats;

  ThreatHeatmapPainter(this.threats);

  @override
  void paint(Canvas canvas, Size size) {
    const gridSize = 20;
    final cellWidth = size.width / gridSize;
    final cellHeight = size.height / gridSize;

    final heatmap = List.generate(gridSize, (_) => List.filled(gridSize, 0.0));

    // Generate heatmap data
    for (final threat in threats) {
      final random = Random(threat.id.hashCode);
      final x = (random.nextDouble() * gridSize).floor();
      final y = (random.nextDouble() * gridSize).floor();
      heatmap[y][x] += threat.riskScore;
    }

    // Draw heatmap
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        final intensity = (heatmap[y][x] / 10).clamp(0.0, 1.0);
        if (intensity > 0) {
          final paint = Paint()
            ..color = Color.lerp(Colors.transparent, Colors.red, intensity)!;

          canvas.drawRect(
            Rect.fromLTWH(x * cellWidth, y * cellHeight, cellWidth, cellHeight),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ThreatNetworkPainter extends CustomPainter {
  final List<ThreatEvent> threats;

  ThreatNetworkPainter(this.threats);

  @override
  void paint(Canvas canvas, Size size) {
    final nodes = <Offset>[];
    final center = Offset(size.width / 2, size.height / 2);

    // Generate node positions
    for (int i = 0; i < threats.length && i < 15; i++) {
      final random = Random(threats[i].id.hashCode);
      nodes.add(Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      ));
    }

    // Draw connections
    final connectionPaint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..strokeWidth = 1;

    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final distance = (nodes[i] - nodes[j]).distance;
        if (distance < 150) {
          canvas.drawLine(nodes[i], nodes[j], connectionPaint);
        }
      }
    }

    // Draw nodes
    for (int i = 0; i < nodes.length; i++) {
      final threat = threats[i];
      final paint = Paint()
        ..color = _getThreatColor(threat.severity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(nodes[i], 8, paint);
    }
  }

  Color _getThreatColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
