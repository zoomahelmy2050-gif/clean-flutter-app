import 'dart:async';
import 'dart:math';
import 'dart:developer' as developer;

class SecurityROIMetric {
  final String metricId;
  final String name;
  final String category;
  final double value;
  final String unit;
  final DateTime timestamp;
  final Map<String, dynamic> breakdown;

  SecurityROIMetric({
    required this.metricId,
    required this.name,
    required this.category,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.breakdown = const {},
  });

  Map<String, dynamic> toJson() => {
    'metric_id': metricId,
    'name': name,
    'category': category,
    'value': value,
    'unit': unit,
    'timestamp': timestamp.toIso8601String(),
    'breakdown': breakdown,
  };
}

class CostBenefitAnalysis {
  final String analysisId;
  final String securityInitiative;
  final double implementationCost;
  final double annualOperatingCost;
  final double riskReductionValue;
  final double productivityGain;
  final double complianceSavings;
  final double totalBenefit;
  final double netROI;
  final DateTime analysisDate;

  CostBenefitAnalysis({
    required this.analysisId,
    required this.securityInitiative,
    required this.implementationCost,
    required this.annualOperatingCost,
    required this.riskReductionValue,
    required this.productivityGain,
    required this.complianceSavings,
    required this.totalBenefit,
    required this.netROI,
    required this.analysisDate,
  });

  Map<String, dynamic> toJson() => {
    'analysis_id': analysisId,
    'security_initiative': securityInitiative,
    'implementation_cost': implementationCost,
    'annual_operating_cost': annualOperatingCost,
    'risk_reduction_value': riskReductionValue,
    'productivity_gain': productivityGain,
    'compliance_savings': complianceSavings,
    'total_benefit': totalBenefit,
    'net_roi': netROI,
    'analysis_date': analysisDate.toIso8601String(),
  };
}

class SecurityInvestment {
  final String investmentId;
  final String name;
  final String category;
  final double amount;
  final DateTime startDate;
  final DateTime? endDate;
  final String status;
  final Map<String, dynamic> outcomes;

  SecurityInvestment({
    required this.investmentId,
    required this.name,
    required this.category,
    required this.amount,
    required this.startDate,
    this.endDate,
    required this.status,
    this.outcomes = const {},
  });

  Map<String, dynamic> toJson() => {
    'investment_id': investmentId,
    'name': name,
    'category': category,
    'amount': amount,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate?.toIso8601String(),
    'status': status,
    'outcomes': outcomes,
  };
}

class BusinessIntelligenceService {
  static final BusinessIntelligenceService _instance = BusinessIntelligenceService._internal();
  factory BusinessIntelligenceService() => _instance;
  BusinessIntelligenceService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  final List<SecurityROIMetric> _roiMetrics = [];
  final List<CostBenefitAnalysis> _costBenefitAnalyses = [];
  final List<SecurityInvestment> _securityInvestments = [];
  final Map<String, List<double>> _trendData = {};
  
  final StreamController<SecurityROIMetric> _metricController = StreamController.broadcast();
  final StreamController<CostBenefitAnalysis> _analysisController = StreamController.broadcast();

  Stream<SecurityROIMetric> get metricStream => _metricController.stream;
  Stream<CostBenefitAnalysis> get analysisStream => _analysisController.stream;

  Timer? _analyticsTimer;
  final Random _random = Random();

  Future<void> initialize() async {
    await _setupSecurityInvestments();
    await _generateInitialMetrics();
    await _performCostBenefitAnalyses();
    _startPeriodicAnalytics();
    _isInitialized = true;
    
    developer.log('Business Intelligence Service initialized', name: 'BusinessIntelligenceService');
  }

