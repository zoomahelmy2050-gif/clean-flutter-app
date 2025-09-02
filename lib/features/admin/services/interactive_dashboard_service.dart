import 'dart:async';
import 'dart:math';
import 'dart:developer' as developer;
import '../../../core/models/dashboard_models.dart';
import '../../../core/models/analytics_models.dart';

class InteractiveDashboardService {
  static final InteractiveDashboardService _instance = InteractiveDashboardService._internal();
  factory InteractiveDashboardService() => _instance;
  InteractiveDashboardService._internal();

  final Random _random = Random();
  Timer? _updateTimer;

  // Streams for real-time updates
  final StreamController<List<DashboardLayout>> _dashboardsController = StreamController<List<DashboardLayout>>.broadcast();
  final StreamController<List<DashboardWidget>> _widgetsController = StreamController<List<DashboardWidget>>.broadcast();
  final StreamController<DashboardLayout> _layoutUpdateController = StreamController<DashboardLayout>.broadcast();

  Stream<List<DashboardLayout>> get dashboardsStream => _dashboardsController.stream;
  Stream<List<DashboardWidget>> get widgetsStream => _widgetsController.stream;
  Stream<DashboardLayout> get layoutUpdateStream => _layoutUpdateController.stream;

  // Data storage
  final List<DashboardLayout> _dashboards = [];
  final List<WidgetTemplate> _widgetTemplates = [];
  final List<DashboardFilter> _globalFilters = [];
  final List<DashboardExport> _exports = [];
  final List<DashboardPermission> _permissions = [];

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    developer.log('Initializing Interactive Dashboard Service', name: 'InteractiveDashboardService');
    
    await _generateInitialData();
    _startRealTimeUpdates();
    
