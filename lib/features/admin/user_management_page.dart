import 'package:flutter/material.dart';
import '../../locator.dart';
import '../../core/services/hybrid_auth_service.dart';
import '../../core/services/role_management_service.dart' as role_mgmt;
import 'package:intl/intl.dart';
import '../../generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:clean_flutter/core/services/language_service.dart';
import 'pages/manage_roles_page.dart';
import '../../core/services/enhanced_rbac_service.dart';
import '../../features/auth/services/auth_service.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _newUserEmailController = TextEditingController();
  final TextEditingController _newUserPasswordController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'All';
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;
  
  final HybridAuthService _hybridAuthService = locator<HybridAuthService>();
  final role_mgmt.RoleManagementService _roleService = locator<role_mgmt.RoleManagementService>();
  final EnhancedRBACService _rbacService = locator<EnhancedRBACService>();
  final AuthService _authService = locator<AuthService>();
  late TabController _tabController;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkPermissions();
    _loadUsers();
  }
  
  Future<void> _checkPermissions() async {
    final currentUserEmail = _authService.currentUser;
    if (currentUserEmail != null) {
      // Initialize RBAC service for the current user
      await _rbacService.initialize(currentUserEmail);
      
      // Check if user has permission to manage users
      final hasPermission = await _rbacService.hasPermission(
        Permission.manageUsers,
      );
      if (mounted) {
        setState(() {
          _hasPermission = hasPermission;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _newUserEmailController.dispose();
    _newUserPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _hybridAuthService.getAllUsersDetailed();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load users: $e')),
        );
      }
    }
  }

  Future<void> _createUser() async {
    final email = _newUserEmailController.text.trim();
    final password = _newUserPasswordController.text.trim();
    
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _hybridAuthService.register(email, password);
      if (result['success'] == true) {
        _newUserEmailController.clear();
        _newUserPasswordController.clear();
        await _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User $email created successfully')),
          );
        }
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          final error = result['error'] ?? 'Failed to create user';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating user: $e')),
        );
      }
    }
  }

  Future<void> _blockUser(String email) async {
    try {
      await _hybridAuthService.blockUser(email);
      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User $email blocked successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to block user: $e')),
        );
      }
    }
  }

  Future<void> _unblockUser(String email) async {
    try {
      await _hybridAuthService.unblockUser(email);
      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User $email unblocked successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unblock user: $e')),
        );
      }
    }
  }

  Future<void> _resetPassword(String email) async {
    try {
      final newPassword = await _hybridAuthService.resetUserPassword(email);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Password Reset'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New password for $email:'),
                const SizedBox(height: 8),
                SelectableText(
                  newPassword,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Please share this password securely with the user.'),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reset password: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    return _users.where((user) {
      final matchesSearch = _searchQuery.isEmpty ||
          user['email'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _selectedStatus == 'All' ||
          (_selectedStatus == 'Active' && !(user['blocked'] ?? false)) ||
          (_selectedStatus == 'Blocked' && (user['blocked'] ?? false));
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Check permissions and show access denied if user doesn't have permission
    if (!_hasPermission) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('User Management'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 100,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'Access Denied',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'You need the "Manage Users" permission to access this page.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Consumer<LanguageService>(
          builder: (context, languageService, child) {
            final l10n = AppLocalizations.of(context)!;
            return Text(l10n.userManagement);
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Users', icon: Icon(Icons.people)),
            Tab(text: 'Roles', icon: Icon(Icons.admin_panel_settings)),
            Tab(text: 'Activity', icon: Icon(Icons.history)),
            Tab(text: 'Security', icon: Icon(Icons.security)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh Users',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsersTab(),
          _buildRolesTab(),
          _buildActivityTab(),
          _buildSecurityTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateUserDialog,
        tooltip: 'Add User',
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        // Search and Filter Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _selectedStatus,
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All')),
                  DropdownMenuItem(value: 'Active', child: Text('Active')),
                  DropdownMenuItem(value: 'Blocked', child: Text('Blocked')),
                ],
                onChanged: (value) {
                  setState(() => _selectedStatus = value ?? 'All');
                },
              ),
            ],
          ),
        ),
        // Users List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredUsers.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No users found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        return _buildUserCard(user);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final email = user['email'] as String;
    final isBlocked = user['blocked'] as bool? ?? false;
    final createdAt = user['createdAt'] as String?;
    
    // Get user's current role
    final userId = email; // Using email as userId for now
    final roleAssignment = _roleService.roleAssignments.firstWhere(
      (assignment) => assignment.userEmail == email,
      orElse: () => role_mgmt.UserRoleAssignment(
        userId: userId,
        userEmail: email,
        role: role_mgmt.UserRole.user,
        assignedAt: DateTime.now(),
        assignedBy: 'system',
      ),
    );
    
    // Check if this is the admin email
    final isAdminEmail = email.toLowerCase() == 'env.hygiene@gmail.com';
    final displayRole = isAdminEmail ? role_mgmt.UserRole.superAdmin : roleAssignment.role;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isBlocked ? Colors.red : Colors.green,
          child: Icon(
            isBlocked ? Icons.person_off : Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(email),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Status: ${isBlocked ? 'Blocked' : 'Active'}'),
                const SizedBox(width: 16),
                Text(_getRoleName(displayRole),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getRoleColor(displayRole),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            if (createdAt != null)
              Text('Created: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(createdAt))}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Role assignment button
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              color: Theme.of(context).primaryColor,
              tooltip: 'Assign Role',
              onPressed: isAdminEmail 
                ? null // Disable for admin email as it's always super admin
                : () => _showRoleAssignmentDialog(email, displayRole),
            ),
            // Actions menu
            PopupMenuButton<String>(
              onSelected: (action) {
                switch (action) {
                  case 'block':
                    _blockUser(email);
                    break;
                  case 'unblock':
                    _unblockUser(email);
                    break;
                  case 'reset':
                    _resetPassword(email);
                    break;
                }
              },
              itemBuilder: (context) => [
                if (!isBlocked)
                  const PopupMenuItem(
                    value: 'block',
                    child: Row(
                      children: [
                        Icon(Icons.block, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Block User'),
                      ],
                    ),
                  ),
                if (isBlocked)
                  const PopupMenuItem(
                    value: 'unblock',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Unblock User'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'reset',
                  child: Row(
                    children: [
                      Icon(Icons.lock_reset, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Reset Password'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRolesTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Role Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Total Roles: ${_roleService.getAllRoles().length}'),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: _roleService.getAllRoles().map((role) => Chip(
                      label: Text(role.name),
                      backgroundColor: Colors.blue[100],
                    )).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageRolesPage(),
                ),
              );
            },
            icon: const Icon(Icons.settings),
            label: const Text('Manage Roles'),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('User Activity Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Active Sessions: 12'),
                  const Text('Total Activities: 247'),
                  const SizedBox(height: 16),
                  const Text('Recent Activities:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const ListTile(
                    dense: true,
                    leading: Icon(Icons.circle, size: 8, color: Colors.blue),
                    title: Text('User login', style: TextStyle(fontSize: 14)),
                    subtitle: Text('Dec 25, 12:30'),
                  ),
                  const ListTile(
                    dense: true,
                    leading: Icon(Icons.circle, size: 8, color: Colors.green),
                    title: Text('Profile updated', style: TextStyle(fontSize: 14)),
                    subtitle: Text('Dec 25, 11:45'),
                  ),
                  const ListTile(
                    dense: true,
                    leading: Icon(Icons.circle, size: 8, color: Colors.orange),
                    title: Text('Password changed', style: TextStyle(fontSize: 14)),
                    subtitle: Text('Dec 24, 16:20'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/admin/activity'),
            icon: const Icon(Icons.analytics),
            label: const Text('View Full Activity Log'),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Security Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Security Score: 85/100'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: 0.85,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  const SizedBox(height: 16),
                  const Text('Security Settings:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    dense: true,
                    title: const Text('Two-Factor Authentication'),
                    value: true,
                    onChanged: (value) {
                      // Security service integration
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Two-Factor Authentication ${value ? 'enabled' : 'disabled'}')),
                      );
                    },
                  ),
                  SwitchListTile(
                    dense: true,
                    title: const Text('Password Complexity'),
                    value: true,
                    onChanged: (value) {
                      // Security service integration
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Password Complexity ${value ? 'enabled' : 'disabled'}')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/admin/security'),
            icon: const Icon(Icons.security),
            label: const Text('Security Settings'),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(role_mgmt.UserRole role) {
    switch (role) {
      case role_mgmt.UserRole.superAdmin:
        return Colors.red;
      case role_mgmt.UserRole.admin:
        return Colors.orange;
      case role_mgmt.UserRole.moderator:
        return Colors.green;
      case role_mgmt.UserRole.user:
        return Colors.blue;
      case role_mgmt.UserRole.guest:
        return Colors.grey;
    }
  }


  String _getRoleName(role_mgmt.UserRole role) {
    switch (role) {
      case role_mgmt.UserRole.superAdmin:
        return 'Super Admin';
      case role_mgmt.UserRole.admin:
        return 'Admin';
      case role_mgmt.UserRole.moderator:
        return 'Moderator';
      case role_mgmt.UserRole.user:
        return 'User';
      case role_mgmt.UserRole.guest:
        return 'Guest';
    }
  }

  void _showRoleAssignmentDialog(String email, role_mgmt.UserRole currentRole) {
    role_mgmt.UserRole selectedRole = currentRole;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Assign Role'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Assign role to: $email'),
              const SizedBox(height: 16),
              const Text(
                'Select Role:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...role_mgmt.UserRole.values.map((role) => RadioListTile<role_mgmt.UserRole>(
                title: Text(_getRoleName(role)),
                subtitle: Text(_getRoleDescription(role)),
                value: role,
                groupValue: selectedRole,
                onChanged: (value) {
                  setState(() => selectedRole = value!);
                },
                secondary: Icon(
                  _getRoleIcon(role),
                  color: _getRoleColor(role),
                ),
              )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _assignRole(email, selectedRole);
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleDescription(role_mgmt.UserRole role) {
    switch (role) {
      case role_mgmt.UserRole.superAdmin:
        return 'Full system access with all permissions';
      case role_mgmt.UserRole.admin:
        return 'Administrative access with user management';
      case role_mgmt.UserRole.moderator:
        return 'Content moderation and basic management';
      case role_mgmt.UserRole.user:
        return 'Standard user with basic access';
      case role_mgmt.UserRole.guest:
        return 'Limited access for temporary users';
    }
  }

  IconData _getRoleIcon(role_mgmt.UserRole role) {
    switch (role) {
      case role_mgmt.UserRole.superAdmin:
        return Icons.verified_user;
      case role_mgmt.UserRole.admin:
        return Icons.admin_panel_settings;
      case role_mgmt.UserRole.moderator:
        return Icons.supervised_user_circle;
      case role_mgmt.UserRole.user:
        return Icons.person;
      case role_mgmt.UserRole.guest:
        return Icons.person_outline;
    }
  }

  Future<void> _assignRole(String email, role_mgmt.UserRole role) async {
    setState(() => _isLoading = true);
    try {
      final userId = email; // Using email as userId for now
      final success = await _roleService.assignRoleToUser(
        userId,
        email,
        role,
        assignedBy: 'admin',
      );
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Role ${_getRoleName(role)} assigned to $email'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to assign role'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error assigning role: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showCreateUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _newUserEmailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'user@example.com',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newUserPasswordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Enter password',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createUser();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
