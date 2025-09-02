import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/migration_service.dart';
import '../../../core/services/backend_sync_service.dart';
import '../../../core/services/database_service.dart';
import '../../../locator.dart';

class DatabaseProviders extends StatelessWidget {
  final Widget child;

  const DatabaseProviders({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => MigrationService(locator<DatabaseService>()),
        ),
        ChangeNotifierProvider(
          create: (_) => BackendSyncService(locator<DatabaseService>()),
        ),
      ],
      child: child,
    );
  }
}
