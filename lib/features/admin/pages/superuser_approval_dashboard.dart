import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../../core/services/pending_actions_service.dart';
import '../../../core/models/rbac_models.dart';
import 'package:intl/intl.dart';

class SuperuserApprovalDashboard extends StatefulWidget {
  const SuperuserApprovalDashboard({Key? key}) : super(key: key);

  @override
  State<SuperuserApprovalDashboard> createState() => _SuperuserApprovalDashboardState();
}

class _SuperuserApprovalDashboardState extends State<SuperuserApprovalDashboard> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _rejectionReasonController = TextEditingController();
  ActionStatus _filterStatus = ActionStatus.pending;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _filterStatus = ActionStatus.pending;
            break;
          case 1:
            _filterStatus = ActionStatus.approved;
            break;
          case 2:
            _filterStatus = ActionStatus.rejected;
            break;
          case 3:
            _filterStatus = ActionStatus.expired;
            break;
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rejectionReasonController.dispose();
    super.dispose();
  }

  Future<void> _approveAction(BuildContext context, PendingAction action) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final pendingActionsService = Provider.of<PendingActionsService>(context, listen: false);
    final currentUser = authService.currentUser;
    
    if (currentUser == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Approve Action'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Action: ${action.actionType.name}'),
              Text('Target: ${action.targetUserName}'),
              Text('Requested by: ${action.requestedByName}'),
              const SizedBox(height: 8),
              Text('Reason: ${action.reason}'),
              const SizedBox(height: 16),
              const Text(
                'Are you sure you want to approve this action?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (action.actionType == ActionType.deleteUser)
                const Text(
                  'This will permanently delete the user!',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await pendingActionsService.approveAction(
          actionId: action.id,
          approvedBy: currentUser,
          approvedByName: currentUser,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Action approved and executed'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to approve action: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _rejectAction(BuildContext context, PendingAction action) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final pendingActionsService = Provider.of<PendingActionsService>(context, listen: false);
    final currentUser = authService.currentUser;
    
    if (currentUser == null) return;

    _rejectionReasonController.clear();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reject Action'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Action: ${action.actionType.name}'),
              Text('Target: ${action.targetUserName}'),
              Text('Requested by: ${action.requestedByName}'),
              const SizedBox(height: 8),
              Text('Reason: ${action.reason}'),
              const SizedBox(height: 16),
              TextField(
                controller: _rejectionReasonController,
                decoration: const InputDecoration(
                  labelText: 'Rejection reason *',
                  hintText: 'Explain why this request is rejected',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && _rejectionReasonController.text.trim().isNotEmpty) {
      try {
        await pendingActionsService.rejectAction(
          actionId: action.id,
          rejectedBy: currentUser,
          rejectedByName: currentUser,
          rejectionReason: _rejectionReasonController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Action rejected'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reject action: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else if (confirmed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a rejection reason'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Widget _buildActionCard(PendingAction action) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.pending;
    
    switch (action.status) {
      case ActionStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.pending_actions;
        break;
      case ActionStatus.approved:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case ActionStatus.rejected:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case ActionStatus.expired:
        statusColor = Colors.grey;
        statusIcon = Icons.schedule;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    action.actionType.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    action.status.name.toUpperCase(),
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  backgroundColor: statusColor,
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('Target User', action.targetUserName),
            _buildInfoRow('Requested By', '${action.requestedByName} (${action.requestedByRole.displayName})'),
            _buildInfoRow('Requested At', dateFormat.format(action.requestedAt)),
            _buildInfoRow('Reason', action.reason),
            
            if (action.status == ActionStatus.approved) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Approved By', action.approvedByName ?? 'N/A'),
              if (action.approvedAt != null)
                _buildInfoRow('Approved At', dateFormat.format(action.approvedAt!)),
            ],
            
            if (action.status == ActionStatus.rejected) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Rejected By', action.approvedByName ?? 'N/A'),
              if (action.approvedAt != null)
                _buildInfoRow('Rejected At', dateFormat.format(action.approvedAt!)),
              if (action.rejectionReason != null)
                _buildInfoRow('Rejection Reason', action.rejectionReason!),
            ],
            
            if (action.status == ActionStatus.pending) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _rejectAction(context, action),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _approveAction(context, action),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final pendingActionsService = Provider.of<PendingActionsService>(context);
    final currentUser = authService.currentUser;
    
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Approval Dashboard')),
        body: const Center(child: Text('Not authenticated')),
      );
    }
    
    final currentUserRole = authService.getUserRole(currentUser);
    
    // Check if user has permission to approve actions
    if (!currentUserRole.canApprove()) {
      return Scaffold(
        appBar: AppBar(title: const Text('Approval Dashboard')),
        body: const Center(
          child: Text(
            'You do not have permission to approve actions',
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }

    List<PendingAction> filteredActions;
    switch (_filterStatus) {
      case ActionStatus.pending:
        filteredActions = pendingActionsService.pendingActions;
        break;
      case ActionStatus.approved:
        filteredActions = pendingActionsService.approvedActions;
        break;
      case ActionStatus.rejected:
        filteredActions = pendingActionsService.rejectedActions;
        break;
      case ActionStatus.expired:
        filteredActions = pendingActionsService.allActions
            .where((a) => a.status == ActionStatus.expired)
            .toList();
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Superuser Approval Dashboard'),
        backgroundColor: Colors.red.shade700,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Pending',
              icon: Badge(
                label: Text(pendingActionsService.pendingCount.toString()),
                child: const Icon(Icons.pending_actions),
              ),
            ),
            const Tab(text: 'Approved', icon: Icon(Icons.check_circle)),
            const Tab(text: 'Rejected', icon: Icon(Icons.cancel)),
            const Tab(text: 'Expired', icon: Icon(Icons.schedule)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Permission Notice
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.red.shade50,
            child: Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'As a superuser, you can approve or reject sensitive action requests from staff and admin users.',
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
              ],
            ),
          ),
          
          // Action List
          Expanded(
            child: filteredActions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _filterStatus == ActionStatus.pending
                              ? Icons.check_circle_outline
                              : Icons.inbox,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _filterStatus == ActionStatus.pending
                              ? 'No pending actions'
                              : 'No ${_filterStatus.name} actions',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredActions.length,
                    itemBuilder: (context, index) {
                      return _buildActionCard(filteredActions[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _filterStatus == ActionStatus.expired && 
              filteredActions.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () async {
                await pendingActionsService.clearExpiredActions();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Expired actions cleared'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              label: const Text('Clear Expired'),
              icon: const Icon(Icons.clear_all),
              backgroundColor: Colors.orange,
            )
          : null,
    );
  }
}
