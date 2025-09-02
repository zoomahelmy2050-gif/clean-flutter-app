import 'dart:async';
import 'dart:developer' as developer;

class ExecutiveReport {
  final String reportId;
  final String title;
  final String type;
  final Map<String, dynamic> data;
  final Map<String, dynamic> metrics;
  final List<String> insights;
  final List<String> recommendations;
  final DateTime generatedAt;
  final String generatedBy;

  ExecutiveReport({
    required this.reportId,
    required this.title,
    required this.type,
    required this.data,
    required this.metrics,
    required this.insights,
    required this.recommendations,
    required this.generatedAt,
    required this.generatedBy,
  });

  Map<String, dynamic> toJson() => {
    'report_id': reportId,
    'title': title,
    'type': type,
    'data': data,
    'metrics': metrics,
    'insights': insights,
    'recommendations': recommendations,
    'generated_at': generatedAt.toIso8601String(),
    'generated_by': generatedBy,
  };
}

class DashboardWidget {
  final String widgetId;
  final String title;
  final String type;
  final Map<String, dynamic> configuration;
  final Map<String, dynamic> data;
  final int refreshIntervalMinutes;

  DashboardWidget({
    required this.widgetId,
    required this.title,
    required this.type,
    required this.configuration,
    required this.data,
    this.refreshIntervalMinutes = 15,
  });

  Map<String, dynamic> toJson() => {
    'widget_id': widgetId,
    'title': title,
    'type': type,
    'configuration': configuration,
    'data': data,
    'refresh_interval_minutes': refreshIntervalMinutes,
  };
}

class ExecutiveDashboard {
  final String dashboardId;
  final String name;
  final String targetAudience;
  final List<DashboardWidget> widgets;
  final Map<String, dynamic> layout;
  final DateTime lastUpdated;

  ExecutiveDashboard({
    required this.dashboardId,
    required this.name,
    required this.targetAudience,
    required this.widgets,
    required this.layout,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
    'dashboard_id': dashboardId,
    'name': name,
    'target_audience': targetAudience,
    'widgets': widgets.map((w) => w.toJson()).toList(),
    'layout': layout,
    'last_updated': lastUpdated.toIso8601String(),
  };
}

class ExecutiveReportingService {
  static final ExecutiveReportingService _instance = ExecutiveReportingService._internal();
  factory ExecutiveReportingService() => _instance;
  ExecutiveReportingService._internal();

  final Map<String, ExecutiveReport> _reports = {};
  final Map<String, ExecutiveDashboard> _dashboards = {};
  final List<String> _scheduledReports = [];
  
  final StreamController<ExecutiveReport> _reportController = StreamController.broadcast();
  final StreamController<ExecutiveDashboard> _dashboardController = StreamController.broadcast();

  Stream<ExecutiveReport> get reportStream => _reportController.stream;
  Stream<ExecutiveDashboard> get dashboardStream => _dashboardController.stream;

  Timer? _scheduledReportTimer;

  Future<void> initialize() async {
    await _createDefaultDashboards();
    await _generateInitialReports();
    _startScheduledReporting();
    
    developer.log('Executive Reporting Service initialized', name: 'ExecutiveReportingService');
  }

