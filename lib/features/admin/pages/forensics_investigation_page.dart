import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/forensics_investigation_service.dart';

class ForensicsInvestigationPage extends StatefulWidget {
  const ForensicsInvestigationPage({super.key});

  @override
  State<ForensicsInvestigationPage> createState() => _ForensicsInvestigationPageState();
}

class _ForensicsInvestigationPageState extends State<ForensicsInvestigationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

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
        title: const Text('Forensics & Investigation'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Timeline'),
            Tab(text: 'Memory'),
            Tab(text: 'Network'),
            Tab(text: 'Files'),
            Tab(text: 'Evidence'),
          ],
        ),
      ),
      body: Consumer<ForensicsInvestigationService>(
        builder: (context, service, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildTimelineTab(service),
              _buildMemoryTab(service),
              _buildNetworkTab(service),
              _buildFilesTab(service),
              _buildEvidenceTab(service),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimelineTab(ForensicsInvestigationService service) {
    final correlatedEvents = service.correlatedEvents;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search Events',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {},
                ),
              ),
            ],
          ),
        ),
        
        if (correlatedEvents.isNotEmpty)
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: correlatedEvents.length,
              itemBuilder: (context, index) {
                final correlationId = correlatedEvents.keys.elementAt(index);
                final events = correlatedEvents[correlationId]!;
                return Card(
                  child: Container(
                    width: 200,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Correlation: ${correlationId.substring(0, 8)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('${events.length} events'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        
        Expanded(
          child: ListView.builder(
            itemCount: service.timelineEvents.length,
            itemBuilder: (context, index) {
              final event = service.timelineEvents[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getSeverityColor(event.severity),
                    child: Icon(
                      _getEventIcon(event.type),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(event.description),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${event.source} - ${event.type}'),
                      Text(
                        _dateFormat.format(event.timestamp),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMemoryTab(ForensicsInvestigationService service) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: service.isAnalyzingMemory ? Colors.red.shade50 : null,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  service.isAnalyzingMemory 
                      ? 'Memory Analysis Active' 
                      : 'Memory Analysis Inactive',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: service.isAnalyzingMemory ? Colors.red : null,
                  ),
                ),
              ),
              Switch(
                value: service.isAnalyzingMemory,
                onChanged: (_) => service.toggleMemoryAnalysis(),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => service.captureMemoryDump('Server_Main'),
                icon: const Icon(Icons.memory),
                label: const Text('Capture Dump'),
              ),
            ],
          ),
        ),
        
        Container(
          height: 150,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: service.memoryDumps.isEmpty
              ? const Center(child: Text('No memory dumps captured'))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: service.memoryDumps.length,
                  itemBuilder: (context, index) {
                    final dump = service.memoryDumps[index];
                    return Card(
                      child: Container(
                        width: 200,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dump.system,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('Size: ${dump.size} MB'),
                            Text('Status: ${dump.status}'),
                            if (dump.findings > 0)
                              Text('Findings: ${dump.findings}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        
        Expanded(
          child: ListView.builder(
            itemCount: service.processAnalyses.length,
            itemBuilder: (context, index) {
              final process = service.processAnalyses[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                color: process.isSuspicious ? Colors.red.shade50 : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: process.isSuspicious ? Colors.red : Colors.blue,
                    child: Icon(
                      process.isSuspicious ? Icons.warning : Icons.memory,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text('${process.processName} (PID: ${process.processId})'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Parent: ${process.parentProcess}'),
                      Row(
                        children: [
                          Text('CPU: ${process.cpuUsage.toStringAsFixed(1)}%'),
                          const SizedBox(width: 16),
                          Text('Memory: ${process.memoryUsage} MB'),
                        ],
                      ),
                      if (process.suspicionReasons.isNotEmpty)
                        ...process.suspicionReasons.map((reason) => 
                          Text('⚠ $reason', style: const TextStyle(color: Colors.red, fontSize: 12))
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkTab(ForensicsInvestigationService service) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: service.isCapturingPackets ? Colors.green.shade50 : null,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  service.isCapturingPackets 
                      ? 'Capturing Packets (${service.capturedPackets.length})' 
                      : 'Packet Capture Inactive',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: service.isCapturingPackets ? Colors.green : null,
                  ),
                ),
              ),
              Switch(
                value: service.isCapturingPackets,
                onChanged: (_) => service.togglePacketCapture(),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: ListView.builder(
            itemCount: service.capturedPackets.length,
            itemBuilder: (context, index) {
              final packet = service.capturedPackets[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                color: packet.isMalicious ? Colors.red.shade50 : null,
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    packet.isMalicious ? Icons.warning : Icons.wifi,
                    color: packet.isMalicious ? Colors.red : Colors.blue,
                    size: 20,
                  ),
                  title: Text(
                    '${packet.sourceIp}:${packet.sourcePort} → ${packet.destinationIp}:${packet.destinationPort}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text('${packet.protocol} | ${packet.size} bytes | ${packet.flags}'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilesTab(ForensicsInvestigationService service) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: service.isMonitoringFiles ? Colors.blue.shade50 : null,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  service.isMonitoringFiles 
                      ? 'File Monitoring Active' 
                      : 'File Monitoring Inactive',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: service.isMonitoringFiles ? Colors.blue : null,
                  ),
                ),
              ),
              Switch(
                value: service.isMonitoringFiles,
                onChanged: (_) => service.toggleFileMonitoring(),
              ),
            ],
          ),
        ),
        
        if (service.fileChanges.isNotEmpty)
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: service.fileChanges.length,
              itemBuilder: (context, index) {
                final change = service.fileChanges[index];
                return Card(
                  color: Colors.orange.shade50,
                  child: Container(
                    width: 250,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          change.path,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text('Type: ${change.changeType}'),
                        Text(
                          _dateFormat.format(change.timestamp),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        
        Expanded(
          child: ListView.builder(
            itemCount: service.fileHashes.length,
            itemBuilder: (context, index) {
              final path = service.fileHashes.keys.elementAt(index);
              final hash = service.fileHashes[path]!;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.insert_drive_file, size: 20),
                  ),
                  title: Text(path),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hash: ${hash.hash.substring(0, 32)}...'),
                      Text('Size: ${_formatBytes(hash.size)}'),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEvidenceTab(ForensicsInvestigationService service) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: const Text(
            'Evidence Management',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        
        Expanded(
          child: ListView.builder(
            itemCount: service.evidenceItems.length,
            itemBuilder: (context, index) {
              final evidence = service.evidenceItems[index];
              final custody = service.custodyLogs[evidence.id] ?? [];
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: _getEvidenceTypeColor(evidence.type),
                    child: Icon(
                      _getEvidenceIcon(evidence.type),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(evidence.description),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Case: ${evidence.caseId} | Type: ${evidence.type}'),
                      Text('Status: ${evidence.status}'),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Location: ${evidence.location}'),
                          Text('Collected By: ${evidence.collectedBy}'),
                          Text('Date: ${_dateFormat.format(evidence.collectionDate)}'),
                          const SizedBox(height: 16),
                          const Text(
                            'Chain of Custody',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (custody.isEmpty)
                            const Text('No custody logs')
                          else
                            ...custody.map((log) => Card(
                              child: ListTile(
                                dense: true,
                                title: Text('${log.action} by ${log.person}'),
                                subtitle: Text(log.notes),
                                trailing: Text(
                                  _dateFormat.format(log.timestamp),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            )),
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
  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'Critical': return Colors.red;
      case 'High': return Colors.orange;
      case 'Medium': return Colors.yellow.shade700;
      default: return Colors.green;
    }
  }

  Color _getEvidenceTypeColor(String type) {
    switch (type) {
      case 'Digital': return Colors.blue;
      case 'Physical': return Colors.brown;
      case 'Documentary': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'Login': return Icons.login;
      case 'FileAccess': return Icons.folder_open;
      case 'NetworkConnection': return Icons.wifi;
      case 'ProcessStart': return Icons.play_arrow;
      case 'RegistryChange': return Icons.settings;
      default: return Icons.event;
    }
  }

  IconData _getEvidenceIcon(String type) {
    switch (type) {
      case 'Digital': return Icons.computer;
      case 'Physical': return Icons.inventory;
      case 'Documentary': return Icons.description;
      default: return Icons.folder;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
