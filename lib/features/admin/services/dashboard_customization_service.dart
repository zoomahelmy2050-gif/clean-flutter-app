import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

class DashboardWidget {
  final String id;
  final String type;
  final String title;
  final Map<String, dynamic> config;
  final int position;
  final bool isVisible;
  final String size; // small, medium, large
  
  DashboardWidget({
    required this.id,
    required this.type,
    required this.title,
    required this.config,
    required this.position,
    this.isVisible = true,
    this.size = 'medium',
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'config': config,
    'position': position,
    'isVisible': isVisible,
    'size': size,
  };
  
  factory DashboardWidget.fromJson(Map<String, dynamic> json) => DashboardWidget(
    id: json['id'],
    type: json['type'],
    title: json['title'],
    config: json['config'],
    position: json['position'],
    isVisible: json['isVisible'] ?? true,
    size: json['size'] ?? 'medium',
  );
}

class RoleDashboard {
  final String role;
  final List<DashboardWidget> widgets;
  final Map<String, dynamic> layout;
  final Map<String, dynamic> preferences;
  
  RoleDashboard({
    required this.role,
    required this.widgets,
    required this.layout,
    required this.preferences,
  });
  
  Map<String, dynamic> toJson() => {
    'role': role,
    'widgets': widgets.map((w) => w.toJson()).toList(),
    'layout': layout,
    'preferences': preferences,
  };
  
  factory RoleDashboard.fromJson(Map<String, dynamic> json) => RoleDashboard(
    role: json['role'],
    widgets: (json['widgets'] as List).map((w) => DashboardWidget.fromJson(w)).toList(),
    layout: json['layout'] ?? {},
    preferences: json['preferences'] ?? {},
  );
}

class KPIMetric {
  final String id;
  final String name;
  final dynamic value;
  final dynamic target;
  final String trend; // up, down, stable
  final double percentageChange;
  final String period;
  final Map<String, dynamic> details;
  
  KPIMetric({
    required this.id,
    required this.name,
    required this.value,
    this.target,
    required this.trend,
    required this.percentageChange,
    required this.period,
    required this.details,
  });
}

class AlertCorrelation {
  final String id;
  final String name;
  final List<String> relatedAlerts;
  final String correlationType;
  final double confidence;
  final Map<String, dynamic> pattern;
  final DateTime detectedAt;
  final String severity;
  
  AlertCorrelation({
    required this.id,
    required this.name,
    required this.relatedAlerts,
    required this.correlationType,
    required this.confidence,
    required this.pattern,
    required this.detectedAt,
    required this.severity,
  });
}

class DashboardCustomizationService extends ChangeNotifier {
  final Map<String, RoleDashboard> _roleDashboards = {};
  final List<KPIMetric> _kpiMetrics = [];
  final List<AlertCorrelation> _alertCorrelations = [];
  final Map<String, List<String>> _widgetPermissions = {};
  String _currentRole = 'admin';
  bool _isLoading = false;
  
  List<DashboardWidget> get currentWidgets => 
    _roleDashboards[_currentRole]?.widgets ?? _getDefaultWidgets();
  
  List<KPIMetric> get kpiMetrics => _kpiMetrics;
  List<AlertCorrelation> get alertCorrelations => _alertCorrelations;
  String get currentRole => _currentRole;
  bool get isLoading => _isLoading;
  
  DashboardCustomizationService() {
    _initializeService();
  }
  
  Future<void> _initializeService() async {
    await _loadDashboards();
    _generateKPIMetrics();
    _generateAlertCorrelations();
    _startCorrelationEngine();
  }
  
