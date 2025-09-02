import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ai_security_copilot_service.dart';
import '../../../core/services/language_service.dart';
import 'package:intl/intl.dart';

class AISecurityCopilotPage extends StatefulWidget {
  const AISecurityCopilotPage({Key? key}) : super(key: key);

  @override
  State<AISecurityCopilotPage> createState() => _AISecurityCopilotPageState();
}

class _AISecurityCopilotPageState extends State<AISecurityCopilotPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _queryController = TextEditingController();
  List<Map<String, dynamic>> _currentResults = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AISecurityCopilotService, LanguageService>(
      builder: (context, copilotService, languageService, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('AI Security Copilot'),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: [
                Tab(text: 'Natural Language Query'),
                Tab(text: 'Threat Analysis'),
                Tab(text: 'Predictive Threats'),
                Tab(text: 'Auto Hunt Results'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildNaturalLanguageQuery(copilotService),
              _buildThreatAnalysis(copilotService),
              _buildPredictiveThreats(copilotService),
              _buildAutoHuntResults(copilotService),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNaturalLanguageQuery(AISecurityCopilotService service) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Natural Language Security Query',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 8),
              Text(
                'Ask security questions in plain English',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      decoration: InputDecoration(
                        hintText: 'e.g., "Show me all suspicious login attempts from Russia in the last week"',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                      onSubmitted: (_) => _executeQuery(service),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: service.isAnalyzing ? null : () => _executeQuery(service),
                    icon: service.isAnalyzing 
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.search),
                    label: Text('Search'),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  _buildQueryChip('Suspicious logins', service),
                  _buildQueryChip('Failed attempts last week', service),
                  _buildQueryChip('Data exfiltration attempts', service),
                  _buildQueryChip('Unusual behavior patterns', service),
                  _buildQueryChip('Threats from China', service),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _currentResults.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.query_stats, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Enter a query to search security events',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: _currentResults.length,
                itemBuilder: (context, index) {
                  final result = _currentResults[index];
                  return _buildResultCard(result);
                },
              ),
        ),
      ],
    );
  }

  Widget _buildQueryChip(String query, AISecurityCopilotService service) {
    return ActionChip(
      label: Text(query),
      onPressed: () {
        _queryController.text = query;
        _executeQuery(service);
      },
    );
  }

  void _executeQuery(AISecurityCopilotService service) async {
    if (_queryController.text.isEmpty) return;
    
    final results = await service.processNaturalLanguageQuery(_queryController.text);
    setState(() {
      _currentResults = results;
    });
  }

  Widget _buildResultCard(Map<String, dynamic> result) {
    final type = result['type'] ?? 'unknown';
    IconData icon;
    Color color;
    
    switch (type) {
      case 'suspicious_login':
        icon = Icons.warning_amber;
        color = Colors.orange;
        break;
      case 'geo_threat':
        icon = Icons.public;
        color = Colors.red;
        break;
      case 'failed_attempt':
        icon = Icons.block;
        color = Colors.deepOrange;
        break;
      case 'anomaly':
        icon = Icons.psychology;
        color = Colors.purple;
        break;
      case 'data_exfiltration':
        icon = Icons.cloud_upload;
        color = Colors.red[700]!;
        break;
      default:
        icon = Icons.info;
        color = Colors.blue;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(_formatResultTitle(result)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatResultDescription(result)),
            SizedBox(height: 4),
            if (result['timestamp'] != null)
              Text(
                DateFormat('MMM d, y HH:mm').format(result['timestamp']),
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        trailing: result['severity'] != null || result['risk_score'] != null
          ? _buildSeverityBadge(result['severity'] ?? _getRiskLevel(result['risk_score']))
          : null,
        onTap: () => _showDetailDialog(result),
      ),
    );
  }

  String _formatResultTitle(Map<String, dynamic> result) {
    final type = result['type'] ?? 'unknown';
    switch (type) {
      case 'suspicious_login':
        return 'Suspicious Login: ${result['username'] ?? 'Unknown'}';
      case 'geo_threat':
        return '${result['threat_type']} from ${result['source_country']}';
      case 'failed_attempt':
        return 'Failed Login: ${result['username']}';
      case 'anomaly':
        return result['anomaly_type'] ?? 'Anomaly Detected';
      case 'data_exfiltration':
        return 'Data Exfiltration to ${result['destination']}';
      default:
        return 'Security Event';
    }
  }

  String _formatResultDescription(Map<String, dynamic> result) {
    final type = result['type'] ?? 'unknown';
    switch (type) {
      case 'suspicious_login':
        return 'From ${result['source_ip']} (${result['country']}) - ${result['attempts']} attempts';
      case 'geo_threat':
        return 'Target: ${result['target_system']} - ${result['blocked'] == true ? 'Blocked' : 'Active'}';
      case 'failed_attempt':
        return 'Reason: ${result['reason']} - ${result['consecutive_failures']} consecutive failures';
      case 'anomaly':
        return 'Deviation: ${result['baseline_deviation']} - Score: ${(result['anomaly_score'] * 100).toStringAsFixed(0)}%';
      case 'data_exfiltration':
        return '${result['data_size_mb']} MB - ${result['sensitive_data'] == true ? 'Sensitive Data' : 'Regular Data'}';
      default:
        return result['description'] ?? 'No description available';
    }
  }

  String _getRiskLevel(double? score) {
    if (score == null) return 'low';
    if (score > 0.8) return 'critical';
    if (score > 0.6) return 'high';
    if (score > 0.4) return 'medium';
    return 'low';
  }

  Widget _buildSeverityBadge(String severity) {
    Color color;
    switch (severity.toLowerCase()) {
      case 'critical':
        color = Colors.red;
        break;
      case 'high':
        color = Colors.orange;
        break;
      case 'medium':
        color = Colors.yellow[700]!;
        break;
      case 'low':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        severity.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildThreatAnalysis(AISecurityCopilotService service) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: service.isAnalyzing ? null : () async {
              final analysis = await service.analyzeThreat('Current security posture analysis');
              _showAnalysisDialog(analysis);
            },
            icon: Icon(Icons.analytics),
            label: Text('Run Threat Analysis'),
          ),
        ),
        Expanded(
          child: service.analyses.isEmpty
            ? Center(child: Text('No analyses performed yet'))
            : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: service.analyses.length,
                itemBuilder: (context, index) {
                  final analysis = service.analyses[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 16),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: _getRiskColor(analysis.riskLevel).withOpacity(0.2),
                        child: Icon(
                          Icons.analytics,
                          color: _getRiskColor(analysis.riskLevel),
                        ),
                      ),
                      title: Text('Analysis: ${analysis.query}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('MMM d, y HH:mm').format(analysis.timestamp),
                            style: TextStyle(fontSize: 12),
                          ),
                          SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: analysis.confidenceScore,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getConfidenceColor(analysis.confidenceScore),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Confidence: ${(analysis.confidenceScore * 100).toStringAsFixed(0)}%',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Analysis:', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 8),
                              Text(analysis.analysis),
                              SizedBox(height: 16),
                              Text('Recommendations:', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 8),
                              ...analysis.recommendations.map((rec) => Padding(
                                padding: EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.check_circle, size: 16, color: Colors.green),
                                    SizedBox(width: 8),
                                    Expanded(child: Text(rec)),
                                  ],
                                ),
                              )),
                              SizedBox(height: 16),
                              Text('Affected Assets:', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: analysis.affectedAssets.map((asset) => Chip(
                                  label: Text(asset, style: TextStyle(fontSize: 12)),
                                  backgroundColor: Colors.grey[200],
                                )).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildPredictiveThreats(AISecurityCopilotService service) {
    return service.predictions.isEmpty
      ? Center(child: Text('No predictive threats identified'))
      : ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: service.predictions.length,
          itemBuilder: (context, index) {
            final prediction = service.predictions[index];
            return Card(
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: _getProbabilityColor(prediction.probability),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            prediction.threatType,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        _buildProbabilityBadge(prediction.probability),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Predicted: ${DateFormat('MMM d, y HH:mm').format(prediction.predictedTime)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 12),
                    Text('Attack Vector: ${prediction.attackVector}'),
                    SizedBox(height: 12),
                    Text('Vulnerabilities:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    ...prediction.vulnerabilities.map((vuln) => Padding(
                      padding: EdgeInsets.only(left: 16, bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.bug_report, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text(vuln),
                        ],
                      ),
                    )),
                    SizedBox(height: 12),
                    ExpansionTile(
                      title: Text('Recommended Mitigations'),
                      children: [
                        _buildMitigationSection('Immediate', prediction.mitigations['immediate']),
                        _buildMitigationSection('Short Term', prediction.mitigations['short_term']),
                        _buildMitigationSection('Long Term', prediction.mitigations['long_term']),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
  }

  Widget _buildMitigationSection(String title, List<dynamic>? items) {
    if (items == null || items.isEmpty) return SizedBox.shrink();
    
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.arrow_right, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text(item.toString())),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildProbabilityBadge(double probability) {
    final percentage = (probability * 100).toStringAsFixed(0);
    final color = _getProbabilityColor(probability);
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        '$percentage%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAutoHuntResults(AISecurityCopilotService service) {
    return service.huntResults.isEmpty
      ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.radar, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Automated threat hunting is active'),
              Text('No anomalies detected', style: TextStyle(color: Colors.grey)),
            ],
          ),
        )
      : ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: service.huntResults.length,
          itemBuilder: (context, index) {
            final result = service.huntResults[index];
            return Card(
              margin: EdgeInsets.only(bottom: 16),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.purple.withOpacity(0.2),
                  child: Icon(Icons.radar, color: Colors.purple),
                ),
                title: Text(result.anomalyType),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(result.description),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          DateFormat('HH:mm:ss').format(result.detectedAt),
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        SizedBox(width: 16),
                        if (result.autoInvestigated)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Auto-Investigated',
                              style: TextStyle(fontSize: 10, color: Colors.green),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                trailing: CircularProgressIndicator(
                  value: result.anomalyScore,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getAnomalyColor(result.anomalyScore),
                  ),
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Evidence:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        ...result.evidence.entries.map((e) => Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              SizedBox(width: 100, child: Text('${e.key}:')),
                              Expanded(child: Text(e.value.toString())),
                            ],
                          ),
                        )),
                        SizedBox(height: 16),
                        Text('Investigation Steps:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        ...result.investigationSteps.asMap().entries.map((e) => Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 10,
                                child: Text('${e.key + 1}', style: TextStyle(fontSize: 10)),
                              ),
                              SizedBox(width: 8),
                              Expanded(child: Text(e.value)),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
  }

  Color _getRiskColor(String level) {
    switch (level.toLowerCase()) {
      case 'critical': return Colors.red;
      case 'high': return Colors.orange;
      case 'medium': return Colors.yellow[700]!;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.8) return Colors.green;
    if (confidence > 0.6) return Colors.blue;
    if (confidence > 0.4) return Colors.orange;
    return Colors.red;
  }

  Color _getProbabilityColor(double probability) {
    if (probability > 0.7) return Colors.red;
    if (probability > 0.5) return Colors.orange;
    if (probability > 0.3) return Colors.yellow[700]!;
    return Colors.green;
  }

  Color _getAnomalyColor(double score) {
    if (score > 0.8) return Colors.red;
    if (score > 0.6) return Colors.orange;
    return Colors.yellow[700]!;
  }

  void _showDetailDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Event Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: result.entries.map((e) => Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      '${e.key}:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(child: Text(e.value.toString())),
                ],
              ),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAnalysisDialog(ThreatAnalysis analysis) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Threat Analysis Complete'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Risk Level: ${analysis.riskLevel.toUpperCase()}'),
              SizedBox(height: 8),
              Text('Confidence: ${(analysis.confidenceScore * 100).toStringAsFixed(0)}%'),
              SizedBox(height: 16),
              Text(analysis.analysis),
              SizedBox(height: 16),
              Text('Recommendations:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...analysis.recommendations.map((rec) => Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('• $rec'),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
