import 'package:flutter/material.dart';

enum UserRole {
  superuser,
  admin,
  staff,
  user,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.superuser:
        return 'Superuser';
      case UserRole.admin:
        return 'Admin';
      case UserRole.staff:
        return 'Staff';
      case UserRole.user:
        return 'User';
    }
  }

  int get level {
    switch (this) {
      case UserRole.superuser:
        return 100;
      case UserRole.admin:
        return 50;
      case UserRole.staff:
        return 20;
      case UserRole.user:
        return 10;
    }
  }

  bool canDelete() => this == UserRole.superuser || this == UserRole.admin;
  bool canApprove() => this == UserRole.superuser;
  bool canRequestDelete() => this == UserRole.staff || this == UserRole.admin || this == UserRole.superuser;
  bool canViewUsers() => this != UserRole.user;
  bool canEditUsers() => this == UserRole.admin || this == UserRole.superuser;
}

enum ActionType {
  deleteUser,
  suspendUser,
  resetPassword,
  changeRole,
  exportData,
  bulkDelete,
}

enum ActionStatus {
  pending,
  approved,
  rejected,
  expired,
}

class PendingAction {
  final String id;
  final ActionType actionType;
  final String requestedBy;
  final String requestedByName;
  final UserRole requestedByRole;
  final DateTime requestedAt;
  final String targetUserId;
  final String targetUserName;
  final String reason;
  final ActionStatus status;
  final String? approvedBy;
  final String? approvedByName;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final Map<String, dynamic>? metadata;

  PendingAction({
    required this.id,
    required this.actionType,
    required this.requestedBy,
    required this.requestedByName,
    required this.requestedByRole,
    required this.requestedAt,
    required this.targetUserId,
    required this.targetUserName,
    required this.reason,
    required this.status,
    this.approvedBy,
    this.approvedByName,
    this.approvedAt,
    this.rejectionReason,
    this.metadata,
  });

  factory PendingAction.fromJson(Map<String, dynamic> json) {
    return PendingAction(
      id: json['id'],
      actionType: ActionType.values.firstWhere(
        (e) => e.toString() == 'ActionType.${json['actionType']}',
      ),
      requestedBy: json['requestedBy'],
      requestedByName: json['requestedByName'] ?? 'Unknown',
      requestedByRole: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${json['requestedByRole']}',
      ),
      requestedAt: DateTime.parse(json['requestedAt']),
      targetUserId: json['targetUserId'],
      targetUserName: json['targetUserName'] ?? 'Unknown',
      reason: json['reason'],
      status: ActionStatus.values.firstWhere(
        (e) => e.toString() == 'ActionStatus.${json['status']}',
      ),
      approvedBy: json['approvedBy'],
      approvedByName: json['approvedByName'],
      approvedAt: json['approvedAt'] != null 
          ? DateTime.parse(json['approvedAt'])
          : null,
      rejectionReason: json['rejectionReason'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'actionType': actionType.toString().split('.').last,
      'requestedBy': requestedBy,
      'requestedByName': requestedByName,
      'requestedByRole': requestedByRole.toString().split('.').last,
      'requestedAt': requestedAt.toIso8601String(),
      'targetUserId': targetUserId,
      'targetUserName': targetUserName,
      'reason': reason,
      'status': status.toString().split('.').last,
      'approvedBy': approvedBy,
      'approvedByName': approvedByName,
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'metadata': metadata,
    };
  }

  String get actionDescription {
    switch (actionType) {
      case ActionType.deleteUser:
        return 'Delete user: $targetUserName';
      case ActionType.suspendUser:
        return 'Suspend user: $targetUserName';
      case ActionType.resetPassword:
        return 'Reset password for: $targetUserName';
      case ActionType.changeRole:
        return 'Change role for: $targetUserName';
      case ActionType.exportData:
        return 'Export data for: $targetUserName';
      case ActionType.bulkDelete:
        return 'Bulk delete users';
    }
  }

  IconData get actionIcon {
    switch (actionType) {
      case ActionType.deleteUser:
        return Icons.delete_forever;
      case ActionType.suspendUser:
        return Icons.block;
      case ActionType.resetPassword:
        return Icons.lock_reset;
      case ActionType.changeRole:
        return Icons.admin_panel_settings;
      case ActionType.exportData:
        return Icons.download;
      case ActionType.bulkDelete:
        return Icons.delete_sweep;
    }
  }

  Color get statusColor {
    switch (status) {
      case ActionStatus.pending:
        return Colors.orange;
      case ActionStatus.approved:
        return Colors.green;
      case ActionStatus.rejected:
        return Colors.red;
      case ActionStatus.expired:
        return Colors.grey;
    }
  }
}

class StaffPermissions {
  static const List<String> allowedActions = [
    'view_users',
    'request_delete',
    'request_suspend',
    'request_password_reset',
    'view_logs',
    'view_basic_analytics',
  ];

  static const List<String> deniedActions = [
    'direct_delete',
    'direct_suspend',
    'change_roles',
    'access_sensitive_data',
    'export_all_data',
    'modify_system_settings',
    'approve_actions',
  ];
}