  Future<void> _loadDashboards() async {
    _isLoading = true;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    final dashboardsJson = prefs.getString('role_dashboards');
    
    if (dashboardsJson != null) {
      final dashboards = json.decode(dashboardsJson) as Map<String, dynamic>;
      dashboards.forEach((role, data) {
        _roleDashboards[role] = RoleDashboard.fromJson(data);
      });
    } else {
      _initializeDefaultDashboards();
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  void _initializeDefaultDashboards() {
    // Admin Dashboard
    _roleDashboards['admin'] = RoleDashboard(
      role: 'admin',
      widgets: _getDefaultWidgets(),
      layout: {'columns': 3, 'spacing': 16},
      preferences: {'theme': 'dark', 'autoRefresh': true, 'refreshInterval': 30},
    );
    
    // Security Analyst Dashboard
    _roleDashboards['analyst'] = RoleDashboard(
      role: 'analyst',
      widgets: _getAnalystWidgets(),
      layout: {'columns': 2, 'spacing': 12},
      preferences: {'theme': 'light', 'autoRefresh': true, 'refreshInterval': 60},
    );
    
    // Executive Dashboard
    _roleDashboards['executive'] = RoleDashboard(
      role: 'executive',
      widgets: _getExecutiveWidgets(),
      layout: {'columns': 2, 'spacing': 20},
      preferences: {'theme': 'light', 'autoRefresh': false},
    );
    
    // SOC Manager Dashboard
    _roleDashboards['soc_manager'] = RoleDashboard(
      role: 'soc_manager',
      widgets: _getSOCManagerWidgets(),
      layout: {'columns': 3, 'spacing': 16},
      preferences: {'theme': 'dark', 'autoRefresh': true, 'refreshInterval': 15},
    );
  }
  
  List<DashboardWidget> _getDefaultWidgets() {
    return [
      DashboardWidget(
        id: 'threat_overview',
        type: 'threat_map',
        title: 'Global Threat Overview',
        config: {'showHeatmap': true, 'updateInterval': 30},
        position: 0,
        size: 'large',
      ),
      DashboardWidget(
        id: 'security_score',
        type: 'kpi',
        title: 'Security Score',
        config: {'metric': 'overall_score', 'showTrend': true},
        position: 1,
        size: 'medium',
      ),
      DashboardWidget(
        id: 'active_incidents',
        type: 'counter',
        title: 'Active Incidents',
        config: {'severity': 'all', 'showBreakdown': true},
        position: 2,
        size: 'small',
      ),
      DashboardWidget(
        id: 'recent_alerts',
        type: 'list',
        title: 'Recent Alerts',
        config: {'limit': 10, 'showSeverity': true},
        position: 3,
        size: 'medium',
      ),
      DashboardWidget(
        id: 'compliance_status',
        type: 'gauge',
        title: 'Compliance Status',
        config: {'frameworks': ['ISO27001', 'GDPR', 'HIPAA']},
        position: 4,
        size: 'medium',
      ),
    ];
  }
  
  List<DashboardWidget> _getAnalystWidgets() {
    return [
      DashboardWidget(
        id: 'alert_queue',
        type: 'queue',
        title: 'Alert Queue',
        config: {'autoAssign': true, 'prioritySort': true},
        position: 0,
        size: 'large',
      ),
      DashboardWidget(
        id: 'investigation_tools',
        type: 'toolbox',
        title: 'Investigation Tools',
        config: {'quickAccess': ['whois', 'virustotal', 'shodan']},
        position: 1,
        size: 'medium',
      ),
      DashboardWidget(
        id: 'threat_intel',
        type: 'feed',
        title: 'Threat Intelligence Feed',
        config: {'sources': ['internal', 'osint', 'commercial']},
        position: 2,
        size: 'medium',
      ),
      DashboardWidget(
        id: 'case_workload',
        type: 'workload',
        title: 'My Cases',
        config: {'showStatus': true, 'showDeadlines': true},
        position: 3,
        size: 'medium',
      ),
    ];
  }
  
  List<DashboardWidget> _getExecutiveWidgets() {
    return [
      DashboardWidget(
        id: 'executive_summary',
        type: 'summary',
        title: 'Executive Summary',
        config: {'period': 'monthly', 'compareLastPeriod': true},
        position: 0,
        size: 'large',
      ),
      DashboardWidget(
        id: 'risk_matrix',
        type: 'matrix',
        title: 'Risk Matrix',
        config: {'showMitigation': true, 'highlightCritical': true},
        position: 1,
        size: 'large',
      ),
      DashboardWidget(
        id: 'budget_utilization',
        type: 'budget',
        title: 'Security Budget',
        config: {'showForecast': true, 'breakdownByCategory': true},
        position: 2,
        size: 'medium',
      ),
      DashboardWidget(
        id: 'roi_metrics',
        type: 'roi',
        title: 'Security ROI',
        config: {'metrics': ['prevented_losses', 'efficiency_gains']},
        position: 3,
        size: 'medium',
      ),
    ];
  }
  
  List<DashboardWidget> _getSOCManagerWidgets() {
    return [
      DashboardWidget(
        id: 'team_performance',
        type: 'team',
        title: 'Team Performance',
        config: {'showIndividual': true, 'showSLA': true},
        position: 0,
        size: 'large',
      ),
      DashboardWidget(
        id: 'shift_schedule',
        type: 'schedule',
        title: 'Shift Schedule',
        config: {'showCoverage': true, 'allowSwap': true},
        position: 1,
        size: 'medium',
      ),
      DashboardWidget(
        id: 'escalations',
        type: 'escalation',
        title: 'Escalations',
        config: {'autoEscalate': true, 'thresholds': {'p1': 15, 'p2': 30}},
        position: 2,
        size: 'medium',
      ),
      DashboardWidget(
        id: 'sla_compliance',
        type: 'sla',
        title: 'SLA Compliance',
        config: {'targets': {'response': 15, 'resolution': 240}},
        position: 3,
        size: 'medium',
      ),
      DashboardWidget(
        id: 'resource_utilization',
        type: 'resources',
        title: 'Resource Utilization',
        config: {'showCapacity': true, 'forecastDemand': true},
        position: 4,
        size: 'medium',
      ),
    ];
  }
  
  void _generateKPIMetrics() {
    final random = Random();
    _kpiMetrics.clear();
    
    _kpiMetrics.addAll([
      KPIMetric(
        id: 'mttr',
        name: 'Mean Time to Respond',
        value: '${random.nextInt(20) + 5} min',
        target: '15 min',
        trend: random.nextBool() ? 'up' : 'down',
        percentageChange: random.nextDouble() * 20 - 10,
        period: 'Last 7 days',
        details: {
          'p1_incidents': '${random.nextInt(10) + 2} min',
          'p2_incidents': '${random.nextInt(30) + 10} min',
          'p3_incidents': '${random.nextInt(60) + 30} min',
        },
      ),
      KPIMetric(
        id: 'threat_detection_rate',
        name: 'Threat Detection Rate',
        value: '${random.nextInt(20) + 80}%',
        target: '95%',
        trend: 'up',
        percentageChange: random.nextDouble() * 10,
        period: 'Last 30 days',
        details: {
          'true_positives': random.nextInt(500) + 200,
          'false_positives': random.nextInt(50) + 10,
          'detection_sources': ['SIEM', 'EDR', 'NDR', 'UEBA'],
        },
      ),
      KPIMetric(
        id: 'incident_volume',
        name: 'Incident Volume',
        value: random.nextInt(100) + 50,
        target: null,
        trend: random.nextBool() ? 'up' : 'stable',
        percentageChange: random.nextDouble() * 30 - 15,
        period: 'This week',
        details: {
          'critical': random.nextInt(5),
          'high': random.nextInt(15) + 5,
          'medium': random.nextInt(30) + 10,
          'low': random.nextInt(50) + 20,
        },
      ),
      KPIMetric(
        id: 'compliance_score',
        name: 'Compliance Score',
        value: '${random.nextInt(10) + 90}%',
        target: '100%',
        trend: 'stable',
        percentageChange: random.nextDouble() * 5 - 2.5,
        period: 'Current quarter',
        details: {
          'passed_controls': random.nextInt(50) + 150,
          'failed_controls': random.nextInt(10) + 5,
          'pending_audits': random.nextInt(5),
        },
      ),
      KPIMetric(
        id: 'security_training',
        name: 'Security Training Completion',
        value: '${random.nextInt(15) + 85}%',
        target: '100%',
        trend: 'up',
        percentageChange: random.nextDouble() * 8,
        period: 'This month',
        details: {
          'completed_users': random.nextInt(200) + 800,
          'pending_users': random.nextInt(100) + 50,
          'overdue_users': random.nextInt(50) + 10,
        },
      ),
    ]);
    
    notifyListeners();
  }
  
  void _generateAlertCorrelations() {
    final random = Random();
    final correlationTypes = ['temporal', 'behavioral', 'threat_campaign', 'attack_chain', 'geographic'];
    final severities = ['low', 'medium', 'high', 'critical'];
    
    _alertCorrelations.clear();
    
    for (int i = 0; i < 5; i++) {
      final type = correlationTypes[random.nextInt(correlationTypes.length)];
      final severity = severities[random.nextInt(severities.length)];
      
      _alertCorrelations.add(AlertCorrelation(
        id: 'corr_${DateTime.now().millisecondsSinceEpoch}_$i',
        name: _generateCorrelationName(type),
        relatedAlerts: List.generate(
          random.nextInt(5) + 3,
          (j) => 'alert_${random.nextInt(10000)}',
        ),
        correlationType: type,
        confidence: random.nextDouble() * 0.4 + 0.6,
        pattern: _generateCorrelationPattern(type),
        detectedAt: DateTime.now().subtract(Duration(minutes: random.nextInt(60))),
        severity: severity,
      ));
    }
    
    notifyListeners();
  }
  
  String _generateCorrelationName(String type) {
    switch (type) {
      case 'temporal':
        return 'Rapid succession login failures';
      case 'behavioral':
        return 'Unusual data access pattern';
      case 'threat_campaign':
        return 'APT28 campaign indicators';
      case 'attack_chain':
        return 'Lateral movement attempt';
      case 'geographic':
        return 'Distributed attack from multiple regions';
      default:
        return 'Suspicious activity cluster';
    }
  }
  
  Map<String, dynamic> _generateCorrelationPattern(String type) {
    final random = Random();
    switch (type) {
      case 'temporal':
        return {
          'time_window': '${random.nextInt(10) + 5} minutes',
          'event_count': random.nextInt(50) + 10,
          'source_ips': random.nextInt(5) + 1,
        };
      case 'behavioral':
        return {
          'deviation_score': random.nextDouble(),
          'affected_users': random.nextInt(10) + 1,
          'anomaly_type': 'access_pattern',
        };
      case 'threat_campaign':
        return {
          'iocs_matched': random.nextInt(20) + 5,
          'ttps': ['T1566', 'T1055', 'T1003'],
          'attribution_confidence': '${random.nextInt(30) + 70}%',
        };
      case 'attack_chain':
        return {
          'stages_detected': random.nextInt(4) + 2,
          'kill_chain_phase': 'exploitation',
          'predicted_next': 'privilege_escalation',
        };
      case 'geographic':
        return {
          'countries': random.nextInt(10) + 3,
          'coordination_likelihood': '${random.nextInt(40) + 60}%',
          'botnet_probability': random.nextDouble(),
        };
      default:
        return {};
    }
  }
  
  void _startCorrelationEngine() {
    Future.delayed(Duration(seconds: 30), () {
      if (!disposed) {
        _generateAlertCorrelations();
        _generateKPIMetrics();
        _startCorrelationEngine();
      }
    });
  }
  
  bool disposed = false;
  
  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
  
  // Dashboard Management Methods
  
  Future<void> switchRole(String role) async {
    _currentRole = role;
    await _loadDashboards();
    notifyListeners();
  }
  
  Future<void> addWidget(DashboardWidget widget) async {
    final dashboard = _roleDashboards[_currentRole];
    if (dashboard != null) {
      dashboard.widgets.add(widget);
      await _saveDashboards();
      notifyListeners();
    }
  }
  
  Future<void> removeWidget(String widgetId) async {
    final dashboard = _roleDashboards[_currentRole];
    if (dashboard != null) {
      dashboard.widgets.removeWhere((w) => w.id == widgetId);
      await _saveDashboards();
      notifyListeners();
    }
  }
  
  Future<void> updateWidget(String widgetId, Map<String, dynamic> updates) async {
    final dashboard = _roleDashboards[_currentRole];
    if (dashboard != null) {
      final widgetIndex = dashboard.widgets.indexWhere((w) => w.id == widgetId);
      if (widgetIndex != -1) {
        final widget = dashboard.widgets[widgetIndex];
        dashboard.widgets[widgetIndex] = DashboardWidget(
          id: widget.id,
          type: widget.type,
          title: updates['title'] ?? widget.title,
          config: updates['config'] ?? widget.config,
          position: updates['position'] ?? widget.position,
          isVisible: updates['isVisible'] ?? widget.isVisible,
          size: updates['size'] ?? widget.size,
        );
        await _saveDashboards();
        notifyListeners();
      }
    }
  }
  
  Future<void> reorderWidgets(List<String> widgetIds) async {
    final dashboard = _roleDashboards[_currentRole];
    if (dashboard != null) {
      final reorderedWidgets = <DashboardWidget>[];
      for (int i = 0; i < widgetIds.length; i++) {
        final widget = dashboard.widgets.firstWhere((w) => w.id == widgetIds[i]);
        reorderedWidgets.add(DashboardWidget(
          id: widget.id,
          type: widget.type,
          title: widget.title,
          config: widget.config,
          position: i,
          isVisible: widget.isVisible,
          size: widget.size,
        ));
      }
      dashboard.widgets
        ..clear()
        ..addAll(reorderedWidgets);
      await _saveDashboards();
      notifyListeners();
    }
  }
  
  Future<void> updateLayout(Map<String, dynamic> layout) async {
    final dashboard = _roleDashboards[_currentRole];
    if (dashboard != null) {
      dashboard.layout.addAll(layout);
      await _saveDashboards();
      notifyListeners();
    }
  }
  
  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    final dashboard = _roleDashboards[_currentRole];
    if (dashboard != null) {
      dashboard.preferences.addAll(preferences);
      await _saveDashboards();
      notifyListeners();
    }
  }
  
  Future<void> resetToDefault() async {
    _initializeDefaultDashboards();
    await _saveDashboards();
    notifyListeners();
  }
  
  Future<void> _saveDashboards() async {
    final prefs = await SharedPreferences.getInstance();
    final dashboardsMap = <String, dynamic>{};
    _roleDashboards.forEach((role, dashboard) {
      dashboardsMap[role] = dashboard.toJson();
    });
    await prefs.setString('role_dashboards', json.encode(dashboardsMap));
  }
  
  // Alert Correlation Methods
  
  List<AlertCorrelation> getCorrelationsByType(String type) {
    return _alertCorrelations.where((c) => c.correlationType == type).toList();
  }
  
  List<AlertCorrelation> getHighConfidenceCorrelations({double threshold = 0.8}) {
    return _alertCorrelations.where((c) => c.confidence >= threshold).toList();
  }
  
  List<AlertCorrelation> getRecentCorrelations({Duration? within}) {
    final cutoff = DateTime.now().subtract(within ?? Duration(hours: 1));
    return _alertCorrelations.where((c) => c.detectedAt.isAfter(cutoff)).toList();
  }
  
  // KPI Methods
  
  KPIMetric? getKPIById(String id) {
    try {
      return _kpiMetrics.firstWhere((kpi) => kpi.id == id);
    } catch (_) {
      return null;
    }
  }
  
  List<KPIMetric> getKPIsByTrend(String trend) {
    return _kpiMetrics.where((kpi) => kpi.trend == trend).toList();
  }
  
  Map<String, dynamic> getKPISummary() {
    int improving = _kpiMetrics.where((kpi) => kpi.trend == 'up' && kpi.percentageChange > 0).length;
    int declining = _kpiMetrics.where((kpi) => kpi.trend == 'down' && kpi.percentageChange < 0).length;
    int stable = _kpiMetrics.where((kpi) => kpi.trend == 'stable').length;
    
    return {
      'total': _kpiMetrics.length,
      'improving': improving,
      'declining': declining,
      'stable': stable,
      'metrics': _kpiMetrics.map((kpi) => {
        'id': kpi.id,
        'name': kpi.name,
        'value': kpi.value,
        'trend': kpi.trend,
      }).toList(),
    };
  }
}
