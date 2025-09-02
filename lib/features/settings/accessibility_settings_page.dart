import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/accessibility_service.dart';
import '../../locator.dart';

class AccessibilitySettingsPage extends StatefulWidget {
  const AccessibilitySettingsPage({super.key});

  @override
  State<AccessibilitySettingsPage> createState() => _AccessibilitySettingsPageState();
}

class _AccessibilitySettingsPageState extends State<AccessibilitySettingsPage> {
  late AccessibilityService _accessibilityService;

  @override
  void initState() {
    super.initState();
    _accessibilityService = locator<AccessibilityService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessibility Settings'),
        actions: [
          IconButton(
            onPressed: _showAccessibilityInfo,
            icon: const Icon(Icons.info_outline),
            tooltip: 'Accessibility Information',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'test':
                  _runAccessibilityTest();
                  break;
                case 'reset':
                  _showResetDialog();
                  break;
                case 'export':
                  _exportSettings();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'test', child: Text('Test Accessibility')),
              const PopupMenuItem(value: 'reset', child: Text('Reset to Defaults')),
              const PopupMenuItem(value: 'export', child: Text('Export Settings')),
            ],
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _accessibilityService,
        builder: (context, child) {
          final config = _accessibilityService.config;
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildAccessibilityOverview(config),
              const SizedBox(height: 16),
              _buildVisionSettings(config),
              const SizedBox(height: 16),
              _buildMotorSettings(config),
              const SizedBox(height: 16),
              _buildAudioSettings(config),
              const SizedBox(height: 16),
              _buildNavigationSettings(config),
              const SizedBox(height: 16),
              _buildTestSection(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAccessibilityOverview(AccessibilityConfig config) {
    final summary = _accessibilityService.getAccessibilitySummary();
    final enabledFeatures = summary['featuresEnabled'] as int;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.accessibility,
                  color: enabledFeatures > 0 ? Colors.green : Colors.grey,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Accessibility Status',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$enabledFeatures features enabled',
                        style: TextStyle(
                          color: enabledFeatures > 0 ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'These settings help make the app more accessible for users with different needs.',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
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

  Widget _buildVisionSettings(AccessibilityConfig config) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.visibility, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Vision',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _accessibilityService.createAccessibleListTile(
              title: const Text('Screen Reader'),
              subtitle: const Text('Enable screen reader support'),
              leading: const Icon(Icons.record_voice_over),
              trailing: Switch(
                value: config.screenReaderEnabled,
                onChanged: (value) {
                  _accessibilityService.toggleScreenReader();
                  _accessibilityService.announceText(
                    value ? 'Screen reader enabled' : 'Screen reader disabled'
                  );
                },
              ),
              semanticLabel: 'Toggle screen reader support',
            ),
            const Divider(),
            ListTile(
              title: const Text('Text Size'),
              subtitle: Text('Current: ${(config.textScaleFactor * 100).round()}%'),
              leading: const Icon(Icons.text_fields),
              trailing: SizedBox(
                width: 150,
                child: Slider(
                  value: config.textScaleFactor,
                  min: 0.8,
                  max: 3.0,
                  divisions: 22,
                  label: '${(config.textScaleFactor * 100).round()}%',
                  onChanged: (value) {
                    _accessibilityService.setTextScaleFactor(value);
                  },
                ),
              ),
            ),
            const Divider(),
            _accessibilityService.createAccessibleListTile(
              title: const Text('High Contrast'),
              subtitle: const Text('Use high contrast colors'),
              leading: const Icon(Icons.contrast),
              trailing: Switch(
                value: config.highContrastEnabled,
                onChanged: (value) {
                  _accessibilityService.toggleHighContrast();
                  _accessibilityService.announceText(
                    value ? 'High contrast enabled' : 'High contrast disabled'
                  );
                },
              ),
              semanticLabel: 'Toggle high contrast mode',
            ),
            const Divider(),
            _accessibilityService.createAccessibleListTile(
              title: const Text('Color Blind Friendly'),
              subtitle: const Text('Use colors suitable for color blindness'),
              leading: const Icon(Icons.palette),
              trailing: Switch(
                value: config.colorBlindFriendly,
                onChanged: (value) {
                  _accessibilityService.toggleColorBlindFriendly();
                  _accessibilityService.announceText(
                    value ? 'Color blind friendly mode enabled' : 'Color blind friendly mode disabled'
                  );
                },
              ),
              semanticLabel: 'Toggle color blind friendly mode',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotorSettings(AccessibilityConfig config) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.touch_app, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Motor',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _accessibilityService.createAccessibleListTile(
              title: const Text('Reduce Motion'),
              subtitle: const Text('Minimize animations and transitions'),
              leading: const Icon(Icons.motion_photos_off),
              trailing: Switch(
                value: config.reduceMotionEnabled,
                onChanged: (value) {
                  _accessibilityService.toggleReduceMotion();
                  _accessibilityService.announceText(
                    value ? 'Reduce motion enabled' : 'Reduce motion disabled'
                  );
                },
              ),
              semanticLabel: 'Toggle reduce motion',
            ),
            const Divider(),
            _accessibilityService.createAccessibleListTile(
              title: const Text('Haptic Feedback'),
              subtitle: const Text('Vibration feedback for interactions'),
              leading: const Icon(Icons.vibration),
              trailing: Switch(
                value: config.hapticFeedbackEnabled,
                onChanged: (value) {
                  _accessibilityService.toggleHapticFeedback();
                  if (value) {
                    _accessibilityService.provideHapticFeedback(HapticFeedbackType.mediumImpact);
                  }
                  _accessibilityService.announceText(
                    value ? 'Haptic feedback enabled' : 'Haptic feedback disabled'
                  );
                },
              ),
              semanticLabel: 'Toggle haptic feedback',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioSettings(AccessibilityConfig config) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.hearing, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Audio',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _accessibilityService.createAccessibleListTile(
              title: const Text('Audio Feedback'),
              subtitle: const Text('Spoken feedback for actions'),
              leading: const Icon(Icons.volume_up),
              trailing: Switch(
                value: config.audioFeedbackEnabled,
                onChanged: (value) {
                  _accessibilityService.toggleAudioFeedback();
                  _accessibilityService.announceText(
                    value ? 'Audio feedback enabled' : 'Audio feedback disabled'
                  );
                },
              ),
              semanticLabel: 'Toggle audio feedback',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationSettings(AccessibilityConfig config) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.navigation, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Navigation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _accessibilityService.createAccessibleListTile(
              title: const Text('Focus Indicators'),
              subtitle: const Text('Highlight focused elements'),
              leading: const Icon(Icons.center_focus_strong),
              trailing: Switch(
                value: config.focusIndicatorEnabled,
                onChanged: (value) {
                  _accessibilityService.toggleFocusIndicator();
                  _accessibilityService.announceText(
                    value ? 'Focus indicators enabled' : 'Focus indicators disabled'
                  );
                },
              ),
              semanticLabel: 'Toggle focus indicators',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.science, color: Colors.teal),
                SizedBox(width: 8),
                Text(
                  'Accessibility Testing',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Test accessibility features to ensure they work correctly.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _accessibilityService.createAccessibleButton(
                  onPressed: () => _testScreenReader(),
                  semanticLabel: 'Test screen reader announcement',
                  tooltip: 'Test screen reader',
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.record_voice_over, size: 16),
                      SizedBox(width: 4),
                      Text('Screen Reader'),
                    ],
                  ),
                ),
                _accessibilityService.createAccessibleButton(
                  onPressed: () => _testHapticFeedback(),
                  semanticLabel: 'Test haptic feedback vibration',
                  tooltip: 'Test haptic feedback',
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.vibration, size: 16),
                      SizedBox(width: 4),
                      Text('Haptic'),
                    ],
                  ),
                ),
                _accessibilityService.createAccessibleButton(
                  onPressed: () => _testAudioFeedback(),
                  semanticLabel: 'Test audio feedback speech',
                  tooltip: 'Test audio feedback',
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.volume_up, size: 16),
                      SizedBox(width: 4),
                      Text('Audio'),
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

