import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../locator.dart';
import '../../../core/services/hybrid_auth_service.dart';
import '../../../core/services/role_management_service.dart';
import 'package:provider/provider.dart';
import '../../../core/services/language_service.dart';

class ManageRolesPage extends StatefulWidget {
  const ManageRolesPage({super.key});

  @override
  State<ManageRolesPage> createState() => _ManageRolesPageState();
}

class _ManageRolesPageState extends State<ManageRolesPage> {
  final HybridAuthService _hybridAuthService = locator<HybridAuthService>();
  final RoleManagementService _roleService = locator<RoleManagementService>();
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = false;
  String _searchQuery = '';
  UserRole? _filterRole;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _hybridAuthService.getAllUsersDetailed();
      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
      _filterUsers();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load users: $e')),
        );
      }
    }
  }

  void _filterUsers() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filteredUsers = _users.where((user) {
        final email = user['email'].toString().toLowerCase();
        final matchesSearch = _searchQuery.isEmpty || email.contains(_searchQuery);
        
        if (!matchesSearch) return false;
        
        if (_filterRole != null) {
          final userId = user['email'] as String;
          final userRole = _getUserRole(userId);
          return userRole == _filterRole;
        }
        
        return true;
      }).toList();
    });
  }

  UserRole _getUserRole(String email) {
    // Check if this is the admin email
    if (email.toLowerCase() == 'env.hygiene@gmail.com') {
      return UserRole.superAdmin;
    }
    
    final roleAssignment = _roleService.roleAssignments.firstWhere(
      (assignment) => assignment.userEmail == email,
      orElse: () => UserRoleAssignment(
        userId: email,
        userEmail: email,
        role: UserRole.user,
        assignedAt: DateTime.now(),
        assignedBy: 'system',
      ),
    );
    
    return roleAssignment.role;
  }

  Future<void> _assignRole(String email, UserRole role) async {
    setState(() => _isLoading = true);
    try {
      final userId = email;
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
        // Refresh the UI
        setState(() {});
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

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return Colors.red;
      case UserRole.admin:
        return Colors.orange;
      case UserRole.moderator:
        return Colors.green;
      case UserRole.user:
        return Colors.blue;
      case UserRole.guest:
        return Colors.grey;
    }
  }

  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.admin:
        return 'Admin';
      case UserRole.moderator:
        return 'Moderator';
      case UserRole.user:
        return 'User';
      case UserRole.guest:
        return 'Guest';
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return Icons.verified_user;
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.moderator:
        return Icons.shield;
      case UserRole.user:
        return Icons.person;
      case UserRole.guest:
        return Icons.person_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<LanguageService>(
          builder: (context, languageService, child) {
            return const Text('Manage User Roles');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by email...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                  ),
                ),
                const SizedBox(height: 12),
                // Role Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Filter by role: '),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('All'),
                        selected: _filterRole == null,
                        onSelected: (selected) {
                          setState(() {
                            _filterRole = null;
                            _filterUsers();
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ...UserRole.values.map((role) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(_getRoleName(role)),
                          selected: _filterRole == role,
                          backgroundColor: _getRoleColor(role).withOpacity(0.1),
                          selectedColor: _getRoleColor(role).withOpacity(0.3),
                          onSelected: (selected) {
                            setState(() {
                              _filterRole = selected ? role : null;
                              _filterUsers();
                            });
                          },
                        ),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Statistics Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Users: ${_filteredUsers.length}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (_filterRole != null)
                  Chip(
                    label: Text('Showing ${_getRoleName(_filterRole!)} users'),
                    onDeleted: () {
                      setState(() {
                        _filterRole = null;
                        _filterUsers();
                      });
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
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No users found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (_searchQuery.isNotEmpty || _filterRole != null)
                              TextButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _filterRole = null;
                                    _filterUsers();
                                  });
                                },
                                child: const Text('Clear filters'),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return _buildUserRoleCard(user);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRoleCard(Map<String, dynamic> user) {
    final email = user['email'] as String;
    final isBlocked = user['blocked'] as bool? ?? false;
    final createdAt = user['createdAt'] as String?;
    final currentRole = _getUserRole(email);
    final isAdminEmail = email.toLowerCase() == 'env.hygiene@gmail.com';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Row
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isBlocked 
                      ? Colors.red.withOpacity(0.2)
                      : _getRoleColor(currentRole).withOpacity(0.2),
                  child: Icon(
                    _getRoleIcon(currentRole),
                    color: isBlocked ? Colors.red : _getRoleColor(currentRole),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        email,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (isBlocked)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red),
                              ),
                              child: const Text(
                                'BLOCKED',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (isBlocked) const SizedBox(width: 8),
                          Text(
                            createdAt != null
                                ? 'Joined ${DateFormat('MMM dd, yyyy').format(DateTime.parse(createdAt))}'
                                : 'No join date',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            // Current Role Display
            Row(
              children: [
                const Text(
                  'Current Role: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRoleColor(currentRole).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getRoleColor(currentRole),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getRoleIcon(currentRole),
                        size: 16,
                        color: _getRoleColor(currentRole),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getRoleName(currentRole),
                        style: TextStyle(
                          color: _getRoleColor(currentRole),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAdminEmail) ...[
                  const SizedBox(width: 8),
                  const Chip(
                    label: Text(
                      'PROTECTED',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Colors.amber,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            // Role Selection
            if (!isAdminEmail) ...[
              const Text(
                'Assign New Role:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: UserRole.values.map((role) {
                  final isSelected = role == currentRole;
                  return ChoiceChip(
                    label: Text(_getRoleName(role)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected && role != currentRole) {
                        _showConfirmationDialog(email, currentRole, role);
                      }
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: _getRoleColor(role).withOpacity(0.3),
                    labelStyle: TextStyle(
                      color: isSelected ? _getRoleColor(role) : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    avatar: Icon(
                      _getRoleIcon(role),
                      size: 18,
                      color: isSelected ? _getRoleColor(role) : Colors.grey[600],
                    ),
                  );
                }).toList(),
              ),
            ] else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.lock, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This is the primary admin account and cannot be modified',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialog(String email, UserRole currentRole, UserRole newRole) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Role Change'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Change role for $email?'),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRoleColor(currentRole).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getRoleName(currentRole),
                    style: TextStyle(
                      color: _getRoleColor(currentRole),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRoleColor(newRole).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getRoleName(newRole),
                    style: TextStyle(
                      color: _getRoleColor(newRole),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
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
              _assignRole(email, newRole);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getRoleColor(newRole),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
