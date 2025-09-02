import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/role_management_service.dart';

class RoleManagementPage extends StatefulWidget {
  const RoleManagementPage({Key? key}) : super(key: key);

  @override
  State<RoleManagementPage> createState() => _RoleManagementPageState();
}

class _RoleManagementPageState extends State<RoleManagementPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoleManagementService>().initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Role Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.admin_panel_settings), text: 'Roles'),
            Tab(icon: Icon(Icons.people), text: 'Assignments'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRolesTab(),
          _buildAssignmentsTab(),
          _buildAnalyticsTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: _showCreateRoleDialog,
              child: const Icon(Icons.add),
              tooltip: 'Create Custom Role',
            )
          : _tabController.index == 1
              ? FloatingActionButton(
                  onPressed: _showAssignRoleDialog,
                  child: const Icon(Icons.person_add),
                  tooltip: 'Assign Role',
                )
              : null,
    );
  }

  Widget _buildRolesTab() {
    return Consumer<RoleManagementService>(
      builder: (context, roleService, child) {
        if (roleService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final allRoles = roleService.getAllRoles();
        final filteredRoles = allRoles.where((role) =>
            role.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            role.description.toLowerCase().contains(_searchQuery.toLowerCase())
        ).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search roles...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredRoles.length,
                itemBuilder: (context, index) {
                  final role = filteredRoles[index];
                  return _buildRoleCard(role, roleService);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRoleCard(RoleData role, RoleManagementService roleService) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Color(int.parse(role.color.replaceFirst('#', '0xFF'))),
          child: Icon(
            role.isSystemRole ? Icons.verified : Icons.admin_panel_settings,
            color: Colors.white,
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(role.name, style: const TextStyle(fontWeight: FontWeight.bold))),
            if (role.isSystemRole)
              Chip(
                label: const Text('System', style: TextStyle(fontSize: 12)),
                backgroundColor: Colors.grey[300],
              ),
          ],
        ),
        subtitle: Text(role.description),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Permissions (${role.permissions.length})', 
                     style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: role.permissions.map((permission) => Chip(
                    label: Text(
                      permission.name.replaceAllMapped(
                        RegExp(r'([A-Z])'),
                        (match) => ' ${match.group(1)}',
                      ).trim(),
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.blue[100],
                  )).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Created: ${_formatDate(role.createdAt)}', 
                         style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    if (!role.isSystemRole)
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showEditRoleDialog(role),
                            tooltip: 'Edit Role',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteRoleDialog(role, roleService),
                            tooltip: 'Delete Role',
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsTab() {
    return Consumer<RoleManagementService>(
      builder: (context, roleService, child) {
        if (roleService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final assignments = roleService.roleAssignments;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            final assignment = assignments[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(assignment.userEmail.substring(0, 1).toUpperCase()),
                ),
                title: Text(assignment.userEmail),
                subtitle: Text('Role: ${assignment.role.name}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'remove') {
                      roleService.removeUserRole(assignment.userId);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'remove', child: Text('Remove')),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    return Consumer<RoleManagementService>(
      builder: (context, roleService, child) {
        final distribution = roleService.getRoleDistribution();
        
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Role Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      ...distribution.entries.map((entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key),
                            Chip(label: Text(entry.value.toString())),
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
      },
    );
  }

  void _showCreateRoleDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateRoleDialog(),
    );
  }

  void _showEditRoleDialog(RoleData role) {
    showDialog(
      context: context,
      builder: (context) => CreateRoleDialog(existingRole: role),
    );
  }

  void _showDeleteRoleDialog(RoleData role, RoleManagementService roleService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Role'),
        content: Text('Delete "${role.name}" role?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              roleService.deleteCustomRole(role.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAssignRoleDialog() {
    showDialog(
      context: context,
      builder: (context) => AssignRoleDialog(),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class CreateRoleDialog extends StatefulWidget {
  final RoleData? existingRole;
  const CreateRoleDialog({Key? key, this.existingRole}) : super(key: key);

  @override
  State<CreateRoleDialog> createState() => _CreateRoleDialogState();
}

class _CreateRoleDialogState extends State<CreateRoleDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  Set<Permission> _selectedPermissions = {};

  @override
  void initState() {
    super.initState();
    if (widget.existingRole != null) {
      _nameController.text = widget.existingRole!.name;
      _descriptionController.text = widget.existingRole!.description;
      _selectedPermissions = widget.existingRole!.permissions.toSet();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingRole == null ? 'Create Role' : 'Edit Role'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Role Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 16),
            const Text('Permissions:', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView(
                children: Permission.values.map((permission) => CheckboxListTile(
                  title: Text(permission.name),
                  value: _selectedPermissions.contains(permission),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedPermissions.add(permission);
                      } else {
                        _selectedPermissions.remove(permission);
                      }
                    });
                  },
                )).toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _saveRole, child: const Text('Save')),
      ],
    );
  }

  void _saveRole() {
    final roleService = context.read<RoleManagementService>();
    final role = RoleData(
      id: widget.existingRole?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      description: _descriptionController.text,
      permissions: _selectedPermissions.toList(),
      createdAt: widget.existingRole?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (widget.existingRole == null) {
      roleService.createCustomRole(role);
    } else {
      roleService.updateCustomRole(widget.existingRole!.id, role);
    }
    Navigator.pop(context);
  }
}

class AssignRoleDialog extends StatefulWidget {
  const AssignRoleDialog({Key? key}) : super(key: key);

  @override
  State<AssignRoleDialog> createState() => _AssignRoleDialogState();
}

class _AssignRoleDialogState extends State<AssignRoleDialog> {
  final _emailController = TextEditingController();
  UserRole _selectedRole = UserRole.user;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assign Role'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'User Email'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<UserRole>(
            value: _selectedRole,
            decoration: const InputDecoration(labelText: 'Role'),
            items: UserRole.values.map((role) => DropdownMenuItem(
              value: role,
              child: Text(role.name),
            )).toList(),
            onChanged: (value) => setState(() => _selectedRole = value!),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _assignRole, child: const Text('Assign')),
      ],
    );
  }

  void _assignRole() {
    final roleService = context.read<RoleManagementService>();
    roleService.assignRoleToUser(
      DateTime.now().millisecondsSinceEpoch.toString(),
      _emailController.text,
      _selectedRole,
    );
    Navigator.pop(context);
  }
}
