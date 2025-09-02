import 'package:flutter/material.dart';
import 'package:clean_flutter/locator.dart';
import 'package:clean_flutter/features/auth/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SendFeedbackPage extends StatefulWidget {
  const SendFeedbackPage({super.key});

  @override
  State<SendFeedbackPage> createState() => _SendFeedbackPageState();
}

class _SendFeedbackPageState extends State<SendFeedbackPage> {
  final _authService = locator<AuthService>();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  String? _currentUser;

  // Feedback settings
  String _feedbackType = 'general';
  int _rating = 0;
  bool _includeSystemInfo = true;
  bool _allowFollowUp = true;

  final List<Map<String, dynamic>> _feedbackTypes = [
    {
      'value': 'general',
      'name': 'General Feedback',
      'icon': Icons.feedback,
      'description': 'Share your thoughts about the app',
    },
    {
      'value': 'bug',
      'name': 'Bug Report',
      'icon': Icons.bug_report,
      'description': 'Report a technical issue or bug',
    },
    {
      'value': 'feature',
      'name': 'Feature Request',
      'icon': Icons.lightbulb_outline,
      'description': 'Suggest new features or improvements',
    },
    {
      'value': 'security',
      'name': 'Security Concern',
      'icon': Icons.security,
      'description': 'Report security issues or concerns',
    },
    {
      'value': 'performance',
      'name': 'Performance Issue',
      'icon': Icons.speed,
      'description': 'Report slow performance or crashes',
    },
    {
      'value': 'ui',
      'name': 'UI/UX Feedback',
      'icon': Icons.design_services,
      'description': 'Feedback about user interface and experience',
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.currentUser;
    _emailController.text = _currentUser ?? '';
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare email content
      final selectedType = _feedbackTypes.firstWhere(
        (type) => type['value'] == _feedbackType,
        orElse: () => _feedbackTypes.first,
      );

      String emailBody =
          '''
Feedback Type: ${selectedType['name']}
${_rating > 0 ? 'Rating: $_rating/5 stars\n' : ''}
From: ${_emailController.text}
Allow Follow-up: ${_allowFollowUp ? 'Yes' : 'No'}

Message:
${_messageController.text}

${_includeSystemInfo ? '''
---
System Information:
Platform: Flutter App
User: $_currentUser
Timestamp: ${DateTime.now().toIso8601String()}
''' : ''}
      ''';

      // Create mailto URL
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'env.hygiene@gmail.com',
        query: Uri.encodeQueryComponent(
          'subject=App Feedback - ${selectedType['name']}&body=$emailBody',
        ).replaceAll('+', '%20'),
      );

      // Try to launch email client with mode preference
      try {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);

        if (mounted) {
          // Show success dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              icon: const Icon(Icons.email, color: Colors.green, size: 48),
              title: const Text('Email Client Opened'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Your email client has been opened with your feedback. Please send the email to complete the submission.',
                  ),
                  SizedBox(height: 16),
                  Text(
                    'If the email client didn\'t open, please copy the feedback and send it manually to env.hygiene@gmail.com',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(); // Close feedback page
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        // If launching fails, show manual copy dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Email Client Not Available'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Please copy the following feedback and send it manually to:',
                    ),
                    const SizedBox(height: 8),
                    const SelectableText(
                      'env.hygiene@gmail.com',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Subject:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SelectableText(selectedType['name']),
                    const SizedBox(height: 8),
                    const Text(
                      'Message:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SelectableText(emailBody),
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open email client: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Copy Email',
              onPressed: () {
                // Show manual copy dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Manual Email'),
                    content: const Text(
                      'Please send your feedback manually to: env.hygiene@gmail.com',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearForm() {
    _subjectController.clear();
    _messageController.clear();
    setState(() {
      _feedbackType = 'general';
      _rating = 0;
      _includeSystemInfo = true;
      _allowFollowUp = true;
    });
  }

  String get _selectedTypeDescription {
    final type = _feedbackTypes.firstWhere(
      (type) => type['value'] == _feedbackType,
      orElse: () => _feedbackTypes.first,
    );
    return type['description'];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Feedback'),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                _clearForm();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear Form'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.feedback,
                            color: theme.colorScheme.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'We Value Your Feedback',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Your feedback helps us improve the app and provide a better experience for everyone. Please share your thoughts, report issues, or suggest new features.',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Feedback Type
              Text(
                'Feedback Type',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _feedbackTypes.map((type) {
                          final isSelected = _feedbackType == type['value'];
                          return ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  type['icon'],
                                  size: 16,
                                  color: isSelected
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(type['name']),
                              ],
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _feedbackType = type['value'];
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withOpacity(
                            0.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedTypeDescription,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
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

              const SizedBox(height: 24),

              // Rating (for general feedback)
              if (_feedbackType == 'general') ...[
                Text(
                  'Overall Rating',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'How would you rate your overall experience?',
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final starIndex = index + 1;
                            return IconButton(
                              icon: Icon(
                                starIndex <= _rating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: starIndex <= _rating
                                    ? Colors.amber
                                    : Colors.grey,
                                size: 32,
                              ),
                              onPressed: () {
                                setState(() {
                                  _rating = starIndex;
                                });
                              },
                            );
                          }),
                        ),
                        if (_rating > 0)
                          Center(
                            child: Text(
                              _rating == 1
                                  ? 'Poor'
                                  : _rating == 2
                                  ? 'Fair'
                                  : _rating == 3
                                  ? 'Good'
                                  : _rating == 4
                                  ? 'Very Good'
                                  : 'Excellent',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],

              // Feedback Details
              Text(
                'Feedback Details',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _subjectController,
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          hintText: 'Brief summary of your feedback',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.subject),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Subject is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          hintText: 'Please provide detailed feedback...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.message),
                        ),
                        maxLines: 6,
                        maxLength: 2000,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Message is required';
                          }
                          if (value.trim().length < 10) {
                            return 'Please provide more detailed feedback';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Contact Information
              Text(
                'Contact Information',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'your.email@example.com',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Allow follow-up contact'),
                        subtitle: const Text(
                          'We may contact you for clarification',
                        ),
                        value: _allowFollowUp,
                        onChanged: (value) {
                          setState(() {
                            _allowFollowUp = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Additional Options
              Text(
                'Additional Options',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Include system information'),
                      subtitle: const Text(
                        'Help us diagnose issues by including device and app info',
                      ),
                      value: _includeSystemInfo,
                      onChanged: (value) {
                        setState(() {
                          _includeSystemInfo = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _submitFeedback,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(_isLoading ? 'Sending...' : 'Send Feedback'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Privacy Notice
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.privacy_tip_outlined,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Privacy Notice',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your feedback will be used to improve our services. We respect your privacy and will only use your contact information to respond to your feedback if you\'ve allowed follow-up contact.',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
