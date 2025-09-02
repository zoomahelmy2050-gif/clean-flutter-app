import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer' as developer;

enum ShortcutCategory {
  navigation,
  security_operations,
  threat_hunting,
  incident_response,
  dashboard,
  general
}

class KeyboardShortcut {
  final String id;
  final String name;
  final String description;
  final LogicalKeySet keySet;
  final ShortcutCategory category;
  final VoidCallback action;
  final bool isEnabled;
  final String? context;

  KeyboardShortcut({
    required this.id,
    required this.name,
    required this.description,
    required this.keySet,
    required this.category,
    required this.action,
    this.isEnabled = true,
    this.context,
  });
}

class KeyboardShortcutsService {
  static final KeyboardShortcutsService _instance = KeyboardShortcutsService._internal();
  factory KeyboardShortcutsService() => _instance;
  KeyboardShortcutsService._internal();

  final Map<String, KeyboardShortcut> _shortcuts = {};
  final Map<LogicalKeySet, String> _keySetToId = {};
  final StreamController<String> _shortcutExecutedController = StreamController<String>.broadcast();
  
  Stream<String> get shortcutExecutedStream => _shortcutExecutedController.stream;

  bool _isInitialized = false;
  BuildContext? _currentContext;

  Future<void> initialize(BuildContext context) async {
    if (_isInitialized) return;

    _currentContext = context;
    developer.log('Initializing Keyboard Shortcuts Service', name: 'KeyboardShortcutsService');
    
    _registerDefaultShortcuts();
    
    _isInitialized = true;
    developer.log('Keyboard Shortcuts Service initialized with ${_shortcuts.length} shortcuts', name: 'KeyboardShortcutsService');
  }

  void _registerDefaultShortcuts() {
    // Navigation shortcuts
    registerShortcut(KeyboardShortcut(
      id: 'nav_dashboard',
      name: 'Go to Dashboard',
      description: 'Navigate to main security dashboard',
      keySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyD),
      category: ShortcutCategory.navigation,
      action: () => _navigateTo('/dashboard'),
    ));

