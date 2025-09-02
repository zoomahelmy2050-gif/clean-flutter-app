import 'package:flutter/material.dart';
import 'package:clean_flutter/locator.dart';
import 'package:clean_flutter/features/auth/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  final _authService = locator<AuthService>();
  final _searchController = TextEditingController();

  bool _isLoading = false;
  String? _currentUser;
  String _searchQuery = '';
  String _selectedCategory = 'all';

  final List<Map<String, dynamic>> _categories = [
    {'value': 'all', 'name': 'All Topics', 'icon': Icons.help_outline},
    {'value': 'account', 'name': 'Account & Security', 'icon': Icons.security},
    {'value': 'features', 'name': 'Features & Usage', 'icon': Icons.star},
    {
      'value': 'troubleshooting',
      'name': 'Troubleshooting',
      'icon': Icons.build,
    },
    {'value': 'privacy', 'name': 'Privacy & Data', 'icon': Icons.privacy_tip},
    {'value': 'billing', 'name': 'Billing & Plans', 'icon': Icons.payment},
  ];

  final List<Map<String, dynamic>> _helpArticles = [
    {
      'id': '1',
      'title': 'Getting Started with Your Account',
      'category': 'account',
      'description': 'Learn how to set up and secure your account',
      'content':
          'This comprehensive guide will walk you through the initial setup process for your Environmental Center account. Start by creating a strong password and enabling two-factor authentication for maximum security.',
      'tags': ['setup', 'account', 'security'],
      'popular': true,
    },
    {
      'id': '2',
      'title': 'Setting Up Two-Factor Authentication',
      'category': 'account',
      'description': 'Enhance your account security with 2FA',
      'content':
          'Two-factor authentication adds an extra layer of security to your account. You can use authenticator apps like Google Authenticator or receive codes via email.',
      'tags': ['2fa', 'security', 'totp'],
      'popular': true,
    },
    {
      'id': '3',
      'title': 'Managing Your Backup Codes',
      'category': 'account',
      'description': 'How to generate and use backup codes',
      'content':
          'Backup codes are essential for account recovery when you lose access to your primary authentication method. Store them securely and use them only when necessary.',
      'tags': ['backup', 'recovery', 'codes'],
      'popular': false,
    },
    {
      'id': '4',
      'title': 'Understanding Security Alerts',
      'category': 'features',
      'description': 'Configure and manage security notifications',
      'content':
          'Security alerts help you stay informed about account activity. You can customize which notifications you receive and how you receive them.',
      'tags': ['alerts', 'notifications', 'security'],
      'popular': true,
    },
    {
      'id': '5',
      'title': 'Customizing App Appearance',
      'category': 'features',
      'description': 'Personalize your app theme and display settings',
      'content':
          'You can customize the app appearance to match your preferences. Choose between light and dark themes, adjust font sizes, and enable accessibility features.',
      'tags': ['theme', 'appearance', 'customization'],
      'popular': false,
    },
    {
      'id': '6',
      'title': 'Troubleshooting Login Issues',
      'category': 'troubleshooting',
      'description': 'Common solutions for login problems',
      'content':
          'If you\'re having trouble logging in, try clearing your browser cache, checking your internet connection, or resetting your password.',
      'tags': ['login', 'troubleshooting', 'password'],
      'popular': true,
    },
    {
      'id': '7',
      'title': 'Data Privacy and Protection',
      'category': 'privacy',
      'description': 'How we protect your personal information',
      'content':
          'Your privacy is important to us. We use industry-standard encryption and security measures to protect your personal data and never share it without your consent.',
      'tags': ['privacy', 'data', 'protection'],
      'popular': false,
    },
  ];

  final List<Map<String, dynamic>> _quickActions = [
    {
      'title': 'Contact Support',
      'subtitle': 'Get help from our team',
      'icon': Icons.support_agent,
      'action': 'contact_support',
    },
    {
      'title': 'Report a Bug',
      'subtitle': 'Report technical issues',
      'icon': Icons.bug_report,
      'action': 'report_bug',
    },
    {
      'title': 'Feature Request',
      'subtitle': 'Suggest improvements',
      'icon': Icons.lightbulb_outline,
      'action': 'feature_request',
    },
    {
      'title': 'System Status',
      'subtitle': 'Check service status',
      'icon': Icons.health_and_safety,
      'action': 'system_status',
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.currentUser;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredArticles {
    return _helpArticles.where((article) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          article['title'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          article['description'].toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          (article['tags'] as List<String>).any(
            (tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()),
          );

      final matchesCategory =
          _selectedCategory == 'all' ||
          article['category'] == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<void> _performQuickAction(String action) async {
    switch (action) {
      case 'contact_support':
        _showContactSupportDialog();
        break;
      case 'report_bug':
        _showReportBugDialog();
        break;
      case 'feature_request':
        _showFeatureRequestDialog();
        break;
      case 'system_status':
        _showSystemStatusDialog();
        break;
    }
  }

  void _showContactSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.support_agent, color: Colors.blue),
            SizedBox(width: 8),
            Text('Contact Support'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need help? Contact our support team:'),
            SizedBox(height: 16),
            SelectableText(
              '📧 support@environmentalcenter.com\n📞 +1 (555) 123-4567\n💬 Live Chat: Available 9 AM - 5 PM EST',
              style: TextStyle(fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final Uri emailUri = Uri(
                scheme: 'mailto',
                path: 'support@environmentalcenter.com',
                query:
                    'subject=Support Request&body=Hello, I need help with...',
              );
              if (await canLaunchUrl(emailUri)) {
                await launchUrl(emailUri);
              }
            },
            child: const Text('Send Email'),
          ),
        ],
      ),
    );
  }

  void _showReportBugDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.bug_report, color: Colors.red),
            SizedBox(width: 8),
            Text('Report a Bug'),
          ],
        ),
        content: const Text(
          'Found a bug? Help us improve by reporting it. Please include:\n\n• Steps to reproduce the issue\n• What you expected to happen\n• What actually happened\n• Screenshots if applicable',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final Uri emailUri = Uri(
                scheme: 'mailto',
                path: 'bugs@environmentalcenter.com',
                query:
                    'subject=Bug Report&body=Bug Description:\n\nSteps to reproduce:\n1.\n2.\n3.\n\nExpected behavior:\n\nActual behavior:\n\nDevice/Browser info:\n',
              );
              if (await canLaunchUrl(emailUri)) {
                await launchUrl(emailUri);
              }
            },
            child: const Text('Report Bug'),
          ),
        ],
      ),
    );
  }

  void _showFeatureRequestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.orange),
            SizedBox(width: 8),
            Text('Feature Request'),
          ],
        ),
        content: const Text(
          'Have an idea for a new feature? We\'d love to hear it!\n\nPlease describe:\n• What feature you\'d like to see\n• How it would help you\n• Any specific requirements',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final Uri emailUri = Uri(
                scheme: 'mailto',
                path: 'features@environmentalcenter.com',
                query:
                    'subject=Feature Request&body=Feature Description:\n\nHow it would help:\n\nSpecific requirements:\n\nAdditional notes:\n',
              );
              if (await canLaunchUrl(emailUri)) {
                await launchUrl(emailUri);
              }
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  void _showSystemStatusDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.health_and_safety, color: Colors.green),
            SizedBox(width: 8),
            Text('System Status'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('API Services'),
              subtitle: Text('Operational'),
              dense: true,
            ),
            ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('Authentication'),
              subtitle: Text('Operational'),
              dense: true,
            ),
            ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('Database'),
              subtitle: Text('Operational'),
              dense: true,
            ),
            ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('File Storage'),
              subtitle: Text('Operational'),
              dense: true,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _viewArticle(Map<String, dynamic> article) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      article['title'],
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                article['description'],
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    article['content'],
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: (article['tags'] as List<String>).map((tag) {
                  return Chip(
                    label: Text(tag),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceVariant,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Help Center'), elevation: 0),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search help articles...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Category Filter
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category['value'];

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          category['icon'],
                          size: 16,
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(category['name']),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category['value'];
                      });
                    },
                  ),
                );
              },
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Actions
                  if (_searchQuery.isEmpty && _selectedCategory == 'all') ...[
                    Text(
                      'Quick Actions',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 600
                            ? 4
                            : 2;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                childAspectRatio: 1.2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                          itemCount: _quickActions.length,
                          itemBuilder: (context, index) {
                            final action = _quickActions[index];
                            return Card(
                              child: InkWell(
                                onTap: () =>
                                    _performQuickAction(action['action']),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        action['icon'],
                                        size: 32,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        action['title'],
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        action['subtitle'],
                                        style: theme.textTheme.bodySmall,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                  ],

                  // Help Articles
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _searchQuery.isNotEmpty || _selectedCategory != 'all'
                            ? 'Search Results (${_filteredArticles.length})'
                            : 'Popular Articles',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_searchQuery.isEmpty && _selectedCategory == 'all')
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = 'all';
                            });
                          },
                          child: const Text('View All'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_filteredArticles.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No articles found',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your search or category filter',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredArticles.length,
                      itemBuilder: (context, index) {
                        final article = _filteredArticles[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primary
                                  .withOpacity(0.1),
                              child: Icon(
                                article['popular']
                                    ? Icons.star
                                    : Icons.help_outline,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            title: Text(
                              article['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(article['description']),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 4,
                                  children: (article['tags'] as List<String>)
                                      .take(3)
                                      .map((tag) {
                                        return Chip(
                                          label: Text(tag),
                                          backgroundColor:
                                              theme.colorScheme.surfaceVariant,
                                          labelStyle: const TextStyle(
                                            fontSize: 12,
                                          ),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                        );
                                      })
                                      .toList(),
                                ),
                              ],
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () => _viewArticle(article),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
