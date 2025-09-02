import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../../core/services/pending_actions_service.dart';
import '../../../core/models/rbac_models.dart';
import '../../../l10n/app_localizations.dart';

class StaffUserManagementPage extends StatefulWidget {
  const StaffUserManagementPage({Key? key}) : super(key: key);

  @override
  State<StaffUserManagementPage> createState() => _StaffUserManagementPageState();
}

class _StaffUserManagementPageState extends State<StaffUserManagementPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _requestUserDeletion(
    BuildContext context,
    String targetEmail,
    String targetName,
  ) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final pendingActionsService = Provider.of<PendingActionsService>(context, listen: false);
    final currentUser = authService.currentUser;
    
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not authenticated')),
      );
      return;
    }

    _reasonController.clear();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Request User Deletion'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You are requesting to delete user: $targetName ($targetEmail)'),
              const SizedBox(height: 16),
              const Text(
                'This action requires superuser approval.',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for deletion *',
                  hintText: 'Please provide a detailed reason',
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
                backgroundColor: Colors.orange,
              ),
              child: const Text('Submit Request'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && _reasonController.text.trim().isNotEmpty) {
      try {
        final currentUserRole = authService.getUserRole(currentUser);
        
        await pendingActionsService.requestAction(
          actionType: ActionType.deleteUser,
          requestedBy: currentUser,
          requestedByName: currentUser,
          requestedByRole: currentUserRole,
          targetUserId: targetEmail,
          targetUserName: targetName,
          reason: _reasonController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deletion request for $targetName submitted for approval'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to submit request: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else if (confirmed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a reason for the deletion request'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final pendingActionsService = Provider.of<PendingActionsService>(context);
    final currentUser = authService.currentUser;
    
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('User Management')),
        body: const Center(child: Text('Not authenticated')),
      );
    }
    
    final currentUserRole = authService.getUserRole(currentUser);
    
    // Check if user has permission to view this page
    if (!currentUserRole.canViewUsers()) {
      return Scaffold(
        appBar: AppBar(title: const Text('User Management')),
        body: const Center(
          child: Text(
            'You do not have permission to view this page',
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }

    final allUsers = authService.getAllUsersWithRoles();
    final filteredUsers = allUsers.where((user) {
      final email = user['email'] as String;
      return email.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management (Staff)'),
        backgroundColor: Colors.orange.shade700,
      ),
      body: Column(
        children: [
          // Permission Notice
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange.shade50,
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'As a staff member, you can request user deletions. All requests require superuser approval.',
                    style: TextStyle(color: Colors.orange.shade900),
                  ),
                ),
              ],
            ),
          ),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search users',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Pending Actions Summary
          Consumer<PendingActionsService>(
            builder: (context, service, _) {
              final myPendingRequests = service.getActionsForUser(currentUser)
                  .where((a) => a.status == ActionStatus.pending)
                  .toList();
              
              if (myPendingRequests.isNotEmpty) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.pending_actions, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'You have ${myPendingRequests.length} pending request(s) awaiting approval',
                        style: TextStyle(color: Colors.blue.shade900),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          
          const SizedBox(height: 8),
          
          // User List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                final email = user['email'] as String;
                final role = user['role'] as UserRole;
                final mfaEnabled = user['mfaEnabled'] as bool;
                final totpEnabled = user['totpEnabled'] as bool;
                final isBlocked = user['isBlocked'] as bool;
                
                // Check if there's a pending action for this user
                final pendingAction = pendingActionsService.getActionsTargetingUser(email)
                    .where((a) => a.status == ActionStatus.pending)
                    .firstOrNull;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: role == UserRole.superuser
                          ? Colors.red
                          : role == UserRole.admin
                              ? Colors.purple
                              : role == UserRole.staff
                                  ? Colors.orange
                                  : Colors.blue,
                      child: Text(
                        email.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(email),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Role: ${role.displayName}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: role == UserRole.superuser
                                ? Colors.red
                                : role == UserRole.admin
                                    ? Colors.purple
                                    : role == UserRole.staff
                                        ? Colors.orange
                                        : Colors.blue,
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (mfaEnabled)
                              const Chip(
                                label: Text('MFA', style: TextStyle(fontSize: 10)),
                                backgroundColor: Colors.green,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            if (totpEnabled)
                              const Chip(
                                label: Text('TOTP', style: TextStyle(fontSize: 10)),
                                backgroundColor: Colors.blue,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            if (isBlocked)
                              const Chip(
                                label: Text('BLOCKED', style: TextStyle(fontSize: 10)),
                                backgroundColor: Colors.red,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            if (pendingAction != null)
                              Chip(
                                label: Text(
                                  'PENDING ${pendingAction.actionType.name.toUpperCase()}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                                backgroundColor: Colors.orange,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Only show delete request button for non-superuser accounts
                        // and if there's no pending deletion request
                        if (role != UserRole.superuser && 
                            pendingAction?.actionType != ActionType.deleteUser)
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.orange,
                            tooltip: 'Request Deletion',
                            onPressed: () => _requestUserDeletion(
                              context,
                              email,
                              email,
                            ),
                          ),
                        if (pendingAction?.actionType == ActionType.deleteUser)
                          const Tooltip(
                            message: 'Deletion request pending',
                            child: Icon(
                              Icons.hourglass_empty,
                              color: Colors.orange,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
