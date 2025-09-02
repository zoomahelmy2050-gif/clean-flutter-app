import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/icon_service.dart';
import '../../locator.dart';

class IconPickerPage extends StatefulWidget {
  final String itemId;
  final String serviceName;
  final Function(IconData?, String?) onIconSelected;

  const IconPickerPage({
    super.key,
    required this.itemId,
    required this.serviceName,
    required this.onIconSelected,
  });

  @override
  State<IconPickerPage> createState() => _IconPickerPageState();
}

class _IconPickerPageState extends State<IconPickerPage> {
  late IconService _iconService;
  final TextEditingController _searchController = TextEditingController();
  Map<String, IconData> _filteredIcons = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _iconService = locator<IconService>();
    _filteredIcons = _iconService.getBuiltInIcons();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterIcons(String query) {
    setState(() {
      _filteredIcons = _iconService.searchBuiltInIcons(query);
    });
  }

  Future<void> _pickCustomIcon() async {
    setState(() => _isLoading = true);
    
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        await _iconService.setCustomIcon(widget.itemId, bytes);
        
        if (mounted) {
          widget.onIconSelected(Icons.image, widget.itemId);
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set custom icon: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _removeCustomIcon() async {
    await _iconService.removeCustomIcon(widget.itemId);
    if (mounted) {
      widget.onIconSelected(null, null);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCustomIcon = _iconService.hasCustomIcon(widget.itemId);
    final suggestions = _iconService.getIconSuggestions(widget.serviceName);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Icon'),
        elevation: 0,
        actions: [
          if (hasCustomIcon)
            IconButton(
              onPressed: _removeCustomIcon,
              icon: const Icon(Icons.delete),
              tooltip: 'Remove custom icon',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchBar(),
                if (hasCustomIcon) _buildCustomIconSection(),
                if (suggestions.isNotEmpty) _buildSuggestionsSection(suggestions),
                Expanded(child: _buildIconGrid()),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickCustomIcon,
        tooltip: 'Upload custom icon',
        child: const Icon(Icons.add_photo_alternate),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: _filterIcons,
        decoration: InputDecoration(
          hintText: 'Search icons...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _filterIcons('');
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomIconSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.image, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Custom Icon',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: FutureBuilder<String?>(
                  future: Future.value(_iconService.getCustomIconPath(widget.itemId)),
                  builder: (context, snapshot) {
                    final iconPath = snapshot.data;
                    if (iconPath != null && File(iconPath).existsSync()) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(iconPath),
                          fit: BoxFit.cover,
                        ),
                      );
                    }
                    return const Icon(Icons.image, color: Colors.grey);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current custom icon'),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        TextButton(
                          onPressed: _pickCustomIcon,
                          child: const Text('Replace'),
                        ),
                        TextButton(
                          onPressed: _removeCustomIcon,
                          child: const Text('Remove'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsSection(List<MapEntry<String, IconData>> suggestions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Suggested for "${widget.serviceName}"',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildIconTile(
                  suggestion.value,
                  suggestion.key,
                  isHighlighted: true,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildIconGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemCount: _filteredIcons.length,
        itemBuilder: (context, index) {
          final entry = _filteredIcons.entries.elementAt(index);
          return _buildIconTile(entry.value, entry.key);
        },
      ),
    );
  }

  Widget _buildIconTile(IconData icon, String name, {bool isHighlighted = false}) {
    return InkWell(
      onTap: () {
        widget.onIconSelected(icon, name);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isHighlighted 
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHighlighted
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: isHighlighted ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: isHighlighted ? 32 : 28,
              color: isHighlighted
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                color: isHighlighted
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
