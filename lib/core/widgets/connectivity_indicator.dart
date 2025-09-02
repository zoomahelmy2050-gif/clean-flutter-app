import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';

class ConnectivityIndicator extends StatelessWidget {
  const ConnectivityIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, child) {
        if (connectivity.isFullyConnected) {
          return const SizedBox.shrink(); // Hide when fully connected
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _getStatusColor(connectivity),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getStatusIcon(connectivity),
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                connectivity.connectionStatus,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (!connectivity.isOnline)
                const Text(
                  'Using cached data',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(ConnectivityService connectivity) {
    if (!connectivity.isOnline) return Colors.red.shade600;
    if (!connectivity.isBackendReachable) return Colors.orange.shade600;
    return Colors.green.shade600;
  }

  IconData _getStatusIcon(ConnectivityService connectivity) {
    if (!connectivity.isOnline) return Icons.wifi_off;
    if (!connectivity.isBackendReachable) return Icons.cloud_off;
    return Icons.wifi;
  }
}

class ConnectivityAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;

  const ConnectivityAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          title: Text(title),
          actions: actions,
          automaticallyImplyLeading: showBackButton,
        ),
        const ConnectivityIndicator(),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 32);
}