  Future<void> _setupSecurityInvestments() async {
    final investments = [
      SecurityInvestment(
        investmentId: 'inv_mfa_implementation',
        name: 'Multi-Factor Authentication Implementation',
        category: 'Authentication',
        amount: 150000,
        startDate: DateTime.now().subtract(const Duration(days: 365)),
        endDate: DateTime.now().subtract(const Duration(days: 300)),
        status: 'completed',
        outcomes: {
          'security_incidents_reduced': 85,
          'user_adoption_rate': 92,
          'support_tickets_reduced': 40,
        },
      ),
      SecurityInvestment(
        investmentId: 'inv_siem_platform',
        name: 'SIEM Platform Deployment',
        category: 'Monitoring',
        amount: 500000,
        startDate: DateTime.now().subtract(const Duration(days: 200)),
        endDate: DateTime.now().subtract(const Duration(days: 120)),
        status: 'completed',
        outcomes: {
          'threat_detection_improvement': 75,
          'incident_response_time_reduction': 60,
          'false_positive_reduction': 45,
        },
      ),
      SecurityInvestment(
        investmentId: 'inv_security_training',
        name: 'Employee Security Training Program',
        category: 'Training',
        amount: 75000,
        startDate: DateTime.now().subtract(const Duration(days: 180)),
        status: 'ongoing',
        outcomes: {
          'phishing_click_rate_reduction': 70,
          'security_awareness_score': 88,
          'policy_compliance_improvement': 55,
        },
      ),
      SecurityInvestment(
        investmentId: 'inv_endpoint_protection',
        name: 'Advanced Endpoint Protection',
        category: 'Endpoint Security',
        amount: 200000,
        startDate: DateTime.now().subtract(const Duration(days: 90)),
        status: 'ongoing',
        outcomes: {
          'malware_detection_rate': 98,
          'endpoint_incidents_reduced': 80,
          'remediation_time_improvement': 65,
        },
      ),
      SecurityInvestment(
        investmentId: 'inv_zero_trust',
        name: 'Zero Trust Architecture',
        category: 'Network Security',
        amount: 800000,
        startDate: DateTime.now().subtract(const Duration(days: 60)),
        status: 'in_progress',
        outcomes: {
          'lateral_movement_prevention': 90,
          'privileged_access_control': 95,
          'network_segmentation_coverage': 78,
        },
      ),
    ];

    _securityInvestments.addAll(investments);
  }

  Future<void> _generateInitialMetrics() async {
    final categories = [
      'Cost Avoidance',
      'Productivity Gains',
      'Compliance Savings',
      'Risk Reduction',
      'Operational Efficiency',
    ];

    for (final category in categories) {
      await _generateMetricsForCategory(category);
    }
  }

  Future<void> _generateMetricsForCategory(String category) async {
    switch (category) {
      case 'Cost Avoidance':
        await _generateCostAvoidanceMetrics();
        break;
      case 'Productivity Gains':
        await _generateProductivityMetrics();
        break;
      case 'Compliance Savings':
        await _generateComplianceMetrics();
        break;
      case 'Risk Reduction':
        await _generateRiskReductionMetrics();
        break;
      case 'Operational Efficiency':
        await _generateOperationalMetrics();
        break;
    }
  }

  Future<void> _generateCostAvoidanceMetrics() async {
    final metrics = [
      SecurityROIMetric(
        metricId: 'ca_breach_prevention',
        name: 'Data Breach Prevention Savings',
        category: 'Cost Avoidance',
        value: 2500000 + (_random.nextDouble() * 500000),
        unit: 'USD',
        timestamp: DateTime.now(),
        breakdown: {
          'regulatory_fines_avoided': 800000,
          'legal_costs_avoided': 400000,
          'reputation_damage_avoided': 900000,
          'business_disruption_avoided': 400000,
        },
      ),
      SecurityROIMetric(
        metricId: 'ca_downtime_prevention',
        name: 'System Downtime Prevention',
        category: 'Cost Avoidance',
        value: 1200000 + (_random.nextDouble() * 300000),
        unit: 'USD',
        timestamp: DateTime.now(),
        breakdown: {
          'lost_revenue_avoided': 800000,
          'recovery_costs_avoided': 250000,
          'customer_compensation_avoided': 150000,
        },
      ),
      SecurityROIMetric(
        metricId: 'ca_fraud_prevention',
        name: 'Fraud Prevention Savings',
        category: 'Cost Avoidance',
        value: 850000 + (_random.nextDouble() * 200000),
        unit: 'USD',
        timestamp: DateTime.now(),
        breakdown: {
          'financial_fraud_prevented': 600000,
          'identity_theft_prevention': 150000,
          'investigation_costs_avoided': 100000,
        },
      ),
    ];

    for (final metric in metrics) {
      _roiMetrics.add(metric);
      _metricController.add(metric);
    }
  }

