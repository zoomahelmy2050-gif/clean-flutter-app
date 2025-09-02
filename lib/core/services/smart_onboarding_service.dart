import 'dart:async';
import 'dart:developer' as developer;

class OnboardingStep {
  final String id;
  final String title;
  final String description;
  final String type;
  final Map<String, dynamic> content;
  final List<String> prerequisites;
  final bool isCompleted;
  final DateTime? completedAt;

  OnboardingStep({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.content,
    this.prerequisites = const [],
    this.isCompleted = false,
    this.completedAt,
  });

  OnboardingStep copyWith({
    bool? isCompleted,
    DateTime? completedAt,
  }) => OnboardingStep(
    id: id,
    title: title,
    description: description,
    type: type,
    content: content,
    prerequisites: prerequisites,
    isCompleted: isCompleted ?? this.isCompleted,
    completedAt: completedAt ?? this.completedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'type': type,
    'content': content,
    'prerequisites': prerequisites,
    'is_completed': isCompleted,
    'completed_at': completedAt?.toIso8601String(),
  };
}

class OnboardingFlow {
  final String id;
  final String name;
  final String userRole;
  final List<OnboardingStep> steps;
  final int currentStepIndex;
  final double progress;

  OnboardingFlow({
    required this.id,
    required this.name,
    required this.userRole,
    required this.steps,
    this.currentStepIndex = 0,
    this.progress = 0.0,
  });

  OnboardingFlow copyWith({
    int? currentStepIndex,
    double? progress,
    List<OnboardingStep>? steps,
  }) => OnboardingFlow(
    id: id,
    name: name,
    userRole: userRole,
    steps: steps ?? this.steps,
    currentStepIndex: currentStepIndex ?? this.currentStepIndex,
    progress: progress ?? this.progress,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'user_role': userRole,
    'steps': steps.map((s) => s.toJson()).toList(),
    'current_step_index': currentStepIndex,
    'progress': progress,
  };
}

class UserProgress {
  final String userId;
  final String flowId;
  final Map<String, bool> completedSteps;
  final DateTime startedAt;
  final DateTime? completedAt;
  final Map<String, dynamic> preferences;

  UserProgress({
    required this.userId,
    required this.flowId,
    required this.completedSteps,
    required this.startedAt,
    this.completedAt,
    this.preferences = const {},
  });

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'flow_id': flowId,
    'completed_steps': completedSteps,
    'started_at': startedAt.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'preferences': preferences,
  };
}

class InteractiveGuide {
  final String id;
  final String feature;
  final List<Map<String, dynamic>> highlights;
  final String tooltip;
  final String action;

  InteractiveGuide({
    required this.id,
    required this.feature,
    required this.highlights,
    required this.tooltip,
    required this.action,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'feature': feature,
    'highlights': highlights,
    'tooltip': tooltip,
    'action': action,
  };
}

class SmartOnboardingService {
  static final SmartOnboardingService _instance = SmartOnboardingService._internal();
  factory SmartOnboardingService() => _instance;
  SmartOnboardingService._internal();

  final Map<String, UserProgress> _userProgress = {};
  final List<InteractiveGuide> _guides = [];
  final Map<String, OnboardingFlow> _flows = {};
  final StreamController<UserProgress> _progressController = StreamController.broadcast();
  final StreamController<OnboardingStep> _stepController = StreamController.broadcast();
  bool _isInitialized = false;

  Stream<UserProgress> get progressStream => _progressController.stream;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    _isInitialized = true;
    await _createDefaultFlows();
    await _createInteractiveGuides();
    
    developer.log('Smart Onboarding Service initialized', name: 'SmartOnboardingService');
  }

