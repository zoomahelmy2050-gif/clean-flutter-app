import 'dart:convert';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ForensicsInvestigationService extends ChangeNotifier {
  // Timeline Analysis
  final List<TimelineEvent> _timelineEvents = [];
  final Map<String, List<TimelineEvent>> _correlatedEvents = {};
  
  // Memory Forensics
  final List<MemoryDump> _memoryDumps = [];
  final List<ProcessAnalysis> _processAnalyses = [];
  
  // Network Packet Analysis
  final List<NetworkPacket> _capturedPackets = [];
  final Map<String, PacketStatistics> _packetStats = {};
  
  // File Integrity Monitoring
  final Map<String, FileHash> _fileHashes = {};
  final List<FileChange> _fileChanges = [];
  
  // Evidence Chain of Custody
  final List<Evidence> _evidenceItems = [];
  final Map<String, List<CustodyLog>> _custodyLogs = {};
  
  // Incident Reconstruction
  final List<IncidentReconstruction> _reconstructions = [];
  
  // Forensic Tools Status
  bool _isCapturingPackets = false;
  bool _isMonitoringFiles = false;
  bool _isAnalyzingMemory = false;

  ForensicsInvestigationService() {
    _initialize();
  }

  // Getters
  List<TimelineEvent> get timelineEvents => List.unmodifiable(_timelineEvents);
  Map<String, List<TimelineEvent>> get correlatedEvents => Map.unmodifiable(_correlatedEvents);
  List<MemoryDump> get memoryDumps => List.unmodifiable(_memoryDumps);
  List<ProcessAnalysis> get processAnalyses => List.unmodifiable(_processAnalyses);
  List<NetworkPacket> get capturedPackets => List.unmodifiable(_capturedPackets);
  Map<String, PacketStatistics> get packetStats => Map.unmodifiable(_packetStats);
  Map<String, FileHash> get fileHashes => Map.unmodifiable(_fileHashes);
  List<FileChange> get fileChanges => List.unmodifiable(_fileChanges);
  List<Evidence> get evidenceItems => List.unmodifiable(_evidenceItems);
  Map<String, List<CustodyLog>> get custodyLogs => Map.unmodifiable(_custodyLogs);
  List<IncidentReconstruction> get reconstructions => List.unmodifiable(_reconstructions);
  bool get isCapturingPackets => _isCapturingPackets;
  bool get isMonitoringFiles => _isMonitoringFiles;
  bool get isAnalyzingMemory => _isAnalyzingMemory;

  Future<void> _initialize() async {
    await _loadData();
    _generateMockData();
    _startForensicMonitoring();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load timeline events
    final eventsJson = prefs.getString('forensics_timeline_events');
    if (eventsJson != null) {
      final events = json.decode(eventsJson) as List;
      _timelineEvents.clear();
      _timelineEvents.addAll(events.map((e) => TimelineEvent.fromJson(e)));
    }
    
    // Load evidence items
    final evidenceJson = prefs.getString('forensics_evidence');
    if (evidenceJson != null) {
      final items = json.decode(evidenceJson) as List;
      _evidenceItems.clear();
      _evidenceItems.addAll(items.map((e) => Evidence.fromJson(e)));
    }
    
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save timeline events
    await prefs.setString('forensics_timeline_events',
        json.encode(_timelineEvents.map((e) => e.toJson()).toList()));
    
    // Save evidence items
    await prefs.setString('forensics_evidence',
        json.encode(_evidenceItems.map((e) => e.toJson()).toList()));
  }

  void _generateMockData() {
    final random = Random();
    final now = DateTime.now();
    
    // Generate timeline events
    for (int i = 0; i < 50; i++) {
      _timelineEvents.add(TimelineEvent(
        id: 'event_$i',
        timestamp: now.subtract(Duration(minutes: random.nextInt(1440))),
        source: ['System', 'Network', 'Application', 'User'][random.nextInt(4)],
        type: ['Login', 'FileAccess', 'NetworkConnection', 'ProcessStart', 'RegistryChange'][random.nextInt(5)],
        description: 'Event description $i',
        severity: ['Low', 'Medium', 'High', 'Critical'][random.nextInt(4)],
        artifacts: ['log_$i.txt', 'memory_$i.dmp'],
        correlationId: random.nextBool() ? 'correlation_${random.nextInt(10)}' : null,
      ));
    }
    
    // Correlate events
    _correlateTimelineEvents();
    
    // Generate memory dumps
    for (int i = 0; i < 3; i++) {
      _memoryDumps.add(MemoryDump(
        id: 'dump_$i',
        timestamp: now.subtract(Duration(hours: i * 8)),
        size: random.nextInt(8000) + 2000, // MB
        system: 'Server_${i + 1}',
        status: i == 0 ? 'Analyzing' : 'Completed',
        findings: i > 0 ? random.nextInt(5) : 0,
      ));
    }
    
    // Generate process analyses
    for (int i = 0; i < 10; i++) {
      _processAnalyses.add(ProcessAnalysis(
        processId: random.nextInt(10000),
        processName: ['chrome.exe', 'svchost.exe', 'explorer.exe', 'notepad.exe'][random.nextInt(4)],
        parentProcess: 'explorer.exe',
        startTime: now.subtract(Duration(hours: random.nextInt(24))),
        memoryUsage: random.nextInt(500) + 50,
        cpuUsage: random.nextDouble() * 100,
        networkConnections: random.nextInt(10),
        isSuspicious: random.nextDouble() > 0.8,
        suspicionReasons: random.nextDouble() > 0.8 
            ? ['Unusual network activity', 'Memory injection detected'] 
            : [],
      ));
    }
    
    // Generate network packets
    for (int i = 0; i < 100; i++) {
      final packet = NetworkPacket(
        id: 'packet_$i',
        timestamp: now.subtract(Duration(seconds: random.nextInt(3600))),
        sourceIp: '192.168.1.${random.nextInt(255)}',
        destinationIp: '10.0.0.${random.nextInt(255)}',
        sourcePort: random.nextInt(65535),
        destinationPort: [80, 443, 22, 3389, 8080][random.nextInt(5)],
        protocol: ['TCP', 'UDP', 'ICMP'][random.nextInt(3)],
        size: random.nextInt(1500) + 50,
        flags: ['SYN', 'ACK', 'FIN', 'RST'][random.nextInt(4)],
        payload: 'Encrypted',
        isMalicious: random.nextDouble() > 0.95,
      );
      _capturedPackets.add(packet);
      
      // Update statistics
      final key = '${packet.sourceIp}->${packet.destinationIp}';
      final stats = _packetStats[key] ?? PacketStatistics();
      stats.totalPackets++;
      stats.totalBytes += packet.size;
      _packetStats[key] = stats;
    }
    
    // Generate file hashes
    final files = [
      '/system/kernel32.dll',
      '/windows/system32/cmd.exe',
      '/users/admin/documents/report.pdf',
      '/program files/app/config.xml',
    ];
    
    for (final file in files) {
      _fileHashes[file] = FileHash(
        path: file,
        hash: _generateRandomHash(),
        algorithm: 'SHA-256',
        lastModified: now.subtract(Duration(days: random.nextInt(30))),
        size: random.nextInt(1000000),
      );
    }
    
    // Generate evidence items
    for (int i = 0; i < 5; i++) {
      final evidence = Evidence(
        id: 'evidence_$i',
        caseId: 'case_${random.nextInt(3)}',
        type: ['Digital', 'Physical', 'Documentary'][random.nextInt(3)],
        description: 'Evidence item $i',
        collectedBy: 'Investigator ${random.nextInt(3) + 1}',
        collectionDate: now.subtract(Duration(days: random.nextInt(7))),
        location: 'Location $i',
        hash: _generateRandomHash(),
        chainOfCustody: [],
        tags: ['tag${random.nextInt(5)}', 'priority${random.nextInt(3)}'],
        status: ['Collected', 'Analyzing', 'Archived'][random.nextInt(3)],
      );
      _evidenceItems.add(evidence);
      
      // Add custody logs
      _custodyLogs[evidence.id] = [
        CustodyLog(
          timestamp: evidence.collectionDate,
          action: 'Collected',
          person: evidence.collectedBy,
          notes: 'Initial collection',
        ),
      ];
    }
    
    // Generate incident reconstructions
    for (int i = 0; i < 2; i++) {
      _reconstructions.add(IncidentReconstruction(
        id: 'reconstruction_$i',
        incidentId: 'incident_$i',
        title: 'Security Incident $i',
        timeline: _timelineEvents.take(10).toList(),
        attackVector: ['Phishing', 'Malware', 'Insider Threat'][random.nextInt(3)],
        impactAssessment: 'Medium to High',
        rootCause: 'Unpatched vulnerability',
        recommendations: [
          'Apply security patches',
          'Implement MFA',
          'Enhance monitoring',
        ],
        status: i == 0 ? 'In Progress' : 'Completed',
      ));
    }
  }

  void _correlateTimelineEvents() {
    _correlatedEvents.clear();
    for (final event in _timelineEvents) {
      if (event.correlationId != null) {
        _correlatedEvents[event.correlationId!] ??= [];
        _correlatedEvents[event.correlationId!]!.add(event);
      }
    }
  }

  String _generateRandomHash() {
    final random = Random();
    const chars = '0123456789abcdef';
    return List.generate(64, (_) => chars[random.nextInt(16)]).join();
  }

  void _startForensicMonitoring() {
    // Simulate continuous monitoring
    Stream.periodic(const Duration(seconds: 10), (_) => null).listen((_) {
      if (_isCapturingPackets) {
        _captureNewPacket();
      }
      if (_isMonitoringFiles) {
        _checkFileIntegrity();
      }
      if (_isAnalyzingMemory) {
        _analyzeMemoryPattern();
      }
    });
  }

  void _captureNewPacket() {
    final random = Random();
    final now = DateTime.now();
    
    final packet = NetworkPacket(
      id: 'packet_${_capturedPackets.length}',
      timestamp: now,
      sourceIp: '192.168.1.${random.nextInt(255)}',
      destinationIp: '10.0.0.${random.nextInt(255)}',
      sourcePort: random.nextInt(65535),
      destinationPort: [80, 443, 22, 3389][random.nextInt(4)],
      protocol: ['TCP', 'UDP'][random.nextInt(2)],
      size: random.nextInt(1500) + 50,
      flags: ['SYN', 'ACK'][random.nextInt(2)],
      payload: 'Real-time capture',
      isMalicious: random.nextDouble() > 0.98,
    );
    
    _capturedPackets.insert(0, packet);
    if (_capturedPackets.length > 1000) {
      _capturedPackets.removeLast();
    }
    
    notifyListeners();
  }

  void _checkFileIntegrity() {
    final random = Random();
    if (random.nextDouble() > 0.9) {
      final files = _fileHashes.keys.toList();
      if (files.isNotEmpty) {
        final file = files[random.nextInt(files.length)];
        _fileChanges.insert(0, FileChange(
          path: file,
          timestamp: DateTime.now(),
          oldHash: _fileHashes[file]!.hash,
          newHash: _generateRandomHash(),
          changeType: 'Modified',
        ));
        
        if (_fileChanges.length > 100) {
          _fileChanges.removeLast();
        }
        
        notifyListeners();
      }
    }
  }

  void _analyzeMemoryPattern() {
    // Simulate memory analysis patterns
    final random = Random();
    if (random.nextDouble() > 0.95) {
      _processAnalyses.insert(0, ProcessAnalysis(
        processId: random.nextInt(10000),
        processName: 'suspicious.exe',
        parentProcess: 'unknown',
        startTime: DateTime.now(),
        memoryUsage: random.nextInt(500) + 100,
        cpuUsage: random.nextDouble() * 100,
        networkConnections: random.nextInt(20),
        isSuspicious: true,
        suspicionReasons: ['Anomalous behavior detected'],
      ));
      
      if (_processAnalyses.length > 50) {
        _processAnalyses.removeLast();
      }
      
      notifyListeners();
    }
  }

  // Timeline Analysis Methods
  Future<void> addTimelineEvent(TimelineEvent event) async {
    _timelineEvents.insert(0, event);
    _correlateTimelineEvents();
    await _saveData();
    notifyListeners();
  }

  List<TimelineEvent> getEventsInRange(DateTime start, DateTime end) {
    return _timelineEvents.where((e) => 
      e.timestamp.isAfter(start) && e.timestamp.isBefore(end)
    ).toList();
  }

  List<TimelineEvent> getCorrelatedEvents(String correlationId) {
    return _correlatedEvents[correlationId] ?? [];
  }

  // Memory Forensics Methods
  Future<void> captureMemoryDump(String system) async {
    final dump = MemoryDump(
      id: 'dump_${_memoryDumps.length}',
      timestamp: DateTime.now(),
      size: Random().nextInt(8000) + 2000,
      system: system,
      status: 'Capturing',
      findings: 0,
    );
    
    _memoryDumps.insert(0, dump);
    notifyListeners();
    
    // Simulate capture completion
    await Future.delayed(const Duration(seconds: 5));
    dump.status = 'Analyzing';
    notifyListeners();
    
    await Future.delayed(const Duration(seconds: 10));
    dump.status = 'Completed';
    dump.findings = Random().nextInt(5);
    await _saveData();
    notifyListeners();
  }

  void toggleMemoryAnalysis() {
    _isAnalyzingMemory = !_isAnalyzingMemory;
    notifyListeners();
  }

  // Network Packet Analysis Methods
  void togglePacketCapture() {
    _isCapturingPackets = !_isCapturingPackets;
    notifyListeners();
  }

  List<NetworkPacket> filterPackets({
    String? sourceIp,
    String? destinationIp,
    String? protocol,
    bool? maliciousOnly,
  }) {
    return _capturedPackets.where((packet) {
      if (sourceIp != null && !packet.sourceIp.contains(sourceIp)) return false;
      if (destinationIp != null && !packet.destinationIp.contains(destinationIp)) return false;
      if (protocol != null && packet.protocol != protocol) return false;
      if (maliciousOnly == true && !packet.isMalicious) return false;
      return true;
    }).toList();
  }

  // File Integrity Methods
  void toggleFileMonitoring() {
    _isMonitoringFiles = !_isMonitoringFiles;
    notifyListeners();
  }

  Future<void> addFileToMonitor(String path) async {
    _fileHashes[path] = FileHash(
      path: path,
      hash: _generateRandomHash(),
      algorithm: 'SHA-256',
      lastModified: DateTime.now(),
      size: Random().nextInt(1000000),
    );
    await _saveData();
    notifyListeners();
  }

  // Evidence Management Methods
  Future<void> addEvidence(Evidence evidence) async {
    _evidenceItems.add(evidence);
    _custodyLogs[evidence.id] = [
      CustodyLog(
        timestamp: DateTime.now(),
        action: 'Added to system',
        person: evidence.collectedBy,
        notes: 'Initial entry',
      ),
    ];
    await _saveData();
    notifyListeners();
  }

  Future<void> updateCustody(String evidenceId, String action, String person, String notes) async {
    _custodyLogs[evidenceId] ??= [];
    _custodyLogs[evidenceId]!.add(CustodyLog(
      timestamp: DateTime.now(),
      action: action,
      person: person,
      notes: notes,
    ));
    await _saveData();
    notifyListeners();
  }

  // Incident Reconstruction Methods
  Future<IncidentReconstruction> reconstructIncident(String incidentId) async {
    // Simulate reconstruction process
    await Future.delayed(const Duration(seconds: 3));
    
    final reconstruction = IncidentReconstruction(
      id: 'reconstruction_${_reconstructions.length}',
      incidentId: incidentId,
      title: 'Incident Reconstruction',
      timeline: _timelineEvents.take(20).toList(),
      attackVector: 'Under Analysis',
      impactAssessment: 'Analyzing...',
      rootCause: 'Investigation in progress',
      recommendations: [],
      status: 'In Progress',
    );
    
    _reconstructions.insert(0, reconstruction);
    notifyListeners();
    
    return reconstruction;
  }

  // Export Methods
  Map<String, dynamic> exportForensicData() {
    return {
      'exportDate': DateTime.now().toIso8601String(),
      'timelineEvents': _timelineEvents.map((e) => e.toJson()).toList(),
      'memoryDumps': _memoryDumps.map((e) => e.toJson()).toList(),
      'networkPackets': _capturedPackets.take(100).map((e) => e.toJson()).toList(),
      'fileIntegrity': _fileHashes.map((k, v) => MapEntry(k, v.toJson())),
      'evidence': _evidenceItems.map((e) => e.toJson()).toList(),
      'custodyLogs': _custodyLogs,
    };
  }
}