  Future<void> _createDefaultDashboards() async {
    // CEO Dashboard
    await createDashboard(ExecutiveDashboard(
      dashboardId: 'ceo_dashboard',
      name: 'CEO Security Overview',
      targetAudience: 'CEO',
      widgets: [
        DashboardWidget(
          widgetId: 'security_score_kpi',
          title: 'Overall Security Score',
          type: 'kpi',
          configuration: {'threshold_critical': 70, 'threshold_warning': 85},
          data: {'current_score': 92, 'trend': 'up', 'change': '+3%'},
        ),
        DashboardWidget(
          widgetId: 'threat_landscape',
          title: 'Threat Landscape',
          type: 'chart',
          configuration: {'chart_type': 'donut', 'time_range': '30d'},
          data: {
            'threats_blocked': 1247,
            'threats_by_type': {'malware': 45, 'phishing': 30, 'ransomware': 15, 'other': 10},
          },
        ),
        DashboardWidget(
          widgetId: 'compliance_status',
          title: 'Compliance Status',
          type: 'status_grid',
          configuration: {'frameworks': ['SOC2', 'ISO27001', 'GDPR', 'HIPAA']},
          data: {
            'SOC2': {'status': 'compliant', 'score': 98},
            'ISO27001': {'status': 'compliant', 'score': 95},
            'GDPR': {'status': 'compliant', 'score': 97},
            'HIPAA': {'status': 'review_needed', 'score': 88},
          },
        ),
        DashboardWidget(
          widgetId: 'security_investments',
          title: 'Security Investment ROI',
          type: 'financial_chart',
          configuration: {'currency': 'USD', 'time_range': '12m'},
          data: {
            'investment': 2500000,
            'savings': 4200000,
            'roi_percentage': 168,
            'incidents_prevented': 23,
          },
        ),
      ],
      layout: {
        'grid_columns': 2,
        'widget_positions': {
          'security_score_kpi': {'row': 0, 'col': 0, 'width': 1, 'height': 1},
          'threat_landscape': {'row': 0, 'col': 1, 'width': 1, 'height': 1},
          'compliance_status': {'row': 1, 'col': 0, 'width': 1, 'height': 1},
          'security_investments': {'row': 1, 'col': 1, 'width': 1, 'height': 1},
        },
      },
      lastUpdated: DateTime.now(),
    ));

    // CISO Dashboard
    await createDashboard(ExecutiveDashboard(
      dashboardId: 'ciso_dashboard',
      name: 'CISO Security Operations',
      targetAudience: 'CISO',
      widgets: [
        DashboardWidget(
          widgetId: 'active_incidents',
          title: 'Active Security Incidents',
          type: 'incident_list',
          configuration: {'max_items': 10, 'severity_filter': 'all'},
          data: {
            'total_active': 3,
            'critical': 0,
            'high': 1,
            'medium': 2,
            'incidents': [
              {'id': 'INC-001', 'severity': 'high', 'type': 'data_breach_attempt', 'status': 'investigating'},
              {'id': 'INC-002', 'severity': 'medium', 'type': 'phishing_campaign', 'status': 'contained'},
              {'id': 'INC-003', 'severity': 'medium', 'type': 'malware_detection', 'status': 'remediation'},
            ],
          },
        ),
        DashboardWidget(
          widgetId: 'vulnerability_metrics',
          title: 'Vulnerability Management',
          type: 'vulnerability_chart',
          configuration: {'time_range': '30d', 'include_trends': true},
          data: {
            'total_vulnerabilities': 156,
            'critical': 2,
            'high': 15,
            'medium': 67,
            'low': 72,
            'patched_this_month': 89,
            'mean_time_to_patch': 4.2,
          },
        ),
      ],
      layout: {
        'grid_columns': 2,
        'widget_positions': {
          'active_incidents': {'row': 0, 'col': 0, 'width': 2, 'height': 1},
          'vulnerability_metrics': {'row': 1, 'col': 0, 'width': 2, 'height': 1},
        },
      },
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> _generateInitialReports() async {
    await generateReport(
      type: 'monthly_security_summary',
      title: 'Monthly Security Executive Summary',
      generatedBy: 'system',
    );

    await generateReport(
      type: 'quarterly_risk_assessment',
      title: 'Quarterly Risk Assessment Report',
      generatedBy: 'system',
    );
  }

  void _startScheduledReporting() {
    _scheduledReportTimer = Timer.periodic(const Duration(hours: 24), (_) {
      _generateScheduledReports();
    });
  }

  Future<void> _generateScheduledReports() async {
    final now = DateTime.now();
    
    if (now.day == 1) {
      await generateReport(
        type: 'monthly_security_summary',
        title: 'Monthly Security Executive Summary - ${_getMonthName(now.month)} ${now.year}',
        generatedBy: 'scheduled',
      );
    }
    
    if (now.day == 1 && [1, 4, 7, 10].contains(now.month)) {
      await generateReport(
        type: 'quarterly_risk_assessment',
        title: 'Quarterly Risk Assessment - Q${((now.month - 1) ~/ 3) + 1} ${now.year}',
        generatedBy: 'scheduled',
      );
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Future<ExecutiveReport> generateReport({
    required String type,
    required String title,
    required String generatedBy,
    Map<String, dynamic>? customData,
  }) async {
    final reportId = 'RPT_${DateTime.now().millisecondsSinceEpoch}';
    
    Map<String, dynamic> reportData;
    Map<String, dynamic> metrics;
    List<String> insights;
    List<String> recommendations;

    switch (type) {
      case 'monthly_security_summary':
        reportData = await _generateMonthlySecurityData();
        metrics = await _calculateMonthlyMetrics();
        insights = _generateMonthlyInsights(metrics);
        recommendations = _generateMonthlyRecommendations(metrics);
        break;
        
      case 'quarterly_risk_assessment':
        reportData = await _generateQuarterlyRiskData();
        metrics = await _calculateQuarterlyMetrics();
        insights = _generateQuarterlyInsights(metrics);
        recommendations = _generateQuarterlyRecommendations(metrics);
        break;
        
      default:
        reportData = customData ?? {};
        metrics = {};
        insights = [];
        recommendations = [];
    }

    final report = ExecutiveReport(
      reportId: reportId,
      title: title,
      type: type,
      data: reportData,
      metrics: metrics,
      insights: insights,
      recommendations: recommendations,
      generatedAt: DateTime.now(),
      generatedBy: generatedBy,
    );

    _reports[reportId] = report;
    _reportController.add(report);

    developer.log('Generated executive report: $title', name: 'ExecutiveReportingService');

    return report;
  }

  Future<Map<String, dynamic>> _generateMonthlySecurityData() async {
    return {
      'security_incidents': {
        'total': 15,
        'critical': 1,
        'high': 4,
        'medium': 7,
        'low': 3,
        'resolved': 13,
        'avg_resolution_time_hours': 18.5,
      },
      'threat_landscape': {
        'threats_detected': 2456,
        'threats_blocked': 2398,
        'success_rate': 97.6,
        'top_threat_types': ['phishing', 'malware', 'ransomware'],
      },
      'vulnerability_management': {
        'vulnerabilities_discovered': 89,
        'vulnerabilities_patched': 82,
        'critical_outstanding': 2,
        'avg_patch_time_days': 4.2,
      },
    };
  }

  Future<Map<String, dynamic>> _calculateMonthlyMetrics() async {
    return {
      'overall_security_score': 92.5,
      'incident_response_efficiency': 89.2,
      'threat_detection_rate': 97.6,
      'vulnerability_remediation_rate': 92.1,
      'compliance_score': 94.8,
    };
  }

  List<String> _generateMonthlyInsights(Map<String, dynamic> metrics) {
    return [
      'Overall security posture improved by 3.2% compared to last month',
      'Incident response time decreased by 15% due to improved automation',
      'Threat detection rate of 97.6% exceeds industry benchmark',
      'Critical vulnerability count reduced by 60% through proactive patching',
    ];
  }

  List<String> _generateMonthlyRecommendations(Map<String, dynamic> metrics) {
    return [
      'Implement additional automation for medium-priority incident response',
      'Enhance threat intelligence feeds to improve detection capabilities',
      'Schedule quarterly penetration testing to validate security controls',
      'Expand security awareness training programs',
    ];
  }

  Future<Map<String, dynamic>> _generateQuarterlyRiskData() async {
    return {
      'risk_assessment': {
        'total_risks_identified': 45,
        'critical_risks': 3,
        'high_risks': 8,
        'medium_risks': 22,
        'low_risks': 12,
        'risks_mitigated': 38,
      },
      'business_impact_analysis': {
        'critical_systems': 15,
        'systems_with_backup': 14,
        'rto_compliance': 93.3,
        'rpo_compliance': 96.7,
      },
    };
  }

  Future<Map<String, dynamic>> _calculateQuarterlyMetrics() async {
    return {
      'overall_risk_score': 2.8,
      'risk_mitigation_rate': 84.4,
      'business_continuity_readiness': 94.7,
      'security_maturity_score': 4.2,
    };
  }

  List<String> _generateQuarterlyInsights(Map<String, dynamic> metrics) {
    return [
      'Overall risk score decreased from 3.2 to 2.8, indicating improved security posture',
      'Business continuity readiness at 94.7% exceeds industry benchmarks',
      'Risk mitigation rate of 84.4% demonstrates effective risk management',
    ];
  }

  List<String> _generateQuarterlyRecommendations(Map<String, dynamic> metrics) {
    return [
      'Focus on the 3 remaining critical risks for immediate mitigation',
      'Implement automated risk assessment tools for continuous monitoring',
      'Enhance business continuity testing frequency to quarterly',
    ];
  }

  Future<ExecutiveDashboard> createDashboard(ExecutiveDashboard dashboard) async {
    _dashboards[dashboard.dashboardId] = dashboard;
    _dashboardController.add(dashboard);
    
    developer.log('Created executive dashboard: ${dashboard.name}', name: 'ExecutiveReportingService');
    
    return dashboard;
  }

  Future<List<ExecutiveReport>> getReports({String? type, int? limit}) async {
    var reports = _reports.values.toList();
    
    if (type != null) {
      reports = reports.where((r) => r.type == type).toList();
    }
    
    reports.sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
    
    if (limit != null && limit > 0) {
      reports = reports.take(limit).toList();
    }
    
    return reports;
  }

  Future<ExecutiveReport?> getReport(String reportId) async {
    return _reports[reportId];
  }

  Future<List<ExecutiveDashboard>> getDashboards() async {
    return _dashboards.values.toList();
  }

  Future<ExecutiveDashboard?> getDashboard(String dashboardId) async {
    return _dashboards[dashboardId];
  }

  Map<String, dynamic> getReportingMetrics() {
    return {
      'total_reports': _reports.length,
      'reports_by_type': _getReportsByType(),
      'total_dashboards': _dashboards.length,
      'scheduled_reports': _scheduledReports.length,
    };
  }

  Map<String, int> _getReportsByType() {
    final typeCount = <String, int>{};
    for (final report in _reports.values) {
      typeCount[report.type] = (typeCount[report.type] ?? 0) + 1;
    }
    return typeCount;
  }

  void dispose() {
    _scheduledReportTimer?.cancel();
    _reportController.close();
    _dashboardController.close();
  }
}
