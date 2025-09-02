import 'dart:async';
import 'dart:math';
import '../../../core/models/user_management_models.dart';
import 'dart:developer' as developer;

class EnhancedUserManagementService {
  final List<UserProfile> _users = [];
  final List<BulkOperation> _bulkOperations = [];
  final List<UserActivity> _userActivities = [];
  final List<UserSession> _userSessions = [];
  final List<UserNotification> _notifications = [];
  
  final StreamController<BulkOperation> _bulkOperationController = StreamController.broadcast();
  final StreamController<UserProfile> _userUpdateController = StreamController.broadcast();
  final StreamController<UserActivity> _activityController = StreamController.broadcast();
  
  Stream<BulkOperation> get bulkOperationStream => _bulkOperationController.stream;
  Stream<UserProfile> get userUpdateStream => _userUpdateController.stream;
  Stream<UserActivity> get activityStream => _activityController.stream;
  
  EnhancedUserManagementService() {
    _initializeMockData();
  }

  void _initializeMockData() {
    final random = Random();
    final now = DateTime.now();
    
    // Generate mock users
    final roles = UserRole.values;
    final statuses = UserStatus.values;
    final lifecycleStages = UserLifecycleStage.values;
    
    for (int i = 1; i <= 50; i++) {
      final user = UserProfile(
        id: 'user_$i',
        email: 'user$i@example.com',
        displayName: 'User $i',
        firstName: 'First$i',
        lastName: 'Last$i',
        phoneNumber: '+1${random.nextInt(9000000000) + 1000000000}',
        status: statuses[random.nextInt(statuses.length)],
        role: roles[random.nextInt(roles.length)],
        createdAt: now.subtract(Duration(days: random.nextInt(365))),
        lastLoginAt: now.subtract(Duration(hours: random.nextInt(168))),
        lastActivityAt: now.subtract(Duration(minutes: random.nextInt(1440))),
        metadata: {
          'source': random.nextBool() ? 'web' : 'mobile',
          'region': ['US', 'EU', 'APAC'][random.nextInt(3)],
          'department': ['Engineering', 'Marketing', 'Sales', 'Support'][random.nextInt(4)],
        },
        permissions: _generateRandomPermissions(random),
        lifecycleStage: lifecycleStages[random.nextInt(lifecycleStages.length)],
        riskScore: random.nextDouble() * 100,
        isMfaEnabled: random.nextBool(),
        profileImageUrl: random.nextBool() ? 'https://example.com/avatar$i.jpg' : null,
        preferences: {
          'theme': random.nextBool() ? 'dark' : 'light',
          'notifications': random.nextBool(),
          'language': ['en', 'es', 'fr', 'de'][random.nextInt(4)],
        },
      );
      _users.add(user);
    }

    // Generate mock bulk operations
    _bulkOperations.addAll([
      BulkOperation(
        id: 'bulk_1',
        action: BulkAction.activate,
        userIds: _users.take(10).map((u) => u.id).toList(),
        parameters: {'reason': 'Monthly activation batch'},
        initiatedBy: 'admin@example.com',
        initiatedAt: now.subtract(const Duration(hours: 2)),
        completedAt: now.subtract(const Duration(hours: 1, minutes: 45)),
        status: 'completed',
        totalUsers: 10,
        processedUsers: 10,
        successfulUsers: 9,
        failedUsers: 1,
        errors: ['User user_5 already active'],
        results: {'activated_users': 9, 'skipped_users': 1},
      ),
      BulkOperation(
        id: 'bulk_2',
        action: BulkAction.changeRole,
        userIds: _users.skip(10).take(5).map((u) => u.id).toList(),
        parameters: {'new_role': 'editor', 'reason': 'Promotion batch'},
        initiatedBy: 'admin@example.com',
        initiatedAt: now.subtract(const Duration(minutes: 30)),
        status: 'in_progress',
        totalUsers: 5,
        processedUsers: 3,
        successfulUsers: 3,
        failedUsers: 0,
        errors: [],
        results: {'processed_count': 3},
      ),
      BulkOperation(
        id: 'bulk_3',
        action: BulkAction.resetPassword,
        userIds: _users.skip(15).take(8).map((u) => u.id).toList(),
        parameters: {'send_email': true, 'force_change': true},
        initiatedBy: 'security@example.com',
        initiatedAt: now.subtract(const Duration(days: 1)),
        completedAt: now.subtract(const Duration(days: 1, hours: -1)),
        status: 'completed',
        totalUsers: 8,
        processedUsers: 8,
        successfulUsers: 8,
        failedUsers: 0,
        errors: [],
        results: {'passwords_reset': 8, 'emails_sent': 8},
      ),
    ]);

    // Generate mock user activities
    for (int i = 0; i < 100; i++) {
      final user = _users[random.nextInt(_users.length)];
      final activities = [
        'login', 'logout', 'profile_update', 'password_change', 
        'mfa_enable', 'mfa_disable', 'data_export', 'settings_change'
      ];
      final activity = activities[random.nextInt(activities.length)];
      
      _userActivities.add(UserActivity(
        id: 'activity_$i',
        userId: user.id,
        action: activity,
        description: _getActivityDescription(activity),
        timestamp: now.subtract(Duration(minutes: random.nextInt(10080))), // Last week
        ipAddress: '192.168.1.${random.nextInt(255)}',
        userAgent: 'Mozilla/5.0 (${random.nextBool() ? 'Windows' : 'macOS'}) Chrome/120.0',
        location: ['New York, US', 'London, UK', 'Tokyo, JP', 'Sydney, AU'][random.nextInt(4)],
        metadata: {
          'session_id': 'sess_${random.nextInt(100000)}',
          'device_type': random.nextBool() ? 'desktop' : 'mobile',
        },
      ));
    }

    // Generate mock user sessions
    for (int i = 0; i < 30; i++) {
      final user = _users[random.nextInt(_users.length)];
      final startTime = now.subtract(Duration(hours: random.nextInt(72)));
      final isActive = random.nextBool();
      
      _userSessions.add(UserSession(
        id: 'session_$i',
        userId: user.id,
        startTime: startTime,
        endTime: isActive ? null : startTime.add(Duration(minutes: random.nextInt(480))),
        ipAddress: '192.168.1.${random.nextInt(255)}',
        userAgent: 'Mozilla/5.0 (${random.nextBool() ? 'Windows' : 'macOS'}) Chrome/120.0',
        location: ['New York, US', 'London, UK', 'Tokyo, JP'][random.nextInt(3)],
        isActive: isActive,
        metadata: {
          'device_type': random.nextBool() ? 'desktop' : 'mobile',
          'browser': ['Chrome', 'Firefox', 'Safari', 'Edge'][random.nextInt(4)],
        },
      ));
    }

    // Generate mock notifications
    for (int i = 0; i < 25; i++) {
      final user = _users[random.nextInt(_users.length)];
      final types = ['security', 'system', 'promotion', 'reminder'];
      final type = types[random.nextInt(types.length)];
      
      _notifications.add(UserNotification(
        id: 'notification_$i',
        userId: user.id,
        title: _getNotificationTitle(type),
        message: _getNotificationMessage(type),
        type: type,
        createdAt: now.subtract(Duration(hours: random.nextInt(168))),
        readAt: random.nextBool() ? now.subtract(Duration(hours: random.nextInt(24))) : null,
        isRead: random.nextBool(),
        data: {
          'priority': ['low', 'medium', 'high'][random.nextInt(3)],
          'category': type,
        },
      ));
    }
  }

