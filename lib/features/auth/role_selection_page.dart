import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/role_management_service.dart';
import '../admin/security_center_page.dart';
import '../home/home_page.dart';

class RoleSelectionPage extends StatefulWidget {
  final String userEmail;
  final UserRole userRole;

  const RoleSelectionPage({
    super.key,
    required this.userEmail,
    required this.userRole,
  });

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  bool _isLoading = false;

  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'Super Administrator';
      case UserRole.admin:
        return 'Administrator';
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

  void _selectRole(String mode) async {
    setState(() => _isLoading = true);
    
    // Store the selected mode in shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_mode_${widget.userEmail}', mode);
    
    if (mounted) {
      if (mode == 'admin') {
        // Navigate to admin security center
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SecurityCenterPage()),
          (route) => false,
        );
      } else {
        // Navigate to normal user dashboard
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage(initialTab: 3)),
          (route) => false,
        );
      }
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
                    const Color(0xFF1a1a1a),
                    const Color(0xFF2d2d2d),
                  ]
                : [
                    Colors.blue[50]!,
                    Colors.blue[100]!,
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Welcome Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: _getRoleColor(widget.userRole).withOpacity(0.2),
                          child: Icon(
                            _getRoleIcon(widget.userRole),
                            size: 40,
                            color: _getRoleColor(widget.userRole),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Welcome Back!',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.userEmail,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getRoleColor(widget.userRole).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getRoleColor(widget.userRole),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            _getRoleName(widget.userRole),
                            style: TextStyle(
                              color: _getRoleColor(widget.userRole),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Selection Title
                  Text(
                    'How would you like to continue?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose your access mode for this session',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Role Selection Cards
                  Row(
                    children: [
                      // Admin Mode Card
                      Expanded(
                        child: _buildRoleCard(
                          context,
                          title: 'Admin Mode',
                          subtitle: 'Access Security Center',
                          description: 'Manage users, view logs, configure security settings',
                          icon: Icons.security,
                          color: _getRoleColor(widget.userRole),
                          onTap: _isLoading ? null : () => _selectRole('admin'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // User Mode Card
                      Expanded(
                        child: _buildRoleCard(
                          context,
                          title: 'User Mode',
                          subtitle: 'Normal Dashboard',
                          description: 'Access standard features and personal settings',
                          icon: Icons.dashboard,
                          color: Colors.blue,
                          onTap: _isLoading ? null : () => _selectRole('user'),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Quick Access Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You can switch between modes anytime from the profile menu',
                            style: TextStyle(
                              color: Colors.blue[700],
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
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isEnabled = onTap != null;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 240,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isEnabled ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isEnabled 
                  ? color.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: isEnabled ? color : Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isEnabled ? null : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isEnabled ? color : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (_isLoading && isEnabled)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