  Future<void> _generateProductivityMetrics() async {
    final metrics = [
      SecurityROIMetric(
        metricId: 'pg_automation_gains',
        name: 'Security Automation Productivity Gains',
        category: 'Productivity Gains',
        value: 450000 + (_random.nextDouble() * 100000),
        unit: 'USD',
        timestamp: DateTime.now(),
        breakdown: {
          'manual_process_reduction': 200000,
          'faster_incident_response': 150000,
          'reduced_false_positives': 100000,
        },
      ),
      SecurityROIMetric(
        metricId: 'pg_sso_efficiency',
        name: 'Single Sign-On Efficiency Gains',
        category: 'Productivity Gains',
        value: 180000 + (_random.nextDouble() * 50000),
        unit: 'USD',
        timestamp: DateTime.now(),
        breakdown: {
          'password_reset_reduction': 80000,
          'login_time_savings': 60000,
          'help_desk_cost_reduction': 40000,
        },
      ),
      SecurityROIMetric(
        metricId: 'pg_secure_collaboration',
        name: 'Secure Collaboration Tools',
        category: 'Productivity Gains',
        value: 320000 + (_random.nextDouble() * 80000),
        unit: 'USD',
        timestamp: DateTime.now(),
        breakdown: {
          'meeting_efficiency_improvement': 150000,
          'secure_file_sharing_gains': 100000,
          'remote_work_enablement': 70000,
        },
      ),
    ];

    for (final metric in metrics) {
      _roiMetrics.add(metric);
      _metricController.add(metric);
    }
  }

  Future<void> _generateComplianceMetrics() async {
    final metrics = [
      SecurityROIMetric(
        metricId: 'cs_audit_savings',
        name: 'Audit and Compliance Savings',
        category: 'Compliance Savings',
        value: 380000 + (_random.nextDouble() * 70000),
        unit: 'USD',
        timestamp: DateTime.now(),
        breakdown: {
          'audit_preparation_efficiency': 150000,
          'automated_reporting_savings': 120000,
          'compliance_staff_optimization': 110000,
        },
      ),
      SecurityROIMetric(
        metricId: 'cs_regulatory_alignment',
        name: 'Regulatory Alignment Benefits',
        category: 'Compliance Savings',
        value: 250000 + (_random.nextDouble() * 50000),
        unit: 'USD',
        timestamp: DateTime.now(),
        breakdown: {
          'gdpr_compliance_efficiency': 100000,
          'sox_compliance_automation': 80000,
          'industry_standard_alignment': 70000,
        },
      ),
    ];

    for (final metric in metrics) {
      _roiMetrics.add(metric);
      _metricController.add(metric);
    }
  }

  Future<void> _generateRiskReductionMetrics() async {
    final metrics = [
      SecurityROIMetric(
        metricId: 'rr_cyber_insurance',
        name: 'Cyber Insurance Premium Reduction',
        category: 'Risk Reduction',
        value: 120000 + (_random.nextDouble() * 30000),
        unit: 'USD',
        timestamp: DateTime.now(),
        breakdown: {
          'premium_discount_earned': 80000,
          'deductible_reduction': 25000,
          'coverage_improvement_value': 15000,
        },
      ),
      SecurityROIMetric(
        metricId: 'rr_business_continuity',
        name: 'Business Continuity Improvement',
        category: 'Risk Reduction',
        value: 680000 + (_random.nextDouble() * 150000),
        unit: 'USD',
        timestamp: DateTime.now(),
        breakdown: {
          'disaster_recovery_readiness': 300000,
          'backup_system_reliability': 200000,
          'incident_recovery_speed': 180000,
        },
      ),
    ];

    for (final metric in metrics) {
      _roiMetrics.add(metric);
      _metricController.add(metric);
    }
  }

