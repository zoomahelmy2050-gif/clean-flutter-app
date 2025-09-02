import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/zero_trust_service.dart';
import 'package:intl/intl.dart';

class ZeroTrustPage extends StatefulWidget {
  const ZeroTrustPage({super.key});

  @override
  State<ZeroTrustPage> createState() => _ZeroTrustPageState();
}

class _ZeroTrustPageState extends State<ZeroTrustPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zero Trust Architecture'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Microsegmentation'),
            Tab(text: 'PAM'),
            Tab(text: 'Identity Governance'),
          ],
        ),
      ),
      body: Consumer<ZeroTrustService>(
        builder: (context, service, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildMicrosegmentationTab(context, service),
              _buildPAMTab(context, service),
              _buildIdentityGovernanceTab(context, service),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMicrosegmentationTab(BuildContext context, ZeroTrustService service) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Network Segments', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          
          // Segments grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            itemCount: service.segments.length,
            itemBuilder: (context, index) {
              final segment = service.segments[index];
              return Card(
                elevation: 2,
                child: InkWell(
                  onTap: () => _showSegmentDetails(context, segment),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.hub,
                              color: _getRiskColor(segment.riskLevel),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                segment.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'VLAN: ${segment.vlanId}',
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          segment.subnet,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Icon(
                              Icons.computer,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${segment.assets.length} assets',
                              style: theme.textTheme.bodySmall,
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getRiskColor(segment.riskLevel).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                segment.riskLevel.toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: _getRiskColor(segment.riskLevel),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          Text('Segmentation Policies', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          
          // Policies list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: service.policies.length,
            itemBuilder: (context, index) {
              final policy = service.policies[index];
              final sourceSegment = service.segments.firstWhere(
                (s) => s.id == policy.sourceSegment,
                orElse: () => service.segments.first,
              );
              final destSegment = service.segments.firstWhere(
                (s) => s.id == policy.destSegment,
                orElse: () => service.segments.first,
              );
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    policy.action == 'allow' ? Icons.check_circle : Icons.block,
                    color: policy.action == 'allow' ? Colors.green : Colors.red,
                  ),
                  title: Text(policy.name),
                  subtitle: Text(
                    '${sourceSegment.name} → ${destSegment.name}\n'
                    'Protocols: ${policy.protocols.join(", ")}',
                  ),
                  trailing: Switch(
                    value: policy.enabled,
                    onChanged: (value) {
                      service.togglePolicyStatus(policy.id);
                    },
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPAMTab(BuildContext context, ZeroTrustService service) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Privileged Accounts
          Text('Privileged Accounts', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: service.privilegedAccounts.length,
            itemBuilder: (context, index) {
              final account = service.privilegedAccounts[index];
              final isCheckedOut = account.checkOutStatus == 'checked-out';
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  account.accountName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  account.accountType,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          _buildRiskBadge(account.riskScore),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.lock, size: 16, color: theme.disabledColor),
                          const SizedBox(width: 4),
                          Text(
                            'Last rotated: ${_formatDateTime(account.lastRotated)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      if (isCheckedOut) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person, size: 16, color: Colors.orange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Checked out by: ${account.checkedOutBy}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  service.checkInPrivilegedAccount(account.id);
                                },
                                child: const Text('Check In'),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            service.checkOutPrivilegedAccount(
                              account.id,
                              'current.user@company.com',
                              const Duration(hours: 2),
                            );
                          },
                          icon: const Icon(Icons.lock_open),
                          label: const Text('Check Out'),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          Text('Access Requests', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          
          // Access Requests
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: service.accessRequests.length,
            itemBuilder: (context, index) {
              final request = service.accessRequests[index];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(request.status).withOpacity(0.2),
                    child: Icon(
                      _getStatusIcon(request.status),
                      color: _getStatusColor(request.status),
                    ),
                  ),
                  title: Text('${request.requestor} → ${request.resource}'),
                  subtitle: Text(
                    '${request.accessType} - ${request.justification}\n'
                    'Duration: ${request.duration.inHours} hours',
                  ),
                  trailing: request.status == 'pending'
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () {
                                service.approveAccessRequest(
                                  request.id,
                                  'admin@company.com',
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                service.denyAccessRequest(
                                  request.id,
                                  'admin@company.com',
                                  'Insufficient justification',
                                );
                              },
                            ),
                          ],
                        )
                      : Chip(
                          label: Text(request.status.toUpperCase()),
                          backgroundColor: _getStatusColor(request.status).withOpacity(0.2),
                        ),
                  isThreeLine: true,
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          Text('Session Recordings', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          
          // Session Recordings
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: service.sessionRecordings.length,
            itemBuilder: (context, index) {
              final recording = service.sessionRecordings[index];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.videocam, color: Colors.red),
                  title: Text('${recording.user} on ${recording.resource}'),
                  subtitle: Text(
                    'Session: ${recording.sessionId}\n'
                    'Commands: ${recording.commands.length}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening session recording...')),
                      );
                    },
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityGovernanceTab(BuildContext context, ZeroTrustService service) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trust Scores
          Text('Trust Scores', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: service.trustScores.entries.map((entry) {
                  final score = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(entry.key),
                        ),
                        SizedBox(
                          width: 150,
                          child: LinearProgressIndicator(
                            value: score,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getTrustScoreColor(score),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(score * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: _getTrustScoreColor(score),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          Text('Identity Profiles', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          
          // Identity Profiles
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: service.identityProfiles.length,
            itemBuilder: (context, index) {
              final profile = service.identityProfiles[index];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.userId,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${profile.jobTitle} - ${profile.department}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          _buildRiskBadge(profile.riskScore.toInt()),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Chip(
                            label: Text(profile.accessLevel.toUpperCase()),
                            backgroundColor: profile.accessLevel == 'privileged'
                                ? Colors.orange.withOpacity(0.2)
                                : Colors.blue.withOpacity(0.2),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(profile.certificationStatus.toUpperCase()),
                            backgroundColor: profile.certificationStatus == 'certified'
                                ? Colors.green.withOpacity(0.2)
                                : Colors.red.withOpacity(0.2),
                          ),
                        ],
                      ),
                      if (profile.anomalies.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning, size: 16, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(
                                'Anomalies: ${profile.anomalies.join(", ")}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Entitlements: ${profile.entitlements.join(", ")}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          Text('Access Certifications', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          
          // Access Certifications
          if (service.certifications.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.assignment_turned_in, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        'No active certifications',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          service.createAccessCertification(
                            'Q1 2024 Access Review',
                            service.identityProfiles.map((p) => p.userId).toList(),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Start Certification'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: service.certifications.length,
              itemBuilder: (context, index) {
                final cert = service.certifications[index];
                final progress = cert.completedUsers.length / cert.targetUsers.length;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cert.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: progress),
                        const SizedBox(height: 8),
                        Text(
                          '${cert.completedUsers.length}/${cert.targetUsers.length} completed',
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          'Due: ${DateFormat.yMMMd().format(cert.dueDate)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showSegmentDetails(BuildContext context, NetworkSegment segment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(segment.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Description: ${segment.description}'),
              const SizedBox(height: 8),
              Text('VLAN ID: ${segment.vlanId}'),
              Text('Subnet: ${segment.subnet}'),
              Text('Risk Level: ${segment.riskLevel}'),
              const SizedBox(height: 12),
              const Text('Assets:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...segment.assets.map((asset) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Text('• $asset'),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(String level) {
    switch (level.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow[700]!;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'denied':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'denied':
        return Icons.cancel;
      case 'pending':
        return Icons.pending;
      default:
        return Icons.help_outline;
    }
  }

  Color _getTrustScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.yellow[700]!;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
  }

  Widget _buildRiskBadge(int score) {
    Color color;
    String label;
    
    if (score >= 80) {
      color = Colors.red;
      label = 'HIGH';
    } else if (score >= 50) {
      color = Colors.orange;
      label = 'MED';
    } else {
      color = Colors.green;
      label = 'LOW';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Risk: $label',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat.yMMMd().add_jm().format(dateTime);
  }
}