  List<String> _generateRandomPermissions(Random random) {
    final allPermissions = [
      'read_profile', 'write_profile', 'read_users', 'write_users',
      'read_admin', 'write_admin', 'read_reports', 'write_reports',
      'manage_roles', 'manage_permissions', 'export_data', 'import_data'
    ];
    
    final count = random.nextInt(6) + 2; // 2-7 permissions
    final permissions = <String>[];
    final shuffled = [...allPermissions]..shuffle(random);
    
    for (int i = 0; i < count && i < shuffled.length; i++) {
      permissions.add(shuffled[i]);
    }
    
    return permissions;
  }

  String _getActivityDescription(String action) {
    switch (action) {
      case 'login':
        return 'User logged into the system';
      case 'logout':
        return 'User logged out of the system';
      case 'profile_update':
        return 'User updated their profile information';
      case 'password_change':
        return 'User changed their password';
      case 'mfa_enable':
        return 'User enabled multi-factor authentication';
      case 'mfa_disable':
        return 'User disabled multi-factor authentication';
      case 'data_export':
        return 'User exported their data';
      case 'settings_change':
        return 'User modified their account settings';
      default:
        return 'User performed an action';
    }
  }

  String _getNotificationTitle(String type) {
    switch (type) {
      case 'security':
        return 'Security Alert';
      case 'system':
        return 'System Update';
      case 'promotion':
        return 'New Features Available';
      case 'reminder':
        return 'Account Reminder';
      default:
        return 'Notification';
    }
  }