  Future<void> _generateOperationalMetrics() async {
    final metrics = [
      SecurityROIMetric(
        metricId: 'oe_staff_efficiency',
        name: 'Security Staff Efficiency Gains',
        category: 'Operational Efficiency',
        value: 290000 + (_random.nextDouble() * 60000),
        unit: 'USD',
        timestamp: DateTime.now(),
        breakdown: {
          'threat_hunting_automation': 120000,
          'incident_response_streamlining': 100000,
          'reporting_automation': 70000,
        },
      ),
      SecurityROIMetric(
        metricId: 'oe_vendor_consolidation',
        name: 'Security Vendor Consolidation',
        category: 'Operational Efficiency',
        value: 180000 + (_random.nextDouble() * 40000),
        unit: 'USD',
        timestamp: DateTime.now(),
        breakdown: {
          'license_cost_optimization': 100000,
          'integration_cost_reduction': 50000,
          'management_overhead_reduction': 30000,
        },
      ),
    ];

    for (final metric in metrics) {
      _roiMetrics.add(metric);
      _metricController.add(metric);
    }
  }

  Future<void> _performCostBenefitAnalyses() async {
    for (final investment in _securityInvestments) {
      await _generateCostBenefitAnalysis(investment);
    }
  }

  Future<void> _generateCostBenefitAnalysis(SecurityInvestment investment) async {
    final riskReductionValue = _calculateRiskReductionValue(investment);
    final productivityGain = _calculateProductivityGain(investment);
    final complianceSavings = _calculateComplianceSavings(investment);
    final totalBenefit = riskReductionValue + productivityGain + complianceSavings;
    final netROI = ((totalBenefit - investment.amount) / investment.amount) * 100;

    final analysis = CostBenefitAnalysis(
      analysisId: 'cba_${investment.investmentId}_${DateTime.now().millisecondsSinceEpoch}',
      securityInitiative: investment.name,
      implementationCost: investment.amount,
      annualOperatingCost: investment.amount * 0.15, // 15% of implementation cost
      riskReductionValue: riskReductionValue,
      productivityGain: productivityGain,
      complianceSavings: complianceSavings,
      totalBenefit: totalBenefit,
      netROI: netROI,
      analysisDate: DateTime.now(),
    );

    _costBenefitAnalyses.add(analysis);
    _analysisController.add(analysis);
  }

  double _calculateRiskReductionValue(SecurityInvestment investment) {
    switch (investment.category) {
      case 'Authentication':
        return investment.amount * 2.5; // High risk reduction for auth
      case 'Monitoring':
        return investment.amount * 3.0; // Very high for monitoring
      case 'Training':
        return investment.amount * 1.8; // Moderate for training
      case 'Endpoint Security':
        return investment.amount * 2.2; // Good for endpoint
      case 'Network Security':
        return investment.amount * 2.8; // High for network
      default:
        return investment.amount * 2.0;
    }
  }

  double _calculateProductivityGain(SecurityInvestment investment) {
    switch (investment.category) {
      case 'Authentication':
        return investment.amount * 0.8; // SSO productivity gains
      case 'Monitoring':
        return investment.amount * 1.2; // Automation benefits
      case 'Training':
        return investment.amount * 0.6; // Reduced incidents
      case 'Endpoint Security':
        return investment.amount * 0.9; // Less downtime
      case 'Network Security':
        return investment.amount * 0.7; // Network efficiency
      default:
        return investment.amount * 0.5;
    }
  }

  double _calculateComplianceSavings(SecurityInvestment investment) {
    switch (investment.category) {
      case 'Authentication':
        return investment.amount * 0.4; // Identity compliance
      case 'Monitoring':
        return investment.amount * 0.8; // Audit trail benefits
      case 'Training':
        return investment.amount * 0.3; // Awareness compliance
      case 'Endpoint Security':
        return investment.amount * 0.5; // Data protection
      case 'Network Security':
        return investment.amount * 0.6; // Network compliance
      default:
        return investment.amount * 0.3;
    }
  }

  void _startPeriodicAnalytics() {
    _analyticsTimer = Timer.periodic(const Duration(hours: 24), (_) {
      _updateTrendData();
      _generatePeriodicMetrics();
    });
  }

  Future<void> _updateTrendData() async {
    final categories = ['Cost Avoidance', 'Productivity Gains', 'Compliance Savings', 'Risk Reduction'];
    
    for (final category in categories) {
      _trendData[category] ??= [];
      
      final categoryMetrics = _roiMetrics.where((m) => m.category == category);
      final totalValue = categoryMetrics.fold<double>(0, (sum, m) => sum + m.value);
      
      _trendData[category]!.add(totalValue);
      
      // Keep only last 30 days of data
      if (_trendData[category]!.length > 30) {
        _trendData[category]!.removeAt(0);
      }
    }
  }