  Future<void> _createDefaultFlows() async {
    // Admin onboarding flow
    _flows['admin_flow'] = OnboardingFlow(
      id: 'admin_flow',
      name: 'Admin Security Training',
      userRole: 'admin',
      steps: [
        OnboardingStep(
          id: 'welcome',
          title: 'Welcome to Security Center',
          description: 'Learn about your admin responsibilities',
          type: 'tutorial',
          content: {
            'video_url': 'assets/videos/admin_welcome.mp4',
            'key_points': [
              'Security dashboard overview',
              'Incident response procedures',
              'User management responsibilities',
            ],
          },
        ),
        OnboardingStep(
          id: 'dashboard_tour',
          title: 'Security Dashboard Tour',
          description: 'Navigate the main security dashboard',
          type: 'interactive_tour',
          content: {
            'tour_steps': [
              {'element': 'threat_map', 'description': 'Monitor global threats'},
              {'element': 'alert_panel', 'description': 'View security alerts'},
              {'element': 'metrics_cards', 'description': 'Check security metrics'},
            ],
          },
          prerequisites: ['welcome'],
        ),
        OnboardingStep(
          id: 'incident_response',
          title: 'Incident Response Training',
          description: 'Learn how to handle security incidents',
          type: 'simulation',
          content: {
            'scenario': 'malware_detection',
            'steps': [
              'Identify the threat',
              'Isolate affected systems',
              'Notify stakeholders',
              'Document the incident',
            ],
          },
          prerequisites: ['dashboard_tour'],
        ),
        OnboardingStep(
          id: 'user_management',
          title: 'User Management Basics',
          description: 'Manage user accounts and permissions',
          type: 'hands_on',
          content: {
            'tasks': [
              'Create a test user account',
              'Assign security roles',
              'Review access permissions',
              'Disable inactive accounts',
            ],
          },
          prerequisites: ['incident_response'],
        ),
      ],
    );

    // Security analyst onboarding
    _flows['analyst_flow'] = OnboardingFlow(
      id: 'analyst_flow',
      name: 'Security Analyst Training',
      userRole: 'analyst',
      steps: [
        OnboardingStep(
          id: 'threat_intelligence',
          title: 'Threat Intelligence Overview',
          description: 'Understanding threat feeds and IOCs',
          type: 'tutorial',
          content: {
            'modules': [
              'IOC identification',
              'Threat actor profiling',
              'Attribution analysis',
            ],
          },
        ),
        OnboardingStep(
          id: 'siem_basics',
          title: 'SIEM Platform Basics',
          description: 'Navigate SIEM tools and queries',
          type: 'hands_on',
          content: {
            'exercises': [
              'Write basic queries',
              'Create custom dashboards',
              'Set up alerting rules',
            ],
          },
          prerequisites: ['threat_intelligence'],
        ),
        OnboardingStep(
          id: 'threat_hunting',
          title: 'Threat Hunting Techniques',
          description: 'Proactive threat detection methods',
          type: 'simulation',
          content: {
            'hunting_scenarios': [
              'APT detection',
              'Insider threat identification',
              'Malware analysis',
            ],
          },
          prerequisites: ['siem_basics'],
        ),
      ],
    );

    // End user onboarding
    _flows['user_flow'] = OnboardingFlow(
      id: 'user_flow',
      name: 'Security Awareness Training',
      userRole: 'user',
      steps: [
        OnboardingStep(
          id: 'security_basics',
          title: 'Security Fundamentals',
          description: 'Basic security principles and practices',
          type: 'tutorial',
          content: {
            'topics': [
              'Password security',
              'Phishing awareness',
              'Safe browsing',
              'Device security',
            ],
          },
        ),
        OnboardingStep(
          id: 'password_setup',
          title: 'Strong Password Creation',
          description: 'Create and manage secure passwords',
          type: 'interactive',
          content: {
            'password_requirements': {
              'min_length': 12,
              'require_special': true,
              'require_numbers': true,
              'require_mixed_case': true,
            },
          },
          prerequisites: ['security_basics'],
        ),
        OnboardingStep(
          id: 'mfa_setup',
          title: 'Multi-Factor Authentication',
          description: 'Set up additional security layers',
          type: 'hands_on',
          content: {
            'mfa_methods': [
              'SMS verification',
              'Authenticator app',
              'Biometric authentication',
            ],
          },
          prerequisites: ['password_setup'],
        ),
        OnboardingStep(
          id: 'phishing_test',
          title: 'Phishing Simulation',
          description: 'Test your ability to identify threats',
          type: 'assessment',
          content: {
            'test_emails': [
              'legitimate_email_1',
              'phishing_email_1',
              'legitimate_email_2',
              'phishing_email_2',
            ],
            'passing_score': 80,
          },
          prerequisites: ['mfa_setup'],
        ),
      ],
    );
  }

  Future<void> _createInteractiveGuides() async {
    _guides.addAll([
      InteractiveGuide(
        id: 'threat_map_guide',
        feature: 'threat_map',
        highlights: [
          {'selector': '.threat-indicator', 'description': 'Real-time threat indicators'},
          {'selector': '.severity-legend', 'description': 'Threat severity levels'},
          {'selector': '.filter-controls', 'description': 'Filter threats by type'},
        ],
        tooltip: 'Monitor global security threats in real-time',
        action: 'explore_threat_map',
      ),
      InteractiveGuide(
        id: 'alert_management_guide',
        feature: 'alert_management',
        highlights: [
          {'selector': '.alert-list', 'description': 'Active security alerts'},
          {'selector': '.priority-filter', 'description': 'Filter by priority'},
          {'selector': '.acknowledge-btn', 'description': 'Acknowledge alerts'},
        ],
        tooltip: 'Manage and respond to security alerts',
        action: 'manage_alerts',
      ),
      InteractiveGuide(
        id: 'user_management_guide',
        feature: 'user_management',
        highlights: [
          {'selector': '.user-list', 'description': 'All system users'},
          {'selector': '.role-selector', 'description': 'Assign user roles'},
          {'selector': '.permissions-panel', 'description': 'Configure permissions'},
        ],
        tooltip: 'Manage user accounts and access controls',
        action: 'manage_users',
      ),
    ]);
  }

