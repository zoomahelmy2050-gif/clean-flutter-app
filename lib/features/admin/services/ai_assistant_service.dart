import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'ai_security_service.dart';
import '../../../core/services/rbac_service.dart';
import '../../auth/services/auth_service.dart';

class AIChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? category;
  final Map<String, dynamic>? metadata;
  
  AIChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.category,
    this.metadata,
  });
}

class AIContext {
  final String topic;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  
  AIContext({
    required this.topic,
    required this.data,
    required this.timestamp,
  });
}

class AIAssistantService extends ChangeNotifier {
  final List<AIChatMessage> _messages = [];
  final List<Map<String, dynamic>> _contextHistory = [];
  final Map<String, dynamic> _conversationContext = {};
  bool _isTyping = false;
  String _currentModel = 'SecurityAI-v3.0';
  final Map<String, dynamic> _knowledgeBase = {};
  late final AISecurityService _securityService;
  
  List<AIChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  String get currentModel => _currentModel;
  
  AIAssistantService() {
    _initializeKnowledgeBase();
    _initializeSecurity();
  }
  
  void _initializeSecurity() {
    _securityService = AISecurityService(
      rbacService: RBACService(),
      authService: AuthService(),
    );
  }
  
  void _initializeKnowledgeBase() {
    _knowledgeBase['security_features'] = {
      'mfa': 'Multi-Factor Authentication with TOTP, SMS, Email, and Biometric support',
      'rbac': 'Role-Based Access Control with Super Admin, Admin, Moderator, User, and Guest roles',
      'threat_detection': 'Real-time threat monitoring with AI-powered anomaly detection',
      'compliance': 'GDPR, HIPAA, SOC2, PCI-DSS compliance reporting and tracking',
      'incident_response': 'Automated incident response workflows with playbook execution',
      'audit_logs': 'Comprehensive audit logging with tamper-proof blockchain storage',
      'vulnerability_scanning': 'Continuous vulnerability assessment and patch management',
      'device_trust': 'Device fingerprinting and trust management system',
      'behavioral_biometrics': 'Keystroke dynamics and mouse pattern analysis',
      'siem_integration': 'Integration with Splunk, QRadar, ArcSight, and LogRhythm',
    };
    
    _knowledgeBase['user_management'] = {
      'bulk_operations': 'Bulk user import/export, role assignment, and account management',
      'lifecycle': 'Automated user provisioning and deprovisioning workflows',
      'risk_scoring': 'ML-powered user risk assessment with behavioral analytics',
      'session_management': 'Active session monitoring and forced logout capabilities',
      'password_policies': 'Configurable password complexity and rotation policies',
    };
    
    _knowledgeBase['analytics'] = {
      'dashboards': 'Customizable security dashboards with drag-and-drop widgets',
      'reports': 'Scheduled and on-demand security reports with export capabilities',
      'metrics': 'Real-time KPIs including MTTD, MTTR, security score, and compliance rate',
      'trends': 'Historical trend analysis with predictive forecasting',
      'alerts': 'Smart alert correlation and intelligent notification routing',
    };
  }
  
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;
    
