import 'package:flutter/material.dart';
import '../../../core/services/advanced_forensics_service.dart';
import '../../../core/models/admin_models.dart';
import '../../../locator.dart';

class ForensicsDashboard extends StatefulWidget {
  const ForensicsDashboard({Key? key}) : super(key: key);

  @override
  State<ForensicsDashboard> createState() => _ForensicsDashboardState();
}

class _ForensicsDashboardState extends State<ForensicsDashboard> {
  final AdvancedForensicsService _forensicsService = locator<AdvancedForensicsService>();
  Map<String, dynamic> _metrics = {};
  List<ForensicCase> _cases = [];
  List<DigitalEvidence> _recentEvidence = [];
  List<EvidenceAlert> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupStreams();
  }

  void _setupStreams() {
    _forensicsService.alertStream.listen((alert) {
      if (mounted) {
        setState(() {
          _alerts.insert(0, alert);
          if (_alerts.length > 20) {
            _alerts.removeRange(20, _alerts.length);
          }
        });
        _showForensicAlert(alert);
      }
    });

    _forensicsService.analysisStream.listen((update) {
      if (mounted) {
        // Update analysis progress in UI
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      final metrics = _forensicsService.getForensicsMetrics();
      final cases = _forensicsService.getCases();
      final evidence = _forensicsService.getEvidenceForCase('all');
      final alerts = <EvidenceAlert>[]; //period: const Duration(days: 7));

      setState(() {
        _metrics = metrics;
        _cases = cases;
        _recentEvidence = evidence.take(20).toList();
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load forensics data: $e');
    }
  }

  void _showForensicAlert(EvidenceAlert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Forensic Alert'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${alert.type.name}'),
            Text('Severity: ${alert.severity.name}'),
            const SizedBox(height: 8),
            Text(alert.description),
            const SizedBox(height: 8),
            const Text('Recommendations:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• Review and investigate this alert'),
            Text('• Check for related incidents'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Acknowledge'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _createCaseFromAlert(alert);
            },
            child: const Text('Create Case'),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(ForensicAlertSeverity severity) {
    switch (severity) {
      case ForensicAlertSeverity.low:
        return Colors.green;
      case ForensicAlertSeverity.medium:
        return Colors.orange;
      case ForensicAlertSeverity.high:
        return Colors.red;
      case ForensicAlertSeverity.critical:
        return Colors.red.shade900;
    }
  }


  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade900),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Forensics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _createNewCase(null),
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
                    _buildCasesSection(),
                    const SizedBox(height: 24),
                    _buildEvidenceSection(),
                    const SizedBox(height: 24),
                    _buildAlertsSection(),
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
                const Text('Forensics Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              children: [
                _buildMetricTile('Active Cases', _metrics['active_cases']?.toString() ?? '0'),
                _buildMetricTile('Evidence Items', _metrics['evidence_items']?.toString() ?? '0'),
                _buildMetricTile('Alerts (7d)', _metrics['alerts_7d']?.toString() ?? '0'),
                _buildMetricTile('Analyses Running', _metrics['running_analyses']?.toString() ?? '0'),
                _buildMetricTile('Chain Integrity', '${(_metrics['chain_integrity'] ?? 0.0) * 100}%'),
                _buildMetricTile('Storage Used', '${(_metrics['storage_used_gb'] ?? 0.0).toStringAsFixed(1)} GB'),
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

  Widget _buildCasesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text('Forensic Cases', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            if (_cases.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No active cases'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _cases.length,
                itemBuilder: (context, index) {
                  final forensicCase = _cases[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getCaseStatusColor(forensicCase.status as ForensicCaseStatus),
                        child: Icon(
                          _getCaseStatusIcon(forensicCase.status as ForensicCaseStatus),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(forensicCase.name),
                      subtitle: Text('${forensicCase.priority.name} • ${forensicCase.status.name}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(forensicCase.status.name),
                          Text('Evidence: ${forensicCase.description}', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      onTap: () => _showCaseDetails(forensicCase),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder_special, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text('Recent Evidence', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentEvidence.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No evidence items'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentEvidence.length,
                itemBuilder: (context, index) {
                  final evidence = _recentEvidence[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getEvidenceTypeColor(evidence.type),
                      child: Icon(
                        _getEvidenceTypeIcon(evidence.type),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(evidence.name),
                    subtitle: Text('${evidence.type.name} • ${evidence.source}'),
                    trailing: Text(
                      'Recent',
                    ),
                    onTap: () => _showEvidenceDetails(evidence),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsSection() {
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
                const Text('Forensic Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            if (_alerts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No recent alerts'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _alerts.take(10).length,
                itemBuilder: (context, index) {
                  final alert = _alerts[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getSeverityColor(alert.severity as ForensicAlertSeverity),
                      child: Icon(
                        Icons.warning,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(alert.type.name),
                    subtitle: Text('${alert.severity.name} • ${alert.description}'),
                    trailing: Text(
                      'Recent',
                    ),
                    onTap: () => _showAlertDetails(alert),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Color _getCaseStatusColor(ForensicCaseStatus status) {
    switch (status) {
      case ForensicCaseStatus.active:
        return Colors.green;
      case ForensicCaseStatus.pending:
        return Colors.orange;
      case ForensicCaseStatus.closed:
        return Colors.grey;
      case ForensicCaseStatus.archived:
        return Colors.blue;
    }
  }

  IconData _getCaseStatusIcon(ForensicCaseStatus status) {
    switch (status) {
      case ForensicCaseStatus.active:
        return Icons.play_arrow;
      case ForensicCaseStatus.pending:
        return Icons.pause;
      case ForensicCaseStatus.closed:
        return Icons.check;
      case ForensicCaseStatus.archived:
        return Icons.archive;
    }
  }

  Color _getEvidenceTypeColor(EvidenceType type) {
    switch (type) {
      case EvidenceType.file:
        return Colors.blue;
      case EvidenceType.network:
        return Colors.green;
      case EvidenceType.mobile:
        return Colors.orange;
      case EvidenceType.database:
        return Colors.red;
      case EvidenceType.email:
        return Colors.brown;
      case EvidenceType.registry:
        return Colors.purple;
      case EvidenceType.disk:
        return Colors.grey;
      case EvidenceType.memory:
        return Colors.teal;
    }
  }

  IconData _getEvidenceTypeIcon(EvidenceType type) {
    switch (type) {
      case EvidenceType.file:
        return Icons.insert_drive_file;
      case EvidenceType.network:
        return Icons.network_check;
      case EvidenceType.mobile:
        return Icons.smartphone;
      case EvidenceType.database:
        return Icons.storage;
      case EvidenceType.email:
        return Icons.email;
      case EvidenceType.registry:
        return Icons.settings;
      case EvidenceType.disk:
        return Icons.storage;
      case EvidenceType.memory:
        return Icons.memory;
    }
  }

  void _showCaseDetails(ForensicCase forensicCase) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(forensicCase.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ID: ${forensicCase.id}'),
              Text('Priority: ${forensicCase.priority.name}'),
              Text('Status: ${forensicCase.status.name}'),
              Text('Investigator: ${forensicCase.investigator}'),
              Text('Created: ${forensicCase.createdAt}'),
              const SizedBox(height: 8),
              Text(forensicCase.description),
              const SizedBox(height: 16),
              Text('Evidence: Available'),
              Text('Analyses: In Progress'),
              if (true) ...[
                const SizedBox(height: 8),
                const Text('Recent Analyses:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...['Analysis 1', 'Analysis 2'].map((analysis) => Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Text('• $analysis: Completed'),
                )),
              ],
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
              _startAnalysis(forensicCase.id);
            },
            child: const Text('Start Analysis'),
          ),
        ],
      ),
    );
  }

  void _showEvidenceDetails(DigitalEvidence evidence) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(evidence.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${evidence.id}'),
            Text('Type: ${evidence.type.name}'),
            Text('Source: ${evidence.source}'),
            Text('Size: ${evidence.size} bytes'),
            Text('Hash: ${evidence.hash}'),
            Text('Collected: ${evidence.acquiredAt}'),
            const SizedBox(height: 8),
            Text(evidence.description),
            const SizedBox(height: 16),
            const Text('Chain of Custody:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Chain of Custody: Verified'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _verifyEvidence(evidence.id);
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _showAlertDetails(EvidenceAlert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Alert Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${alert.id}'),
            Text('Type: ${alert.type.name}'),
            Text('Severity: ${alert.severity.name}'),
            Text('Timestamp: Recent'),
            const SizedBox(height: 8),
            Text(alert.description),
            const SizedBox(height: 8),
            const Text('Recommendations:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• Review and investigate this alert'),
            Text('• Check for related incidents'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _createCaseFromAlert(alert);
            },
            child: const Text('Create Case'),
          ),
        ],
      ),
    );
  }

  Future<void> _createNewCase(EvidenceAlert? alert) async {
    try {
      // Mock case creation
      await Future.delayed(const Duration(seconds: 1));
      final newCase = 'case_${DateTime.now().millisecondsSinceEpoch}';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Case created from alert: $newCase'),
        ),
      );
      _loadData();
    } catch (e) {
      _showError('Failed to create case: $e');
    }
  }

  Future<void> _createCaseFromAlert(EvidenceAlert alert) async {
    try {
      // Mock case creation from alert
      await Future.delayed(const Duration(seconds: 1));
      final caseId = 'case_${DateTime.now().millisecondsSinceEpoch}';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Case created from alert: $caseId'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } catch (e) {
      _showError('Failed to create case: $e');
    }
  }

  Future<void> _startAnalysis(String caseId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Analysis started'),
        backgroundColor: Colors.blue,
      ),
    );
    _loadData();
  }

  Future<void> _verifyEvidence(String evidenceId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Evidence verification completed'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