// Data Models
class TimelineEvent {
  final String id;
  final DateTime timestamp;
  final String source;
  final String type;
  final String description;
  final String severity;
  final List<String> artifacts;
  final String? correlationId;

  TimelineEvent({
    required this.id,
    required this.timestamp,
    required this.source,
    required this.type,
    required this.description,
    required this.severity,
    required this.artifacts,
    this.correlationId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'source': source,
    'type': type,
    'description': description,
    'severity': severity,
    'artifacts': artifacts,
    'correlationId': correlationId,
  };

  factory TimelineEvent.fromJson(Map<String, dynamic> json) => TimelineEvent(
    id: json['id'],
    timestamp: DateTime.parse(json['timestamp']),
    source: json['source'],
    type: json['type'],
    description: json['description'],
    severity: json['severity'],
    artifacts: List<String>.from(json['artifacts']),
    correlationId: json['correlationId'],
  );
}

class MemoryDump {
  final String id;
  final DateTime timestamp;
  final int size; // MB
  final String system;
  String status;
  int findings;

  MemoryDump({
    required this.id,
    required this.timestamp,
    required this.size,
    required this.system,
    required this.status,
    required this.findings,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'size': size,
    'system': system,
    'status': status,
    'findings': findings,
  };

  factory MemoryDump.fromJson(Map<String, dynamic> json) => MemoryDump(
    id: json['id'],
    timestamp: DateTime.parse(json['timestamp']),
    size: json['size'],
    system: json['system'],
    status: json['status'],
    findings: json['findings'],
  );
}

class ProcessAnalysis {
  final int processId;
  final String processName;
  final String parentProcess;
  final DateTime startTime;
  final int memoryUsage; // MB
  final double cpuUsage; // Percentage
  final int networkConnections;
  final bool isSuspicious;
  final List<String> suspicionReasons;

