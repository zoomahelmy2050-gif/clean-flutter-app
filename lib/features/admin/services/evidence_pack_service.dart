import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:clean_flutter/locator.dart';
import 'package:clean_flutter/core/services/xai_logger.dart';
import 'package:clean_flutter/core/services/advanced_login_security_service.dart';

class EvidencePackService with ChangeNotifier {
  Future<Map<String, dynamic>> generate({Map<String, dynamic>? incidentContext}) async {
    final xai = XaiLogger.instance.export(limit: 100);
    final sec = locator<AdvancedLoginSecurityService>();
    if (!sec.isInitialized) {
      await sec.initialize();
    }
    final attempts = sec.getRecentAttempts(limit: 50).map((a) => a.toJson()).toList();
    final stats = sec.getSecurityStats();
    final pack = {
      'generatedAt': DateTime.now().toIso8601String(),
      'incidentContext': incidentContext ?? {},
      'xaiLogs': xai,
      'securityStats': stats,
      'recentAttempts': attempts,
      'version': 1,
    };
    return pack;
  }

  String toPrettyJson(Map<String, dynamic> pack) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(pack);
  }
}