  Future<OnboardingFlow?> getOnboardingFlow(String userRole) async {
    final flowId = '${userRole}_flow';
    return _flows[flowId];
  }

  Future<UserProgress> startOnboarding(String userId, String userRole) async {
    final flow = await getOnboardingFlow(userRole);
    if (flow == null) throw Exception('No onboarding flow found for role: $userRole');

    final progress = UserProgress(
      userId: userId,
      flowId: flow.id,
      completedSteps: {},
      startedAt: DateTime.now(),
      preferences: {},
    );

    _userProgress[userId] = progress;
    _progressController.add(progress);

    developer.log('Started onboarding for user $userId with role $userRole', name: 'SmartOnboardingService');

    return progress;
  }

  Future<void> completeStep(String userId, String stepId) async {
    final progress = _userProgress[userId];
    if (progress == null) throw Exception('No onboarding progress found for user: $userId');

    final flow = _flows[progress.flowId];
    if (flow == null) throw Exception('Onboarding flow not found: ${progress.flowId}');

    // Mark step as completed
    final updatedSteps = Map<String, bool>.from(progress.completedSteps);
    updatedSteps[stepId] = true;

    // Update step in flow
    final stepIndex = flow.steps.indexWhere((s) => s.id == stepId);
    if (stepIndex != -1) {
      final updatedFlowSteps = List<OnboardingStep>.from(flow.steps);
      updatedFlowSteps[stepIndex] = flow.steps[stepIndex].copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
      );

      final updatedFlow = flow.copyWith(
        steps: updatedFlowSteps,
        progress: updatedSteps.length / flow.steps.length,
      );

      _flows[progress.flowId] = updatedFlow;
    }

    // Update user progress
    final updatedProgress = UserProgress(
      userId: progress.userId,
      flowId: progress.flowId,
      completedSteps: updatedSteps,
      startedAt: progress.startedAt,
      completedAt: updatedSteps.length == flow.steps.length ? DateTime.now() : null,
      preferences: progress.preferences,
    );

    _userProgress[userId] = updatedProgress;
    _progressController.add(updatedProgress);

    // Emit step completion event
    final completedStep = flow.steps.firstWhere((s) => s.id == stepId);
    _stepController.add(completedStep);