  String _getNotificationMessage(String type) {
    switch (type) {
      case 'security':
        return 'We detected a login from a new device. If this wasn\'t you, please secure your account.';
      case 'system':
        return 'System maintenance is scheduled for tonight from 2-4 AM EST.';
      case 'promotion':
        return 'Check out our new dashboard features and improved security settings!';
      case 'reminder':
        return 'Don\'t forget to complete your profile setup for better security.';
      default:
        return 'You have a new notification.';
    }
  }

  // Public API methods
  Future<List<UserProfile>> getUsers({
    UserFilter? filter,
    int offset = 0,
    int limit = 20,
    String sortBy = 'createdAt',
    bool ascending = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    var filteredUsers = _users.where((user) {
      if (filter == null) return true;
      
      if (filter.status != null && user.status != filter.status) return false;
      if (filter.role != null && user.role != filter.role) return false;
      if (filter.lifecycleStage != null && user.lifecycleStage != filter.lifecycleStage) return false;
      if (filter.isMfaEnabled != null && user.isMfaEnabled != filter.isMfaEnabled) return false;
      
      if (filter.createdAfter != null && user.createdAt.isBefore(filter.createdAfter!)) return false;
      if (filter.createdBefore != null && user.createdAt.isAfter(filter.createdBefore!)) return false;
      if (filter.lastLoginAfter != null && user.lastLoginAt.isBefore(filter.lastLoginAfter!)) return false;
      if (filter.lastLoginBefore != null && user.lastLoginAt.isAfter(filter.lastLoginBefore!)) return false;
      
      if (filter.minRiskScore != null && user.riskScore < filter.minRiskScore!) return false;
      if (filter.maxRiskScore != null && user.riskScore > filter.maxRiskScore!) return false;
      
      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        final query = filter.searchQuery!.toLowerCase();
        if (!user.email.toLowerCase().contains(query) &&
            !(user.displayName?.toLowerCase().contains(query) ?? false) &&
            !(user.firstName?.toLowerCase().contains(query) ?? false) &&
            !(user.lastName?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }
      
      if (filter.permissions != null && filter.permissions!.isNotEmpty) {
        if (!filter.permissions!.any((perm) => user.permissions.contains(perm))) {
          return false;
        }
      }
      
      return true;
    }).toList();

    // Sort users
    filteredUsers.sort((a, b) {
      dynamic aValue, bValue;
      switch (sortBy) {
        case 'email':
          aValue = a.email;
          bValue = b.email;
          break;
        case 'createdAt':
          aValue = a.createdAt;
          bValue = b.createdAt;
          break;
        case 'lastLoginAt':
          aValue = a.lastLoginAt;
          bValue = b.lastLoginAt;
          break;
        case 'riskScore':
          aValue = a.riskScore;
          bValue = b.riskScore;
          break;
        default:
          aValue = a.createdAt;
          bValue = b.createdAt;
      }
      
      final comparison = Comparable.compare(aValue, bValue);
      return ascending ? comparison : -comparison;
    });

    return filteredUsers.skip(offset).take(limit).toList();
  }

  Future<UserProfile?> getUserById(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _users.firstWhere((user) => user.id == userId, orElse: () => throw Exception('User not found'));
  }

  Future<UserAnalytics> getUserAnalytics() async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1);
    
    final usersByRole = <UserRole, int>{};
    final usersByLifecycleStage = <UserLifecycleStage, int>{};
    final usersByRegion = <String, int>{};
    
    for (final user in _users) {
      usersByRole[user.role] = (usersByRole[user.role] ?? 0) + 1;
      usersByLifecycleStage[user.lifecycleStage] = (usersByLifecycleStage[user.lifecycleStage] ?? 0) + 1;
      
      final region = user.metadata['region'] as String? ?? 'Unknown';
      usersByRegion[region] = (usersByRegion[region] ?? 0) + 1;
    }
    
    return UserAnalytics(
      totalUsers: _users.length,
      activeUsers: _users.where((u) => u.status == UserStatus.active).length,
      inactiveUsers: _users.where((u) => u.status == UserStatus.inactive).length,
      suspendedUsers: _users.where((u) => u.status == UserStatus.suspended).length,
      newUsersThisMonth: _users.where((u) => u.createdAt.isAfter(thisMonth)).length,
      averageRiskScore: _users.map((u) => u.riskScore).reduce((a, b) => a + b) / _users.length,
      mfaEnabledUsers: _users.where((u) => u.isMfaEnabled).length,
      usersByRole: usersByRole,
      usersByLifecycleStage: usersByLifecycleStage,
      usersByRegion: usersByRegion,
      lastUpdated: now,
    );
  }

