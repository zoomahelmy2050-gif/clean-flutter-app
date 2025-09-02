import 'package:flutter/material.dart';
import 'package:clean_flutter/locator.dart';
import 'package:clean_flutter/features/auth/services/auth_service.dart';

class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key});

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> {
  final _authService = locator<AuthService>();

  bool _isLoading = false;
  String? _currentUser;

  // Theme settings
  String _themeMode = 'system';
  String _colorScheme = 'blue';
  bool _dynamicColors = true;

  // Display settings
  String _fontSize = 'medium';
  bool _compactMode = false;
  bool _showAnimations = true;
  bool _highContrast = false;

  // Layout settings
  String _navigationStyle = 'bottom';
  bool _showLabels = true;
  String _density = 'comfortable';

  // Accessibility settings
  bool _reduceMotion = false;
  bool _largeText = false;
  bool _boldText = false;
  String _textScaling = '1.0';

  final List<Map<String, dynamic>> _themes = [
    {'value': 'light', 'name': 'Light', 'icon': Icons.light_mode},
    {'value': 'dark', 'name': 'Dark', 'icon': Icons.dark_mode},
    {'value': 'system', 'name': 'System', 'icon': Icons.brightness_auto},
  ];

  final List<Map<String, dynamic>> _colorSchemes = [
    {'value': 'blue', 'name': 'Blue', 'color': Colors.blue},
    {'value': 'green', 'name': 'Green', 'color': Colors.green},
    {'value': 'purple', 'name': 'Purple', 'color': Colors.purple},
    {'value': 'orange', 'name': 'Orange', 'color': Colors.orange},
    {'value': 'red', 'name': 'Red', 'color': Colors.red},
    {'value': 'teal', 'name': 'Teal', 'color': Colors.teal},
  ];

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.currentUser;
    _loadAppearanceSettings();
  }

  Future<void> _loadAppearanceSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Mock loading appearance settings - in real app, load from backend/preferences
      await Future.delayed(const Duration(milliseconds: 500));

      // Settings are already initialized with default values above
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load appearance settings: $e'),
            backgroundColor: Colors.red,
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

  Future<void> _saveAppearanceSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Mock save operation - in real app, save to backend/preferences
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appearance settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save appearance settings: $e'),
            backgroundColor: Colors.red,
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

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text(
          'Are you sure you want to reset all appearance settings to their default values?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _themeMode = 'system';
        _colorScheme = 'blue';
        _dynamicColors = true;
        _fontSize = 'medium';
        _compactMode = false;
        _showAnimations = true;
        _highContrast = false;
        _navigationStyle = 'bottom';
        _showLabels = true;
        _density = 'comfortable';
        _reduceMotion = false;
        _largeText = false;
        _boldText = false;
        _textScaling = '1.0';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings reset to defaults'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'save') {
                _saveAppearanceSettings();
              } else if (value == 'reset') {
                _resetToDefaults();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'save',
                child: Row(
                  children: [
                    Icon(Icons.save),
                    SizedBox(width: 8),
                    Text('Save Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restore),
                    SizedBox(width: 8),
                    Text('Reset to Defaults'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Theme Settings
                  Text(
                    'Theme',
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
                          Text(
                            'Theme Mode',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: _themes.map((themeOption) {
                              final isSelected =
                                  _themeMode == themeOption['value'];
                              return ChoiceChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      themeOption['icon'],
                                      size: 18,
                                      color: isSelected
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(themeOption['name']),
                                  ],
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _themeMode = themeOption['value'];
                                    });
                                  }
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Color Scheme',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _colorSchemes.map((colorOption) {
                              final isSelected =
                                  _colorScheme == colorOption['value'];
                              return ChoiceChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: colorOption['color'],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(colorOption['name']),
                                  ],
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _colorScheme = colorOption['value'];
                                    });
                                  }
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('Dynamic Colors'),
                            subtitle: const Text(
                              'Use system color palette when available',
                            ),
                            value: _dynamicColors,
                            onChanged: (value) {
                              setState(() {
                                _dynamicColors = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Display Settings
                  Text(
                    'Display',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text('Font Size'),
                          subtitle: Text('Current: ${_fontSize.toUpperCase()}'),
                          trailing: DropdownButton<String>(
                            value: _fontSize,
                            items: const [
                              DropdownMenuItem(
                                value: 'small',
                                child: Text('Small'),
                              ),
                              DropdownMenuItem(
                                value: 'medium',
                                child: Text('Medium'),
                              ),
                              DropdownMenuItem(
                                value: 'large',
                                child: Text('Large'),
                              ),
                              DropdownMenuItem(
                                value: 'extra_large',
                                child: Text('Extra Large'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _fontSize = value ?? 'medium';
                              });
                            },
                          ),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Compact Mode'),
                          subtitle: const Text('Reduce spacing and padding'),
                          value: _compactMode,
                          onChanged: (value) {
                            setState(() {
                              _compactMode = value;
                            });
                          },
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Animations'),
                          subtitle: const Text(
                            'Show smooth transitions and animations',
                          ),
                          value: _showAnimations,
                          onChanged: (value) {
                            setState(() {
                              _showAnimations = value;
                            });
                          },
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('High Contrast'),
                          subtitle: const Text(
                            'Increase contrast for better visibility',
                          ),
                          value: _highContrast,
                          onChanged: (value) {
                            setState(() {
                              _highContrast = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Layout Settings
                  Text(
                    'Layout',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text('Navigation Style'),
                          subtitle: Text(
                            'Current: ${_navigationStyle.toUpperCase()}',
                          ),
                          trailing: DropdownButton<String>(
                            value: _navigationStyle,
                            items: const [
                              DropdownMenuItem(
                                value: 'bottom',
                                child: Text('Bottom'),
                              ),
                              DropdownMenuItem(
                                value: 'rail',
                                child: Text('Side Rail'),
                              ),
                              DropdownMenuItem(
                                value: 'drawer',
                                child: Text('Drawer'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _navigationStyle = value ?? 'bottom';
                              });
                            },
                          ),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Show Navigation Labels'),
                          subtitle: const Text(
                            'Display text labels on navigation items',
                          ),
                          value: _showLabels,
                          onChanged: (value) {
                            setState(() {
                              _showLabels = value;
                            });
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          title: const Text('Content Density'),
                          subtitle: Text('Current: ${_density.toUpperCase()}'),
                          trailing: DropdownButton<String>(
                            value: _density,
                            items: const [
                              DropdownMenuItem(
                                value: 'compact',
                                child: Text('Compact'),
                              ),
                              DropdownMenuItem(
                                value: 'comfortable',
                                child: Text('Comfortable'),
                              ),
                              DropdownMenuItem(
                                value: 'spacious',
                                child: Text('Spacious'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _density = value ?? 'comfortable';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Accessibility Settings
                  Text(
                    'Accessibility',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Reduce Motion'),
                          subtitle: const Text(
                            'Minimize animations and transitions',
                          ),
                          value: _reduceMotion,
                          onChanged: (value) {
                            setState(() {
                              _reduceMotion = value;
                            });
                          },
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Large Text'),
                          subtitle: const Text(
                            'Use larger text sizes throughout the app',
                          ),
                          value: _largeText,
                          onChanged: (value) {
                            setState(() {
                              _largeText = value;
                            });
                          },
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Bold Text'),
                          subtitle: const Text(
                            'Make text bolder for better readability',
                          ),
                          value: _boldText,
                          onChanged: (value) {
                            setState(() {
                              _boldText = value;
                            });
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          title: const Text('Text Scaling'),
                          subtitle: Text('Current: ${_textScaling}x'),
                          trailing: DropdownButton<String>(
                            value: _textScaling,
                            items: const [
                              DropdownMenuItem(
                                value: '0.8',
                                child: Text('0.8x'),
                              ),
                              DropdownMenuItem(
                                value: '0.9',
                                child: Text('0.9x'),
                              ),
                              DropdownMenuItem(
                                value: '1.0',
                                child: Text('1.0x'),
                              ),
                              DropdownMenuItem(
                                value: '1.1',
                                child: Text('1.1x'),
                              ),
                              DropdownMenuItem(
                                value: '1.2',
                                child: Text('1.2x'),
                              ),
                              DropdownMenuItem(
                                value: '1.3',
                                child: Text('1.3x'),
                              ),
                              DropdownMenuItem(
                                value: '1.5',
                                child: Text('1.5x'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _textScaling = value ?? '1.0';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Preview Section
                  Text(
                    'Preview',
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
                          Row(
                            children: [
                              Icon(
                                Icons.preview,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Theme Preview',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant
                                  .withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.outline.withOpacity(
                                  0.2,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sample Card Title',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'This is how your content will look with the current appearance settings.',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    FilledButton(
                                      onPressed: () {},
                                      child: const Text('Primary'),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      onPressed: () {},
                                      child: const Text('Secondary'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Changes will be applied immediately. Some settings may require an app restart to take full effect.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