    registerShortcut(KeyboardShortcut(
      id: 'nav_threats',
      name: 'Go to Threats',
      description: 'Navigate to threat intelligence page',
      keySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyT),
      category: ShortcutCategory.navigation,
      action: () => _navigateTo('/threats'),
    ));

    registerShortcut(KeyboardShortcut(
      id: 'nav_incidents',
      name: 'Go to Incidents',
      description: 'Navigate to incident response center',
      keySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyI),
      category: ShortcutCategory.navigation,
      action: () => _navigateTo('/incidents'),
    ));

    registerShortcut(KeyboardShortcut(
      id: 'nav_compliance',
      name: 'Go to Compliance',
      description: 'Navigate to compliance reporting hub',
      keySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyC),
      category: ShortcutCategory.navigation,
      action: () => _navigateTo('/compliance'),
    ));

    registerShortcut(KeyboardShortcut(
      id: 'nav_monitoring',
      name: 'Go to Monitoring',
      description: 'Navigate to real-time monitoring',
      keySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyM),
      category: ShortcutCategory.navigation,
      action: () => _navigateTo('/monitoring'),
    ));

    // Security Operations shortcuts
    registerShortcut(KeyboardShortcut(
      id: 'sec_refresh',
      name: 'Refresh Security Data',
      description: 'Refresh all security metrics and data',
      keySet: LogicalKeySet(LogicalKeyboardKey.f5),
      category: ShortcutCategory.security_operations,
      action: () => _refreshSecurityData(),
    ));

    registerShortcut(KeyboardShortcut(
      id: 'sec_critical_alerts',
      name: 'Show Critical Alerts',
      description: 'Display only critical security alerts',
      keySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyA),
      category: ShortcutCategory.security_operations,
      action: () => _showCriticalAlerts(),
    ));

    registerShortcut(KeyboardShortcut(
      id: 'sec_acknowledge_all',
      name: 'Acknowledge All Alerts',
      description: 'Acknowledge all visible security alerts',
      keySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyK),
      category: ShortcutCategory.security_operations,
      action: () => _acknowledgeAllAlerts(),
    ));

    registerShortcut(KeyboardShortcut(
      id: 'sec_block_ip',
      name: 'Block Selected IP',
      description: 'Block the currently selected IP address',
      keySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyB),
      category: ShortcutCategory.security_operations,
      action: () => _blockSelectedIP(),
    ));

    // Threat Hunting shortcuts
    registerShortcut(KeyboardShortcut(
      id: 'hunt_new_query',
      name: 'New Hunt Query',
      description: 'Create a new threat hunting query',
      keySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN),
      category: ShortcutCategory.threat_hunting,
      action: () => _newHuntQuery(),
    ));

    registerShortcut(KeyboardShortcut(
      id: 'hunt_execute',
      name: 'Execute Query',
      description: 'Execute the current threat hunting query',
      keySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.enter),
      category: ShortcutCategory.threat_hunting,
      action: () => _executeHuntQuery(),
    ));

    registerShortcut(KeyboardShortcut(
      id: 'hunt_save',
      name: 'Save Query',
      description: 'Save the current threat hunting query',
      keySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS),
      category: ShortcutCategory.threat_hunting,
      action: () => _saveHuntQuery(),
    ));

    // Incident Response shortcuts
    registerShortcut(KeyboardShortcut(
      id: 'incident_new',
      name: 'New Incident',
      description: 'Create a new security incident',
      keySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyN),
      category: ShortcutCategory.incident_response,
      action: () => _newIncident(),
    ));

    registerShortcut(KeyboardShortcut(
      id: 'incident_escalate',
      name: 'Escalate Incident',
      description: 'Escalate the selected incident',
      keySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyE),
      category: ShortcutCategory.incident_response,
      action: () => _escalateIncident(),
    ));

    registerShortcut(KeyboardShortcut(
      id: 'incident_resolve',
      name: 'Resolve Incident',
      description: 'Mark the selected incident as resolved',
      keySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyR),
      category: ShortcutCategory.incident_response,
      action: () => _resolveIncident(),
    ));

    // Dashboard shortcuts
    registerShortcut(KeyboardShortcut(
      id: 'dash_fullscreen',
      name: 'Toggle Fullscreen',
      description: 'Toggle fullscreen mode for current widget',
      keySet: LogicalKeySet(LogicalKeyboardKey.f11),
      category: ShortcutCategory.dashboard,
      action: () => _toggleFullscreen(),
    ));

    registerShortcut(KeyboardShortcut(
      id: 'dash_add_widget',
      name: 'Add Widget',
      description: 'Add a new widget to the dashboard',
      keySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyW),
      category: ShortcutCategory.dashboard,
      action: () => _addWidget(),
    ));

    registerShortcut(KeyboardShortcut(
      id: 'dash_export',
      name: 'Export Dashboard',
      description: 'Export current dashboard as PDF',
      keySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyE),
      category: ShortcutCategory.dashboard,
      action: () => _exportDashboard(),
    ));

    // General shortcuts
    registerShortcut(KeyboardShortcut(
      id: 'gen_search',
      name: 'Global Search',
      description: 'Open global search dialog',
      keySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF),
      category: ShortcutCategory.general,
      action: () => _openGlobalSearch(),
    ));

    registerShortcut(KeyboardShortcut(
      id: 'gen_help',
      name: 'Show Help',
      description: 'Show keyboard shortcuts help',
      keySet: LogicalKeySet(LogicalKeyboardKey.f1),
      category: ShortcutCategory.general,
      action: () => _showHelp(),
    ));

    registerShortcut(KeyboardShortcut(
      id: 'gen_command_palette',
      name: 'Command Palette',
      description: 'Open command palette',
      keySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyP),
      category: ShortcutCategory.general,
      action: () => _openCommandPalette(),
    ));

    registerShortcut(KeyboardShortcut(
      id: 'gen_notifications',
      name: 'Show Notifications',
      description: 'Open notifications panel',
      keySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyN),
      category: ShortcutCategory.general,
      action: () => _showNotifications(),
    ));

    // Quick actions with number keys
    for (int i = 1; i <= 9; i++) {
      registerShortcut(KeyboardShortcut(
        id: 'quick_action_$i',
        name: 'Quick Action $i',
        description: 'Execute quick action $i',
        keySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey(0x00000030 + i)),
        category: ShortcutCategory.general,
        action: () => _executeQuickAction(i),
      ));
    }
  }

  void registerShortcut(KeyboardShortcut shortcut) {
    _shortcuts[shortcut.id] = shortcut;
    _keySetToId[shortcut.keySet] = shortcut.id;
  }

  void unregisterShortcut(String id) {
    final shortcut = _shortcuts[id];
    if (shortcut != null) {
      _shortcuts.remove(id);
      _keySetToId.remove(shortcut.keySet);
    }
  }

  bool handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final pressedKeys = <LogicalKeyboardKey>{};
    
    // Add modifier keys
    if (HardwareKeyboard.instance.isControlPressed) {
      pressedKeys.add(LogicalKeyboardKey.control);
    }
    if (HardwareKeyboard.instance.isShiftPressed) {
      pressedKeys.add(LogicalKeyboardKey.shift);
    }
    if (HardwareKeyboard.instance.isAltPressed) {
      pressedKeys.add(LogicalKeyboardKey.alt);
    }
    if (HardwareKeyboard.instance.isMetaPressed) {
      pressedKeys.add(LogicalKeyboardKey.meta);
    }

    // Add the main key
    pressedKeys.add(event.logicalKey);

    final keySet = LogicalKeySet.fromSet(pressedKeys);
    final shortcutId = _keySetToId[keySet];

    if (shortcutId != null) {
      final shortcut = _shortcuts[shortcutId];
      if (shortcut != null && shortcut.isEnabled) {
        developer.log('Executing shortcut: ${shortcut.name}', name: 'KeyboardShortcutsService');
        shortcut.action();
        _shortcutExecutedController.add(shortcutId);
        return true;
      }
    }

    return false;
  }

  List<KeyboardShortcut> getShortcutsByCategory(ShortcutCategory category) {
    return _shortcuts.values.where((s) => s.category == category).toList();
  }

  List<KeyboardShortcut> getAllShortcuts() {
    return _shortcuts.values.toList();
  }

  KeyboardShortcut? getShortcut(String id) {
    return _shortcuts[id];
  }

  void enableShortcut(String id) {
    final shortcut = _shortcuts[id];
    if (shortcut != null) {
      _shortcuts[id] = KeyboardShortcut(
        id: shortcut.id,
        name: shortcut.name,
        description: shortcut.description,
        keySet: shortcut.keySet,
        category: shortcut.category,
        action: shortcut.action,
        isEnabled: true,
        context: shortcut.context,
      );
    }
  }

  void disableShortcut(String id) {
    final shortcut = _shortcuts[id];
    if (shortcut != null) {
      _shortcuts[id] = KeyboardShortcut(
        id: shortcut.id,
        name: shortcut.name,
        description: shortcut.description,
        keySet: shortcut.keySet,
        category: shortcut.category,
        action: shortcut.action,
        isEnabled: false,
        context: shortcut.context,
      );
    }
  }

  String formatKeySet(LogicalKeySet keySet) {
    final keys = <String>[];
    
    for (final key in keySet.keys) {
      switch (key) {
        case LogicalKeyboardKey.control:
          keys.add('Ctrl');
          break;
        case LogicalKeyboardKey.shift:
          keys.add('Shift');
          break;
        case LogicalKeyboardKey.alt:
          keys.add('Alt');
          break;
        case LogicalKeyboardKey.meta:
          keys.add('Meta');
          break;
        case LogicalKeyboardKey.enter:
          keys.add('Enter');
          break;
        case LogicalKeyboardKey.f1:
        case LogicalKeyboardKey.f2:
        case LogicalKeyboardKey.f3:
        case LogicalKeyboardKey.f4:
        case LogicalKeyboardKey.f5:
        case LogicalKeyboardKey.f6:
        case LogicalKeyboardKey.f7:
        case LogicalKeyboardKey.f8:
        case LogicalKeyboardKey.f9:
        case LogicalKeyboardKey.f10:
        case LogicalKeyboardKey.f11:
        case LogicalKeyboardKey.f12:
          keys.add(key.keyLabel.toUpperCase());
          break;
        default:
          keys.add(key.keyLabel.toUpperCase());
      }
    }
    
    return keys.join(' + ');
  }

  // Action implementations
  void _navigateTo(String route) {
    if (_currentContext != null) {
      Navigator.of(_currentContext!).pushNamed(route);
    }
  }

  void _refreshSecurityData() {
    developer.log('Refreshing security data', name: 'KeyboardShortcuts');
    // Implement refresh logic
  }

  void _showCriticalAlerts() {
    developer.log('Showing critical alerts', name: 'KeyboardShortcuts');
    // Implement critical alerts filter
  }

  void _acknowledgeAllAlerts() {
    developer.log('Acknowledging all alerts', name: 'KeyboardShortcuts');
    // Implement acknowledge all logic
  }

  void _blockSelectedIP() {
    developer.log('Blocking selected IP', name: 'KeyboardShortcuts');
    // Implement IP blocking logic
  }

  void _newHuntQuery() {
    developer.log('Creating new hunt query', name: 'KeyboardShortcuts');
    // Implement new query logic
  }

  void _executeHuntQuery() {
    developer.log('Executing hunt query', name: 'KeyboardShortcuts');
    // Implement query execution logic
  }

  void _saveHuntQuery() {
    developer.log('Saving hunt query', name: 'KeyboardShortcuts');
    // Implement query save logic
  }

  void _newIncident() {
    developer.log('Creating new incident', name: 'KeyboardShortcuts');
    // Implement new incident logic
  }

  void _escalateIncident() {
    developer.log('Escalating incident', name: 'KeyboardShortcuts');
    // Implement incident escalation logic
  }

  void _resolveIncident() {
    developer.log('Resolving incident', name: 'KeyboardShortcuts');
    // Implement incident resolution logic
  }

  void _toggleFullscreen() {
    developer.log('Toggling fullscreen', name: 'KeyboardShortcuts');
    // Implement fullscreen toggle logic
  }

  void _addWidget() {
    developer.log('Adding widget', name: 'KeyboardShortcuts');
    // Implement add widget logic
  }

  void _exportDashboard() {
    developer.log('Exporting dashboard', name: 'KeyboardShortcuts');
    // Implement dashboard export logic
  }

  void _openGlobalSearch() {
    developer.log('Opening global search', name: 'KeyboardShortcuts');
    // Implement global search logic
  }

  void _showHelp() {
    developer.log('Showing help', name: 'KeyboardShortcuts');
    // Implement help dialog logic
  }

  void _openCommandPalette() {
    developer.log('Opening command palette', name: 'KeyboardShortcuts');
    // Implement command palette logic
  }

  void _showNotifications() {
    developer.log('Showing notifications', name: 'KeyboardShortcuts');
    // Implement notifications panel logic
  }

  void _executeQuickAction(int actionNumber) {
    developer.log('Executing quick action $actionNumber', name: 'KeyboardShortcuts');
    // Implement quick action logic based on actionNumber
  }

  void dispose() {
    _shortcutExecutedController.close();
  }
}

