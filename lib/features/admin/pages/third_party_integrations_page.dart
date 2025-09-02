import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/third_party_integrations_service.dart';

class ThirdPartyIntegrationsPage extends StatefulWidget {
  const ThirdPartyIntegrationsPage({super.key});

  @override
  State<ThirdPartyIntegrationsPage> createState() => _ThirdPartyIntegrationsPageState();
}

class _ThirdPartyIntegrationsPageState extends State<ThirdPartyIntegrationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
        title: const Text('Third-Party Integrations'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'MISP'),
            Tab(text: 'ServiceNow'),
            Tab(text: 'CSPM'),
            Tab(text: 'NVD'),
          ],
        ),
      ),
      body: Consumer<ThirdPartyIntegrationsService>(
        builder: (context, service, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(service),
              _buildMISPTab(service),
              _buildServiceNowTab(service),
              _buildCSPMTab(service),
              _buildNVDTab(service),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(ThirdPartyIntegrationsService service) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Integration Status',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...service.integrations.map((integration) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: integration.enabled ? Colors.green : Colors.grey,
                child: Icon(
                  _getIntegrationIcon(integration.type),
                  color: Colors.white,
                ),
              ),
              title: Text(integration.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status: ${integration.status}'),
                  Text('Last Sync: ${_dateFormat.format(integration.lastSync)}'),
                  Text('Endpoint: ${integration.endpoint}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => _showSettingsDialog(context, service, integration),
                  ),
                  IconButton(
                    icon: const Icon(Icons.sync),
                    onPressed: service.isSyncing ? null : () => service.syncIntegration(integration.type),
                  ),
                  Switch(
                    value: integration.enabled,
                    onChanged: (_) => service.toggleIntegration(integration.type),
                  ),
                ],
              ),
            ),
          )),
          const SizedBox(height: 24),
          const Text(
            'Sync Statistics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.event, size: 32, color: Colors.blue),
                        const SizedBox(height: 8),
                        Text('${service.syncStats['MISP'] ?? 0}'),
                        const Text('MISP Events', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.confirmation_number, size: 32, color: Colors.orange),
                        const SizedBox(height: 8),
                        Text('${service.syncStats['ServiceNow'] ?? 0}'),
                        const Text('Incidents', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.cloud_queue, size: 32, color: Colors.green),
                        const SizedBox(height: 8),
                        Text('${service.syncStats['CSPM'] ?? 0}'),
                        const Text('Findings', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.bug_report, size: 32, color: Colors.red),
                        const SizedBox(height: 8),
                        Text('${service.syncStats['NVD'] ?? 0}'),
                        const Text('CVEs', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMISPTab(ThirdPartyIntegrationsService service) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                'MISP Threat Intelligence',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: service.isSyncing ? null : () => service.syncIntegration('MISP'),
                icon: const Icon(Icons.sync),
                label: const Text('Sync Now'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: service.mispEvents.length,
            itemBuilder: (context, index) {
              final event = service.mispEvents[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                color: event.threatLevel == 'Critical' ? Colors.red.shade50 :
                       event.threatLevel == 'High' ? Colors.orange.shade50 : null,
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: _getThreatLevelColor(event.threatLevel),
                    child: Text(
                      event.threatLevel[0],
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(event.info),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ID: ${event.id} | Analysis: ${event.analysis}'),
                      Text('Date: ${_dateFormat.format(event.date)}'),
                      Wrap(
                        spacing: 4,
                        children: event.tags.map((tag) => 
                          Chip(
                            label: Text(tag, style: const TextStyle(fontSize: 10)),
                            visualDensity: VisualDensity.compact,
                          )
                        ).toList(),
                      ),
                    ],
                  ),
                  trailing: event.published 
                      ? const Icon(Icons.public, color: Colors.green)
                      : const Icon(Icons.lock, color: Colors.grey),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Organization: ${event.orgc}'),
                          Text('Distribution: ${event.distribution}'),
                          Text('Attributes: ${event.attributeCount}'),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.visibility, size: 16),
                                label: const Text('View Details'),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.download, size: 16),
                                label: const Text('Export IOCs'),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.share, size: 16),
                                label: const Text('Share'),
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
          ),
        ),
      ],
    );
  }

  Widget _buildServiceNowTab(ThirdPartyIntegrationsService service) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                'ServiceNow Incidents',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _createIncidentDialog(context, service),
                icon: const Icon(Icons.add),
                label: const Text('Create Incident'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: service.serviceNowIncidents.length,
            itemBuilder: (context, index) {
              final incident = service.serviceNowIncidents[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getPriorityColor(incident.priority),
                    child: Text(
                      incident.priority,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  title: Text('${incident.number}: ${incident.shortDescription}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('State: ${incident.state} | Assigned: ${incident.assignedTo}'),
                      Text('Impact: ${incident.impact} | Urgency: ${incident.urgency}'),
                      Text('Created: ${_dateFormat.format(incident.createdOn)}'),
                      if (incident.state == 'Resolved')
                        Text('Resolved by: ${incident.resolvedBy}'),
                    ],
                  ),
                  trailing: _getStateIcon(incident.state),
                  onTap: () => _showIncidentDetails(context, incident),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCSPMTab(ThirdPartyIntegrationsService service) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: const Text(
            'Cloud Security Posture Management',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: service.cspmFindings.length,
            itemBuilder: (context, index) {
              final finding = service.cspmFindings[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: _getSeverityColor(finding.severity),
                    child: Icon(
                      _getCloudProviderIcon(finding.cloudProvider),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text('${finding.cloudProvider} - ${finding.service}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(finding.description),
                      Text('Resource: ${finding.resource}'),
                      Text('Region: ${finding.region} | Risk Score: ${finding.riskScore}'),
                      Row(
                        children: [
                          Chip(
                            label: Text(finding.severity, style: const TextStyle(fontSize: 10)),
                            backgroundColor: _getSeverityColor(finding.severity).withOpacity(0.2),
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 4),
                          Chip(
                            label: Text(finding.status, style: const TextStyle(fontSize: 10)),
                            visualDensity: VisualDensity.compact,
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
                          Text('Compliance: ${finding.complianceFramework} - ${finding.control}'),
                          const SizedBox(height: 8),
                          const Text('Remediation:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(finding.remediation),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: finding.status == 'Acknowledged' ? null : 
                                    () => service.acknowledgeFinding(finding.id),
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text('Acknowledge'),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.build, size: 16),
                                label: const Text('Remediate'),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.cancel, size: 16),
                                label: const Text('Suppress'),
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
          ),
        ),
      ],
    );
  }

  Widget _buildNVDTab(ThirdPartyIntegrationsService service) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: const Text(
            'NVD Vulnerability Database',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: service.nvdVulnerabilities.length,
            itemBuilder: (context, index) {
              final vuln = service.nvdVulnerabilities[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: _getSeverityColor(vuln.severity),
                    child: Text(
                      vuln.cvssScore.toStringAsFixed(1),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(vuln.cveId),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vuln.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Chip(
                            label: Text(vuln.severity, style: const TextStyle(fontSize: 10)),
                            backgroundColor: _getSeverityColor(vuln.severity).withOpacity(0.2),
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 4),
                          if (vuln.exploitAvailable)
                            const Chip(
                              label: Text('Exploit Available', style: TextStyle(fontSize: 10)),
                              backgroundColor: Colors.red,
                              labelStyle: TextStyle(color: Colors.white),
                              visualDensity: VisualDensity.compact,
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
                          Text('CVSS Vector: ${vuln.vector}'),
                          Text('CWE: ${vuln.cweId}'),
                          Text('Published: ${_dateFormat.format(vuln.publishedDate)}'),
                          Text('Modified: ${_dateFormat.format(vuln.modifiedDate)}'),
                          const SizedBox(height: 8),
                          const Text('Affected Products:', style: TextStyle(fontWeight: FontWeight.bold)),
                          ...vuln.affectedProducts.map((p) => Text('• $p')),
                          const SizedBox(height: 8),
                          const Text('References:', style: TextStyle(fontWeight: FontWeight.bold)),
                          ...vuln.references.take(3).map((r) => Text('• $r', style: const TextStyle(fontSize: 12))),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Helper Methods
  IconData _getIntegrationIcon(String type) {
    switch (type) {
      case 'MISP': return Icons.event;
      case 'ServiceNow': return Icons.confirmation_number;
      case 'CSPM': return Icons.cloud_queue;
      case 'NVD': return Icons.bug_report;
      default: return Icons.integration_instructions;
    }
  }

  Color _getThreatLevelColor(String level) {
    switch (level) {
      case 'Critical': return Colors.red;
      case 'High': return Colors.orange;
      case 'Medium': return Colors.yellow.shade700;
      default: return Colors.green;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'P1': return Colors.red;
      case 'P2': return Colors.orange;
      case 'P3': return Colors.yellow.shade700;
      default: return Colors.green;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'Critical': return Colors.red;
      case 'High': return Colors.orange;
      case 'Medium': return Colors.yellow.shade700;
      default: return Colors.green;
    }
  }

  IconData _getCloudProviderIcon(String provider) {
    switch (provider) {
      case 'AWS': return Icons.cloud;
      case 'Azure': return Icons.cloud_circle;
      case 'GCP': return Icons.cloud_queue;
      default: return Icons.cloud_outlined;
    }
  }

  Widget _getStateIcon(String state) {
    switch (state) {
      case 'New':
        return const Icon(Icons.fiber_new, color: Colors.blue);
      case 'In Progress':
        return const Icon(Icons.pending, color: Colors.orange);
      case 'Resolved':
        return const Icon(Icons.check_circle, color: Colors.green);
      default:
        return const Icon(Icons.help_outline);
    }
  }

  void _showSettingsDialog(BuildContext context, ThirdPartyIntegrationsService service, IntegrationConfig integration) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${integration.name} Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Endpoint'),
              controller: TextEditingController(text: integration.endpoint),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'API Key'),
              controller: TextEditingController(text: integration.apiKey),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => service.testConnection(integration.type),
              icon: const Icon(Icons.network_check),
              label: const Text('Test Connection'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Save settings
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _createIncidentDialog(BuildContext context, ThirdPartyIntegrationsService service) {
    String description = '';
    String priority = 'P2';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create ServiceNow Incident'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Description'),
              onChanged: (value) => description = value,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: ['P1', 'P2', 'P3', 'P4'].map((p) => 
                DropdownMenuItem(value: p, child: Text(p))
              ).toList(),
              onChanged: (value) => priority = value ?? 'P2',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              service.createServiceNowIncident(description, priority);
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showIncidentDetails(BuildContext context, ServiceNowIncident incident) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(incident.number),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Description: ${incident.shortDescription}'),
              const SizedBox(height: 8),
              Text('State: ${incident.state}'),
              Text('Priority: ${incident.priority}'),
              Text('Category: ${incident.category}'),
              Text('Assigned To: ${incident.assignedTo}'),
              Text('Impact: ${incident.impact}'),
              Text('Urgency: ${incident.urgency}'),
              const SizedBox(height: 8),
              Text('Created: ${_dateFormat.format(incident.createdOn)}'),
              Text('Updated: ${_dateFormat.format(incident.updatedOn)}'),
              if (incident.state == 'Resolved') ...[
                const SizedBox(height: 8),
                Text('Resolved By: ${incident.resolvedBy}'),
                Text('Close Notes: ${incident.closeNotes}'),
              ],
            ],
          ),
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