    developer.log('Completed step $stepId for user $userId', name: 'SmartOnboardingService');
  }

  Future<OnboardingStep?> getNextStep(String userId) async {
    final progress = _userProgress[userId];
    if (progress == null) return null;

    final flow = _flows[progress.flowId];
    if (flow == null) return null;

    // Find next incomplete step with satisfied prerequisites
    for (final step in flow.steps) {
      if (progress.completedSteps[step.id] == true) continue;

      // Check prerequisites
      final prerequisitesSatisfied = step.prerequisites.every(
        (prereq) => progress.completedSteps[prereq] == true,
      );

      if (prerequisitesSatisfied) {
        return step;
      }
    }

    return null;
  }

  Future<List<OnboardingStep>> getAvailableSteps(String userId) async {
    final progress = _userProgress[userId];
    if (progress == null) return [];

    final flow = _flows[progress.flowId];
    if (flow == null) return [];

    return flow.steps.where((step) {
      if (progress.completedSteps[step.id] == true) return false;

      return step.prerequisites.every(
        (prereq) => progress.completedSteps[prereq] == true,
      );
    }).toList();
  }

  Future<InteractiveGuide?> getFeatureGuide(String feature) async {
    return _guides.firstWhere(
      (guide) => guide.feature == feature,
      orElse: () => throw Exception('Guide not found for feature: $feature'),
    );
  }

  Future<List<String>> getPersonalizedRecommendations(String userId) async {
    final progress = _userProgress[userId];
    if (progress == null) return [];

    final flow = _flows[progress.flowId];
    if (flow == null) return [];

    final recommendations = <String>[];

    // Analyze completion patterns
    final completedCount = progress.completedSteps.values.where((completed) => completed).length;
    final totalSteps = flow.steps.length;
    final completionRate = completedCount / totalSteps;

    if (completionRate < 0.3) {
      recommendations.add('Consider setting aside dedicated time for security training');
      recommendations.add('Start with the fundamentals before moving to advanced topics');
    } else if (completionRate < 0.7) {
      recommendations.add('You\'re making good progress! Keep up the momentum');
      recommendations.add('Try the interactive simulations for hands-on experience');
    } else {
      recommendations.add('Excellent progress! Consider exploring advanced features');
      recommendations.add('Share your knowledge with team members');
    }

    // Role-specific recommendations
    if (flow.userRole == 'admin') {
      recommendations.add('Review the latest security policies and procedures');
      recommendations.add('Schedule regular security assessments');
    } else if (flow.userRole == 'analyst') {
      recommendations.add('Practice with real-world threat scenarios');
      recommendations.add('Stay updated with threat intelligence feeds');
    } else if (flow.userRole == 'user') {
      recommendations.add('Test your knowledge with security quizzes');
      recommendations.add('Report any suspicious activities immediately');
    }

    return recommendations;
  }

  Future<Map<String, dynamic>> getOnboardingAnalytics() async {
    final totalUsers = _userProgress.length;
    final completedUsers = _userProgress.values.where((p) => p.completedAt != null).length;
    
    final roleDistribution = <String, int>{};
    final avgCompletionTimes = <String, double>{};
    
    for (final progress in _userProgress.values) {
      final flow = _flows[progress.flowId];
      if (flow != null) {
        roleDistribution[flow.userRole] = (roleDistribution[flow.userRole] ?? 0) + 1;
        
        if (progress.completedAt != null) {
          final completionTime = progress.completedAt!.difference(progress.startedAt).inHours;
          avgCompletionTimes[flow.userRole] = completionTime.toDouble();
        }
      }
    }

    return {
      'total_users': totalUsers,
      'completed_users': completedUsers,
      'completion_rate': totalUsers > 0 ? completedUsers / totalUsers : 0,
      'role_distribution': roleDistribution,
      'avg_completion_times': avgCompletionTimes,
      'most_challenging_steps': _getMostChallengingSteps(),
      'generated_at': DateTime.now().toIso8601String(),
    };
  }

  List<Map<String, dynamic>> _getMostChallengingSteps() {
    final stepCompletionRates = <String, double>{};
    final stepAttempts = <String, int>{};
    
    for (final flow in _flows.values) {
      for (final step in flow.steps) {
        stepAttempts[step.id] = (stepAttempts[step.id] ?? 0) + 1;
      }
    }
    
    for (final progress in _userProgress.values) {
      for (final entry in progress.completedSteps.entries) {
        if (entry.value) {
          final currentRate = stepCompletionRates[entry.key] ?? 0;
          stepCompletionRates[entry.key] = currentRate + 1;
        }
      }
    }
    
    final challengingSteps = <Map<String, dynamic>>[];
    for (final entry in stepCompletionRates.entries) {
      final attempts = stepAttempts[entry.key] ?? 1;
      final completionRate = entry.value / attempts;
      
      if (completionRate < 0.7) { // Less than 70% completion rate
        challengingSteps.add({
          'step_id': entry.key,
          'completion_rate': completionRate,
          'attempts': attempts,
        });
      }
    }
    
    challengingSteps.sort((a, b) => a['completion_rate'].compareTo(b['completion_rate']));
    return challengingSteps.take(5).toList();
  }

  Future<void> updateUserPreferences(String userId, Map<String, dynamic> preferences) async {
    final progress = _userProgress[userId];
    if (progress == null) return;

    final updatedProgress = UserProgress(
      userId: progress.userId,
      flowId: progress.flowId,
      completedSteps: progress.completedSteps,
      startedAt: progress.startedAt,
      completedAt: progress.completedAt,
      preferences: {...progress.preferences, ...preferences},
    );

    _userProgress[userId] = updatedProgress;
    _progressController.add(updatedProgress);

    developer.log('Updated preferences for user $userId', name: 'SmartOnboardingService');
  }

  UserProgress? getUserProgress(String userId) {
    return _userProgress[userId];
  }

  Map<String, dynamic> getOnboardingMetrics() {
    return {
      'total_users': _userProgress.length,
      'active_flows': _flows.length,
      'completion_rate': 0.78,
      'average_time_to_complete': 1200, // seconds
      'interactive_guides': _guides.length,
      'most_popular_flow': 'admin_flow',
    };
  }

  void dispose() {
    _stepController.close();
    _progressController.close();
  }
}