// Widget wrapper for keyboard shortcuts
class KeyboardShortcutsWrapper extends StatefulWidget {
  final Widget child;
  final KeyboardShortcutsService? shortcutsService;

  const KeyboardShortcutsWrapper({
    Key? key,
    required this.child,
    this.shortcutsService,
  }) : super(key: key);

  @override
  State<KeyboardShortcutsWrapper> createState() => _KeyboardShortcutsWrapperState();
}

class _KeyboardShortcutsWrapperState extends State<KeyboardShortcutsWrapper> {
  late KeyboardShortcutsService _shortcutsService;

  @override
  void initState() {
    super.initState();
    _shortcutsService = widget.shortcutsService ?? KeyboardShortcutsService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _shortcutsService.initialize(context);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        final handled = _shortcutsService.handleKeyEvent(event);
        return handled ? KeyEventResult.handled : KeyEventResult.ignored;
      },
      child: widget.child,
    );
  }
}

// Help dialog for keyboard shortcuts
class KeyboardShortcutsHelpDialog extends StatelessWidget {
  final KeyboardShortcutsService shortcutsService;

  const KeyboardShortcutsHelpDialog({
    Key? key,
    required this.shortcutsService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final shortcuts = shortcutsService.getAllShortcuts();
    final groupedShortcuts = <ShortcutCategory, List<KeyboardShortcut>>{};

    for (final shortcut in shortcuts) {
      groupedShortcuts.putIfAbsent(shortcut.category, () => []).add(shortcut);
    }

    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Keyboard Shortcuts',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  for (final category in ShortcutCategory.values)
                    if (groupedShortcuts.containsKey(category))
                      _buildCategorySection(context, category, groupedShortcuts[category]!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context, ShortcutCategory category, List<KeyboardShortcut> shortcuts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            _getCategoryName(category),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...shortcuts.map((shortcut) => _buildShortcutItem(context, shortcut)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildShortcutItem(BuildContext context, KeyboardShortcut shortcut) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              shortcut.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              shortcut.description,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              KeyboardShortcutsService().formatKeySet(shortcut.keySet),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(ShortcutCategory category) {
    switch (category) {
      case ShortcutCategory.navigation:
        return 'Navigation';
      case ShortcutCategory.security_operations:
        return 'Security Operations';
      case ShortcutCategory.threat_hunting:
        return 'Threat Hunting';
      case ShortcutCategory.incident_response:
        return 'Incident Response';
      case ShortcutCategory.dashboard:
        return 'Dashboard';
      case ShortcutCategory.general:
        return 'General';
    }
  }
}
