enum UserStatus { active, inactive, suspended, locked, pending }
enum UserRole { user, admin, moderator, viewer, editor }
enum BulkAction { activate, deactivate, suspend, delete, changeRole, resetPassword, sendNotification }
enum UserLifecycleStage { registration, onboarding, active, dormant, churning, churned }

class UserProfile {
  final String id;
  final String email;
  final String? displayName;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final UserStatus status;
  final UserRole role;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final DateTime? lastActivityAt;
  final Map<String, dynamic> metadata;
  final List<String> permissions;
  final UserLifecycleStage lifecycleStage;
  final double riskScore;
  final bool isMfaEnabled;
  final String? profileImageUrl;
  final Map<String, dynamic> preferences;

  UserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    required this.status,
    required this.role,
    required this.createdAt,
    required this.lastLoginAt,
    this.lastActivityAt,
    this.metadata = const {},
    this.permissions = const [],
    required this.lifecycleStage,
    required this.riskScore,
    required this.isMfaEnabled,
    this.profileImageUrl,
    this.preferences = const {},
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'],
      displayName: json['displayName'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      phoneNumber: json['phoneNumber'],
      status: UserStatus.values.byName(json['status']),
      role: UserRole.values.byName(json['role']),
      createdAt: DateTime.parse(json['createdAt']),
      lastLoginAt: DateTime.parse(json['lastLoginAt']),
      lastActivityAt: json['lastActivityAt'] != null ? DateTime.parse(json['lastActivityAt']) : null,
      metadata: json['metadata'] ?? {},
      permissions: List<String>.from(json['permissions'] ?? []),
      lifecycleStage: UserLifecycleStage.values.byName(json['lifecycleStage']),
      riskScore: json['riskScore'].toDouble(),
      isMfaEnabled: json['isMfaEnabled'],
      profileImageUrl: json['profileImageUrl'],
      preferences: json['preferences'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'status': status.name,
      'role': role.name,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'lastActivityAt': lastActivityAt?.toIso8601String(),
      'metadata': metadata,
      'permissions': permissions,
      'lifecycleStage': lifecycleStage.name,
      'riskScore': riskScore,
      'isMfaEnabled': isMfaEnabled,
      'profileImageUrl': profileImageUrl,
      'preferences': preferences,
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    UserStatus? status,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    DateTime? lastActivityAt,
    Map<String, dynamic>? metadata,
    List<String>? permissions,
    UserLifecycleStage? lifecycleStage,
    double? riskScore,
    bool? isMfaEnabled,
    String? profileImageUrl,
    Map<String, dynamic>? preferences,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      status: status ?? this.status,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      metadata: metadata ?? this.metadata,
      permissions: permissions ?? this.permissions,
      lifecycleStage: lifecycleStage ?? this.lifecycleStage,
      riskScore: riskScore ?? this.riskScore,
      isMfaEnabled: isMfaEnabled ?? this.isMfaEnabled,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      preferences: preferences ?? this.preferences,
    );
  }
}

class BulkOperation {
  final String id;
  final BulkAction action;
  final List<String> userIds;
  final Map<String, dynamic> parameters;
  final String initiatedBy;
  final DateTime initiatedAt;
  final DateTime? completedAt;
  final String status; // pending, in_progress, completed, failed, cancelled
  final int totalUsers;
  final int processedUsers;
  final int successfulUsers;
  final int failedUsers;
  final List<String> errors;
  final Map<String, dynamic> results;

  BulkOperation({
    required this.id,
    required this.action,
    required this.userIds,
    this.parameters = const {},
    required this.initiatedBy,
    required this.initiatedAt,
    this.completedAt,
    required this.status,
    required this.totalUsers,
    required this.processedUsers,
    required this.successfulUsers,
    required this.failedUsers,
    this.errors = const [],
    this.results = const {},
  });

  factory BulkOperation.fromJson(Map<String, dynamic> json) {
    return BulkOperation(
      id: json['id'],
      action: BulkAction.values.byName(json['action']),
      userIds: List<String>.from(json['userIds']),
      parameters: json['parameters'] ?? {},
      initiatedBy: json['initiatedBy'],
      initiatedAt: DateTime.parse(json['initiatedAt']),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      status: json['status'],
      totalUsers: json['totalUsers'],
      processedUsers: json['processedUsers'],
      successfulUsers: json['successfulUsers'],
      failedUsers: json['failedUsers'],
      errors: List<String>.from(json['errors'] ?? []),
      results: json['results'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action.name,
      'userIds': userIds,
      'parameters': parameters,
      'initiatedBy': initiatedBy,
      'initiatedAt': initiatedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'status': status,
      'totalUsers': totalUsers,
      'processedUsers': processedUsers,
      'successfulUsers': successfulUsers,
      'failedUsers': failedUsers,
      'errors': errors,
      'results': results,
    };
  }
}

class UserFilter {
  final UserStatus? status;
  final UserRole? role;
  final UserLifecycleStage? lifecycleStage;
  final DateTime? createdAfter;
  final DateTime? createdBefore;
  final DateTime? lastLoginAfter;
  final DateTime? lastLoginBefore;
  final double? minRiskScore;
  final double? maxRiskScore;
  final bool? isMfaEnabled;
  final String? searchQuery;
  final List<String>? permissions;

