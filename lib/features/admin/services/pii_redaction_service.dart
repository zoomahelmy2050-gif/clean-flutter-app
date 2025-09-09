import 'package:flutter/foundation.dart';

class PiiRule {
  final String id;
  final String label;
  final RegExp pattern;
  final String replacement;
  PiiRule({required this.id, required this.label, required this.pattern, required this.replacement});
}

class PiiRedactionService with ChangeNotifier {
  final Map<String, PiiRule> _rules = {
    'email': PiiRule(
      id: 'email',
      label: 'Email Addresses',
      pattern: RegExp(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}", multiLine: true),
      replacement: '<redacted:email>',
    ),
    'phone': PiiRule(
      id: 'phone',
      label: 'Phone Numbers',
      pattern: RegExp(r"(?:\+\d{1,3}[ -]?)?(?:\(?\d{2,4}\)?[ -]?)?\d{3,4}[ -]?\d{3,4}", multiLine: true),
      replacement: '<redacted:phone>',
    ),
    'ip': PiiRule(
      id: 'ip',
      label: 'IP Addresses',
      pattern: RegExp(r"\b(?:(?:2(?:5[0-5]|[0-4]\d))|(?:1?\d?\d))(?:\.(?:(?:2(?:5[0-5]|[0-4]\d))|(?:1?\d?\d))){3}\b", multiLine: true),
      replacement: '<redacted:ip>',
    ),
    'credit_card': PiiRule(
      id: 'credit_card',
      label: 'Credit Cards',
      pattern: RegExp(r"\b(?:\d[ -]*?){13,19}\b", multiLine: true),
      replacement: '<redacted:cc>',
    ),
  };

  List<PiiRule> get availableRules => _rules.values.toList();

  String apply(String input, {required List<String> ruleIds}) {
    String result = input;
    for (final id in ruleIds) {
      final rule = _rules[id];
      if (rule == null) continue;
      result = result.replaceAll(rule.pattern, rule.replacement);
    }
    return result;
  }

  Map<String, dynamic> preview(String input, {required List<String> ruleIds}) {
    final Map<String, int> counts = {};
    for (final id in ruleIds) {
      final rule = _rules[id];
      if (rule == null) continue;
      counts[id] = rule.pattern.allMatches(input).length;
    }
    final output = apply(input, ruleIds: ruleIds);
    return {
      'counts': counts,
      'output': output,
    };
  }
}


