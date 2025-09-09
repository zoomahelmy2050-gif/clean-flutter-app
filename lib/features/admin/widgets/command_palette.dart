import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef CommandAction = Future<void> Function(BuildContext context);

class CommandItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final CommandAction onRun;
  CommandItem({required this.title, required this.subtitle, required this.icon, required this.onRun});
}

class CommandPalette extends StatefulWidget {
  final List<CommandItem> commands;
  const CommandPalette({super.key, required this.commands});

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final TextEditingController _q = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.commands.where((c) => c.title.toLowerCase().contains(_query.toLowerCase()) || c.subtitle.toLowerCase().contains(_query.toLowerCase())).toList();
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _q,
                autofocus: true,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Type a command...'),
                onChanged: (v) => setState(() => _query = v),
                onSubmitted: (v) {
                  if (filtered.isNotEmpty) filtered.first.onRun(context);
                },
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final c = filtered[i];
                  return ListTile(
                    leading: Icon(c.icon),
                    title: Text(c.title),
                    subtitle: Text(c.subtitle),
                    onTap: () async {
                      await c.onRun(context);
                      if (mounted) Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GlobalCommandActionProvider {
  static List<CommandItem> provide(BuildContext context) {
    return [
      CommandItem(
        title: 'Go to Admin Security Center',
        subtitle: 'Navigation',
        icon: Icons.admin_panel_settings_outlined,
        onRun: (ctx) async {
          Navigator.of(ctx).pushNamed('/admin-security-center');
        },
      ),
    ];
  }
}

class GlobalCommandPaletteWrapper extends StatefulWidget {
  final Widget child;
  const GlobalCommandPaletteWrapper({required this.child});

  @override
  State<GlobalCommandPaletteWrapper> createState() => _GlobalCommandPaletteWrapperState();
}

class _GlobalCommandPaletteWrapperState extends State<GlobalCommandPaletteWrapper> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _openPalette() {
    final cmds = GlobalCommandActionProvider.provide(context);
    showDialog(context: context, builder: (_) => CommandPalette(commands: cmds));
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          final isMeta = event.isMetaPressed;
          final isCtrl = event.isControlPressed;
          if ((isMeta || isCtrl) && event.logicalKey == LogicalKeyboardKey.keyK) {
            _openPalette();
          }
        }
      },
      child: widget.child,
    );
  }
}


