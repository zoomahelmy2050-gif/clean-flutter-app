import 'package:flutter/material.dart';
import '../../core/services/animations_service.dart';
import '../../locator.dart';

class AnimationsSettingsPage extends StatefulWidget {
  const AnimationsSettingsPage({super.key});

  @override
  State<AnimationsSettingsPage> createState() => _AnimationsSettingsPageState();
}

class _AnimationsSettingsPageState extends State<AnimationsSettingsPage>
    with TickerProviderStateMixin {
  late AnimationsService _animationsService;
  late AnimationController _previewController;
  late Animation<double> _previewAnimation;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    _animationsService = locator<AnimationsService>();
    _previewController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _previewAnimation = CurvedAnimation(
      parent: _previewController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _previewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animation Settings'),
        actions: [
          IconButton(
            onPressed: _showPreviewDialog,
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Preview Animations',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'reset':
                  _showResetDialog();
                  break;
                case 'export':
                  _exportSettings();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'reset', child: Text('Reset to Defaults')),
              const PopupMenuItem(value: 'export', child: Text('Export Settings')),
            ],
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _animationsService,
        builder: (context, child) {
          final config = _animationsService.config;
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildGeneralSettings(config),
              const SizedBox(height: 16),
              _buildSpeedSettings(config),
              const SizedBox(height: 16),
              _buildAccessibilitySettings(config),
              const SizedBox(height: 16),
              _buildSpecificAnimations(config),
              const SizedBox(height: 16),
              _buildPreviewSection(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGeneralSettings(AnimationConfig config) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'General Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Animations'),
              subtitle: const Text('Turn animations on or off globally'),
              value: config.enabled,
              onChanged: (value) {
                _animationsService.toggleAnimations();
                _showAnimationPreview();
              },
              secondary: Icon(
                config.enabled ? Icons.animation : Icons.stop,
                color: config.enabled ? Colors.green : Colors.grey,
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('Animation Status'),
              subtitle: Text(
                config.enabled
                    ? 'Animations are enabled and running'
                    : 'Animations are disabled',
              ),
              leading: Icon(
                config.enabled ? Icons.check_circle : Icons.cancel,
                color: config.enabled ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedSettings(AnimationConfig config) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Animation Speed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...AnimationSpeed.values.map((speed) {
              return RadioListTile<AnimationSpeed>(
                title: Text(_getSpeedName(speed)),
                subtitle: Text(_getSpeedDescription(speed)),
                value: speed,
                groupValue: config.speed,
                onChanged: config.enabled ? (value) {
                  if (value != null) {
                    _animationsService.setAnimationSpeed(value);
                    _showAnimationPreview();
                  }
                } : null,
                secondary: Icon(_getSpeedIcon(speed)),
              );
            }),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Current duration: ${config.duration.inMilliseconds}ms',
                      style: const TextStyle(color: Colors.blue, fontSize: 12),
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

  Widget _buildAccessibilitySettings(AnimationConfig config) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Accessibility',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Reduce Motion'),
              subtitle: const Text('Use simpler animations for better accessibility'),
              value: config.reduceMotion,
              onChanged: config.enabled ? (value) {
                _animationsService.toggleReduceMotion();
              } : null,
              secondary: Icon(
                config.reduceMotion ? Icons.accessibility : Icons.motion_photos_on,
                color: config.reduceMotion ? Colors.orange : Colors.blue,
              ),
            ),
            if (config.reduceMotion) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reduce motion is enabled. Animations will use linear curves and shorter durations.',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpecificAnimations(AnimationConfig config) {
    final specificAnimations = [
      {'key': 'slide', 'name': 'Slide Transitions', 'description': 'Page and element sliding'},
      {'key': 'fade', 'name': 'Fade Transitions', 'description': 'Opacity changes'},
      {'key': 'scale', 'name': 'Scale Transitions', 'description': 'Size changes'},
      {'key': 'rotate', 'name': 'Rotation Transitions', 'description': 'Element rotations'},
      {'key': 'hero', 'name': 'Hero Animations', 'description': 'Shared element transitions'},
      {'key': 'page', 'name': 'Page Transitions', 'description': 'Navigation animations'},
      {'key': 'list_item', 'name': 'List Animations', 'description': 'List item changes'},
      {'key': 'stagger', 'name': 'Staggered Animations', 'description': 'Sequential animations'},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Specific Animations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: config.enabled ? () {
                    _toggleAllSpecificAnimations(true);
                  } : null,
                  child: const Text('Enable All'),
                ),
                TextButton(
                  onPressed: config.enabled ? () {
                    _toggleAllSpecificAnimations(false);
                  } : null,
                  child: const Text('Disable All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...specificAnimations.map((animation) {
              final key = animation['key'] as String;
              final isEnabled = config.specificAnimations[key] ?? true;
              
              return SwitchListTile(
                title: Text(animation['name'] as String),
                subtitle: Text(animation['description'] as String),
                value: isEnabled && config.enabled,
                onChanged: config.enabled ? (value) {
                  _animationsService.setSpecificAnimation(key, value);
                  if (value) _showAnimationPreview();
                } : null,
                secondary: Icon(_getAnimationIcon(key)),
                dense: true,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Animation Preview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _previewAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _showPreview ? _previewAnimation.value : 0.8,
                        child: Opacity(
                          opacity: _showPreview ? _previewAnimation.value : 0.5,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.animation,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _animationsService.animationsEnabled
                        ? _showAnimationPreview
                        : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Test Animation'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAnimationPreview() {
    if (!_animationsService.animationsEnabled) return;
    
    setState(() {
      _showPreview = true;
    });
    
    _previewController.reset();
    _previewController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _showPreview = false;
          });
        }
      });
    });
  }

  void _toggleAllSpecificAnimations(bool enabled) {
    final animations = ['slide', 'fade', 'scale', 'rotate', 'hero', 'page', 'list_item', 'stagger'];
    for (final animation in animations) {
      _animationsService.setSpecificAnimation(animation, enabled);
    }
  }

  void _showPreviewDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Animation Preview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This will demonstrate various animation types:'),
            const SizedBox(height: 16),
            _buildAnimationDemo(),
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

  Widget _buildAnimationDemo() {
    return SizedBox(
      height: 200,
      child: AnimatedListWidget(
        children: [
          _buildDemoCard('Slide', Icons.swipe, Colors.blue),
          _buildDemoCard('Fade', Icons.opacity, Colors.green),
          _buildDemoCard('Scale', Icons.zoom_in, Colors.orange),
          _buildDemoCard('Rotate', Icons.rotate_right, Colors.purple),
        ],
        animationType: AnimationType.fadeIn,
        staggered: true,
      ),
    );
  }

  Widget _buildDemoCard(String title, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Animation Settings'),
        content: const Text(
          'This will reset all animation settings to their default values. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _animationsService.resetToDefaults();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Animation settings reset to defaults')),
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
    final settings = _animationsService.getAnimationSettings();
    // Here you would implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Animation settings exported')),
    );
  }

  String _getSpeedName(AnimationSpeed speed) {
    switch (speed) {
      case AnimationSpeed.slow:
        return 'Slow';
      case AnimationSpeed.normal:
        return 'Normal';
      case AnimationSpeed.fast:
        return 'Fast';
    }
  }

  String _getSpeedDescription(AnimationSpeed speed) {
    switch (speed) {
      case AnimationSpeed.slow:
        return '800ms - More relaxed animations';
      case AnimationSpeed.normal:
        return '400ms - Balanced speed';
      case AnimationSpeed.fast:
        return '200ms - Quick and snappy';
    }
  }

  IconData _getSpeedIcon(AnimationSpeed speed) {
    switch (speed) {
      case AnimationSpeed.slow:
        return Icons.speed;
      case AnimationSpeed.normal:
        return Icons.speed;
      case AnimationSpeed.fast:
        return Icons.fast_forward;
    }
  }

  IconData _getAnimationIcon(String key) {
    switch (key) {
      case 'slide':
        return Icons.swipe;
      case 'fade':
        return Icons.opacity;
      case 'scale':
        return Icons.zoom_in;
      case 'rotate':
        return Icons.rotate_right;
      case 'hero':
        return Icons.flight_takeoff;
      case 'page':
        return Icons.pages;
      case 'list_item':
        return Icons.list;
      case 'stagger':
        return Icons.stairs;
      default:
        return Icons.animation;
    }
  }
}