  Future<BulkOperation> createBulkOperation(
    BulkAction action,
    List<String> userIds,
    Map<String, dynamic> parameters,
    String initiatedBy,
  ) async {
    final operation = BulkOperation(
      id: 'bulk_${DateTime.now().millisecondsSinceEpoch}',
      action: action,
      userIds: userIds,
      parameters: parameters,
      initiatedBy: initiatedBy,
      initiatedAt: DateTime.now(),
      status: 'pending',
      totalUsers: userIds.length,
      processedUsers: 0,
      successfulUsers: 0,
      failedUsers: 0,
    );

    _bulkOperations.insert(0, operation);
    _bulkOperationController.add(operation);
    
    // Start processing asynchronously
    _processBulkOperation(operation);
    
    developer.log('Bulk operation created: ${action.name} for ${userIds.length} users', name: 'UserManagement');
    
    return operation;
  }

  Future<void> _processBulkOperation(BulkOperation operation) async {
    // Update status to in_progress
    final inProgressOp = BulkOperation(
      id: operation.id,
      action: operation.action,
      userIds: operation.userIds,
      parameters: operation.parameters,
      initiatedBy: operation.initiatedBy,
      initiatedAt: operation.initiatedAt,
      status: 'in_progress',
      totalUsers: operation.totalUsers,
      processedUsers: 0,
      successfulUsers: 0,
      failedUsers: 0,
    );
    
    _updateBulkOperation(inProgressOp);
    
    // Simulate processing
    final errors = <String>[];
    int successful = 0;
    int failed = 0;
    
    for (int i = 0; i < operation.userIds.length; i++) {
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate processing time
      
      final userId = operation.userIds[i];
      final success = await _processUserAction(operation.action, userId, operation.parameters);
      
      if (success) {
        successful++;
      } else {
        failed++;
        errors.add('Failed to process user $userId');
      }
      
      // Update progress
      final progressOp = BulkOperation(
        id: operation.id,
        action: operation.action,
        userIds: operation.userIds,
        parameters: operation.parameters,
        initiatedBy: operation.initiatedBy,
        initiatedAt: operation.initiatedAt,
        status: 'in_progress',
        totalUsers: operation.totalUsers,
        processedUsers: i + 1,
        successfulUsers: successful,
        failedUsers: failed,
        errors: errors,
      );
      
      _updateBulkOperation(progressOp);
    }
    
    // Complete operation
    final completedOp = BulkOperation(
      id: operation.id,
      action: operation.action,
      userIds: operation.userIds,
      parameters: operation.parameters,
      initiatedBy: operation.initiatedBy,
      initiatedAt: operation.initiatedAt,
      completedAt: DateTime.now(),
      status: 'completed',
      totalUsers: operation.totalUsers,
      processedUsers: operation.userIds.length,
      successfulUsers: successful,
      failedUsers: failed,
      errors: errors,
      results: {
        'successful_operations': successful,
        'failed_operations': failed,
        'completion_time': DateTime.now().toIso8601String(),
      },
    );
    
    _updateBulkOperation(completedOp);
    
    developer.log('Bulk operation completed: ${operation.id}', name: 'UserManagement');
  }