  ProcessAnalysis({
    required this.processId,
    required this.processName,
    required this.parentProcess,
    required this.startTime,
    required this.memoryUsage,
    required this.cpuUsage,
    required this.networkConnections,
    required this.isSuspicious,
    required this.suspicionReasons,
  });
}

class NetworkPacket {
  final String id;
  final DateTime timestamp;
  final String sourceIp;
  final String destinationIp;
  final int sourcePort;
  final int destinationPort;
  final String protocol;
  final int size;
  final String flags;
  final String payload;
  final bool isMalicious;

  NetworkPacket({
    required this.id,
    required this.timestamp,
    required this.sourceIp,
    required this.destinationIp,
    required this.sourcePort,
    required this.destinationPort,
    required this.protocol,
    required this.size,
    required this.flags,
    required this.payload,
    required this.isMalicious,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'sourceIp': sourceIp,
    'destinationIp': destinationIp,
    'sourcePort': sourcePort,
    'destinationPort': destinationPort,
    'protocol': protocol,
    'size': size,
    'flags': flags,
    'payload': payload,
    'isMalicious': isMalicious,
  };

  factory NetworkPacket.fromJson(Map<String, dynamic> json) => NetworkPacket(
    id: json['id'],
    timestamp: DateTime.parse(json['timestamp']),
    sourceIp: json['sourceIp'],
    destinationIp: json['destinationIp'],
    sourcePort: json['sourcePort'],
    destinationPort: json['destinationPort'],
    protocol: json['protocol'],
    size: json['size'],
    flags: json['flags'],
    payload: json['payload'],
    isMalicious: json['isMalicious'],
  );
}

class PacketStatistics {
  int totalPackets = 0;
  int totalBytes = 0;
}

class FileHash {
  final String path;
  final String hash;
  final String algorithm;
  final DateTime lastModified;
  final int size;