    // Add user message
    final userMessage = AIChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: message,
      isUser: true,
      timestamp: DateTime.now(),
      category: _categorizeMessage(message),
    );
    
    _messages.add(userMessage);
    _isTyping = true;
    notifyListeners();
    
    // Simulate AI processing
    await Future.delayed(Duration(milliseconds: 500 + Random().nextInt(1500)));
    
    // Check if message contains an action request
    final actionInfo = _extractActionFromMessage(message);
    String response;
    
    if (actionInfo != null) {
      // Validate action with security service
      final validation = await _securityService.validateAction(
        action: actionInfo['action'],
        parameters: actionInfo['parameters'] ?? {},
      );
      
      if (validation.isValid) {
        // Generate AI response for allowed action
        response = await _generateResponse(message);
      } else {
        // Return security denial message
        response = '⚠️ Security Alert\n\n${validation.message}';
        if (validation.metadata != null) {
          if (validation.metadata!['requires_auth'] == true) {
            response += '\n\nPlease authenticate to perform this action.';
          }
          if (validation.metadata!['requires_mfa'] == true) {
            response += '\n\nThis action requires multi-factor authentication.';
          }
        }
      }
    } else {
      // Generate normal response for non-action messages
      response = await _generateResponse(message);
    }
    
    final aiMessage = AIChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_ai',
      content: response,
      isUser: false,
      timestamp: DateTime.now(),
      category: userMessage.category,
      metadata: {
        'model': _currentModel,
        'confidence': 0.85 + Random().nextDouble() * 0.15,
        'tokens': response.split(' ').length,
      },
    );
    
    _messages.add(aiMessage);
    _isTyping = false;
    notifyListeners();
    
    // Update context
    _updateContext(message, response);
  }
  
  String _categorizeMessage(String message) {
    final lower = message.toLowerCase();
    
    if (lower.contains('user') || lower.contains('role') || lower.contains('permission')) {
      return 'user_management';
    } else if (lower.contains('threat') || lower.contains('attack') || lower.contains('vulnerability')) {
      return 'security_threats';
    } else if (lower.contains('log') || lower.contains('audit') || lower.contains('activity')) {
      return 'audit_logs';
    } else if (lower.contains('report') || lower.contains('compliance') || lower.contains('gdpr')) {
      return 'compliance';
    } else if (lower.contains('mfa') || lower.contains('authentication') || lower.contains('2fa')) {
      return 'authentication';
    } else if (lower.contains('alert') || lower.contains('notification') || lower.contains('incident')) {
      return 'incidents';
    } else if (lower.contains('dashboard') || lower.contains('metric') || lower.contains('kpi')) {
      return 'analytics';
    }
    
    return 'general';
  }
  
  Future<String> _generateResponse(String query) async {
    final lower = query.toLowerCase();
    
    // User management queries
    if (lower.contains('how many users')) {
      return 'Currently, there are 1,247 active users in the system. This includes:\n\n'
             '• 1 Super Admin (you)\n'
             '• 5 Admins\n'
             '• 12 Moderators\n'
             '• 1,229 Regular Users\n\n'
             'In the last 30 days, 47 new users were added and 3 were deactivated.';
    }
    
    if (lower.contains('assign role') || lower.contains('change role')) {
      return 'To assign or change user roles:\n\n'
             '1. Navigate to **User Management** → **Manage Roles**\n'
             '2. Search for the user by email\n'
             '3. Click on their current role badge\n'
             '4. Select the new role from the dropdown\n'
             '5. Confirm the change\n\n'
             'Note: Only Super Admins can assign Admin or Super Admin roles. The primary admin email (env.hygiene@gmail.com) cannot be changed.';
    }
    
    // Security threats
    if (lower.contains('recent threats') || lower.contains('security threats')) {
      return 'In the last 24 hours, I\'ve detected:\n\n'
             '**🔴 Critical (2)**\n'
             '• SQL injection attempt from IP 192.168.1.45\n'
             '• Privilege escalation attempt by user john.doe@example.com\n\n'
             '**🟡 Medium (8)**\n'
             '• 5 failed MFA attempts from various IPs\n'
             '• 3 suspicious login patterns detected\n\n'
             '**🟢 Low (15)**\n'
             '• Various port scanning attempts (all blocked)\n\n'
             'All threats have been automatically mitigated. Would you like to review the incident reports?';
    }
    
    // Compliance
    if (lower.contains('compliance') || lower.contains('gdpr') || lower.contains('hipaa')) {
      return 'Current compliance status:\n\n'
             '**✅ GDPR**: 98% compliant\n'
             '• Data retention policies: Configured\n'
             '• User consent management: Active\n'
             '• Right to erasure: Automated\n\n'
             '**✅ HIPAA**: 95% compliant\n'
             '• PHI encryption: AES-256\n'
             '• Access controls: Enforced\n'
             '• Audit logs: Complete\n\n'
             '**⚠️ SOC2**: 87% compliant\n'
             '• Missing: Disaster recovery test documentation\n'
             '• Action needed: Schedule Q4 DR test\n\n'
             'Next compliance audit scheduled for: October 15, 2024';
    }
    
    // MFA and Authentication
    if (lower.contains('mfa') || lower.contains('multi-factor') || lower.contains('2fa')) {
      return 'Multi-Factor Authentication Statistics:\n\n'
             '**Adoption Rate**: 73% of users have MFA enabled\n\n'
             '**Methods Used**:\n'
             '• TOTP (Google Authenticator): 45%\n'
             '• SMS: 28%\n'
             '• Email OTP: 18%\n'
             '• Biometric: 9%\n\n'
             '**Recent Activity**:\n'
             '• 342 successful MFA verifications today\n'
             '• 12 failed attempts (potential attacks blocked)\n'
             '• Average verification time: 8.3 seconds\n\n'
             'Recommendation: Enable mandatory MFA for all admin accounts.';
    }
    
    // Audit logs
    if (lower.contains('audit') || lower.contains('logs') || lower.contains('activity')) {
      return 'Audit Log Summary (Last 7 Days):\n\n'
             '**Total Events**: 45,892\n\n'
             '**By Category**:\n'
             '• Authentication: 18,234 events\n'
             '• Authorization: 12,456 events\n'
             '• Data Access: 8,923 events\n'
             '• Configuration Changes: 234 events\n'
             '• Security Events: 6,045 events\n\n'
             '**Top Activities**:\n'
             '1. User login (8,234 events)\n'
             '2. API calls (7,892 events)\n'
             '3. File access (4,567 events)\n\n'
             'All logs are tamper-proof and stored with blockchain verification.';
    }
    
    // Performance metrics
    if (lower.contains('performance') || lower.contains('metric') || lower.contains('kpi')) {
      return 'Security Performance Metrics:\n\n'
             '**Key Indicators**:\n'
             '• Security Score: 92/100 (↑ 3 from last week)\n'
             '• MTTD (Mean Time To Detect): 2.4 minutes\n'
             '• MTTR (Mean Time To Respond): 8.7 minutes\n'
             '• False Positive Rate: 3.2%\n\n'
             '**System Health**:\n'
             '• API Response Time: 142ms average\n'
             '• System Uptime: 99.98%\n'
             '• Active Sessions: 387\n'
             '• CPU Usage: 34%\n'
             '• Memory Usage: 62%\n\n'
             'All metrics are within acceptable ranges. No action needed.';
    }
    
    // Incidents
    if (lower.contains('incident') || lower.contains('alert') || lower.contains('notification')) {
      return 'Active Incidents Summary:\n\n'
             '**🔴 Critical (1)**\n'
             'INC-2024-0892: Potential data exfiltration attempt\n'
             '• Status: Investigating\n'
             '• Assigned to: Security Team Alpha\n'
             '• Started: 15 minutes ago\n\n'
             '**🟡 Medium (3)**\n'
             'INC-2024-0891: Unusual API usage pattern\n'
             'INC-2024-0890: Failed backup job\n'
             'INC-2024-0889: Certificate expiry warning\n\n'
             '**Recent Resolutions**:\n'
             '• INC-2024-0888: DDoS attempt (Mitigated)\n'
             '• INC-2024-0887: Phishing email blocked\n\n'
             'Would you like to view the incident response playbooks?';
    }
    
    // Help and features
    if (lower.contains('help') || lower.contains('what can you do') || lower.contains('features')) {
      return 'I\'m your AI Security Assistant with access to all admin security center features. I can help you with:\n\n'
             '**User Management**\n'
             '• View user statistics and roles\n'
             '• Guide role assignments and permissions\n'
             '• Analyze user risk scores\n\n'
             '**Security Monitoring**\n'
             '• Real-time threat analysis\n'
             '• Incident response guidance\n'
             '• Vulnerability assessments\n\n'
             '**Compliance & Reporting**\n'
             '• Compliance status checks\n'
             '• Generate security reports\n'
             '• Audit log analysis\n\n'
             '**System Administration**\n'
             '• Performance metrics\n'
             '• Configuration recommendations\n'
             '• Best practice guidance\n\n'
             'Just ask me anything about your security center!';
    }
    
    // Default response with context awareness
    return 'Based on your query about "${query}", here\'s what I found:\n\n'
           'The admin security center provides comprehensive tools for managing this aspect of your system. '
           'You have full access to all security features including:\n\n'
           '• Real-time monitoring and threat detection\n'
           '• User and role management\n'
           '• Compliance reporting\n'
           '• Incident response automation\n\n'
           'Could you be more specific about what information you need? '
           'For example, you can ask about:\n'
           '- Recent security threats\n'
           '- User activity and roles\n'
           '- Compliance status\n'
           '- System performance metrics';
  }
  
  void _updateContext(String message, String response) {
    _conversationContext['lastQuery'] = message;
    _conversationContext['lastResponse'] = response;
    _conversationContext['messageCount'] = _messages.length;
    _conversationContext['lastTimestamp'] = DateTime.now().toIso8601String();
  }
  
  Map<String, dynamic>? _extractActionFromMessage(String message) {
    final lower = message.toLowerCase();
    
    // User management actions
    if (lower.contains('create user') || lower.contains('add user')) {
      return {'action': 'create_user', 'parameters': {}};
    }
    if (lower.contains('delete user') || lower.contains('remove user')) {
      return {'action': 'delete_user', 'parameters': {}};
    }
    if (lower.contains('assign role') || lower.contains('change role')) {
      return {'action': 'manage_users', 'parameters': {}};
    }
    
    // Security actions
    if (lower.contains('modify security') || lower.contains('change security settings')) {
      return {'action': 'modify_security', 'parameters': {}};
    }
    if (lower.contains('execute workflow') || lower.contains('run playbook')) {
      return {'action': 'execute_workflow', 'parameters': {}};
    }
    
    // Data actions
    if (lower.contains('export') && lower.contains('sensitive')) {
      return {'action': 'export_sensitive', 'parameters': {}};
    }
    if (lower.contains('delete') && (lower.contains('data') || lower.contains('logs'))) {
      return {'action': 'delete_data', 'parameters': {}};
    }
    
    // Monitoring actions
    if (lower.contains('start monitoring') || lower.contains('enable monitoring')) {
      return {'action': 'monitor_system', 'parameters': {}};
    }
    
    // Sync actions
    if (lower.contains('sync devices') || lower.contains('synchronize')) {
      return {'action': 'sync_devices', 'parameters': {}};
    }
    
    return null; // No action detected
  }
  
  void clearChat() {
    _messages.clear();
    _contextHistory.clear();
    notifyListeners();
  }
  
  void exportChat() {
    // Export chat history
    final export = _messages.map((msg) => {
      'timestamp': msg.timestamp.toIso8601String(),
      'isUser': msg.isUser,
      'content': msg.content,
      'category': msg.category,
    }).toList();
    
    debugPrint('Chat exported: ${export.length} messages');
  }
  
  List<String> getSuggestions() {
    return [
      'Show me recent security threats',
      'How many users are in the system?',
      'What\'s our current compliance status?',
      'Display MFA adoption statistics',
      'Show performance metrics',
      'List active incidents',
      'How do I assign roles to users?',
      'What are the recent audit log entries?',
      'Show me the security score trend',
      'What vulnerabilities were detected today?',
    ];
  }
}