  Future<bool> _processUserAction(BulkAction action, String userId, Map<String, dynamic> parameters) async {
    final userIndex = _users.indexWhere((u) => u.id == userId);
    if (userIndex == -1) return false;
    
    final user = _users[userIndex];
    UserProfile? updatedUser;
    
    try {
      switch (action) {
        case BulkAction.activate:
          updatedUser = user.copyWith(status: UserStatus.active);
          break;
        case BulkAction.deactivate:
          updatedUser = user.copyWith(status: UserStatus.inactive);
          break;
        case BulkAction.suspend:
          updatedUser = user.copyWith(status: UserStatus.suspended);
          break;
        case BulkAction.changeRole:
          final newRole = UserRole.values.byName(parameters['new_role']);
          updatedUser = user.copyWith(role: newRole);
          break;
        case BulkAction.resetPassword:
          // In a real implementation, this would reset the password
          // For now, just log the activity
          _userActivities.insert(0, UserActivity(
            id: 'activity_${DateTime.now().millisecondsSinceEpoch}',
            userId: userId,
            action: 'password_reset',
            description: 'Password reset via bulk operation',
            timestamp: DateTime.now(),
            metadata: {'bulk_operation': true},
          ));
          break;
        case BulkAction.sendNotification:
          final title = parameters['title'] ?? 'Notification';
          final message = parameters['message'] ?? 'You have received a notification.';
          _notifications.insert(0, UserNotification(
            id: 'notification_${DateTime.now().millisecondsSinceEpoch}',
            userId: userId,
            title: title,
            message: message,
            type: 'system',
            createdAt: DateTime.now(),
            isRead: false,
          ));
          break;
        case BulkAction.delete:
          _users.removeAt(userIndex);
          break;
      }
      
      if (updatedUser != null) {
        _users[userIndex] = updatedUser;
        _userUpdateController.add(updatedUser);
      }
      
      return true;
    } catch (e) {
      developer.log('Error processing user action: $e', name: 'UserManagement');
      return false;
    }
  }

  void _updateBulkOperation(BulkOperation operation) {
    final index = _bulkOperations.indexWhere((op) => op.id == operation.id);
    if (index != -1) {
      _bulkOperations[index] = operation;
      _bulkOperationController.add(operation);
    }
  }

  Future<List<BulkOperation>> getBulkOperations({int limit = 20}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _bulkOperations.take(limit).toList();
  }

  Future<BulkOperation?> getBulkOperationById(String operationId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _bulkOperations.firstWhere((op) => op.id == operationId, orElse: () => throw Exception('Operation not found'));
  }