  FileHash({
    required this.path,
    required this.hash,
    required this.algorithm,
    required this.lastModified,
    required this.size,
  });

  Map<String, dynamic> toJson() => {
    'path': path,
    'hash': hash,
    'algorithm': algorithm,
    'lastModified': lastModified.toIso8601String(),
    'size': size,
  };

  factory FileHash.fromJson(Map<String, dynamic> json) => FileHash(
    path: json['path'],
    hash: json['hash'],
    algorithm: json['algorithm'],
    lastModified: DateTime.parse(json['lastModified']),
    size: json['size'],
  );
}

class FileChange {
  final String path;
  final DateTime timestamp;
  final String oldHash;
  final String newHash;
  final String changeType;

  FileChange({
    required this.path,
    required this.timestamp,
    required this.oldHash,
    required this.newHash,
    required this.changeType,
  });
}

class Evidence {
  final String id;
  final String caseId;
  final String type;
  final String description;
  final String collectedBy;
  final DateTime collectionDate;
  final String location;
  final String hash;
  final List<String> chainOfCustody;
  final List<String> tags;
  final String status;

  Evidence({
    required this.id,
    required this.caseId,
    required this.type,
    required this.description,
    required this.collectedBy,
    required this.collectionDate,
    required this.location,
    required this.hash,
    required this.chainOfCustody,
    required this.tags,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'caseId': caseId,
    'type': type,
    'description': description,
    'collectedBy': collectedBy,
    'collectionDate': collectionDate.toIso8601String(),
    'location': location,
    'hash': hash,
    'chainOfCustody': chainOfCustody,
    'tags': tags,
    'status': status,
  };

  factory Evidence.fromJson(Map<String, dynamic> json) => Evidence(
    id: json['id'],
    caseId: json['caseId'],
    type: json['type'],
    description: json['description'],
    collectedBy: json['collectedBy'],
    collectionDate: DateTime.parse(json['collectionDate']),
    location: json['location'],
    hash: json['hash'],
    chainOfCustody: List<String>.from(json['chainOfCustody']),
    tags: List<String>.from(json['tags']),
    status: json['status'],
  );
}

class CustodyLog {
  final DateTime timestamp;
  final String action;
  final String person;
  final String notes;

  CustodyLog({
    required this.timestamp,
    required this.action,
    required this.person,
    required this.notes,
  });
}

class IncidentReconstruction {
  final String id;
  final String incidentId;
  final String title;
  final List<TimelineEvent> timeline;
  final String attackVector;
  final String impactAssessment;
  final String rootCause;
  final List<String> recommendations;
  final String status;

  IncidentReconstruction({
    required this.id,
    required this.incidentId,
    required this.title,
    required this.timeline,
    required this.attackVector,
    required this.impactAssessment,
    required this.rootCause,
    required this.recommendations,
    required this.status,
  });
}
