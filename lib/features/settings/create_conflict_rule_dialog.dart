import 'package:flutter/material.dart';
import '../../core/models/conflict_models.dart';

class CreateConflictRuleDialog extends StatefulWidget {
  final Function(ConflictRule) onRuleCreated;

  const CreateConflictRuleDialog({Key? key, required this.onRuleCreated}) : super(key: key);

  @override
  State<CreateConflictRuleDialog> createState() => _CreateConflictRuleDialogState();
}

class _CreateConflictRuleDialogState extends State<CreateConflictRuleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedItemType = 'Document';
  ConflictType _selectedConflictType = ConflictType.duplicateContent;
  ResolutionAction _selectedAction = ResolutionAction.keepBoth;
  int _priority = 5;
  bool _isEnabled = true;
  
  final List<String> _itemTypes = [
    'Document',
    'Image',
    'Video',
    'Audio',
    'Contact',
    'Calendar Event',
    'Note',
    'Bookmark',
    'File',
    'Folder',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            AppBar(
              title: const Text('Create Conflict Resolution Rule'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBasicInfoSection(),
                      const SizedBox(height: 24),
                      _buildConflictConfigSection(),
                      const SizedBox(height: 24),
                      _buildAdvancedOptionsSection(),
                      const SizedBox(height: 24),
                      _buildPreviewSection(),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: _createRule,
                    child: const Text('Create Rule'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Rule Name',
                hintText: 'Enter a descriptive name for this rule',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a rule name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe when and how this rule should be applied',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConflictConfigSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Conflict Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedItemType,
              decoration: const InputDecoration(
                labelText: 'Item Type',
                border: OutlineInputBorder(),
              ),
              items: _itemTypes.map((type) => DropdownMenuItem(
                value: type,
                child: Text(type),
              )).toList(),
              onChanged: (value) => setState(() => _selectedItemType = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ConflictType>(
              value: _selectedConflictType,
              decoration: const InputDecoration(
                labelText: 'Conflict Type',
                border: OutlineInputBorder(),
              ),
              items: ConflictType.values.map((type) => DropdownMenuItem(
                value: type,
                child: Text(_getConflictTypeDisplayName(type)),
              )).toList(),
              onChanged: (value) => setState(() => _selectedConflictType = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ResolutionAction>(
              value: _selectedAction,
              decoration: const InputDecoration(
                labelText: 'Resolution Action',
                border: OutlineInputBorder(),
              ),
              items: ResolutionAction.values.map((action) => DropdownMenuItem(
                value: action,
                child: Text(_getActionDisplayName(action)),
              )).toList(),
              onChanged: (value) => setState(() => _selectedAction = value!),
            ),
            const SizedBox(height: 16),
            Text(
              'Action Description: ${_getActionDescription(_selectedAction)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedOptionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Advanced Options',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Priority: $_priority'),
                      Slider(
                        value: _priority.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: _priority.toString(),
                        onChanged: (value) => setState(() => _priority = value.round()),
                      ),
                      Text(
                        'Higher priority rules are applied first',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Rule'),
              subtitle: const Text('Rule will be active and applied to conflicts'),
              value: _isEnabled,
              onChanged: (value) => setState(() => _isEnabled = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.preview, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Rule Preview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPreviewItem('Name', _nameController.text.isEmpty ? 'Not specified' : _nameController.text),
            _buildPreviewItem('Item Type', _selectedItemType),
            _buildPreviewItem('Conflict Type', _getConflictTypeDisplayName(_selectedConflictType)),
            _buildPreviewItem('Action', _getActionDisplayName(_selectedAction)),
            _buildPreviewItem('Priority', _priority.toString()),
            _buildPreviewItem('Status', _isEnabled ? 'Enabled' : 'Disabled'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rule Summary:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'When a ${_getConflictTypeDisplayName(_selectedConflictType).toLowerCase()} conflict occurs with $_selectedItemType items, ${_getActionDescription(_selectedAction).toLowerCase()}.',
                    style: TextStyle(color: Colors.blue[800]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _getConflictTypeDisplayName(ConflictType type) {
    switch (type) {
      case ConflictType.duplicateContent:
        return 'Duplicate Content';
      case ConflictType.modifiedContent:
        return 'Modified Content';
      case ConflictType.deletedContent:
        return 'Deleted Content';
      case ConflictType.nameConflict:
        return 'Name Conflict';
      case ConflictType.locationConflict:
        return 'Location Conflict';
      case ConflictType.permissionConflict:
        return 'Permission Conflict';
      case ConflictType.metadataConflict:
        return 'Metadata Conflict';
      case ConflictType.versionConflict:
        return 'Version Conflict';
      case ConflictType.dataModified:
        return 'Data Modified';
      case ConflictType.dataDeleted:
        return 'Data Deleted';
      case ConflictType.dataCreated:
        return 'Data Created';
      case ConflictType.versionMismatch:
        return 'Version Mismatch';
      case ConflictType.schemaConflict:
        return 'Schema Conflict';
    }
  }

  String _getActionDisplayName(ResolutionAction action) {
    switch (action) {
      case ResolutionAction.useLocal:
        return 'Use Local Version';
      case ResolutionAction.useRemote:
        return 'Use Remote Version';
      case ResolutionAction.keepLocal:
        return 'Keep Local Version';
      case ResolutionAction.keepRemote:
        return 'Keep Remote Version';
      case ResolutionAction.keepBoth:
        return 'Keep Both Versions';
      case ResolutionAction.merge:
        return 'Merge Versions';
      case ResolutionAction.skip:
        return 'Skip';
      case ResolutionAction.askUser:
        return 'Ask User';
      case ResolutionAction.newerWins:
        return 'Newer Wins';
      case ResolutionAction.userPreference:
        return 'User Preference';
      case ResolutionAction.skipItem:
        return 'Skip Item';
      case ResolutionAction.deleteItem:
        return 'Delete Item';
      case ResolutionAction.renameItem:
        return 'Rename Item';
    }
  }

  String _getActionDescription(ResolutionAction action) {
    switch (action) {
      case ResolutionAction.useLocal:
        return 'The local version will be used and the remote version will be discarded';
      case ResolutionAction.useRemote:
        return 'The remote version will be used and the local version will be replaced';
      case ResolutionAction.keepLocal:
        return 'The local version will be preserved and the remote version will be discarded';
      case ResolutionAction.keepRemote:
        return 'The remote version will be used and the local version will be replaced';
      case ResolutionAction.keepBoth:
        return 'Both versions will be kept with different names or locations';
      case ResolutionAction.merge:
        return 'The system will attempt to merge both versions automatically';
      case ResolutionAction.skip:
        return 'The conflict will be skipped and not resolved';
      case ResolutionAction.askUser:
        return 'The user will be prompted to choose how to resolve the conflict';
      case ResolutionAction.newerWins:
        return 'The newer version will be used automatically';
      case ResolutionAction.userPreference:
        return 'The user preference will determine the resolution';
      case ResolutionAction.skipItem:
        return 'The conflicting item will be skipped and not processed';
      case ResolutionAction.deleteItem:
        return 'The conflicting item will be deleted from both locations';
      case ResolutionAction.renameItem:
        return 'One of the conflicting items will be automatically renamed';
    }
  }

  void _createRule() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final rule = ConflictRule(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      description: _descriptionController.text,
      itemType: _selectedItemType,
      conflictType: _selectedConflictType,
      resolutionAction: _selectedAction,
      priority: _priority,
      enabled: _isEnabled,
      createdAt: DateTime.now(),
    );

    Navigator.pop(context);
    widget.onRuleCreated(rule);
  }
}
