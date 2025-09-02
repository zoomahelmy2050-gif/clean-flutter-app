enum WidgetType {
  metric_card,
  chart_line,
  chart_bar,
  chart_pie,
  alert_list,
  trend_indicator,
  heatmap,
  gauge,
  table,
  timeline,
  map,
  notification_feed
}

enum ChartTimeRange { hour, day, week, month, quarter, year }
enum WidgetSize { small, medium, large, extra_large }
enum DashboardTheme { light, dark, auto }

class DashboardWidget {
  final String id;
  final String title;
  final String description;
  final WidgetType type;
  final WidgetSize size;
  final Map<String, dynamic> configuration;
  final Map<String, dynamic> dataSource;
  final int gridX;
  final int gridY;
  final int gridWidth;
  final int gridHeight;
  final bool isVisible;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final String createdBy;
  final List<String> permissions;

  DashboardWidget({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.size,
    this.configuration = const {},
    this.dataSource = const {},
    required this.gridX,
    required this.gridY,
    required this.gridWidth,
    required this.gridHeight,
    this.isVisible = true,
    required this.createdAt,
    required this.lastUpdated,
    required this.createdBy,
    this.permissions = const [],
  });

  factory DashboardWidget.fromJson(Map<String, dynamic> json) {
    return DashboardWidget(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: WidgetType.values.byName(json['type']),
      size: WidgetSize.values.byName(json['size']),
      configuration: json['configuration'] ?? {},
      dataSource: json['dataSource'] ?? {},
      gridX: json['gridX'],
      gridY: json['gridY'],
      gridWidth: json['gridWidth'],
      gridHeight: json['gridHeight'],
      isVisible: json['isVisible'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      createdBy: json['createdBy'],
      permissions: List<String>.from(json['permissions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'size': size.name,
      'configuration': configuration,
      'dataSource': dataSource,
      'gridX': gridX,
      'gridY': gridY,
      'gridWidth': gridWidth,
      'gridHeight': gridHeight,
      'isVisible': isVisible,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'createdBy': createdBy,
      'permissions': permissions,
    };
  }

  DashboardWidget copyWith({
    String? title,
    String? description,
    WidgetType? type,
    WidgetSize? size,
    Map<String, dynamic>? configuration,
    Map<String, dynamic>? dataSource,
    int? gridX,
    int? gridY,
    int? gridWidth,
    int? gridHeight,
    bool? isVisible,
    DateTime? lastUpdated,
    List<String>? permissions,
  }) {
    return DashboardWidget(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      size: size ?? this.size,
      configuration: configuration ?? this.configuration,
      dataSource: dataSource ?? this.dataSource,
      gridX: gridX ?? this.gridX,
      gridY: gridY ?? this.gridY,
      gridWidth: gridWidth ?? this.gridWidth,
      gridHeight: gridHeight ?? this.gridHeight,
      isVisible: isVisible ?? this.isVisible,
      createdAt: createdAt,
      lastUpdated: lastUpdated ?? DateTime.now(),
      createdBy: createdBy,
      permissions: permissions ?? this.permissions,
    );
  }
}

class DashboardLayout {
  final String id;
  final String name;
  final String description;
  final List<DashboardWidget> widgets;
  final Map<String, dynamic> settings;
  final DashboardTheme theme;
  final int gridColumns;
  final int gridRows;
  final double gridGap;
  final bool isLocked;
  final DateTime createdAt;
  final DateTime lastModified;
  final String createdBy;
  final List<String> sharedWith;
  final bool isPublic;
  final Map<String, dynamic> metadata;

  DashboardLayout({
    required this.id,
    required this.name,
    required this.description,
    this.widgets = const [],
    this.settings = const {},
    this.theme = DashboardTheme.auto,
    this.gridColumns = 12,
    this.gridRows = 20,
    this.gridGap = 8.0,
    this.isLocked = false,
    required this.createdAt,
    required this.lastModified,
    required this.createdBy,
    this.sharedWith = const [],
    this.isPublic = false,
    this.metadata = const {},
  });

  factory DashboardLayout.fromJson(Map<String, dynamic> json) {
    return DashboardLayout(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      widgets: (json['widgets'] as List?)
          ?.map((e) => DashboardWidget.fromJson(e))
          .toList() ?? [],
      settings: json['settings'] ?? {},
      theme: DashboardTheme.values.byName(json['theme'] ?? 'auto'),
      gridColumns: json['gridColumns'] ?? 12,
      gridRows: json['gridRows'] ?? 20,
      gridGap: (json['gridGap'] ?? 8.0).toDouble(),
      isLocked: json['isLocked'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      lastModified: DateTime.parse(json['lastModified']),
      createdBy: json['createdBy'],
      sharedWith: List<String>.from(json['sharedWith'] ?? []),
      isPublic: json['isPublic'] ?? false,
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'widgets': widgets.map((e) => e.toJson()).toList(),
      'settings': settings,
      'theme': theme.name,
      'gridColumns': gridColumns,
      'gridRows': gridRows,
      'gridGap': gridGap,
      'isLocked': isLocked,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'createdBy': createdBy,
      'sharedWith': sharedWith,
      'isPublic': isPublic,
      'metadata': metadata,
    };
  }
}

class WidgetTemplate {
  final String id;
  final String name;
  final String description;
  final WidgetType type;
  final WidgetSize defaultSize;
  final Map<String, dynamic> defaultConfiguration;
  final List<String> requiredDataFields;
  final String category;
  final String iconPath;
  final bool isCustom;
  final DateTime createdAt;
  final String createdBy;
  final int usageCount;
  final double rating;

  WidgetTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.defaultSize,
    this.defaultConfiguration = const {},
    this.requiredDataFields = const [],
    required this.category,
    required this.iconPath,
    this.isCustom = false,
    required this.createdAt,
    required this.createdBy,
    this.usageCount = 0,
    this.rating = 0.0,
  });

  factory WidgetTemplate.fromJson(Map<String, dynamic> json) {
    return WidgetTemplate(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: WidgetType.values.byName(json['type']),
      defaultSize: WidgetSize.values.byName(json['defaultSize']),
      defaultConfiguration: json['defaultConfiguration'] ?? {},
      requiredDataFields: List<String>.from(json['requiredDataFields'] ?? []),
      category: json['category'],
      iconPath: json['iconPath'],
      isCustom: json['isCustom'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      createdBy: json['createdBy'],
      usageCount: json['usageCount'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'defaultSize': defaultSize.name,
      'defaultConfiguration': defaultConfiguration,
      'requiredDataFields': requiredDataFields,
      'category': category,
      'iconPath': iconPath,
      'isCustom': isCustom,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'usageCount': usageCount,
      'rating': rating,
    };
  }
}

class DashboardFilter {
  final String id;
  final String name;
  final String field;
  final String operator;
  final dynamic value;
  final bool isActive;
  final DateTime createdAt;

  DashboardFilter({
    required this.id,
    required this.name,
    required this.field,
    required this.operator,
    required this.value,
    this.isActive = true,
    required this.createdAt,
  });

  factory DashboardFilter.fromJson(Map<String, dynamic> json) {
    return DashboardFilter(
      id: json['id'],
      name: json['name'],
      field: json['field'],
      operator: json['operator'],
      value: json['value'],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'field': field,
      'operator': operator,
      'value': value,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class DashboardExport {
  final String id;
  final String dashboardId;
  final String format;
  final Map<String, dynamic> options;
  final String status;
  final String? downloadUrl;
  final DateTime requestedAt;
  final DateTime? completedAt;
  final String requestedBy;
  final String? errorMessage;

  DashboardExport({
    required this.id,
    required this.dashboardId,
    required this.format,
    this.options = const {},
    required this.status,
    this.downloadUrl,
    required this.requestedAt,
    this.completedAt,
    required this.requestedBy,
    this.errorMessage,
  });

  factory DashboardExport.fromJson(Map<String, dynamic> json) {
    return DashboardExport(
      id: json['id'],
      dashboardId: json['dashboardId'],
      format: json['format'],
      options: json['options'] ?? {},
      status: json['status'],
      downloadUrl: json['downloadUrl'],
      requestedAt: DateTime.parse(json['requestedAt']),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      requestedBy: json['requestedBy'],
      errorMessage: json['errorMessage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dashboardId': dashboardId,
      'format': format,
      'options': options,
      'status': status,
      'downloadUrl': downloadUrl,
      'requestedAt': requestedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'requestedBy': requestedBy,
      'errorMessage': errorMessage,
    };
  }
}

class DashboardPermission {
  final String id;
  final String dashboardId;
  final String userId;
  final String role;
  final List<String> permissions;
  final DateTime grantedAt;
  final String grantedBy;
  final DateTime? expiresAt;
  final bool isActive;

  DashboardPermission({
    required this.id,
    required this.dashboardId,
    required this.userId,
    required this.role,
    this.permissions = const [],
    required this.grantedAt,
    required this.grantedBy,
    this.expiresAt,
    this.isActive = true,
  });

  factory DashboardPermission.fromJson(Map<String, dynamic> json) {
    return DashboardPermission(
      id: json['id'],
      dashboardId: json['dashboardId'],
      userId: json['userId'],
      role: json['role'],
      permissions: List<String>.from(json['permissions'] ?? []),
      grantedAt: DateTime.parse(json['grantedAt']),
      grantedBy: json['grantedBy'],
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dashboardId': dashboardId,
      'userId': userId,
      'role': role,
      'permissions': permissions,
      'grantedAt': grantedAt.toIso8601String(),
      'grantedBy': grantedBy,
      'expiresAt': expiresAt?.toIso8601String(),
      'isActive': isActive,
    };
  }
}