    _isInitialized = true;
    developer.log('Interactive Dashboard Service initialized', name: 'InteractiveDashboardService');
  }

  Future<void> _generateInitialData() async {
    // Generate widget templates
    _widgetTemplates.addAll(_generateWidgetTemplates());
    
    // Generate initial dashboards
    _dashboards.addAll(_generateDashboards());
    
    // Generate global filters
    _globalFilters.addAll(_generateGlobalFilters());
    
    // Generate permissions
    _permissions.addAll(_generatePermissions());
  }

  void _startRealTimeUpdates() {
    // Update dashboard data every 30 seconds
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateDashboardData();
    });
  }

  void _updateDashboardData() {
    // Simulate real-time data updates for widgets
    for (final dashboard in _dashboards) {
      for (int i = 0; i < dashboard.widgets.length; i++) {
        final widget = dashboard.widgets[i];
        if (widget.type == WidgetType.metric_card || 
            widget.type == WidgetType.gauge ||
            widget.type == WidgetType.trend_indicator) {
          // Update widget with new data
          final updatedWidget = widget.copyWith(
            lastUpdated: DateTime.now(),
            configuration: {
              ...widget.configuration,
              'value': _generateRandomValue(widget.type),
              'lastUpdate': DateTime.now().toIso8601String(),
            },
          );
          dashboard.widgets[i] = updatedWidget;
        }
      }
    }
    
    _dashboardsController.add(List.from(_dashboards));
  }

  List<WidgetTemplate> _generateWidgetTemplates() {
    return [
      WidgetTemplate(
        id: 'template_1',
        name: 'Security Score Card',
        description: 'Display overall security score with trend indicator',
        type: WidgetType.metric_card,
        defaultSize: WidgetSize.medium,
        defaultConfiguration: {
          'showTrend': true,
          'colorScheme': 'security',
          'threshold': 80,
        },
        requiredDataFields: ['score', 'trend', 'timestamp'],
        category: 'Security',
        iconPath: 'assets/icons/security.svg',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        createdBy: 'system',
        usageCount: 45,
        rating: 4.8,
      ),
      WidgetTemplate(
        id: 'template_2',
        name: 'Threat Timeline',
        description: 'Timeline view of security threats and incidents',
        type: WidgetType.timeline,
        defaultSize: WidgetSize.large,
        defaultConfiguration: {
          'timeRange': '24h',
          'showSeverity': true,
          'groupBy': 'type',
        },
        requiredDataFields: ['timestamp', 'severity', 'type', 'description'],
        category: 'Threats',
        iconPath: 'assets/icons/timeline.svg',
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        createdBy: 'system',
        usageCount: 32,
        rating: 4.6,
      ),
      WidgetTemplate(
        id: 'template_3',
        name: 'Alert Distribution Chart',
        description: 'Pie chart showing distribution of alerts by severity',
        type: WidgetType.chart_pie,
        defaultSize: WidgetSize.medium,
        defaultConfiguration: {
          'showLabels': true,
          'showPercentages': true,
          'colorScheme': 'severity',
        },
        requiredDataFields: ['severity', 'count'],
        category: 'Analytics',
        iconPath: 'assets/icons/pie_chart.svg',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        createdBy: 'system',
        usageCount: 28,
        rating: 4.4,
      ),
      WidgetTemplate(
        id: 'template_4',
        name: 'System Performance Gauge',
        description: 'Gauge showing system performance metrics',
        type: WidgetType.gauge,
        defaultSize: WidgetSize.small,
        defaultConfiguration: {
          'minValue': 0,
          'maxValue': 100,
          'thresholds': [60, 80, 95],
          'unit': '%',
        },
        requiredDataFields: ['value', 'label'],
        category: 'Performance',
        iconPath: 'assets/icons/gauge.svg',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        createdBy: 'system',
        usageCount: 38,
        rating: 4.7,
      ),
      WidgetTemplate(
        id: 'template_5',
        name: 'User Activity Heatmap',
        description: 'Heatmap showing user activity patterns',
        type: WidgetType.heatmap,
        defaultSize: WidgetSize.large,
        defaultConfiguration: {
          'timeRange': 'week',
          'colorScheme': 'activity',
          'showTooltips': true,
        },
        requiredDataFields: ['hour', 'day', 'activity_count'],
        category: 'User Behavior',
        iconPath: 'assets/icons/heatmap.svg',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        createdBy: 'system',
        usageCount: 22,
        rating: 4.3,
      ),
    ];
  }

  List<DashboardLayout> _generateDashboards() {
    final now = DateTime.now();
    
    return [
      DashboardLayout(
        id: 'dashboard_1',
        name: 'Security Overview',
        description: 'Main security monitoring dashboard',
        widgets: _generateSecurityOverviewWidgets(),
        theme: DashboardTheme.auto,
        gridColumns: 12,
        gridRows: 20,
        createdAt: now.subtract(const Duration(days: 10)),
        lastModified: now.subtract(const Duration(hours: 2)),
        createdBy: 'admin',
        sharedWith: ['security_team', 'management'],
        isPublic: false,
      ),
      DashboardLayout(
        id: 'dashboard_2',
        name: 'Threat Intelligence',
        description: 'Advanced threat detection and analysis',
        widgets: _generateThreatIntelligenceWidgets(),
        theme: DashboardTheme.dark,
        gridColumns: 12,
        gridRows: 16,
        createdAt: now.subtract(const Duration(days: 7)),
        lastModified: now.subtract(const Duration(hours: 6)),
        createdBy: 'security_analyst',
        sharedWith: ['incident_response'],
        isPublic: false,
      ),
      DashboardLayout(
        id: 'dashboard_3',
        name: 'Executive Summary',
        description: 'High-level security metrics for executives',
        widgets: _generateExecutiveSummaryWidgets(),
        theme: DashboardTheme.light,
        gridColumns: 8,
        gridRows: 12,
        createdAt: now.subtract(const Duration(days: 5)),
        lastModified: now.subtract(const Duration(hours: 12)),
        createdBy: 'ciso',
        sharedWith: ['executives', 'board'],
        isPublic: true,
      ),
    ];
  }

  List<DashboardWidget> _generateSecurityOverviewWidgets() {
    final now = DateTime.now();
    
    return [
      DashboardWidget(
        id: 'widget_1',
        title: 'Overall Security Score',
        description: 'Current security posture score',
        type: WidgetType.metric_card,
        size: WidgetSize.medium,
        configuration: {
          'value': 87.5,
          'trend': 'up',
          'changePercent': 2.3,
          'threshold': 80,
          'color': 'green',
        },
        dataSource: {'endpoint': '/api/security/score'},
        gridX: 0,
        gridY: 0,
        gridWidth: 3,
        gridHeight: 2,
        createdAt: now.subtract(const Duration(days: 5)),
        lastUpdated: now,
        createdBy: 'admin',
      ),
      DashboardWidget(
        id: 'widget_2',
        title: 'Active Threats',
        description: 'Number of active security threats',
        type: WidgetType.metric_card,
        size: WidgetSize.medium,
        configuration: {
          'value': 12,
          'trend': 'down',
          'changePercent': -15.2,
          'threshold': 20,
          'color': 'orange',
        },
        dataSource: {'endpoint': '/api/threats/active'},
        gridX: 3,
        gridY: 0,
        gridWidth: 3,
        gridHeight: 2,
        createdAt: now.subtract(const Duration(days: 5)),
        lastUpdated: now,
        createdBy: 'admin',
      ),
      DashboardWidget(
        id: 'widget_3',
        title: 'System Health',
        description: 'Overall system health gauge',
        type: WidgetType.gauge,
        size: WidgetSize.medium,
        configuration: {
          'value': 94.2,
          'minValue': 0,
          'maxValue': 100,
          'thresholds': [60, 80, 95],
          'unit': '%',
        },
        dataSource: {'endpoint': '/api/system/health'},
        gridX: 6,
        gridY: 0,
        gridWidth: 3,
        gridHeight: 2,
        createdAt: now.subtract(const Duration(days: 5)),
        lastUpdated: now,
        createdBy: 'admin',
      ),
      DashboardWidget(
        id: 'widget_4',
        title: 'Alert Trends',
        description: 'Security alert trends over time',
        type: WidgetType.chart_line,
        size: WidgetSize.large,
        configuration: {
          'timeRange': '7d',
          'showPoints': true,
          'showGrid': true,
          'colorScheme': 'security',
        },
        dataSource: {'endpoint': '/api/alerts/trends'},
        gridX: 0,
        gridY: 2,
        gridWidth: 6,
        gridHeight: 4,
        createdAt: now.subtract(const Duration(days: 5)),
        lastUpdated: now,
        createdBy: 'admin',
      ),
      DashboardWidget(
        id: 'widget_5',
        title: 'Recent Alerts',
        description: 'List of recent security alerts',
        type: WidgetType.alert_list,
        size: WidgetSize.large,
        configuration: {
          'maxItems': 10,
          'showSeverity': true,
          'showTimestamp': true,
          'allowAcknowledge': true,
        },
        dataSource: {'endpoint': '/api/alerts/recent'},
        gridX: 6,
        gridY: 2,
        gridWidth: 6,
        gridHeight: 4,
        createdAt: now.subtract(const Duration(days: 5)),
        lastUpdated: now,
        createdBy: 'admin',
      ),
    ];
  }

  List<DashboardWidget> _generateThreatIntelligenceWidgets() {
    final now = DateTime.now();
    
    return [
      DashboardWidget(
        id: 'widget_6',
        title: 'Threat Map',
        description: 'Geographic distribution of threats',
        type: WidgetType.map,
        size: WidgetSize.large,
        configuration: {
          'mapType': 'world',
          'showHeatmap': true,
          'showMarkers': true,
          'colorScheme': 'threat',
        },
        dataSource: {'endpoint': '/api/threats/geographic'},
        gridX: 0,
        gridY: 0,
        gridWidth: 8,
        gridHeight: 6,
        createdAt: now.subtract(const Duration(days: 3)),
        lastUpdated: now,
        createdBy: 'security_analyst',
      ),
      DashboardWidget(
        id: 'widget_7',
        title: 'Attack Vectors',
        description: 'Distribution of attack vectors',
        type: WidgetType.chart_pie,
        size: WidgetSize.medium,
        configuration: {
          'showLabels': true,
          'showPercentages': true,
          'colorScheme': 'attack_vectors',
        },
        dataSource: {'endpoint': '/api/threats/vectors'},
        gridX: 8,
        gridY: 0,
        gridWidth: 4,
        gridHeight: 3,
        createdAt: now.subtract(const Duration(days: 3)),
        lastUpdated: now,
        createdBy: 'security_analyst',
      ),
      DashboardWidget(
        id: 'widget_8',
        title: 'Threat Timeline',
        description: 'Timeline of security incidents',
        type: WidgetType.timeline,
        size: WidgetSize.medium,
        configuration: {
          'timeRange': '24h',
          'showSeverity': true,
          'groupBy': 'type',
        },
        dataSource: {'endpoint': '/api/threats/timeline'},
        gridX: 8,
        gridY: 3,
        gridWidth: 4,
        gridHeight: 3,
        createdAt: now.subtract(const Duration(days: 3)),
        lastUpdated: now,
        createdBy: 'security_analyst',
      ),
    ];
  }

  List<DashboardWidget> _generateExecutiveSummaryWidgets() {
    final now = DateTime.now();
    
    return [
      DashboardWidget(
        id: 'widget_9',
        title: 'Security KPIs',
        description: 'Key security performance indicators',
        type: WidgetType.table,
        size: WidgetSize.large,
        configuration: {
          'columns': ['Metric', 'Current', 'Target', 'Status'],
          'sortable': true,
          'showStatus': true,
        },
        dataSource: {'endpoint': '/api/kpis/security'},
        gridX: 0,
        gridY: 0,
        gridWidth: 8,
        gridHeight: 6,
        createdAt: now.subtract(const Duration(days: 2)),
        lastUpdated: now,
        createdBy: 'ciso',
      ),
      DashboardWidget(
        id: 'widget_10',
        title: 'Monthly Trends',
        description: 'Monthly security trend analysis',
        type: WidgetType.chart_bar,
        size: WidgetSize.large,
        configuration: {
          'timeRange': '12m',
          'showGrid': true,
          'colorScheme': 'executive',
        },
        dataSource: {'endpoint': '/api/trends/monthly'},
        gridX: 0,
        gridY: 6,
        gridWidth: 8,
        gridHeight: 6,
        createdAt: now.subtract(const Duration(days: 2)),
        lastUpdated: now,
        createdBy: 'ciso',
      ),
    ];
  }

  List<DashboardFilter> _generateGlobalFilters() {
    final now = DateTime.now();
    
    return [
      DashboardFilter(
        id: 'filter_1',
        name: 'Time Range',
        field: 'timestamp',
        operator: 'between',
        value: {
          'start': now.subtract(const Duration(days: 7)).toIso8601String(),
          'end': now.toIso8601String(),
        },
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      DashboardFilter(
        id: 'filter_2',
        name: 'Severity',
        field: 'severity',
        operator: 'in',
        value: ['high', 'critical'],
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      DashboardFilter(
        id: 'filter_3',
        name: 'Status',
        field: 'status',
        operator: 'equals',
        value: 'active',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  List<DashboardPermission> _generatePermissions() {
    final now = DateTime.now();
    
    return [
      DashboardPermission(
        id: 'perm_1',
        dashboardId: 'dashboard_1',
        userId: 'security_team',
        role: 'editor',
        permissions: ['view', 'edit', 'share'],
        grantedAt: now.subtract(const Duration(days: 10)),
        grantedBy: 'admin',
      ),
      DashboardPermission(
        id: 'perm_2',
        dashboardId: 'dashboard_2',
        userId: 'incident_response',
        role: 'viewer',
        permissions: ['view'],
        grantedAt: now.subtract(const Duration(days: 7)),
        grantedBy: 'security_analyst',
      ),
      DashboardPermission(
        id: 'perm_3',
        dashboardId: 'dashboard_3',
        userId: 'executives',
        role: 'viewer',
        permissions: ['view', 'export'],
        grantedAt: now.subtract(const Duration(days: 5)),
        grantedBy: 'ciso',
      ),
    ];
  }

  double _generateRandomValue(WidgetType type) {
    switch (type) {
      case WidgetType.metric_card:
        return 50 + _random.nextDouble() * 50;
      case WidgetType.gauge:
        return 60 + _random.nextDouble() * 40;
      case WidgetType.trend_indicator:
        return -10 + _random.nextDouble() * 20;
      default:
        return _random.nextDouble() * 100;
    }
  }

  // Public API methods
  Future<List<DashboardLayout>> getDashboards({String? userId}) async {
    await initialize();
    if (userId != null) {
      // Filter dashboards based on user permissions
      final userDashboards = <DashboardLayout>[];
      for (final dashboard in _dashboards) {
        if (dashboard.createdBy == userId || 
            dashboard.isPublic || 
            dashboard.sharedWith.contains(userId)) {
          userDashboards.add(dashboard);
        }
      }
      return userDashboards;
    }
    return List.from(_dashboards);
  }

  Future<DashboardLayout?> getDashboard(String id) async {
    await initialize();
    try {
      return _dashboards.firstWhere((d) => d.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<WidgetTemplate>> getWidgetTemplates({String? category}) async {
    await initialize();
    if (category != null) {
      return _widgetTemplates.where((t) => t.category.toLowerCase() == category.toLowerCase()).toList();
    }
    return List.from(_widgetTemplates);
  }

  Future<DashboardLayout> createDashboard({
    required String name,
    required String description,
    required String createdBy,
    DashboardTheme theme = DashboardTheme.auto,
    int gridColumns = 12,
    int gridRows = 20,
  }) async {
    await initialize();
    
    final dashboard = DashboardLayout(
      id: 'dashboard_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      theme: theme,
      gridColumns: gridColumns,
      gridRows: gridRows,
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      createdBy: createdBy,
    );
    
    _dashboards.add(dashboard);
    _dashboardsController.add(List.from(_dashboards));
    
    return dashboard;
  }

  Future<DashboardWidget> addWidget({
    required String dashboardId,
    required String templateId,
    required String title,
    required int gridX,
    required int gridY,
    required int gridWidth,
    required int gridHeight,
    Map<String, dynamic>? customConfiguration,
  }) async {
    await initialize();
    
    final template = _widgetTemplates.firstWhere((t) => t.id == templateId);
    final dashboardIndex = _dashboards.indexWhere((d) => d.id == dashboardId);
    
    if (dashboardIndex == -1) throw Exception('Dashboard not found');
    
    final widget = DashboardWidget(
      id: 'widget_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: template.description,
      type: template.type,
      size: template.defaultSize,
      configuration: customConfiguration ?? template.defaultConfiguration,
      gridX: gridX,
      gridY: gridY,
      gridWidth: gridWidth,
      gridHeight: gridHeight,
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
      createdBy: 'current_user',
    );
    
    final dashboard = _dashboards[dashboardIndex];
    final updatedWidgets = [...dashboard.widgets, widget];
    
    _dashboards[dashboardIndex] = DashboardLayout(
      id: dashboard.id,
      name: dashboard.name,
      description: dashboard.description,
      widgets: updatedWidgets,
      settings: dashboard.settings,
      theme: dashboard.theme,
      gridColumns: dashboard.gridColumns,
      gridRows: dashboard.gridRows,
      gridGap: dashboard.gridGap,
      isLocked: dashboard.isLocked,
      createdAt: dashboard.createdAt,
      lastModified: DateTime.now(),
      createdBy: dashboard.createdBy,
      sharedWith: dashboard.sharedWith,
      isPublic: dashboard.isPublic,
      metadata: dashboard.metadata,
    );
    
    _layoutUpdateController.add(_dashboards[dashboardIndex]);
    _dashboardsController.add(List.from(_dashboards));
    
    return widget;
  }

  Future<void> updateWidgetPosition({
    required String dashboardId,
    required String widgetId,
    required int gridX,
    required int gridY,
    required int gridWidth,
    required int gridHeight,
  }) async {
    await initialize();
    
    final dashboardIndex = _dashboards.indexWhere((d) => d.id == dashboardId);
    if (dashboardIndex == -1) return;
    
    final dashboard = _dashboards[dashboardIndex];
    final widgetIndex = dashboard.widgets.indexWhere((w) => w.id == widgetId);
    if (widgetIndex == -1) return;
    
    final updatedWidget = dashboard.widgets[widgetIndex].copyWith(
      gridX: gridX,
      gridY: gridY,
      gridWidth: gridWidth,
      gridHeight: gridHeight,
      lastUpdated: DateTime.now(),
    );
    
    final updatedWidgets = [...dashboard.widgets];
    updatedWidgets[widgetIndex] = updatedWidget;
    
    _dashboards[dashboardIndex] = DashboardLayout(
      id: dashboard.id,
      name: dashboard.name,
      description: dashboard.description,
      widgets: updatedWidgets,
      settings: dashboard.settings,
      theme: dashboard.theme,
      gridColumns: dashboard.gridColumns,
      gridRows: dashboard.gridRows,
      gridGap: dashboard.gridGap,
      isLocked: dashboard.isLocked,
      createdAt: dashboard.createdAt,
      lastModified: DateTime.now(),
      createdBy: dashboard.createdBy,
      sharedWith: dashboard.sharedWith,
      isPublic: dashboard.isPublic,
      metadata: dashboard.metadata,
    );
    
    _layoutUpdateController.add(_dashboards[dashboardIndex]);
  }

  Future<void> removeWidget(String dashboardId, String widgetId) async {
    await initialize();
    
    final dashboardIndex = _dashboards.indexWhere((d) => d.id == dashboardId);
    if (dashboardIndex == -1) return;
    
    final dashboard = _dashboards[dashboardIndex];
    final updatedWidgets = dashboard.widgets.where((w) => w.id != widgetId).toList();
    
    _dashboards[dashboardIndex] = DashboardLayout(
      id: dashboard.id,
      name: dashboard.name,
      description: dashboard.description,
      widgets: updatedWidgets,
      settings: dashboard.settings,
      theme: dashboard.theme,
      gridColumns: dashboard.gridColumns,
      gridRows: dashboard.gridRows,
      gridGap: dashboard.gridGap,
      isLocked: dashboard.isLocked,
      createdAt: dashboard.createdAt,
      lastModified: DateTime.now(),
      createdBy: dashboard.createdBy,
      sharedWith: dashboard.sharedWith,
      isPublic: dashboard.isPublic,
      metadata: dashboard.metadata,
    );
    
    _layoutUpdateController.add(_dashboards[dashboardIndex]);
    _dashboardsController.add(List.from(_dashboards));
  }

  Future<DashboardExport> exportDashboard({
    required String dashboardId,
    required String format,
    required String requestedBy,
    Map<String, dynamic>? options,
  }) async {
    await initialize();
    
    final export = DashboardExport(
      id: 'export_${DateTime.now().millisecondsSinceEpoch}',
      dashboardId: dashboardId,
      format: format,
      options: options ?? {},
      status: 'processing',
      requestedAt: DateTime.now(),
      requestedBy: requestedBy,
    );
    
    _exports.add(export);
    
    // Simulate export processing
    Timer(const Duration(seconds: 5), () {
      final index = _exports.indexWhere((e) => e.id == export.id);
      if (index != -1) {
        _exports[index] = DashboardExport(
          id: export.id,
          dashboardId: export.dashboardId,
          format: export.format,
          options: export.options,
          status: 'completed',
          downloadUrl: '/downloads/${export.id}.${format}',
          requestedAt: export.requestedAt,
          completedAt: DateTime.now(),
          requestedBy: export.requestedBy,
        );
      }
    });
    
    return export;
  }

  Future<List<DashboardFilter>> getGlobalFilters() async {
    await initialize();
    return List.from(_globalFilters);
  }

  Future<void> applyGlobalFilter(DashboardFilter filter) async {
    await initialize();
    
    final existingIndex = _globalFilters.indexWhere((f) => f.field == filter.field);
    if (existingIndex != -1) {
      _globalFilters[existingIndex] = filter;
    } else {
      _globalFilters.add(filter);
    }
    
    // Trigger dashboard updates with new filters
    _updateDashboardData();
  }

  void dispose() {
    _updateTimer?.cancel();
    
    _dashboardsController.close();
    _widgetsController.close();
    _layoutUpdateController.close();
  }
}