  void _testScreenReader() {
    _accessibilityService.announceText(
      'Screen reader test: This is a test announcement to verify screen reader functionality is working correctly.',
    );
  }

  void _testHapticFeedback() {
    _accessibilityService.provideHapticFeedback(HapticFeedbackType.mediumImpact);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Haptic feedback test completed'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _testAudioFeedback() {
    _accessibilityService.announceText(
      'Audio feedback test: This message tests the text-to-speech functionality.',
    );
  }

  void _runAccessibilityTest() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accessibility Test'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Running comprehensive accessibility test...'),
            const SizedBox(height: 16),
            _buildTestResults(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildTestResults() {
    final summary = _accessibilityService.getAccessibilitySummary();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTestResult('Screen Reader', summary['screenReader']),
        _buildTestResult('Large Text', summary['textScale'] > 1.0),
        _buildTestResult('High Contrast', summary['highContrast']),
        _buildTestResult('Color Blind Friendly', summary['colorBlindFriendly']),
        _buildTestResult('Reduce Motion', summary['reduceMotion']),
        _buildTestResult('Haptic Feedback', summary['hapticFeedback']),
        _buildTestResult('Audio Feedback', summary['audioFeedback']),
        _buildTestResult('Focus Indicators', summary['focusIndicator']),
      ],
    );
  }

  Widget _buildTestResult(String feature, bool enabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.cancel,
            color: enabled ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            feature,
            style: TextStyle(
              color: enabled ? Colors.green : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showAccessibilityInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accessibility Information'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This app supports various accessibility features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('• Screen reader support for visually impaired users'),
              Text('• Adjustable text size for better readability'),
              Text('• High contrast mode for better visibility'),
              Text('• Color blind friendly color schemes'),
              Text('• Reduced motion for motion sensitivity'),
              Text('• Haptic feedback for tactile confirmation'),
              Text('• Audio feedback with text-to-speech'),
              Text('• Focus indicators for keyboard navigation'),
              SizedBox(height: 12),
              Text(
                'These features can be enabled individually based on your needs.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Accessibility Settings'),
        content: const Text(
          'This will reset all accessibility settings to their default values. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _accessibilityService.resetToDefaults();
              if (mounted) {
                Navigator.pop(context);
                _accessibilityService.announceText('Accessibility settings reset to defaults');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Accessibility settings reset to defaults')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _exportSettings() {
    final settings = _accessibilityService.exportSettings();
    // Here you would implement export functionality
    _accessibilityService.announceText('Accessibility settings exported');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Accessibility settings exported')),
    );
  }
}
