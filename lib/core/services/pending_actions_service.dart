import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/rbac_models.dart';

class PendingActionsService extends ChangeNotifier {
  static const String _storageKey = 'pending_actions';
  final List<PendingAction> _pendingActions = [];
  final StreamController<PendingAction> _actionRequestedController = StreamController<PendingAction>.broadcast();
  final StreamController<PendingAction> _actionApprovedController = StreamController<PendingAction>.broadcast();
  final StreamController<PendingAction> _actionRejectedController = StreamController<PendingAction>.broadcast();
  
  List<PendingAction> get pendingActions => List.unmodifiable(_pendingActions.where((a) => a.status == ActionStatus.pending));
  List<PendingAction> get allActions => List.unmodifiable(_pendingActions);
  List<PendingAction> get approvedActions => List.unmodifiable(_pendingActions.where((a) => a.status == ActionStatus.approved));
  List<PendingAction> get rejectedActions => List.unmodifiable(_pendingActions.where((a) => a.status == ActionStatus.rejected));
  
  Stream<PendingAction> get actionRequestedStream => _actionRequestedController.stream;
  Stream<PendingAction> get actionApprovedStream => _actionApprovedController.stream;
  Stream<PendingAction> get actionRejectedStream => _actionRejectedController.stream;

  int get pendingCount => pendingActions.length;
  
  PendingActionsService() {
    _loadActions();
  }

  Future<void> _loadActions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_storageKey);
      if (data != null) {
        final List<dynamic> jsonList = json.decode(data);
        _pendingActions.clear();
        _pendingActions.addAll(
          jsonList.map((json) => PendingAction.fromJson(json)),
        );
        
        // Mark old pending actions as expired (older than 7 days)
        final now = DateTime.now();
        for (final action in _pendingActions) {
          if (action.status == ActionStatus.pending &&
              now.difference(action.requestedAt).inDays > 7) {
            _pendingActions[_pendingActions.indexOf(action)] = PendingAction(
              id: action.id,
              actionType: action.actionType,
              requestedBy: action.requestedBy,
              requestedByName: action.requestedByName,
              requestedByRole: action.requestedByRole,
              requestedAt: action.requestedAt,
              targetUserId: action.targetUserId,
              targetUserName: action.targetUserName,
              reason: action.reason,
              status: ActionStatus.expired,
              metadata: action.metadata,
            );
          }
        }
        await _saveActions();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading pending actions: $e');
    }
  }

  Future<void> _saveActions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String data = json.encode(
        _pendingActions.map((action) => action.toJson()).toList(),
      );
      await prefs.setString(_storageKey, data);
    } catch (e) {
      debugPrint('Error saving pending actions: $e');
    }
  }

  Future<String> requestAction({
    required ActionType actionType,
    required String requestedBy,
    required String requestedByName,
    required UserRole requestedByRole,
    required String targetUserId,
    required String targetUserName,
    required String reason,
    Map<String, dynamic>? metadata,
  }) async {
    final actionId = 'ACTION_${DateTime.now().millisecondsSinceEpoch}_${requestedBy}';
    
    final action = PendingAction(
      id: actionId,
      actionType: actionType,
      requestedBy: requestedBy,
      requestedByName: requestedByName,
      requestedByRole: requestedByRole,
      requestedAt: DateTime.now(),
      targetUserId: targetUserId,
      targetUserName: targetUserName,
      reason: reason,
      status: ActionStatus.pending,
      metadata: metadata,
    );
    
    _pendingActions.add(action);
    await _saveActions();
    _actionRequestedController.add(action);
    notifyListeners();
    
    return actionId;
  }

  Future<bool> approveAction({
    required String actionId,
    required String approvedBy,
    required String approvedByName,
  }) async {
    final index = _pendingActions.indexWhere((a) => a.id == actionId);
    if (index == -1) return false;
    
    final action = _pendingActions[index];
    if (action.status != ActionStatus.pending) return false;
    
    final updatedAction = PendingAction(
      id: action.id,
      actionType: action.actionType,
      requestedBy: action.requestedBy,
      requestedByName: action.requestedByName,
      requestedByRole: action.requestedByRole,
      requestedAt: action.requestedAt,
      targetUserId: action.targetUserId,
      targetUserName: action.targetUserName,
      reason: action.reason,
      status: ActionStatus.approved,
      approvedBy: approvedBy,
      approvedByName: approvedByName,
      approvedAt: DateTime.now(),
      metadata: action.metadata,
    );
    
    _pendingActions[index] = updatedAction;
    await _saveActions();
    _actionApprovedController.add(updatedAction);
    notifyListeners();
    
    // Execute the action
    await _executeAction(updatedAction);
    
    return true;
  }

  Future<bool> rejectAction({
    required String actionId,
    required String rejectedBy,
    required String rejectedByName,
    required String rejectionReason,
  }) async {
    final index = _pendingActions.indexWhere((a) => a.id == actionId);
    if (index == -1) return false;
    
    final action = _pendingActions[index];
    if (action.status != ActionStatus.pending) return false;
    
    final updatedAction = PendingAction(
      id: action.id,
      actionType: action.actionType,
      requestedBy: action.requestedBy,
      requestedByName: action.requestedByName,
      requestedByRole: action.requestedByRole,
      requestedAt: action.requestedAt,
      targetUserId: action.targetUserId,
      targetUserName: action.targetUserName,
      reason: action.reason,
      status: ActionStatus.rejected,
      approvedBy: rejectedBy,
      approvedByName: rejectedByName,
      approvedAt: DateTime.now(),
      rejectionReason: rejectionReason,
      metadata: action.metadata,
    );
    
    _pendingActions[index] = updatedAction;
    await _saveActions();
    _actionRejectedController.add(updatedAction);
    notifyListeners();
    
    return true;
  }

  Future<void> _executeAction(PendingAction action) async {
    // This would be integrated with your backend
    // For now, we'll just log the action
    debugPrint('Executing action: ${action.actionType} for user ${action.targetUserId}');
    
    switch (action.actionType) {
      case ActionType.deleteUser:
        // Integrate with user deletion service
        debugPrint('Deleting user: ${action.targetUserId}');
        break;
      case ActionType.suspendUser:
        // Integrate with user suspension service
        debugPrint('Suspending user: ${action.targetUserId}');
        break;
      case ActionType.resetPassword:
        // Integrate with password reset service
        debugPrint('Resetting password for: ${action.targetUserId}');
        break;
      case ActionType.changeRole:
        // Integrate with role management service
        debugPrint('Changing role for: ${action.targetUserId}');
        break;
      case ActionType.exportData:
        // Integrate with data export service
        debugPrint('Exporting data for: ${action.targetUserId}');
        break;
      case ActionType.bulkDelete:
        // Integrate with bulk operations service
        debugPrint('Performing bulk delete');
        break;
    }
  }

  List<PendingAction> getActionsForUser(String userId) {
    return _pendingActions.where((a) => a.requestedBy == userId).toList();
  }

  List<PendingAction> getActionsTargetingUser(String userId) {
    return _pendingActions.where((a) => a.targetUserId == userId).toList();
  }

  Future<void> clearExpiredActions() async {
    _pendingActions.removeWhere((a) => a.status == ActionStatus.expired);
    await _saveActions();
    notifyListeners();
  }

  @override
  void dispose() {
    _actionRequestedController.close();
    _actionApprovedController.close();
    _actionRejectedController.close();
    super.dispose();
  }
}
