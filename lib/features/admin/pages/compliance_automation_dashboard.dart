import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/security_compliance_automation_service.dart';
import '../../../locator.dart';

class _MockComplianceStatus {
  final bool isCompliant;
  final double complianceScore;
  final int violationCount;
  final DateTime lastCheckTime;

  _MockComplianceStatus({
    required this.isCompliant,
    required this.complianceScore,
    required this.violationCount,
    required this.lastCheckTime,
  });
}

class ComplianceAutomationDashboard extends StatefulWidget {
  const ComplianceAutomationDashboard({Key? key}) : super(key: key);

  @override
  State<ComplianceAutomationDashboard> createState() => _ComplianceAutomationDashboardState();
}

class _ComplianceAutomationDashboardState extends State<ComplianceAutomationDashboard> {
  final SecurityComplianceAutomationService _complianceService = locator<SecurityComplianceAutomationService>();
  Map<String, dynamic> _metrics = {};
  List<ComplianceFramework> _frameworks = [];
  List<ComplianceViolation> _recentViolations = [];
  List<ComplianceEvent> _recentEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupStreams();
  }

  void _setupStreams() {
    _complianceService.violationStream.listen((violation) {
      if (mounted) {
        setState(() {
          _recentViolations.insert(0, violation);
          if (_recentViolations.length > 20) {
            _recentViolations.removeRange(20, _recentViolations.length);
          }
        });
        _showViolationAlert(violation);
      }
    });

    _complianceService.eventStream.listen((event) {
      if (mounted) {
        setState(() {
          _recentEvents.insert(0, event);
          if (_recentEvents.length > 50) {
            _recentEvents.removeRange(50, _recentEvents.length);
          }
        });
      }
    });
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      final metrics = _complianceService.getComplianceMetrics();
      final frameworks = _complianceService.getAvailableFrameworks();
      final violations = _complianceService.getOpenViolations();
      final events = <ComplianceEvent>[];

      setState(() {
        _metrics = metrics;
        _frameworks = frameworks;
        _recentViolations = violations;
        _recentEvents = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load compliance data: $e');
    }
  }

  void _showViolationAlert(ComplianceViolation violation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: _getSeverityColor(violation.severity)),
            const SizedBox(width: 8),
            const Text('Compliance Violation'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Framework: ${violation.frameworkId}'),
            Text('Rule: ${violation.ruleId}'),
            Text('Severity: ${violation.severity.name}'),
            const SizedBox(height: 8),
            Text(violation.description),
            if (violation.remediation != null) ...[
              const SizedBox(height: 16),
              const Text('Remediation:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(violation.remediation!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Acknowledge'),
          ),
          if (violation.remediation != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resolveViolation(violation);
              },
              child: const Text('Resolve'),
            ),
        ],
      ),
    );
  }

  Color _getSeverityColor(ComplianceSeverity severity) {
    switch (severity) {
      case ComplianceSeverity.critical:
        return Colors.red.shade800;
      case ComplianceSeverity.high:
        return Colors.orange.shade800;
      case ComplianceSeverity.medium:
        return Colors.yellow.shade700;
      case ComplianceSeverity.low:
        return Colors.blue.shade600;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compliance Automation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.assessment),
            onPressed: _runComplianceAssessment,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetricsSection(),
                    const SizedBox(height: 24),
                    _buildFrameworksSection(),
                    const SizedBox(height: 24),
                    _buildViolationsSection(),
                    const SizedBox(height: 24),
                    _buildEventsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text('Compliance Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              children: [
                _buildMetricTile('Total Frameworks', _metrics['total_frameworks']?.toString() ?? '0'),
                _buildMetricTile('Compliant', _metrics['compliant_frameworks']?.toString() ?? '0'),
                _buildMetricTile('Violations (7d)', _metrics['violations_7d']?.toString() ?? '0'),
                _buildMetricTile('Overall Score', '${(_metrics['overall_compliance_score'] ?? 0.0) * 100}%'),
                _buildMetricTile('Active Rules', _metrics['active_rules']?.toString() ?? '0'),
                _buildMetricTile('Last Check', _formatLastCheck(_metrics['last_check_time'])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String title, String value) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
        ],
      ),
    );
  }

  String _formatLastCheck(dynamic timestamp) {
    if (timestamp == null) return 'Never';
    if (timestamp is DateTime) {
      final now = DateTime.now();
      final diff = now.difference(timestamp);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    }
    return 'Unknown';
  }

  Widget _buildFrameworksSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.rule, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text('Compliance Frameworks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _frameworks.length,
              itemBuilder: (context, index) {
                final framework = _frameworks[index];
                final status = _createMockFrameworkStatus(framework.id);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: status.isCompliant ? Colors.green : Colors.red,
                      child: Icon(
                        status.isCompliant ? Icons.check : Icons.warning,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(framework.name),
                    subtitle: Text(framework.description),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${(status.complianceScore * 100).toStringAsFixed(1)}%'),
                        Text('${status.violationCount} violations', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    onTap: () => _showFrameworkDetails(framework, status),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViolationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text('Recent Violations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentViolations.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No recent violations'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentViolations.length,
                itemBuilder: (context, index) {
                  final violation = _recentViolations[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getSeverityColor(violation.severity),
                      child: Icon(
                        Icons.warning,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(violation.ruleId),
                    subtitle: Text('${violation.frameworkId} • ${violation.severity.name}'),
                    trailing: Text(
                      '${violation.detectedAt.hour}:${violation.detectedAt.minute.toString().padLeft(2, '0')}',
                    ),
                    onTap: () => _showViolationDetails(violation),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text('Recent Events', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentEvents.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No recent events'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentEvents.take(10).length,
                itemBuilder: (context, index) {
                  final event = _recentEvents[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getEventTypeColor(event.type),
                      child: Icon(
                        _getEventTypeIcon(event.type),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(event.type.name),
                    subtitle: Text(event.details),
                    trailing: Text(
                      '${event.timestamp.hour}:${event.timestamp.minute.toString().padLeft(2, '0')}',
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Color _getEventTypeColor(ComplianceEventType type) {
    switch (type) {
      case ComplianceEventType.ruleCheck:
        return Colors.blue;
      case ComplianceEventType.violation:
        return Colors.red;
      case ComplianceEventType.assessment:
        return Colors.green;
      case ComplianceEventType.remediation:
        return Colors.orange;
    }
  }

  IconData _getEventTypeIcon(ComplianceEventType type) {
    switch (type) {
      case ComplianceEventType.ruleCheck:
        return Icons.check;
      case ComplianceEventType.violation:
        return Icons.warning;
      case ComplianceEventType.assessment:
        return Icons.assessment;
      case ComplianceEventType.remediation:
        return Icons.build;
    }
  }

  void _showFrameworkDetails(ComplianceFramework framework, _MockComplianceStatus status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(framework.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(framework.description),
              const SizedBox(height: 16),
              Text('Compliance Score: ${(status.complianceScore * 100).toStringAsFixed(1)}%'),
              Text('Violations: ${status.violationCount}'),
              Text('Last Check: ${status.lastCheckTime}'),
              const SizedBox(height: 16),
              const Text('Requirements:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...framework.requirements.map((req) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Text('• $req'),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _runFrameworkCheck(framework.id);
            },
            child: const Text('Run Check'),
          ),
        ],
      ),
    );
  }

  void _showViolationDetails(ComplianceViolation violation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Violation Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${violation.id}'),
            Text('Framework: ${violation.frameworkId}'),
            Text('Rule: ${violation.ruleId}'),
            Text('Severity: ${violation.severity.name}'),
            Text('Timestamp: ${violation.detectedAt}'),
            const SizedBox(height: 8),
            Text(violation.description),
            if (violation.remediation != null) ...[
              const SizedBox(height: 16),
              const Text('Remediation:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(violation.remediation!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (violation.remediation != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resolveViolation(violation);
              },
              child: const Text('Resolve'),
            ),
        ],
      ),
    );
  }

  Future<void> _runComplianceAssessment() async {
    try {
      await _complianceService.runManualAssessment(
        frameworkId: 'soc2',
        assessor: 'System Admin',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compliance assessment started'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } catch (e) {
      _showError('Failed to run compliance assessment: $e');
    }
  }

  Future<void> _runFrameworkCheck(String frameworkId) async {
    try {
      // Mock compliance check - in real implementation would trigger framework-specific checks
      await Future.delayed(const Duration(seconds: 1));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Compliance check started for $frameworkId'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } catch (e) {
      _showError('Failed to run framework check: $e');
    }
  }

  Future<void> _resolveViolation(ComplianceViolation violation) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Resolving violation ${violation.id}'),
        backgroundColor: Colors.blue,
      ),
    );
    // In a real implementation, this would trigger automated remediation
    _loadData();
  }

  _MockComplianceStatus _createMockFrameworkStatus(String frameworkId) {
    // Mock compliance status for demonstration
    return _MockComplianceStatus(
      isCompliant: frameworkId.hashCode % 3 != 0,
      complianceScore: 0.75 + (frameworkId.hashCode % 25) / 100.0,
      violationCount: frameworkId.hashCode % 5,
      lastCheckTime: DateTime.now().subtract(Duration(hours: frameworkId.hashCode % 24)),
    );
  }
}
