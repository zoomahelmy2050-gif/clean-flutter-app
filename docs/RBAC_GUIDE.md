# Role-Based Access Control (RBAC) Guide

## Overview
The Flutter Security App now includes a comprehensive Role-Based Access Control (RBAC) system that restricts access to features based on user roles and permissions.

## User Roles

### 1. Super Admin
- **Access Level**: Full system access
- **Permissions**: All permissions
- **Use Case**: System administrators and security team leaders

### 2. Admin
- **Key Permissions**:
  - View and manage security settings
  - Manage users and roles
  - View audit logs
  - Execute security playbooks
  - Configure system settings
  - Export data
- **Use Case**: Security managers and IT administrators

### 3. Security Analyst
- **Key Permissions**:
  - View security center and dashboards
  - Execute playbooks
  - View and acknowledge alerts
  - View and mitigate threats
  - Access analytics
- **Use Case**: SOC analysts and security operations staff

### 4. Auditor
- **Key Permissions**:
  - View dashboards and reports
  - Access audit logs
  - Export data for compliance
  - View compliance status
- **Use Case**: Compliance officers and internal auditors

### 5. Viewer
- **Key Permissions**:
  - View dashboards
  - View reports
  - View analytics
- **Use Case**: Stakeholders and read-only users

### 6. User
- **Key Permissions**:
  - View and edit own profile
  - View notifications
  - Change password
- **Use Case**: Regular application users

## Features and Required Permissions

| Feature | Required Permission | Minimum Role |
|---------|-------------------|--------------|
| Security Settings | `manageSecurity` | Admin |
| View Logs | `viewAuditLogs` | Auditor |
| Vulnerability Scanning | `manageSecurity` | Admin |
| User Behavior Analytics | `viewAnalytics` | Viewer |
| User Management | `manageUsers` | Admin |
| Incident Response | `executePlaybooks` | Security Analyst |
| Compliance Reporting | `viewCompliance` | Auditor |

## Implementation in UI

### Protected Features in Security Center
The Security Center page now includes RBAC protection for sensitive features:

```dart
// Example of RBAC-protected card
_buildRBACProtectedCard(
  permission: Permission.manageSecurity,
  icon: Icons.security,
  title: 'Security Settings',
  subtitle: 'Manage MFA options',
  requiredRoleText: 'Requires admin role',
  onTap: () {
    // Navigate to protected feature
  },
)
```

### Visual Feedback
- **Authorized Users**: See normal feature descriptions and can access features
- **Unauthorized Users**: See role requirement messages and receive access denied notifications

## API Usage

### Check User Permissions
```dart
final rbacService = locator<RBACService>();

// Check single permission
if (rbacService.hasPermission(Permission.manageSecurity)) {
  // User has permission
}

// Check multiple permissions (all required)
if (rbacService.hasAllPermissions({
  Permission.viewAuditLogs,
  Permission.exportData,
})) {
  // User has all permissions
}

// Check feature access
if (rbacService.canAccessFeature('vulnerability_scanning')) {
  // User can access feature
}
```

### Update User Role
```dart
// Admin operation only
await rbacService.updateUserRole(UserRole.securityAnalyst);
```

### Add Custom Permissions
```dart
// Grant additional permission
await rbacService.addCustomPermission(Permission.viewThreats);

// Revoke permission
await rbacService.removeCustomPermission(Permission.viewThreats);
```

## Security Considerations

### Principle of Least Privilege
- Users are assigned the minimum role necessary for their job function
- Custom permissions should be granted sparingly and reviewed regularly

### Audit Logging
- All permission checks are logged for audit purposes
- Role changes are tracked with timestamps and user IDs
- Failed access attempts are recorded

### Role Management Best Practices
1. **Regular Reviews**: Audit user roles quarterly
2. **Separation of Duties**: Ensure critical functions require multiple roles
3. **Emergency Access**: Maintain break-glass procedures for critical situations
4. **Training**: Ensure users understand their access levels

## Testing RBAC

### Manual Testing
1. Log in with different user roles
2. Verify feature access matches role permissions
3. Test access denied notifications
4. Verify audit logs capture permission checks

### Automated Testing
Run the RBAC integration tests:
```bash
flutter test test/rbac_integration_test.dart
```

## Troubleshooting

### Common Issues

1. **Feature Not Accessible**
   - Verify user role in settings
   - Check required permissions for feature
   - Review audit logs for denied access

2. **Permission Not Working**
   - Ensure RBAC service is initialized
   - Check if custom permissions are persisted
   - Verify role definitions in code

3. **Role Changes Not Applied**
   - Refresh the UI after role update
   - Check if changes are saved to storage
   - Verify network connectivity for sync

## Future Enhancements

### Planned Features
- Dynamic role creation through admin UI
- Time-based access controls
- Contextual permissions based on data sensitivity
- Delegation and approval workflows
- Integration with enterprise identity providers

### Backend Integration
When connecting to production backend:
1. Replace mock user ID with actual authenticated user
2. Sync roles and permissions from server
3. Implement server-side permission validation
4. Add real-time permission updates via WebSocket

## Support
For questions or issues with RBAC:
1. Check audit logs for detailed error messages
2. Review this documentation
3. Contact security team for role adjustments
4. Submit feature requests through feedback system
