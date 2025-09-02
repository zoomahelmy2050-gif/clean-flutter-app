import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/language_service.dart';
import '../../generated/app_localizations.dart';

class SecurityHubPage extends StatefulWidget {
  final String email;

  const SecurityHubPage({super.key, required this.email});

  @override
  State<SecurityHubPage> createState() => _SecurityHubPageState();
}

class _SecurityHubPageState extends State<SecurityHubPage> {
  Map<String, dynamic> _securityData = {
    'securityScore': 85,
    'activeSessions': 3,
    'recentAlerts': 2,
  };

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF0A1628),
          appBar: AppBar(
            title: Text(
              localizations.securityHub,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF1E3A5F),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Security Score Widget
                _buildSecurityScoreWidget(),
                
                const SizedBox(height: 24),
                
                // Additional Security Features can be added here in the future
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSecurityScoreWidget() {
    final score = _securityData['securityScore'] ?? 0;
    final color = score >= 80 ? Colors.green : score >= 60 ? Colors.orange : Colors.red;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircularProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeWidth: 8,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Security Score',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '$score/100',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    score >= 80 ? 'Excellent' : score >= 60 ? 'Good' : 'Needs Improvement',
                    style: TextStyle(color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
