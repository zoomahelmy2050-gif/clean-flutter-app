import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/emerging_threats_service.dart';

class EmergingThreatsPage extends StatefulWidget {
  const EmergingThreatsPage({super.key});

  @override
  State<EmergingThreatsPage> createState() => _EmergingThreatsPageState();
}

class _EmergingThreatsPageState extends State<EmergingThreatsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emerging Threats Management'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.warning), text: 'Threats'),
            Tab(icon: Icon(Icons.devices), text: 'IoT'),
            Tab(icon: Icon(Icons.view_in_ar), text: 'Containers'),
            Tab(icon: Icon(Icons.api), text: 'APIs'),
            Tab(icon: Icon(Icons.local_shipping), text: 'Supply Chain'),
          ],
        ),
      ),
      body: Consumer<EmergingThreatsService>(
        builder: (context, service, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverview(service),
              _buildThreats(service),
              _buildIoTDevices(service),
              _buildContainers(service),
              _buildAPIs(service),
              _buildSupplyChain(service),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverview(EmergingThreatsService service) {
    final summary = service.getThreatSummary();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Threat Level Card
          Card(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: summary['criticalThreats'] > 0
                      ? [Colors.red.shade400, Colors.red.shade600]
                      : summary['activeThreats'] > 0
                          ? [Colors.orange.shade400, Colors.orange.shade600]
                          : [Colors.green.shade400, Colors.green.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        summary['criticalThreats'] > 0
                            ? Icons.error
                            : summary['activeThreats'] > 0
                                ? Icons.warning
                                : Icons.shield,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              summary['criticalThreats'] > 0
                                  ? 'Critical Threats Detected'
                                  : summary['activeThreats'] > 0
                                      ? 'Active Threats Monitoring'
                                      : 'Systems Secure',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${summary['activeThreats']} active threats, ${summary['criticalThreats']} critical',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildStatCard(
                'IoT Devices',
                '${summary['vulnerableDevices']}/${summary['totalDevices']}',
                Icons.devices,
                Colors.blue,
                subtitle: 'vulnerable',
              ),
              _buildStatCard(
                'Containers',
                '${summary['nonCompliantContainers']}/${summary['totalContainers']}',
                Icons.view_in_ar,
                Colors.purple,
                subtitle: 'non-compliant',
              ),
              _buildStatCard(
                'API Endpoints',
                '${summary['vulnerableAPIs']}/${summary['totalAPIs']}',
                Icons.api,
                Colors.orange,
                subtitle: 'with issues',
              ),
              _buildStatCard(
                'Supply Chain',
                '${summary['highRiskSuppliers']}/${summary['totalSuppliers']}',
                Icons.local_shipping,
                Colors.red,
                subtitle: 'high risk',
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Active Mitigations
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.teal,
                child: Icon(Icons.build_circle, color: Colors.white),
              ),
              title: const Text('Active Mitigations'),
              subtitle: Text('${summary['activeMitigations']} mitigations in progress'),
              trailing: const Icon(Icons.arrow_forward),
            ),
          ),
          const SizedBox(height: 24),
          
          // Recent Threats
          const Text(
            'Recent Threats',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...service.threats.take(3).map((threat) => _buildThreatCard(threat, service)),
        ],
      ),
    );
  }

  Widget _buildThreats(EmergingThreatsService service) {
    final threats = service.threats;
    
    if (threats.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'No Active Threats',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'All systems are secure',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: threats.length,
      itemBuilder: (context, index) {
        return _buildThreatCard(threats[index], service);
      },
    );
  }

  Widget _buildIoTDevices(EmergingThreatsService service) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: service.iotDevices.length,
      itemBuilder: (context, index) {
        final device = service.iotDevices[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: device.isSecure ? Colors.green : Colors.red,
              child: Icon(
                Icons.devices,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(device.name),
            subtitle: Text('${device.type} - ${device.manufacturer}'),
            trailing: Chip(
              label: Text(
                device.isSecure ? 'Secure' : 'Vulnerable',
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: device.isSecure 
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Firmware', device.firmware),
                    _buildDetailRow('Last Seen', DateFormat('HH:mm:ss').format(device.lastSeen)),
                    const Divider(),
                    if (device.vulnerabilities.isNotEmpty) ...[
                      const Text(
                        'Vulnerabilities',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...device.vulnerabilities.map((v) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.error, size: 16, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(v),
                          ],
                        ),
                      )),
                      const Divider(),
                    ],
                    const Text(
                      'Security Status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...device.securityStatus.entries.map((e) => 
                      _buildDetailRow(e.key, e.value.toString()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContainers(EmergingThreatsService service) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: service.containers.length,
      itemBuilder: (context, index) {
        final container = service.containers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            container.containerName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            container.image,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      container.isCompliant ? Icons.check_circle : Icons.error,
                      color: container.isCompliant ? Colors.green : Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Vulnerability Breakdown
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vulnerabilities: ${container.vulnerabilityCount}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildSeverityBadge('Critical', container.severityBreakdown['critical'] ?? 0, Colors.red),
                          _buildSeverityBadge('High', container.severityBreakdown['high'] ?? 0, Colors.orange),
                          _buildSeverityBadge('Medium', container.severityBreakdown['medium'] ?? 0, Colors.yellow.shade700),
                          _buildSeverityBadge('Low', container.severityBreakdown['low'] ?? 0, Colors.green),
                        ],
                      ),
                    ],
                  ),
                ),
                
                if (container.misconfigurations.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Misconfigurations',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                  const SizedBox(height: 4),
                  ...container.misconfigurations.map((m) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(m),
                      ],
                    ),
                  )),
                ],
                
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Scanned: ${DateFormat('MMM d, HH:mm').format(container.scannedAt)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Rescan'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAPIs(EmergingThreatsService service) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: service.apiEndpoints.length,
      itemBuilder: (context, index) {
        final api = service.apiEndpoints[index];
        final hasIssues = api.securityIssues.isNotEmpty;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: hasIssues ? Colors.orange : Colors.green,
              child: Text(
                api.method,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(api.path),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      api.hasAuthentication ? Icons.lock : Icons.lock_open,
                      size: 16,
                      color: api.hasAuthentication ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      api.hasAuthentication ? 'Authenticated' : 'No Auth',
                      style: TextStyle(
                        fontSize: 12,
                        color: api.hasAuthentication ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      api.hasRateLimiting ? Icons.speed : Icons.all_inclusive,
                      size: 16,
                      color: api.hasRateLimiting ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      api.hasRateLimiting ? 'Rate Limited' : 'No Limits',
                      style: TextStyle(
                        fontSize: 12,
                        color: api.hasRateLimiting ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${api.requestCount} requests | ${api.avgResponseTime.toStringAsFixed(0)}ms avg | ${(api.errorRate * 100).toStringAsFixed(2)}% errors',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                if (hasIssues) ...[
                  const SizedBox(height: 4),
                  ...api.securityIssues.map((issue) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            issue,
                            style: const TextStyle(fontSize: 12, color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
            ),
            isThreeLine: true,
            onTap: () => _showAPIDetails(context, api),
          ),
        );
      },
    );
  }

  Widget _buildSupplyChain(EmergingThreatsService service) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: service.supplyChainRisks.length,
      itemBuilder: (context, index) {
        final risk = service.supplyChainRisks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: _getSeverityColor(risk.riskLevel),
              child: Icon(
                Icons.local_shipping,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text('${risk.vendor} - ${risk.component}'),
            subtitle: Text('Version: ${risk.version}'),
            trailing: _buildSeverityChip(risk.riskLevel),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (risk.vulnerabilities.isNotEmpty) ...[
                      const Text(
                        'Vulnerabilities',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...risk.vulnerabilities.map((v) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.bug_report, size: 16, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(v),
                          ],
                        ),
                      )),
                      const Divider(),
                    ],
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(risk.recommendation),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Dependencies: ${risk.dependencies['direct']} direct, ${risk.dependencies['transitive']} transitive',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Update'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThreatCard(EmergingThreat threat, EmergingThreatsService service) {
    final mitigation = service.mitigations.firstWhere(
      (m) => m.threatId == threat.id,
      orElse: () => ThreatMitigation(
        threatId: '',
        title: '',
        description: '',
        status: MitigationStatus.notStarted,
        steps: [],
        startedAt: DateTime.now(),
        assignee: '',
      ),
    );
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getSeverityColor(threat.severity),
          child: Icon(
            _getCategoryIcon(threat.category),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(threat.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(threat.description),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildSeverityChip(threat.severity),
                const SizedBox(width: 8),
                Text(
                  'Risk: ${threat.riskScore.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('HH:mm').format(threat.discoveredAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (threat.affectedSystems.isNotEmpty) ...[
                  const Text(
                    'Affected Systems',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: threat.affectedSystems.map((s) => Chip(
                      label: Text(s, style: const TextStyle(fontSize: 12)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                if (threat.indicators.isNotEmpty) ...[
                  const Text(
                    'Indicators',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...threat.indicators.map((i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.info, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(i),
                      ],
                    ),
                  )),
                  const SizedBox(height: 12),
                ],
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mitigation Status',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        _buildMitigationChip(mitigation.status),
                      ],
                    ),
                    if (mitigation.threatId.isEmpty)
                      ElevatedButton(
                        onPressed: () => service.startMitigation(threat.id),
                        child: const Text('Start Mitigation'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            if (subtitle != null) ...[
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSeverityChip(ThreatSeverity severity) {
    return Chip(
      label: Text(
        severity.toString().split('.').last.toUpperCase(),
        style: const TextStyle(fontSize: 10, color: Colors.white),
      ),
      backgroundColor: _getSeverityColor(severity),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildMitigationChip(MitigationStatus status) {
    Color color;
    switch (status) {
      case MitigationStatus.notStarted:
        color = Colors.grey;
        break;
      case MitigationStatus.inProgress:
        color = Colors.blue;
        break;
      case MitigationStatus.implemented:
        color = Colors.orange;
        break;
      case MitigationStatus.verified:
        color = Colors.green;
        break;
    }
    
    return Chip(
      label: Text(
        status.toString().split('.').last,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildSeverityBadge(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  Color _getSeverityColor(ThreatSeverity severity) {
    switch (severity) {
      case ThreatSeverity.low:
        return Colors.green;
      case ThreatSeverity.medium:
        return Colors.yellow.shade700;
      case ThreatSeverity.high:
        return Colors.orange;
      case ThreatSeverity.critical:
        return Colors.red;
    }
  }

  IconData _getCategoryIcon(ThreatCategory category) {
    switch (category) {
      case ThreatCategory.iot:
        return Icons.devices;
      case ThreatCategory.container:
        return Icons.view_in_ar;
      case ThreatCategory.api:
        return Icons.api;
      case ThreatCategory.supplyChain:
        return Icons.local_shipping;
      case ThreatCategory.cloud:
        return Icons.cloud;
      case ThreatCategory.aiml:
        return Icons.psychology;
      case ThreatCategory.quantum:
        return Icons.blur_on;
    }
  }

  void _showAPIDetails(BuildContext context, APIEndpoint api) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${api.method} ${api.path}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Request Count', api.requestCount.toString()),
            _buildDetailRow('Avg Response Time', '${api.avgResponseTime.toStringAsFixed(0)}ms'),
            _buildDetailRow('Error Rate', '${(api.errorRate * 100).toStringAsFixed(2)}%'),
            _buildDetailRow('Authentication', api.hasAuthentication ? 'Yes' : 'No'),
            _buildDetailRow('Rate Limiting', api.hasRateLimiting ? 'Yes' : 'No'),
            if (api.securityIssues.isNotEmpty) ...[
              const Divider(),
              const Text('Security Issues', style: TextStyle(fontWeight: FontWeight.bold)),
              ...api.securityIssues.map((issue) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.warning, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(child: Text(issue)),
                  ],
                ),
              )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
