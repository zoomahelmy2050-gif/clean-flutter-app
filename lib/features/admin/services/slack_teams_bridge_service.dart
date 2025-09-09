import 'package:flutter/foundation.dart';

class SlackTeamsBridgeService with ChangeNotifier {
  final List<Map<String, String>> _channels = [];

  List<Map<String, String>> get channels => List.unmodifiable(_channels);

  Future<bool> connectChannel({required String platform, required String channel}) async {
    _channels.add({'platform': platform, 'channel': channel});
    notifyListeners();
    return true;
  }

  Future<bool> sendMessage({required String platform, required String channel, required String text}) async {
    debugPrint('[$platform#$channel] $text');
    return true;
  }
}


