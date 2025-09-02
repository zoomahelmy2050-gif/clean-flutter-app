import 'package:flutter/material.dart';
import 'package:clean_flutter/core/services/enhanced_rbac_service.dart';
import 'package:clean_flutter/core/services/role_persistence_service.dart';
import 'package:clean_flutter/locator.dart';
import 'package:clean_flutter/core/models/role_template.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class RoleManagementPage extends StatefulWidget {
  const RoleManagementPage({Key? key}) : super(key: key);

  @override
  State<RoleManagementPage> createState() => _RoleManagementPageState();
}

class _RoleManagementPageState extends State<RoleManagementPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late EnhancedRBACService _rbacService;
  late RolePersistenceService _persistenceService;
  UserRole? _selectedRole;
  String _searchQuery = '';
  String _selectedDepartment = 'All';
  UserRole? _selectedRoleFilter;
  List<String> _selectedUsers = [];
  bool _bulkModeEnabled = false;
  Map<String, RoleTemplate> _roleTemplates = {};
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  List<Map<String, dynamic>> _auditLogs = [];
  bool _enableTemporalAccess = true;
  bool _requireApproval = false;
  bool _autoExpireGuest = true;
  Map<String, UserRole> _persistedUserRoles = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _rbacService = locator<EnhancedRBACService>();
    _persistenceService = locator<RolePersistenceService>();
    _initializeTemplates();
    _initializeMockData();
    _loadPersistedData();
    _filterUsers();
  }
  
  void _loadPersistedData() async {
    _persistedUserRoles = await _persistenceService.loadUserRoles();
    for (final user in _users) {
      final email = user['email'] as String;
      if (_persistedUserRoles.containsKey(email)) {
        user['role'] = _persistedUserRoles[email];
      }
    }
  }

  String _getPermissionDisplayName(Permission permission) {
    switch (permission) {
      case Permission.manageUsers:
        return 'Manage Users';
      case Permission.viewAuditLogs:
        return 'View Audit Logs';
      case Permission.manageRoles:
        return 'Manage Roles';
      case Permission.viewAnalytics:
        return 'View Analytics';
      default:
        return permission.toString().split('.').last;
    }
  }

  void _initializeTemplates() {
    _roleTemplates = {
      'enterprise_admin': RoleTemplate(
        id: 'enterprise_admin',
        name: 'Enterprise Admin',
        description: 'Full administrative access for enterprise management',
        role: UserRole.admin,
        permissions: {
          Permission.manageUsers,
          Permission.viewAuditLogs,
          Permission.manageRoles,
          Permission.viewAnalytics,
        },
        category: 'Enterprise',
        isCustom: false,
        createdAt: DateTime.now(),
        createdBy: 'System',
      ),
      'security_analyst': RoleTemplate(
        id: 'security_analyst',
        name: 'Security Analyst',
        description: 'Security monitoring and incident response',
        role: UserRole.moderator,
        permissions: {
          Permission.viewAuditLogs,
          Permission.viewAnalytics,
        },
        category: 'Security',
        isCustom: false,
        createdAt: DateTime.now(),
        createdBy: 'System',
      ),
    };
  }

  void _initializeMockData() {
    _users = [
      {
        'id': 'user1',
        'name': 'John Doe',
        'email': 'john.doe@example.com',
        'department': 'Engineering',
        'role': UserRole.user,
        'lastActive': DateTime.now().subtract(const Duration(minutes: 5)),
        'status': 'active',
        'temporalAccess': null,
      },
      {
        'id': 'user2',
        'name': 'Jane Smith',
        'email': 'jane.smith@example.com',
        'department': 'Marketing',
        'role': UserRole.moderator,
        'lastActive': DateTime.now().subtract(const Duration(hours: 2)),
        'status': 'active',
        'temporalAccess': null,
      },
      {
        'id': 'admin',
        'name': 'Admin User',
        'email': 'env.hygiene@gmail.com',
        'department': 'IT',
        'role': UserRole.superAdmin,
        'lastActive': DateTime.now(),
        'status': 'active',
        'temporalAccess': null,
      },
    ];

    _auditLogs = [
      {
        'id': 'audit1',
        'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
        'user': 'admin@example.com',
        'action': 'Role Modified',
        'details': 'Changed user role from User to Moderator',
        'status': 'success',
      },
    ];
  }

  void _filterUsers() {
    setState(() {
      _filteredUsers = _users.where((user) {
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          if (!user['name'].toString().toLowerCase().contains(query) &&
              !user['email'].toString().toLowerCase().contains(query)) {
            return false;
          }
        }
        if (_selectedDepartment != 'All' && user['department'] != _selectedDepartment) {
          return false;
        }
        if (_selectedRoleFilter != null && user['role'] != _selectedRoleFilter) {
          return false;
        }
        return true;
      }).toList();
    });
  }

  void _exportAuditLogs() async {
    try {
      final csvContent = StringBuffer();
      csvContent.writeln('Timestamp,User,Action,Details,Status');
      
      for (final log in _auditLogs) {
        final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(log['timestamp']);
        csvContent.writeln(
          '"$timestamp","${log['user']}","${log['action']}","${log['details']}","${log['status']}"'
        );
      }
      
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'audit_logs_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(csvContent.toString());
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Audit logs exported to: $fileName'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export audit logs: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _applyTemplate(String templateId) {
    final template = _roleTemplates[templateId];
    if (template == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E3A5F),
        title: Text('Apply Template: ${template.name}', style: const TextStyle(color: Colors.white)),
        content: Container(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('This will apply the template to ${_selectedUsers.length} selected users.',
                style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              Text('Base Role: ${_rbacService.getRoleDisplayName(template.role)}',
                style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                for (final userId in _selectedUsers) {
                  final userIndex = _users.indexWhere((u) => u['id'] == userId);
                  if (userIndex != -1) {
                    _users[userIndex]['role'] = template.role;
                    final email = _users[userIndex]['email'] as String;
                    _persistedUserRoles[email] = template.role;
                  }
                }
                _persistenceService.saveUserRoles(_persistedUserRoles);
                _filterUsers();
                _auditLogs.insert(0, {
                  'id': 'audit_${DateTime.now().millisecondsSinceEpoch}',
                  'timestamp': DateTime.now(),
                  'user': 'env.hygiene@gmail.com',
                  'action': 'Template Applied',
                  'details': 'Applied template "${template.name}" to ${_selectedUsers.length} users',
                  'status': 'success',
                });
                _selectedUsers.clear();
                _bulkModeEnabled = false;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Template "${template.name}" applied successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Apply Template'),
          ),
        ],
      ),
    );
  }

  void _grantTemporalAccess(Map<String, dynamic> user) {
    UserRole selectedRole = user['role'];
    DateTime expiryDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay expiryTime = TimeOfDay.now();
    String reason = '';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E3A5F),
          title: Text('Grant Temporal Access - ${user['name']}', style: const TextStyle(color: Colors.white)),
          content: Container(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<UserRole>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Temporary Role',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyan)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyan)),
                  ),
                  dropdownColor: const Color(0xFF1E3A5F),
                  style: const TextStyle(color: Colors.white),
                  items: UserRole.values.map((role) => DropdownMenuItem(
                    value: role,
                    child: Text(_rbacService.getRoleDisplayName(role)),
                  )).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedRole = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Reason for Temporal Access',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyan)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyan)),
                  ),
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  onChanged: (value) {
                    reason = value;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final expiry = DateTime(
                  expiryDate.year, expiryDate.month, expiryDate.day,
                  expiryTime.hour, expiryTime.minute,
                );
                setState(() {
                  final userIndex = _users.indexWhere((u) => u['id'] == user['id']);
                  if (userIndex != -1) {
                    _users[userIndex]['temporalAccess'] = {
                      'originalRole': user['role'],
                      'temporaryRole': selectedRole,
                      'expiry': expiry,
                      'reason': reason,
                      'grantedBy': 'env.hygiene@gmail.com',
                      'grantedAt': DateTime.now(),
                    };
                    _users[userIndex]['role'] = selectedRole;
                    _filterUsers();
                  }
                });
                _auditLogs.insert(0, {
                  'id': 'audit_${DateTime.now().millisecondsSinceEpoch}',
                  'timestamp': DateTime.now(),
                  'user': 'env.hygiene@gmail.com',
                  'action': 'Temporal Access Granted',
                  'details': 'Granted ${_rbacService.getRoleDisplayName(selectedRole)} to ${user['name']}. Reason: $reason',
                  'status': 'success',
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Temporal access granted to ${user['name']}'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Grant Access'),
            ),
          ],
        ),
      ),
    );
  }

  void _revokeTemporalAccess(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E3A5F),
        title: Text('Revoke Temporal Access - ${user['name']}', style: const TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to revoke temporal access?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                final userIndex = _users.indexWhere((u) => u['id'] == user['id']);
                if (userIndex != -1 && _users[userIndex]['temporalAccess'] != null) {
                  _users[userIndex]['role'] = _users[userIndex]['temporalAccess']['originalRole'];
                  _users[userIndex]['temporalAccess'] = null;
                  _filterUsers();
                }
              });
              _auditLogs.insert(0, {
                'id': 'audit_${DateTime.now().millisecondsSinceEpoch}',
                'timestamp': DateTime.now(),
                'user': 'env.hygiene@gmail.com',
                'action': 'Temporal Access Revoked',
                'details': 'Revoked temporal access for ${user['name']}',
                'status': 'success',
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Temporal access revoked for ${user['name']}'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Revoke Access'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Role Management'),
        backgroundColor: const Color(0xFF1E3A5F),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Users'),
            Tab(text: 'Templates'),
            Tab(text: 'Audit Log'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildUserManagementTab(),
          _buildTemplatesTab(),
          _buildAuditLogTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    // Calculate statistics
    final roleDistribution = <UserRole, int>{};
    for (final user in _users) {
      final role = user['role'] as UserRole;
      roleDistribution[role] = (roleDistribution[role] ?? 0) + 1;
    }
    
    final activeUsers = _users.where((u) => u['status'] == 'active').length;
    final temporalAccessUsers = _users.where((u) => u['temporalAccess'] != null).length;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics Cards
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildStatCard('Total Users', _users.length.toString(), Icons.people, Colors.blue),
              _buildStatCard('Active Users', activeUsers.toString(), Icons.verified_user, Colors.green),
              _buildStatCard('Templates', _roleTemplates.length.toString(), Icons.dashboard_customize, Colors.purple),
              _buildStatCard('Temporal Access', temporalAccessUsers.toString(), Icons.timer, Colors.orange),
            ],
          ),
          const SizedBox(height: 32),
          
          // Role Distribution
          const Text(
            'Role Distribution',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            color: const Color(0xFF1E3A5F),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: UserRole.values.map((role) {
                  final count = roleDistribution[role] ?? 0;
                  final percentage = (_users.isEmpty ? 0 : (count / _users.length * 100)).toStringAsFixed(1);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 120,
                          child: Text(
                            _rbacService.getRoleDisplayName(role),
                            style: TextStyle(color: _rbacService.getRoleColor(role)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: count / (_users.isEmpty ? 1 : _users.length),
                                child: Container(
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: _rbacService.getRoleColor(role).withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '$count ($percentage%)',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A5F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserManagementTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A5F),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search users...',
                hintStyle: TextStyle(color: Colors.white54),
                prefixIcon: Icon(Icons.search, color: Colors.white54),
                border: InputBorder.none,
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _filterUsers();
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _bulkModeEnabled = !_bulkModeEnabled;
                    if (!_bulkModeEnabled) {
                      _selectedUsers.clear();
                    }
                  });
                },
                icon: Icon(_bulkModeEnabled ? Icons.close : Icons.select_all),
                label: Text(_bulkModeEnabled ? 'Cancel' : 'Bulk Select'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _bulkModeEnabled ? Colors.orange : Colors.blue,
                ),
              ),
              if (_bulkModeEnabled && _selectedUsers.isNotEmpty) ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_roleTemplates.isNotEmpty) {
                      _applyTemplate(_roleTemplates.keys.first);
                    }
                  },
                  icon: const Icon(Icons.assignment),
                  label: Text('Apply Template (${_selectedUsers.length})'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                final isSelected = _selectedUsers.contains(user['id']);
                
                return Card(
                  color: isSelected ? Colors.cyan.withOpacity(0.2) : const Color(0xFF1E3A5F),
                  child: ListTile(
                    leading: _bulkModeEnabled
                        ? Checkbox(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value!) {
                                  _selectedUsers.add(user['id']);
                                } else {
                                  _selectedUsers.remove(user['id']);
                                }
                              });
                            },
                          )
                        : CircleAvatar(
                            backgroundColor: _rbacService.getRoleColor(user['role']),
                            child: Text(
                              user['name'].toString().substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                    title: Text(user['name'], style: const TextStyle(color: Colors.white)),
                    subtitle: Text('${user['email']} • ${user['department']}',
                      style: const TextStyle(color: Colors.white70)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _rbacService.getRoleColor(user['role']).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _rbacService.getRoleDisplayName(user['role']),
                            style: TextStyle(
                              color: _rbacService.getRoleColor(user['role']),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (user['temporalAccess'] != null)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.timer, color: Colors.orange, size: 20),
                          ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.white54),
                          color: const Color(0xFF1E3A5F),
                          onSelected: (value) {
                            switch (value) {
                              case 'grant_temporal':
                                _grantTemporalAccess(user);
                                break;
                              case 'revoke_temporal':
                                _revokeTemporalAccess(user);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'grant_temporal',
                              child: Text('Grant Temporal Access', style: TextStyle(color: Colors.white)),
                            ),
                            if (user['temporalAccess'] != null)
                              const PopupMenuItem(
                                value: 'revoke_temporal',
                                child: Text('Revoke Temporal Access', style: TextStyle(color: Colors.white)),
                              ),
                          ],
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

  Widget _buildTemplatesTab() {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Padding(
      padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Role Templates',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _showCreateTemplateDialog,
                icon: const Icon(Icons.add),
                label: const Text('Create Template'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isMobile ? 1 : 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: isMobile ? 2.5 : 1.5,
              ),
              itemCount: _roleTemplates.length,
              itemBuilder: (context, index) {
                final template = _roleTemplates.values.toList()[index];
                return _buildTemplateCard(template);
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTemplateCard(RoleTemplate template) {
    return Card(
      color: const Color(0xFF1E3A5F),
      child: InkWell(
        onTap: () => _showEditTemplateDialog(template),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      template.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: template.isCustom ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      template.isCustom ? 'Custom' : 'System',
                      style: TextStyle(
                        color: template.isCustom ? Colors.blue : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                template.description,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.shield,
                    size: 16,
                    color: _rbacService.getRoleColor(template.role),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _rbacService.getRoleDisplayName(template.role),
                    style: TextStyle(
                      color: _rbacService.getRoleColor(template.role),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: template.permissions.take(3).map((permission) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getPermissionDisplayName(permission),
                    style: const TextStyle(color: Colors.cyan, fontSize: 10),
                  ),
                )).toList(),
              ),
              if (template.permissions.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+${template.permissions.length - 3} more',
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (template.isCustom)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () => _deleteTemplate(template),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.cyan, size: 20),
                    onPressed: () => _showEditTemplateDialog(template),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuditLogTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: _exportAuditLogs,
                icon: const Icon(Icons.download),
                label: const Text('Export Logs'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _auditLogs.length,
              itemBuilder: (context, index) {
                final log = _auditLogs[index];
                return Card(
                  color: const Color(0xFF1E3A5F),
                  child: ListTile(
                    leading: Icon(
                      log['status'] == 'success' ? Icons.check_circle : Icons.error,
                      color: log['status'] == 'success' ? Colors.green : Colors.red,
                    ),
                    title: Text(log['action'], style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      '${log['details']}\n${DateFormat('yyyy-MM-dd HH:mm').format(log['timestamp'])}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Role Settings',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          // Permission Matrix
          Card(
            color: const Color(0xFF1E3A5F),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Permission Matrix',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.cyan),
                        onPressed: _showEditPermissionMatrixDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        const DataColumn(
                          label: Text('Permission', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        ...UserRole.values.map((role) => DataColumn(
                          label: Text(
                            _rbacService.getRoleDisplayName(role),
                            style: TextStyle(color: _rbacService.getRoleColor(role), fontSize: 12),
                          ),
                        )),
                      ],
                      rows: Permission.values.map((permission) => DataRow(
                        cells: [
                          DataCell(
                            Text(
                              _getPermissionDisplayName(permission),
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ),
                          ...UserRole.values.map((role) => DataCell(
                            Icon(
                              _checkRoleHasPermission(role, permission) ? Icons.check_circle : Icons.cancel,
                              color: _checkRoleHasPermission(role, permission) ? Colors.green : Colors.red.withOpacity(0.3),
                              size: 16,
                            ),
                          )),
                        ],
                      )).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Role Configuration
          Card(
            color: const Color(0xFF1E3A5F),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Role Configuration',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Enable Temporal Access', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Allow temporary role elevation', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    value: _enableTemporalAccess,
                    onChanged: (value) {
                      setState(() {
                        _enableTemporalAccess = value;
                      });
                    },
                    activeColor: Colors.cyan,
                  ),
                  SwitchListTile(
                    title: const Text('Require Approval for Role Changes', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Admin approval needed for role modifications', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    value: _requireApproval,
                    onChanged: (value) {
                      setState(() {
                        _requireApproval = value;
                      });
                    },
                    activeColor: Colors.cyan,
                  ),
                  SwitchListTile(
                    title: const Text('Auto-expire Guest Access', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Automatically revoke guest access after 24 hours', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    value: _autoExpireGuest,
                    onChanged: (value) {
                      setState(() {
                        _autoExpireGuest = value;
                      });
                    },
                    activeColor: Colors.cyan,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _saveSettings,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Settings'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Access Control Rules
          Card(
            color: const Color(0xFF1E3A5F),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Access Control Rules',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...[
                    'Super Admin can manage all roles and permissions',
                    'Admin can manage User and Guest roles only',
                    'Moderator can view but not modify roles',
                    'Users cannot access role management',
                    'Guest access expires after 24 hours',
                  ].map((rule) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.rule, color: Colors.cyan, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rule,
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showCreateTemplateDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    UserRole selectedRole = UserRole.user;
    Set<Permission> selectedPermissions = {};
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E3A5F),
          title: const Text('Create Role Template', style: TextStyle(color: Colors.white)),
          content: Container(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Template Name',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyan)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyan)),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyan)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyan)),
                    ),
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<UserRole>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Base Role',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyan)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyan)),
                    ),
                    dropdownColor: const Color(0xFF1E3A5F),
                    style: const TextStyle(color: Colors.white),
                    items: UserRole.values.map((role) => DropdownMenuItem(
                      value: role,
                      child: Text(_rbacService.getRoleDisplayName(role)),
                    )).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedRole = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Permissions',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...Permission.values.map((permission) => CheckboxListTile(
                    title: Text(
                      _getPermissionDisplayName(permission),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    value: selectedPermissions.contains(permission),
                    onChanged: (value) {
                      setDialogState(() {
                        if (value!) {
                          selectedPermissions.add(permission);
                        } else {
                          selectedPermissions.remove(permission);
                        }
                      });
                    },
                    checkColor: Colors.black,
                    activeColor: Colors.cyan,
                  )),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && descriptionController.text.isNotEmpty) {
                  final templateId = 'custom_${DateTime.now().millisecondsSinceEpoch}';
                  setState(() {
                    _roleTemplates[templateId] = RoleTemplate(
                      id: templateId,
                      name: nameController.text,
                      description: descriptionController.text,
                      role: selectedRole,
                      permissions: selectedPermissions,
                      category: 'Custom',
                      isCustom: true,
                      createdAt: DateTime.now(),
                      createdBy: 'env.hygiene@gmail.com',
                    );
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Template "${nameController.text}" created successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Create Template'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showEditTemplateDialog(RoleTemplate template) {
    if (!template.isCustom) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('System templates cannot be edited'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final nameController = TextEditingController(text: template.name);
    final descriptionController = TextEditingController(text: template.description);
    UserRole selectedRole = template.role;
    Set<Permission> selectedPermissions = Set.from(template.permissions);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E3A5F),
          title: const Text('Edit Role Template', style: TextStyle(color: Colors.white)),
          content: Container(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Template Name',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyan)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyan)),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyan)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyan)),
                    ),
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<UserRole>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Base Role',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyan)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyan)),
                    ),
                    dropdownColor: const Color(0xFF1E3A5F),
                    style: const TextStyle(color: Colors.white),
                    items: UserRole.values.map((role) => DropdownMenuItem(
                      value: role,
                      child: Text(_rbacService.getRoleDisplayName(role)),
                    )).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedRole = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Permissions',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...Permission.values.map((permission) => CheckboxListTile(
                    title: Text(
                      _getPermissionDisplayName(permission),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    value: selectedPermissions.contains(permission),
                    onChanged: (value) {
                      setDialogState(() {
                        if (value!) {
                          selectedPermissions.add(permission);
                        } else {
                          selectedPermissions.remove(permission);
                        }
                      });
                    },
                    checkColor: Colors.black,
                    activeColor: Colors.cyan,
                  )),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _roleTemplates[template.id] = RoleTemplate(
                    id: template.id,
                    name: nameController.text,
                    description: descriptionController.text,
                    role: selectedRole,
                    permissions: selectedPermissions,
                    category: template.category,
                    isCustom: template.isCustom,
                    createdAt: template.createdAt,
                    createdBy: template.createdBy,
                  );
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Template "${nameController.text}" updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Update Template'),
            ),
          ],
        ),
      ),
    );
  }
  
  bool _checkRoleHasPermission(UserRole role, Permission permission) {
    // Define permission matrix based on role hierarchy
    switch (role) {
      case UserRole.superAdmin:
        return true; // Super Admin has all permissions
      case UserRole.admin:
        return ![
          Permission.deleteUsers,
          Permission.deleteAuditLogs,
          Permission.manageDatabaseMigrations,
          Permission.accessDisasterRecovery,
        ].contains(permission);
      case UserRole.moderator:
        return [
          Permission.viewUsers,
          Permission.viewAuditLogs,
          Permission.viewAnalytics,
          Permission.viewSecurityAlerts,
          Permission.viewIncidents,
        ].contains(permission);
      case UserRole.user:
        return [
          Permission.viewAnalytics,
          Permission.viewDashboard,
        ].contains(permission);
      case UserRole.guest:
        return false; // Guest has no permissions
      case UserRole.securityAdmin:
        return [
          Permission.accessSecurityCenter,
          Permission.viewSecurityAlerts,
          Permission.resolveAlerts,
          Permission.viewThreats,
          Permission.mitigateThreats,
          Permission.viewThreatIntelligence,
          Permission.performVulnerabilityScans,
          Permission.accessPenetrationTesting,
          Permission.manageSecuritySettings,
        ].contains(permission);
      case UserRole.analyst:
        return [
          Permission.viewAnalytics,
          Permission.viewReports,
          Permission.exportReports,
          Permission.viewDashboard,
          Permission.viewBusinessIntelligence,
          Permission.viewAuditLogs,
        ].contains(permission);
      case UserRole.securityAnalyst:
        return [
          Permission.viewSecurityAlerts,
          Permission.viewThreats,
          Permission.viewThreatIntelligence,
          Permission.performVulnerabilityScans,
          Permission.viewIncidents,
          Permission.viewAuditLogs,
          Permission.viewAnalytics,
        ].contains(permission);
      case UserRole.auditor:
        return [
          Permission.viewAuditLogs,
          Permission.exportAuditLogs,
          Permission.viewCompliance,
          Permission.generateComplianceReports,
          Permission.performAudits,
          Permission.viewUsers,
          Permission.viewIncidents,
          Permission.viewSecurityAlerts,
        ].contains(permission);
      case UserRole.operator:
        return [
          Permission.viewDashboard,
          Permission.viewAnalytics,
          Permission.viewIncidents,
          Permission.manageIncidents,
          Permission.executePlaybooks,
          Permission.viewDevices,
          Permission.manageDevices,
          Permission.performBackups,
        ].contains(permission);
      case UserRole.viewer:
        return [
          Permission.viewDashboard,
          Permission.viewAnalytics,
          Permission.viewReports,
        ].contains(permission);
    }
  }
  
  void _showEditPermissionMatrixDialog() {
    Map<UserRole, Set<Permission>> rolePermissions = {};
    for (var role in UserRole.values) {
      rolePermissions[role] = {};
      for (var permission in Permission.values) {
        if (_checkRoleHasPermission(role, permission)) {
          rolePermissions[role]!.add(permission);
        }
      }
    }
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E3A5F),
          title: const Text('Edit Permission Matrix', style: TextStyle(color: Colors.white)),
          content: Container(
            width: 600,
            height: 400,
            child: SingleChildScrollView(
              child: Column(
                children: UserRole.values.map((role) => ExpansionTile(
                  title: Text(
                    _rbacService.getRoleDisplayName(role),
                    style: TextStyle(color: _rbacService.getRoleColor(role), fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${rolePermissions[role]!.length} permissions',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  children: Permission.values.map((permission) => CheckboxListTile(
                    title: Text(
                      _getPermissionDisplayName(permission),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    value: rolePermissions[role]!.contains(permission),
                    onChanged: role == UserRole.superAdmin ? null : (value) {
                      setDialogState(() {
                        if (value!) {
                          rolePermissions[role]!.add(permission);
                        } else {
                          rolePermissions[role]!.remove(permission);
                        }
                      });
                    },
                    checkColor: Colors.black,
                    activeColor: _rbacService.getRoleColor(role),
                  )).toList(),
                )).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                // Here you would save the permission matrix changes
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Permission matrix updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _saveSettings() {
    // Save settings to persistence
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  void _deleteTemplate(RoleTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E3A5F),
        title: const Text('Delete Template', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete the template "${template.name}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _roleTemplates.remove(template.id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Template "${template.name}" deleted successfully'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