  Future<List<UserActivity>> getUserActivities({
    String? userId,
    int limit = 50,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    var activities = _userActivities;
    if (userId != null) {
      activities = activities.where((a) => a.userId == userId).toList();
    }
    
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return activities.take(limit).toList();
  }

  Future<List<UserSession>> getUserSessions({
    String? userId,
    bool? activeOnly,
    int limit = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    var sessions = _userSessions;
    if (userId != null) {
      sessions = sessions.where((s) => s.userId == userId).toList();
    }
    if (activeOnly == true) {
      sessions = sessions.where((s) => s.isActive).toList();
    }
    
    sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    return sessions.take(limit).toList();
  }

  Future<void> terminateUserSession(String sessionId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final sessionIndex = _userSessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex != -1) {
      final session = _userSessions[sessionIndex];
      final updatedSession = UserSession(
        id: session.id,
        userId: session.userId,
        startTime: session.startTime,
        endTime: DateTime.now(),
        ipAddress: session.ipAddress,
        userAgent: session.userAgent,
        location: session.location,
        isActive: false,
        metadata: session.metadata,
      );
      
      _userSessions[sessionIndex] = updatedSession;
      
      developer.log('Session terminated: $sessionId', name: 'UserManagement');
    }
  }

  Future<List<UserNotification>> getUserNotifications({
    String? userId,
    bool? unreadOnly,
    int limit = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    var notifications = _notifications;
    if (userId != null) {
      notifications = notifications.where((n) => n.userId == userId).toList();
    }
    if (unreadOnly == true) {
      notifications = notifications.where((n) => !n.isRead).toList();
    }
    
    notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notifications.take(limit).toList();
  }

  Future<UserProfile> updateUser(String userId, Map<String, dynamic> updates) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final userIndex = _users.indexWhere((u) => u.id == userId);
    if (userIndex == -1) throw Exception('User not found');
    
    final user = _users[userIndex];
    final updatedUser = UserProfile(
      id: user.id,
      email: updates['email'] ?? user.email,
      displayName: updates['displayName'] ?? user.displayName,
      firstName: updates['firstName'] ?? user.firstName,
      lastName: updates['lastName'] ?? user.lastName,
      phoneNumber: updates['phoneNumber'] ?? user.phoneNumber,
      status: updates['status'] != null ? UserStatus.values.byName(updates['status']) : user.status,
      role: updates['role'] != null ? UserRole.values.byName(updates['role']) : user.role,
      createdAt: user.createdAt,
      lastLoginAt: user.lastLoginAt,
      lastActivityAt: DateTime.now(),
      metadata: updates['metadata'] ?? user.metadata,
      permissions: updates['permissions'] ?? user.permissions,
      lifecycleStage: updates['lifecycleStage'] != null ? UserLifecycleStage.values.byName(updates['lifecycleStage']) : user.lifecycleStage,
      riskScore: updates['riskScore'] ?? user.riskScore,
      isMfaEnabled: updates['isMfaEnabled'] ?? user.isMfaEnabled,
      profileImageUrl: updates['profileImageUrl'] ?? user.profileImageUrl,
      preferences: updates['preferences'] ?? user.preferences,
    );
    
    _users[userIndex] = updatedUser;
    _userUpdateController.add(updatedUser);
    
    // Log activity
    _userActivities.insert(0, UserActivity(
      id: 'activity_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      action: 'profile_update',
      description: 'User profile updated by admin',
      timestamp: DateTime.now(),
      metadata: {'updated_fields': updates.keys.toList()},
    ));
    
    developer.log('User updated: $userId', name: 'UserManagement');
    
    return updatedUser;
  }

  Future<Map<String, dynamic>> getUserStatistics() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final now = DateTime.now();
    final last24h = now.subtract(const Duration(hours: 24));
    final last7d = now.subtract(const Duration(days: 7));
    
    return {
      'total_users': _users.length,
      'active_users': _users.where((u) => u.status == UserStatus.active).length,
      'new_users_24h': _users.where((u) => u.createdAt.isAfter(last24h)).length,
      'new_users_7d': _users.where((u) => u.createdAt.isAfter(last7d)).length,
      'active_sessions': _userSessions.where((s) => s.isActive).length,
      'recent_activities': _userActivities.where((a) => a.timestamp.isAfter(last24h)).length,
      'bulk_operations_pending': _bulkOperations.where((op) => op.status == 'pending' || op.status == 'in_progress').length,
      'unread_notifications': _notifications.where((n) => !n.isRead).length,
      'high_risk_users': _users.where((u) => u.riskScore > 70).length,
      'mfa_enabled_percentage': (_users.where((u) => u.isMfaEnabled).length / _users.length * 100).toStringAsFixed(1),
    };
  }

  void dispose() {
    _bulkOperationController.close();
    _userUpdateController.close();
    _activityController.close();
  }
}