  UserFilter({
    this.status,
    this.role,
    this.lifecycleStage,
    this.createdAfter,
    this.createdBefore,
    this.lastLoginAfter,
    this.lastLoginBefore,
    this.minRiskScore,
    this.maxRiskScore,
    this.isMfaEnabled,
    this.searchQuery,
    this.permissions,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status?.name,
      'role': role?.name,
      'lifecycleStage': lifecycleStage?.name,
      'createdAfter': createdAfter?.toIso8601String(),
      'createdBefore': createdBefore?.toIso8601String(),
      'lastLoginAfter': lastLoginAfter?.toIso8601String(),
      'lastLoginBefore': lastLoginBefore?.toIso8601String(),
      'minRiskScore': minRiskScore,
      'maxRiskScore': maxRiskScore,
      'isMfaEnabled': isMfaEnabled,
      'searchQuery': searchQuery,
      'permissions': permissions,
    };
  }
}

class UserAnalytics {
  final int totalUsers;
  final int activeUsers;
  final int inactiveUsers;
  final int suspendedUsers;
  final int newUsersThisMonth;
  final double averageRiskScore;
  final int mfaEnabledUsers;
  final Map<UserRole, int> usersByRole;
  final Map<UserLifecycleStage, int> usersByLifecycleStage;
  final Map<String, int> usersByRegion;
  final DateTime lastUpdated;

  UserAnalytics({
    required this.totalUsers,
    required this.activeUsers,
    required this.inactiveUsers,
    required this.suspendedUsers,
    required this.newUsersThisMonth,
    required this.averageRiskScore,
    required this.mfaEnabledUsers,
    this.usersByRole = const {},
    this.usersByLifecycleStage = const {},
    this.usersByRegion = const {},
    required this.lastUpdated,
  });

  factory UserAnalytics.fromJson(Map<String, dynamic> json) {
    return UserAnalytics(
      totalUsers: json['totalUsers'],
      activeUsers: json['activeUsers'],
      inactiveUsers: json['inactiveUsers'],
      suspendedUsers: json['suspendedUsers'],
      newUsersThisMonth: json['newUsersThisMonth'],
      averageRiskScore: json['averageRiskScore'].toDouble(),
      mfaEnabledUsers: json['mfaEnabledUsers'],
      usersByRole: Map<UserRole, int>.from(
        json['usersByRole']?.map((key, value) => MapEntry(UserRole.values.byName(key), value)) ?? {}
      ),
      usersByLifecycleStage: Map<UserLifecycleStage, int>.from(
        json['usersByLifecycleStage']?.map((key, value) => MapEntry(UserLifecycleStage.values.byName(key), value)) ?? {}
      ),
      usersByRegion: Map<String, int>.from(json['usersByRegion'] ?? {}),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalUsers': totalUsers,
      'activeUsers': activeUsers,
      'inactiveUsers': inactiveUsers,
      'suspendedUsers': suspendedUsers,
      'newUsersThisMonth': newUsersThisMonth,
      'averageRiskScore': averageRiskScore,
      'mfaEnabledUsers': mfaEnabledUsers,
      'usersByRole': usersByRole.map((key, value) => MapEntry(key.name, value)),
      'usersByLifecycleStage': usersByLifecycleStage.map((key, value) => MapEntry(key.name, value)),
      'usersByRegion': usersByRegion,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

class UserActivity {
  final String id;
  final String userId;
  final String action;
  final String description;
  final DateTime timestamp;
  final String? ipAddress;
  final String? userAgent;
  final String? location;
  final Map<String, dynamic> metadata;

  UserActivity({
    required this.id,
    required this.userId,
    required this.action,
    required this.description,
    required this.timestamp,
    this.ipAddress,
    this.userAgent,
    this.location,
    this.metadata = const {},
  });

  factory UserActivity.fromJson(Map<String, dynamic> json) {
    return UserActivity(
      id: json['id'],
      userId: json['userId'],
      action: json['action'],
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
      ipAddress: json['ipAddress'],
      userAgent: json['userAgent'],
      location: json['location'],
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'action': action,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'location': location,
      'metadata': metadata,
    };
  }
}

class UserSession {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final String ipAddress;
  final String userAgent;
  final String? location;
  final bool isActive;
  final Map<String, dynamic> metadata;

  UserSession({
    required this.id,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.ipAddress,
    required this.userAgent,
    this.location,
    required this.isActive,
    this.metadata = const {},
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: json['id'],
      userId: json['userId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      ipAddress: json['ipAddress'],
      userAgent: json['userAgent'],
      location: json['location'],
      isActive: json['isActive'],
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'location': location,
      'isActive': isActive,
      'metadata': metadata,
    };
  }
}

class UserNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final DateTime createdAt;
  final DateTime? readAt;
  final bool isRead;
  final Map<String, dynamic> data;

  UserNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.readAt,
    required this.isRead,
    this.data = const {},
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    return UserNotification(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      createdAt: DateTime.parse(json['createdAt']),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      isRead: json['isRead'],
      data: json['data'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'isRead': isRead,
      'data': data,
    };
  }
}
