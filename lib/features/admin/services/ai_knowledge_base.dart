import 'ai_models.dart';

class AIKnowledgeItem {
  final String id;
  final String category;
  final String topic;
  final String content;
  final Map<String, dynamic> metadata;
  final List<String> tags;
  final DateTime lastUpdated;
  final double relevanceScore;

  AIKnowledgeItem({
    required this.id,
    required this.category,
    required this.topic,
    required this.content,
    required this.metadata,
    required this.tags,
    required this.lastUpdated,
    required this.relevanceScore,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'topic': topic,
    'content': content,
    'metadata': metadata,
    'tags': tags,
    'lastUpdated': lastUpdated.toIso8601String(),
    'relevanceScore': relevanceScore,
  };

  factory AIKnowledgeItem.fromJson(Map<String, dynamic> json) {
    return AIKnowledgeItem(
      id: json['id'],
      category: json['category'],
      topic: json['topic'],
      content: json['content'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      tags: List<String>.from(json['tags'] ?? []),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      relevanceScore: json['relevanceScore']?.toDouble() ?? 0.0,
    );
  }
}

class AIKnowledgeBase {
  static final List<AIKnowledgeItem> systemKnowledge = [
    // System Architecture Knowledge
    AIKnowledgeItem(
      id: 'KB001',
      category: 'System Architecture',
      topic: 'Security Center Overview',
      content: '''The Security Center is a comprehensive security management platform with:
      - Multi-factor authentication (MFA, biometric, behavioral)
      - Role-based access control (RBAC) with Super Admin, Admin, and User roles
      - Real-time threat monitoring and detection
      - Advanced analytics and reporting dashboards
      - Forensics and incident response capabilities
      - Automated security workflows and orchestration
      - Performance monitoring and optimization
      - User behavior analytics (UBA)
      - Integration with external threat intelligence feeds
      - Compliance and audit management
      - Zero-trust network architecture support''',
      metadata: {
        'version': '2.0',
        'importance': 'critical',
        'modules': ['auth', 'monitoring', 'analytics', 'forensics']
      },
      tags: ['architecture', 'overview', 'security', 'core'],
      lastUpdated: DateTime.now(),
      relevanceScore: 1.0,
    ),
    
    // Authentication Knowledge
    AIKnowledgeItem(
      id: 'KB002',
      category: 'Authentication',
      topic: 'Authentication Methods',
      content: '''Available authentication methods in the system:
      - Username/Password with strength validation
      - Two-factor authentication (2FA) via SMS/Email/App
      - Biometric authentication (fingerprint, face recognition)
      - Behavioral authentication (typing patterns, mouse movements)
      - Hardware security keys (FIDO2/WebAuthn)
      - OAuth2/OpenID Connect integration
      - SAML 2.0 SSO support
      - Certificate-based authentication
      - Risk-based authentication with adaptive challenges
      - Session management with configurable timeouts''',
      metadata: {
        'module': 'auth',
        'risk_level': 'high',
        'compliance': ['NIST', 'ISO27001']
      },
      tags: ['authentication', 'security', 'access', 'mfa'],
      lastUpdated: DateTime.now(),
      relevanceScore: 0.95,
    ),
    
    // Monitoring Capabilities
    AIKnowledgeItem(
      id: 'KB003',
      category: 'Monitoring',
      topic: 'Real-time Monitoring',
      content: '''Real-time monitoring capabilities include:
      - Login attempts and authentication patterns
      - API access logs and usage analytics
      - Network traffic analysis and anomaly detection
      - File system integrity monitoring (FIM)
      - Process execution and command tracking
      - Resource utilization (CPU, Memory, Disk, Network)
      - Security event correlation and alerting
      - User behavior patterns and deviations
      - Database query monitoring and optimization
      - Application performance metrics (APM)
      - Container and microservices monitoring
      - Cloud infrastructure monitoring''',
      metadata: {
        'refresh_rate': '1s',
        'retention': '90d',
        'data_sources': 20
      },
      tags: ['monitoring', 'real-time', 'analytics', 'observability'],
      lastUpdated: DateTime.now(),
      relevanceScore: 0.92,
    ),
    
    // Threat Detection
    AIKnowledgeItem(
      id: 'KB004',
      category: 'Threat Intelligence',
      topic: 'Threat Detection Methods',
      content: '''Advanced threat detection capabilities:
      - Machine learning algorithms for anomaly detection
      - Behavioral analytics and UEBA
      - Signature-based detection with updated threat feeds
      - Heuristic analysis for zero-day threats
      - Statistical anomaly detection
      - Correlation engine for complex attack patterns
      - Threat intelligence feed integration (STIX/TAXII)
      - Sandboxing for suspicious files
      - Network traffic analysis (NTA)
      - Endpoint detection and response (EDR)
      - Deception technology and honeypots
      - AI-powered threat hunting''',
      metadata: {
        'accuracy': '98.5%',
        'false_positive_rate': '0.02%',
        'ml_models': 15
      },
      tags: ['threats', 'detection', 'intelligence', 'ml'],
      lastUpdated: DateTime.now(),
      relevanceScore: 0.94,
    ),
    
    // User Management
    AIKnowledgeItem(
      id: 'KB005',
      category: 'User Management',
      topic: 'RBAC and Permissions',
      content: '''Role-based access control system:
      - Super Admin: Full system access, user management, configuration
      - Admin: User management, monitoring, reporting
      - User: Basic access, personal settings
      - Custom roles with granular permissions
      - Attribute-based access control (ABAC) support
      - Dynamic permission assignment
      - Delegation and temporary privileges
      - Separation of duties enforcement
      - Privileged access management (PAM)
      - Just-in-time (JIT) access provisioning''',
      metadata: {
        'roles': 3,
        'permissions': 150,
        'policy_engine': 'XACML'
      },
      tags: ['rbac', 'permissions', 'access-control', 'users'],
      lastUpdated: DateTime.now(),
      relevanceScore: 0.88,
    ),
    
    // Incident Response
    AIKnowledgeItem(
      id: 'KB006',
      category: 'Incident Response',
      topic: 'IR Procedures',
      content: '''Incident response procedures:
      1. Detection and Analysis
         - Alert triage and validation
         - Impact assessment
         - Evidence collection
      2. Containment
         - Isolation of affected systems
         - Preservation of evidence
         - Short-term containment
      3. Eradication
         - Malware removal
         - Vulnerability patching
         - System hardening
      4. Recovery
         - System restoration
         - Monitoring enhancement
         - Validation testing
      5. Post-Incident
         - Lessons learned
         - Process improvement
         - Documentation update''',
      metadata: {
        'mttr': '30min',
        'playbooks': 25,
        'automation_level': '80%'
      },
      tags: ['incident-response', 'security', 'procedures', 'automation'],
      lastUpdated: DateTime.now(),
      relevanceScore: 0.91,
    ),
    
    // Performance Optimization
    AIKnowledgeItem(
      id: 'KB007',
      category: 'Performance',
      topic: 'Optimization Techniques',
      content: '''Performance optimization strategies:
      - Database query optimization and indexing
      - Caching strategies (Redis, Memcached)
      - Load balancing and horizontal scaling
      - Connection pooling and resource management
      - Async processing and message queuing
      - CDN integration for static assets
      - Code profiling and bottleneck identification
      - Memory leak detection and prevention
      - API rate limiting and throttling
      - Compression and minification
      - Lazy loading and pagination
      - Microservices architecture benefits''',
      metadata: {
        'optimization_tools': 12,
        'performance_gain': '40%',
        'response_time': '<100ms'
      },
      tags: ['performance', 'optimization', 'scaling', 'efficiency'],
      lastUpdated: DateTime.now(),
      relevanceScore: 0.85,
    ),
    
    // Compliance and Audit
    AIKnowledgeItem(
      id: 'KB008',
      category: 'Compliance',
      topic: 'Regulatory Requirements',
      content: '''Compliance and regulatory features:
      - GDPR compliance tools and data privacy
      - HIPAA security requirements
      - PCI DSS compliance for payment data
      - SOC 2 Type II controls
      - ISO 27001/27002 alignment
      - NIST Cybersecurity Framework
      - Audit trail and logging requirements
      - Data retention and deletion policies
      - Encryption standards (AES-256, TLS 1.3)
      - Access review and certification
      - Compliance reporting and dashboards
      - Automated compliance checks''',
      metadata: {
        'standards': 8,
        'audit_frequency': 'quarterly',
        'compliance_score': '95%'
      },
      tags: ['compliance', 'audit', 'regulations', 'governance'],
      lastUpdated: DateTime.now(),
      relevanceScore: 0.87,
    ),
    
    // Forensics Capabilities
    AIKnowledgeItem(
      id: 'KB009',
      category: 'Forensics',
      topic: 'Digital Forensics',
      content: '''Digital forensics capabilities:
      - Timeline reconstruction and analysis
      - Memory forensics and RAM analysis
      - Network packet capture and analysis
      - File system forensics and recovery
      - Registry and artifact analysis
      - Log correlation and analysis
      - Hash verification and integrity checking
      - Chain of custody management
      - Evidence packaging and reporting
      - Malware analysis and reverse engineering
      - Mobile device forensics
      - Cloud forensics capabilities''',
      metadata: {
        'tools': 15,
        'evidence_formats': 20,
        'analysis_depth': 'deep'
      },
      tags: ['forensics', 'investigation', 'evidence', 'analysis'],
      lastUpdated: DateTime.now(),
      relevanceScore: 0.86,
    ),
    
    // Automation and Orchestration
    AIKnowledgeItem(
      id: 'KB010',
      category: 'Automation',
      topic: 'Security Orchestration',
      content: '''Security orchestration and automation:
      - SOAR platform integration
      - Automated incident response playbooks
      - Workflow automation engine
      - API-driven automation
      - Custom script execution
      - Scheduled task management
      - Event-driven automation
      - Approval workflows and gates
      - Integration with ticketing systems
      - ChatOps and notification systems
      - Automated remediation actions
      - Policy enforcement automation''',
      metadata: {
        'playbooks': 50,
        'integrations': 30,
        'automation_rate': '75%'
      },
      tags: ['automation', 'orchestration', 'soar', 'workflows'],
      lastUpdated: DateTime.now(),
      relevanceScore: 0.89,
    ),
  ];
  
  static List<AICommand> availableCommands = [
    AICommand(
      id: 'CMD001',
      command: 'analyze_security',
      description: 'Perform comprehensive security analysis',
      parameters: {'depth': 'full|quick', 'scope': 'system|user|network'},
      category: 'security',
      requiredPermissions: ['security.read', 'system.analyze'],
      requiresConfirmation: false,
    ),
    AICommand(
      id: 'CMD002',
      command: 'block_user',
      description: 'Block a user account',
      parameters: {'user_id': 'string', 'reason': 'string', 'duration': 'permanent|temporary'},
      category: 'user_management',
      requiredPermissions: ['user.write', 'admin.access'],
      requiresConfirmation: true,
    ),
    AICommand(
      id: 'CMD003',
      command: 'generate_report',
      description: 'Generate various types of reports',
      parameters: {'type': 'security|performance|user|audit', 'period': 'daily|weekly|monthly'},
      category: 'reporting',
      requiredPermissions: ['report.create'],
      requiresConfirmation: false,
    ),
    AICommand(
      id: 'CMD004',
      command: 'scan_vulnerabilities',
      description: 'Scan for system vulnerabilities',
      parameters: {'target': 'all|specific', 'intensity': 'light|medium|aggressive'},
      category: 'security',
      requiredPermissions: ['security.scan'],
      requiresConfirmation: true,
    ),
    AICommand(
      id: 'CMD005',
      command: 'optimize_performance',
      description: 'Optimize system performance',
      parameters: {'area': 'database|cache|network|all', 'mode': 'auto|manual'},
      category: 'performance',
      requiredPermissions: ['system.optimize'],
      requiresConfirmation: true,
    ),
    AICommand(
      id: 'CMD006',
      command: 'investigate_incident',
      description: 'Investigate security incident',
      parameters: {'incident_id': 'string', 'depth': 'basic|thorough|forensic'},
      category: 'forensics',
      requiredPermissions: ['incident.investigate'],
      requiresConfirmation: false,
    ),
    AICommand(
      id: 'CMD007',
      command: 'enforce_policy',
      description: 'Enforce security policy',
      parameters: {'policy': 'string', 'scope': 'global|group|user', 'action': 'apply|remove'},
      category: 'policy',
      requiredPermissions: ['policy.enforce'],
      requiresConfirmation: true,
    ),
    AICommand(
      id: 'CMD008',
      command: 'monitor_activity',
      description: 'Monitor specific activity',
      parameters: {'target': 'user|system|network', 'duration': 'minutes|hours|continuous'},
      category: 'monitoring',
      requiredPermissions: ['monitor.create'],
      requiresConfirmation: false,
    ),
  ];
  
  static Map<String, List<String>> contextualResponses = {
    'greeting': [
      'Hello! I\'m your advanced AI security assistant with full access to the Security Center.',
      'Welcome back! How can I assist you with security management today?',
      'Greetings! All systems are operational. What would you like to analyze?',
    ],
    'security_alert': [
      'I\'ve detected a security concern that requires your attention.',
      'Alert: Potential security issue identified. Let me provide details.',
      'Security notification: Anomalous activity detected in the system.',
    ],
    'analysis_complete': [
      'Analysis complete. Here are my findings:',
      'I\'ve finished analyzing the data. Results:',
      'Processing complete. Analysis results are ready:',
    ],
    'recommendation': [
      'Based on my analysis, I recommend:',
      'My suggestion would be to:',
      'Optimal course of action:',
    ],
    'confirmation': [
      'Action executed successfully.',
      'Command completed without errors.',
      'Operation finished. All systems normal.',
    ],
  };
  
  static Map<String, dynamic> systemCapabilities = {
    'security': {
      'threat_detection': true,
      'vulnerability_scanning': true,
      'incident_response': true,
      'forensics': true,
      'compliance_checking': true,
    },
    'monitoring': {
      'real_time': true,
      'historical_analysis': true,
      'predictive': true,
      'anomaly_detection': true,
    },
    'automation': {
      'workflow_orchestration': true,
      'auto_remediation': true,
      'scheduled_tasks': true,
      'event_driven': true,
    },
    'integration': {
      'backend_api': true,
      'external_feeds': true,
      'third_party_tools': true,
      'cloud_services': true,
    },
  };
}
