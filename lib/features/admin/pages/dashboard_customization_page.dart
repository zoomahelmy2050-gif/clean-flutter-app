import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/dashboard_customization_service.dart';
import 'package:intl/intl.dart';

class DashboardCustomizationPage extends StatefulWidget {
  const DashboardCustomizationPage({Key? key}) : super(key: key);

  @override
  State<DashboardCustomizationPage> createState() => _DashboardCustomizationPageState();
}

class _DashboardCustomizationPageState extends State<DashboardCustomizationPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedRole = 'admin';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardCustomizationService>(
      builder: (context, service, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Dashboard Customization'),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () => service.resetToDefault(),
                tooltip: 'Reset to Default',
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'Role Dashboards'),
                Tab(text: 'KPI Metrics'),
                Tab(text: 'Alert Correlations'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildRoleDashboards(service),
              _buildKPIMetrics(service),
              _buildAlertCorrelations(service),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoleDashboards(DashboardCustomizationService service) {
    final roles = ['admin', 'analyst', 'executive', 'soc_manager'];
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: SegmentedButton<String>(
            segments: roles.map((role) => ButtonSegment(
              value: role,
              label: Text(role.replaceAll('_', ' ').toUpperCase()),
            )).toList(),
            selected: {_selectedRole},
            onSelectionChanged: (selection) {
              setState(() => _selectedRole = selection.first);
              service.switchRole(_selectedRole);
            },
          ),
        ),
        Expanded(
          child: service.isLoading
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: service.currentWidgets.length,
                itemBuilder: (context, index) {
                  final widget = service.currentWidgets[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(_getWidgetIcon(widget.type)),
                      title: Text(widget.title),
                      subtitle: Text('Type: ${widget.type} | Size: ${widget.size}'),
                      trailing: Switch(
                        value: widget.isVisible,
                        onChanged: (value) {
                          service.updateWidget(widget.id, {'isVisible': value});
                        },
                      ),
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildKPIMetrics(DashboardCustomizationService service) {
    final summary = service.getKPISummary();
    return Column(
      children: [
        Container(
          height: 100,
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMetricCard('Total', summary['total'], Icons.analytics),
              _buildMetricCard('Improving', summary['improving'], Icons.trending_up, Colors.green),
              _buildMetricCard('Declining', summary['declining'], Icons.trending_down, Colors.red),
              _buildMetricCard('Stable', summary['stable'], Icons.trending_flat, Colors.blue),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: service.kpiMetrics.length,
            itemBuilder: (context, index) {
              final kpi = service.kpiMetrics[index];
              return Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getTrendColor(kpi.trend),
                    child: Icon(_getTrendIcon(kpi.trend), color: Colors.white, size: 20),
                  ),
                  title: Text(kpi.name),
                  subtitle: Text('Value: ${kpi.value} | Target: ${kpi.target ?? "N/A"}'),
                  trailing: Text(
                    '${kpi.percentageChange > 0 ? "+" : ""}${kpi.percentageChange.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: kpi.percentageChange > 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCorrelations(DashboardCustomizationService service) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: service.alertCorrelations.length,
      itemBuilder: (context, index) {
        final correlation = service.alertCorrelations[index];
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: _getSeverityColor(correlation.severity),
              child: Text(
                '${(correlation.confidence * 100).toStringAsFixed(0)}%',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(correlation.name),
            subtitle: Text('Type: ${correlation.correlationType} | ${correlation.relatedAlerts.length} alerts'),
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Related Alerts: ${correlation.relatedAlerts.join(", ")}'),
                    SizedBox(height: 8),
                    Text('Detected: ${DateFormat('HH:mm:ss').format(correlation.detectedAt)}'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(String label, int value, IconData icon, [Color? color]) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color ?? Colors.grey),
        Text(value.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  IconData _getWidgetIcon(String type) {
    switch (type) {
      case 'threat_map': return Icons.public;
      case 'kpi': return Icons.trending_up;
      case 'counter': return Icons.numbers;
      case 'list': return Icons.list;
      case 'gauge': return Icons.speed;
      default: return Icons.widgets;
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case 'up': return Icons.arrow_upward;
      case 'down': return Icons.arrow_downward;
      default: return Icons.trending_flat;
    }
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'up': return Colors.green;
      case 'down': return Colors.red;
      default: return Colors.blue;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'critical': return Colors.red;
      case 'high': return Colors.orange;
      case 'medium': return Colors.yellow[700]!;
      default: return Colors.green;
    }
  }
}