  Future<void> _generatePeriodicMetrics() async {
    // Generate new metrics with slight variations
    await _generateMetricsForCategory('Operational Efficiency');
  }

  Future<Map<String, dynamic>> generateROIDashboard() async {
    final totalROI = _calculateTotalROI();
    final categoryBreakdown = _calculateCategoryBreakdown();
    final investmentPerformance = _calculateInvestmentPerformance();
    final trendAnalysis = _calculateTrendAnalysis();

    return {
      'total_roi': totalROI,
      'category_breakdown': categoryBreakdown,
      'investment_performance': investmentPerformance,
      'trend_analysis': trendAnalysis,
      'key_insights': _generateKeyInsights(),
      'recommendations': _generateRecommendations(),
      'generated_at': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _calculateTotalROI() {
    final totalBenefits = _roiMetrics.fold<double>(0, (sum, m) => sum + m.value);
    final totalInvestments = _securityInvestments.fold<double>(0, (sum, i) => sum + i.amount);
    final roi = totalInvestments > 0 ? ((totalBenefits - totalInvestments) / totalInvestments) * 100 : 0;

    return {
      'total_benefits': totalBenefits,
      'total_investments': totalInvestments,
      'net_roi_percentage': roi,
      'payback_period_months': totalInvestments > 0 ? (totalInvestments / (totalBenefits / 12)) : 0,
    };
  }

  Map<String, dynamic> _calculateCategoryBreakdown() {
    final breakdown = <String, Map<String, dynamic>>{};
    
    for (final metric in _roiMetrics) {
      breakdown[metric.category] ??= {
        'total_value': 0.0,
        'metric_count': 0,
        'average_value': 0.0,
      };
      
      breakdown[metric.category]!['total_value'] = 
        (breakdown[metric.category]!['total_value'] as double) + metric.value;
      breakdown[metric.category]!['metric_count'] = 
        (breakdown[metric.category]!['metric_count'] as int) + 1;
    }
    
    // Calculate averages
    for (final category in breakdown.keys) {
      final total = breakdown[category]!['total_value'] as double;
      final count = breakdown[category]!['metric_count'] as int;
      breakdown[category]!['average_value'] = count > 0 ? total / count : 0;
    }
    
    return breakdown;
  }

  List<Map<String, dynamic>> _calculateInvestmentPerformance() {
    return _costBenefitAnalyses.map((analysis) => {
      'initiative': analysis.securityInitiative,
      'investment': analysis.implementationCost,
      'total_benefit': analysis.totalBenefit,
      'net_roi': analysis.netROI,
      'payback_period_months': analysis.implementationCost > 0 ? 
        (analysis.implementationCost / (analysis.totalBenefit / 12)) : 0,
      'risk_adjusted_return': analysis.netROI * 0.85, // 15% risk adjustment
    }).toList();
  }

  Map<String, List<double>> _calculateTrendAnalysis() {
    return Map.from(_trendData);
  }

  List<String> _generateKeyInsights() {
    final insights = <String>[];
    
    final totalROI = _calculateTotalROI();
    final roi = totalROI['net_roi_percentage'] as double;
    
    if (roi > 200) {
      insights.add('Exceptional security ROI of ${roi.toStringAsFixed(1)}% demonstrates strong investment value');
    } else if (roi > 100) {
      insights.add('Strong security ROI of ${roi.toStringAsFixed(1)}% shows positive investment returns');
    } else if (roi > 0) {
      insights.add('Positive security ROI of ${roi.toStringAsFixed(1)}% indicates growing investment value');
    }
    
    final bestCategory = _roiMetrics.groupBy((m) => m.category)
      .entries.map((e) => MapEntry(e.key, e.value.fold<double>(0, (sum, m) => sum + m.value)))
      .reduce((a, b) => a.value > b.value ? a : b);
    
    insights.add('${bestCategory.key} delivers the highest value at \$${(bestCategory.value / 1000000).toStringAsFixed(1)}M');
    
    return insights;
  }

  List<String> _generateRecommendations() {
    return [
      'Continue investing in high-ROI security initiatives like monitoring and authentication',
      'Expand security automation to maximize productivity gains',
      'Leverage compliance benefits to justify additional security investments',
      'Focus on risk reduction initiatives with measurable business impact',
      'Implement comprehensive metrics tracking for all security investments',
    ];
  }

  List<SecurityROIMetric> getROIMetrics({String? category}) {
    if (category != null) {
      return _roiMetrics.where((m) => m.category == category).toList();
    }
    return List.from(_roiMetrics);
  }

  List<CostBenefitAnalysis> getCostBenefitAnalyses() {
    return List.from(_costBenefitAnalyses);
  }

  List<SecurityInvestment> getSecurityInvestments() {
    return List.from(_securityInvestments);
  }

  Map<String, dynamic> getBusinessIntelligenceMetrics() {
    final totalROI = _calculateTotalROI();
    
    return {
      'total_roi_metrics': _roiMetrics.length,
      'total_investments': _securityInvestments.length,
      'total_analyses': _costBenefitAnalyses.length,
      'net_roi_percentage': totalROI['net_roi_percentage'],
      'total_benefits_usd': totalROI['total_benefits'],
      'total_investments_usd': totalROI['total_investments'],
      'categories_tracked': _roiMetrics.map((m) => m.category).toSet().length,
      'trend_data_points': _trendData.values.fold(0, (sum, list) => sum + list.length),
      'last_analysis': DateTime.now().toIso8601String(),
    };
  }

  Future<SecurityROIMetric> calculateSecurityROI(String investmentId, Map<String, dynamic> parameters) async {
    final investment = _securityInvestments.firstWhere(
      (inv) => inv.investmentId == investmentId,
      orElse: () => SecurityInvestment(
        investmentId: investmentId,
        name: 'Unknown Investment',
        category: 'General',
        amount: 10000.0,
        startDate: DateTime.now(),
        status: 'active',
      ),
    );
    
    final roi = SecurityROIMetric(
      metricId: 'roi_${DateTime.now().millisecondsSinceEpoch}',
      name: 'ROI Analysis for ${investment.name}',
      category: 'ROI',
      value: _random.nextDouble() * 200 + 50,
      unit: 'percentage',
      timestamp: DateTime.now(),
      breakdown: {
        'investment_amount': investment.amount,
        'cost_avoidance': investment.amount * 0.1,
        'efficiency_gains': investment.amount * 0.05,
        'compliance_savings': investment.amount * 0.03,
      },
    );
    
    _roiMetrics.add(roi);
    _metricController.add(roi);
    
    return roi;
  }

  Future<Map<String, dynamic>> generateExecutiveReport(String period, List<String> metrics) async {
    final report = {
      'period': period,
      'generated_at': DateTime.now().toIso8601String(),
      'total_investments': _securityInvestments.length,
      'total_roi': _roiMetrics.fold(0.0, (sum, metric) => sum + metric.value) / _roiMetrics.length,
      'cost_savings': _roiMetrics.fold(0.0, (sum, metric) => sum + (metric.breakdown['cost_avoidance'] ?? 0.0)),
      'risk_reduction': _roiMetrics.fold(0.0, (sum, metric) => sum + metric.value) / _roiMetrics.length,
      'key_metrics': metrics.map((metric) => {
        'name': metric,
        'value': _random.nextDouble() * 100,
        'trend': _random.nextBool() ? 'up' : 'down',
      }).toList(),
      'recommendations': [
        'Increase investment in high-ROI security measures',
        'Focus on automation to reduce operational costs',
        'Implement predictive analytics for threat prevention',
      ],
    };
    
    return report;
  }

  void dispose() {
    _analyticsTimer?.cancel();
    _metricController.close();
    _analysisController.close();
  }
}

extension _ListGroupBy<T> on List<T> {
  Map<K, List<T>> groupBy<K>(K Function(T) keyFunction) {
    final map = <K, List<T>>{};
    for (final item in this) {
      final key = keyFunction(item);
      map[key] ??= [];
      map[key]!.add(item);
    }
    return map;
  }
}
