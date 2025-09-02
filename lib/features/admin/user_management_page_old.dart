import 'package:flutter/material.dart';
import '../../locator.dart';
import '../auth/services/auth_service.dart';
import '../../core/services/hybrid_auth_service.dart';
import 'services/logging_service.dart';
import 'package:intl/intl.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _newUserEmailController = TextEditingController();
  final TextEditingController _newUserPasswordController = TextEditingController();
  String _selectedFilter = 'All';
  String _searchQuery = '';
  String _selectedStatus = 'All';
  List<String> _selectedUsers = [];
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;
  
  final HybridAuthService _hybridAuthService = locator<HybridAuthService>();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _newUserEmailController.dispose();
    _newUserPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Users', icon: Icon(Icons.people)),
            Tab(text: 'Roles', icon: Icon(Icons.admin_panel_settings)),
            Tab(text: 'Activity', icon: Icon(Icons.timeline)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsersTab(),
          _buildRolesTab(),
          _buildActivityTab(),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    final authService = locator<AuthService>();
    final allUsers = authService.getAllUsers();
    
    final filteredUsers = allUsers.where((user) {
      final matchesSearch = _searchQuery.isEmpty || 
          user.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _selectedStatus == 'All' || 
          (_selectedStatus == 'Active' && !authService.isUserBlocked(user)) ||
          (_selectedStatus == 'Blocked' && authService.isUserBlocked(user));
      return matchesSearch && matchesStatus;
    }).toList();

    return Column(
      children: [
        // Search and Filter Bar
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search users...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: ['All', 'Active', 'Blocked']
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_selectedUsers.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: _showBulkActionsDialog,
                      icon: const Icon(Icons.settings),
                      label: Text('Actions (${_selectedUsers.length})'),
                    ),
                ],
              ),
            ],
          ),
        ),
        // Users List
        Expanded(
          child: ListView.builder(
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              final isBlocked = authService.isUserBlocked(user);
              final isSelected = _selectedUsers.contains(user);
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value!) {
                          _selectedUsers.add(user);
                        } else {
                          _selectedUsers.remove(user);
                        }
                      });
                    },
                  ),
                  title: Text(user),
                  subtitle: Text(isBlocked ? 'Blocked' : 'Active'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          isBlocked ? Icons.lock_open : Icons.lock,
                          color: isBlocked ? Colors.green : Colors.red,
                        ),
                        onPressed: () => _toggleUserStatus(user, isBlocked),
                      ),
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'reset_password',
                            child: Text('Reset Password'),
                          ),
                          const PopupMenuItem(
                            value: 'view_sessions',
                            child: Text('View Sessions'),
                          ),
                          const PopupMenuItem(
                            value: 'security_log',
                            child: Text('Security Log'),
                          ),
                        ],
                        onSelected: (value) => _handleUserAction(user, value),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRolesTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Role Management',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildRoleCard(
                  'Super Admin',
                  'Full system access',
                  Icons.admin_panel_settings,
                  Colors.red,
                  1,
                ),
                _buildRoleCard(
                  'Admin',
                  'Administrative privileges',
                  Icons.security,
                  Colors.orange,
                  3,
                ),
                _buildRoleCard(
                  'Moderator',
                  'Content moderation',
                  Icons.verified_user,
                  Colors.blue,
                  8,
                ),
                _buildRoleCard(
                  'User',
                  'Standard user access',
                  Icons.person,
                  Colors.green,
                  156,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    final loggingService = locator<LoggingService>();
    final recentActivities = [
      ...loggingService.successfulLogins.map((e) => _ActivityItem(
        'Login', e.username, e.timestamp, Icons.login, Colors.green)),
      ...loggingService.failedAttempts.map((e) => _ActivityItem(
        'Failed Login', e.username, e.timestamp, Icons.warning, Colors.red)),
      ...loggingService.signUps.map((e) => _ActivityItem(
        'Sign Up', e.username, e.timestamp, Icons.person_add, Colors.blue)),
    ];
    
    recentActivities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recentActivities.length,
      itemBuilder: (context, index) {
        final activity = recentActivities[index];
        return Card(
          child: ListTile(
            leading: Icon(activity.icon, color: activity.color),
            title: Text('${activity.type}: ${activity.username}'),
            subtitle: Text(DateFormat.yMMMd().add_jm().format(activity.timestamp)),
            trailing: IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showActivityDetails(activity),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleCard(String title, String description, IconData icon, Color color, int count) {
    return Card(
      child: InkWell(
        onTap: () => _showRoleDetails(title),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count users',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleUserStatus(String user, bool isCurrentlyBlocked) async {
    final authService = locator<AuthService>();
    final loggingService = locator<LoggingService>();
    
    if (isCurrentlyBlocked) {
      await authService.unblockUser(user);
      await loggingService.logAdminAction('unblock_user', user);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unblocked $user')),
        );
      }
    } else {
      await authService.blockUser(user);
      await loggingService.logAdminAction('block_user', user);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Blocked $user')),
        );
      }
    }
    setState(() {});
  }

  void _handleUserAction(String user, String action) {
    switch (action) {
      case 'reset_password':
        _resetUserPassword(user);
        break;
      case 'view_sessions':
        _viewUserSessions(user);
        break;
      case 'security_log':
        _viewUserSecurityLog(user);
        break;
    }
  }

  void _resetUserPassword(String user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text('Reset password for $user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final authService = locator<AuthService>();
              final newPassword = await authService.resetUserPassword(user);
              if (mounted) {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Password Reset'),
                    content: Text('New password for $user: $newPassword'),
                    actions: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _viewUserSessions(String user) {
    // Navigate to user sessions page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing sessions for $user')),
    );
  }

  void _viewUserSecurityLog(String user) {
    // Navigate to user security log
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing security log for $user')),
    );
  }

  void _showBulkActionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bulk Actions (${_selectedUsers.length} users)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Block Selected Users'),
              onTap: () => _performBulkAction('block'),
            ),
            ListTile(
              leading: const Icon(Icons.lock_open),
              title: const Text('Unblock Selected Users'),
              onTap: () => _performBulkAction('unblock'),
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Reset Passwords'),
              onTap: () => _performBulkAction('reset_password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _performBulkAction(String action) async {
    Navigator.pop(context);
    final authService = locator<AuthService>();
    final loggingService = locator<LoggingService>();
    
    for (final user in _selectedUsers) {
      switch (action) {
        case 'block':
          await authService.blockUser(user);
          await loggingService.logAdminAction('bulk_block_user', user);
          break;
        case 'unblock':
          await authService.unblockUser(user);
          await loggingService.logAdminAction('bulk_unblock_user', user);
          break;
        case 'reset_password':
          await authService.resetUserPassword(user);
          await loggingService.logAdminAction('bulk_reset_password', user);
          break;
      }
    }
    
    setState(() {
      _selectedUsers.clear();
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bulk action completed for ${_selectedUsers.length} users')),
      );
    }
  }

  void _showRoleDetails(String role) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$role Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Role: $role'),
            const SizedBox(height: 8),
            const Text('Permissions:'),
            const SizedBox(height: 4),
            ...(_getRolePermissions(role).map((permission) => 
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text('• $permission'),
              )
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to role management page
            },
            child: const Text('Manage'),
          ),
        ],
      ),
    );
  }

  List<String> _getRolePermissions(String role) {
    switch (role) {
      case 'Super Admin':
        return ['Full system access', 'User management', 'Security settings', 'System configuration'];
      case 'Admin':
        return ['User management', 'Security monitoring', 'Content moderation'];
      case 'Moderator':
        return ['Content moderation', 'User reports', 'Basic analytics'];
      case 'User':
        return ['Profile management', 'Basic features'];
      default:
        return [];
    }
  }

  void _showActivityDetails(_ActivityItem activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Activity Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${activity.type}'),
            Text('User: ${activity.username}'),
            Text('Time: ${DateFormat.yMMMd().add_jm().format(activity.timestamp)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem {
  final String type;
  final String username;
  final DateTime timestamp;
  final IconData icon;
  final Color color;

  _ActivityItem(this.type, this.username, this.timestamp, this.icon, this.color);
}
