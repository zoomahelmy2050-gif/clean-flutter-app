import 'package:flutter/material.dart';
import '../services/favorites_service.dart';

class FavoriteButton extends StatefulWidget {
  final String itemId;
  final FavoritesService favoritesService;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showTooltip;
  final VoidCallback? onChanged;

  const FavoriteButton({
    super.key,
    required this.itemId,
    required this.favoritesService,
    this.size = 24,
    this.activeColor,
    this.inactiveColor,
    this.showTooltip = true,
    this.onChanged,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    widget.favoritesService.addListener(_onFavoritesChanged);
  }

  @override
  void dispose() {
    widget.favoritesService.removeListener(_onFavoritesChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) setState(() {});
  }

  void _toggleFavorite() async {
    await widget.favoritesService.toggleFavorite(widget.itemId);
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = widget.favoritesService.isFavorite(widget.itemId);
    final activeColor = widget.activeColor ?? Colors.red;
    final inactiveColor = widget.inactiveColor ?? 
        Theme.of(context).colorScheme.onSurfaceVariant;

    final button = ScaleTransition(
      scale: _scaleAnimation,
      child: IconButton(
        onPressed: _toggleFavorite,
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? activeColor : inactiveColor,
          size: widget.size,
        ),
      ),
    );

    if (widget.showTooltip) {
      return Tooltip(
        message: isFavorite ? 'Remove from favorites' : 'Add to favorites',
        child: button,
      );
    }

    return button;
  }
}

class PinButton extends StatefulWidget {
  final String itemId;
  final FavoritesService favoritesService;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showTooltip;
  final VoidCallback? onChanged;

  const PinButton({
    super.key,
    required this.itemId,
    required this.favoritesService,
    this.size = 20,
    this.activeColor,
    this.inactiveColor,
    this.showTooltip = true,
    this.onChanged,
  });

  @override
  State<PinButton> createState() => _PinButtonState();
}

class _PinButtonState extends State<PinButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.25,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    widget.favoritesService.addListener(_onFavoritesChanged);
  }

  @override
  void dispose() {
    widget.favoritesService.removeListener(_onFavoritesChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) setState(() {});
  }

  void _togglePin() async {
    await widget.favoritesService.togglePin(widget.itemId);
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isPinned = widget.favoritesService.isPinned(widget.itemId);
    final isFavorite = widget.favoritesService.isFavorite(widget.itemId);
    final activeColor = widget.activeColor ?? Colors.orange;
    final inactiveColor = widget.inactiveColor ?? 
        Theme.of(context).colorScheme.onSurfaceVariant;

    // Only show pin button if item is favorite
    if (!isFavorite) {
      return const SizedBox.shrink();
    }

    final button = RotationTransition(
      turns: _rotationAnimation,
      child: IconButton(
        onPressed: _togglePin,
        icon: Icon(
          isPinned ? Icons.push_pin : Icons.push_pin_outlined,
          color: isPinned ? activeColor : inactiveColor,
          size: widget.size,
        ),
      ),
    );

    if (widget.showTooltip) {
      return Tooltip(
        message: isPinned ? 'Unpin from top' : 'Pin to top',
        child: button,
      );
    }

    return button;
  }
}

class FavoritesPinIndicator extends StatelessWidget {
  final String itemId;
  final FavoritesService favoritesService;
  final double size;

  const FavoritesPinIndicator({
    super.key,
    required this.itemId,
    required this.favoritesService,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: favoritesService,
      builder: (context, child) {
        final isFavorite = favoritesService.isFavorite(itemId);
        final isPinned = favoritesService.isPinned(itemId);

        if (!isFavorite && !isPinned) {
          return const SizedBox.shrink();
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPinned) ...[
              Icon(
                Icons.push_pin,
                size: size,
                color: Colors.orange,
              ),
              const SizedBox(width: 4),
            ],
            if (isFavorite) ...[
              Icon(
                Icons.favorite,
                size: size,
                color: Colors.red,
              ),
            ],
          ],
        );
      },
    );
  }
}

class FavoritesActionButtons extends StatelessWidget {
  final String itemId;
  final FavoritesService favoritesService;
  final VoidCallback? onChanged;
  final bool showLabels;

  const FavoritesActionButtons({
    super.key,
    required this.itemId,
    required this.favoritesService,
    this.onChanged,
    this.showLabels = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: favoritesService,
      builder: (context, child) {
        final isFavorite = favoritesService.isFavorite(itemId);
        final isPinned = favoritesService.isPinned(itemId);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showLabels) ...[
              TextButton.icon(
                onPressed: () async {
                  await favoritesService.toggleFavorite(itemId);
                  onChanged?.call();
                },
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : null,
                ),
                label: Text(isFavorite ? 'Unfavorite' : 'Favorite'),
              ),
              if (isFavorite) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () async {
                    await favoritesService.togglePin(itemId);
                    onChanged?.call();
                  },
                  icon: Icon(
                    isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: isPinned ? Colors.orange : null,
                  ),
                  label: Text(isPinned ? 'Unpin' : 'Pin'),
                ),
              ],
            ] else ...[
              FavoriteButton(
                itemId: itemId,
                favoritesService: favoritesService,
                onChanged: onChanged,
              ),
              PinButton(
                itemId: itemId,
                favoritesService: favoritesService,
                onChanged: onChanged,
              ),
            ],
          ],
        );
      },
    );
  }
}
