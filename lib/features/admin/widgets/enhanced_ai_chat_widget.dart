import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ai_security_copilot_service.dart';
import '../services/enhanced_ai_models.dart';
import 'ai_settings_dialog.dart';
import 'package:intl/intl.dart';

class EnhancedAIChatWidget extends StatefulWidget {
  const EnhancedAIChatWidget({Key? key}) : super(key: key);

  @override
  State<EnhancedAIChatWidget> createState() => _EnhancedAIChatWidgetState();
}

class _EnhancedAIChatWidgetState extends State<EnhancedAIChatWidget>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  bool _isProcessing = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    
    _messageController.clear();
    setState(() => _isProcessing = true);
    
    final aiService = context.read<AISecurityCopilotService>();
    
    try {
      if (aiService.settings.deepReasoningEnabled) {
        await aiService.performDeepReasoning(message);
      } else {
        await aiService.processNaturalLanguageQuery(message);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChatTab(),
                _buildAlertsTab(),
                _buildPoliciesTab(),
                _buildActionsTab(),
                _buildInsightsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enhanced AI Security Assistant',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Deep reasoning • Self-learning • Automated actions',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AISettingsDialog(),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: Colors.blue,
      unselectedLabelColor: Colors.grey,
      indicatorColor: Colors.blue,
      tabs: const [
        Tab(icon: Icon(Icons.chat), text: 'Chat'),
        Tab(icon: Icon(Icons.warning), text: 'Alerts'),
        Tab(icon: Icon(Icons.policy), text: 'Policies'),
        Tab(icon: Icon(Icons.bolt), text: 'Actions'),
        Tab(icon: Icon(Icons.insights), text: 'Insights'),
      ],
    );
  }
  
  Widget _buildChatTab() {
    return Column(
      children: [
        Expanded(
          child: Consumer<AISecurityCopilotService>(
            builder: (context, aiService, _) {
              final analyses = aiService.deepAnalyses;
              
              if (analyses.isEmpty && !_isProcessing) {
                return const Center(
                  child: Text('Start a conversation with your AI assistant'),
                );
              }
              
              if (_isProcessing) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Analyzing with deep reasoning...'),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: analyses.length,
                itemBuilder: (context, index) {
                  return _buildAnalysisCard(analyses[index]);
                },
              );
            },
          ),
        ),
        _buildInputArea(),
      ],
    );
  }
  
  Widget _buildAlertsTab() {
    return Consumer<AISecurityCopilotService>(
      builder: (context, aiService, _) {
        final activities = aiService.suspiciousActivities;
        
        if (activities.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text('No suspicious activities detected'),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            return _buildSuspiciousActivityCard(activities[index]);
          },
        );
      },
    );
  }
  
  Widget _buildPoliciesTab() {
    return Consumer<AISecurityCopilotService>(
      builder: (context, aiService, _) {
        final suggestions = aiService.policySuggestions;
        
        if (suggestions.isEmpty) {
          return const Center(
            child: Text('No policy suggestions available'),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            return _buildPolicyCard(suggestions[index]);
          },
        );
      },
    );
  }
  
  Widget _buildActionsTab() {
    return Consumer<AISecurityCopilotService>(
      builder: (context, aiService, _) {
        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                labelColor: Colors.blue,
                tabs: [
                  Tab(text: 'Pending'),
                  Tab(text: 'Executed'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildPendingActions(aiService.pendingActions),
                    _buildExecutedActions(aiService.executedActions),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildInsightsTab() {
    return Consumer<AISecurityCopilotService>(
      builder: (context, aiService, _) {
        final theme = Theme.of(context);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Assistant',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  foreground: Paint()
                    ..shader = LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        Colors.purple,
                      ],
                    ).createShader(
                      const Rect.fromLTWH(0, 0, 200, 70),
                    ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your friendly AI companion - Ask me anything!',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              _buildInsightCard(
                'Total Analyses',
                aiService.deepAnalyses.length.toString(),
                Icons.analytics,
                Colors.blue,
              ),
              _buildInsightCard(
                'Threats Detected',
                aiService.suspiciousActivities.length.toString(),
                Icons.warning,
                Colors.orange,
              ),
              _buildInsightCard(
                'Actions Executed',
                aiService.executedActions.length.toString(),
                Icons.bolt,
                Colors.green,
              ),
              _buildInsightCard(
                'Active Policies',
                aiService.policySuggestions.length.toString(),
                Icons.policy,
                Colors.purple,
              ),
              const SizedBox(height: 16),
              _buildLearningStatus(aiService),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildAnalysisCard(DeepReasoningAnalysis analysis) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(
          Icons.psychology,
          color: _getRiskColor(analysis.riskLevel),
        ),
        title: Text(analysis.query),
        subtitle: Text(
          'Risk: ${analysis.riskLevel} • ${DateFormat('HH:mm').format(analysis.timestamp)}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(analysis.analysis),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      label: Text('Confidence: ${(analysis.confidenceScore * 100).toStringAsFixed(0)}%'),
                      backgroundColor: Colors.blue.shade100,
                    ),
                    if (analysis.recommendations.isNotEmpty)
                      Chip(
                        label: Text('${analysis.recommendations.length} recommendations'),
                        backgroundColor: Colors.green.shade100,
                      ),
                    if (analysis.suggestedActions.isNotEmpty)
                      Chip(
                        label: Text('${analysis.suggestedActions.length} actions'),
                        backgroundColor: Colors.orange.shade100,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSuspiciousActivityCard(SuspiciousActivity activity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          Icons.warning,
          color: activity.severity == 'High' ? Colors.red : Colors.orange,
        ),
        title: Text(activity.description),
        subtitle: Text(
          '${activity.type} • Score: ${(activity.anomalyScore * 100).toStringAsFixed(0)}%',
        ),
        trailing: Text(
          DateFormat('HH:mm').format(activity.detectedAt),
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ),
    );
  }
  
  Widget _buildPolicyCard(PolicySuggestion policy) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.policy, color: Colors.purple),
        title: Text(policy.title),
        subtitle: Text(policy.description),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              policy.impact,
              style: TextStyle(
                color: _getImpactColor(policy.impact),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            Text(
              'Priority: ${(policy.priority * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPendingActions(List<AutomatedAction> actions) {
    if (actions.isEmpty) {
      return const Center(child: Text('No pending actions'));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(Icons.pending, color: _getRiskColor(action.riskLevel)),
            title: Text(action.description),
            subtitle: Text('${action.type} • ${action.riskLevel} risk'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => _rejectAction(action),
                ),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => _approveAction(action),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildExecutedActions(List<AutomatedAction> actions) {
    if (actions.isEmpty) {
      return const Center(child: Text('No executed actions'));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return Card(
          color: Colors.green.shade50,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text(action.description),
            subtitle: Text('${action.type} • ${action.riskLevel} risk'),
            trailing: const Text('Executed', style: TextStyle(color: Colors.green)),
          ),
        );
      },
    );
  }
  
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Ask me anything...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.blue,
            radius: 24,
            child: IconButton(
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send, color: Colors.white),
              onPressed: _isProcessing ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInsightCard(String title, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        trailing: Text(
          value,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }
  
  Widget _buildLearningStatus(AISecurityCopilotService aiService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Learning Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildStatusRow(
              'Deep Reasoning',
              aiService.settings.deepReasoningEnabled,
            ),
            _buildStatusRow(
              'Self-Learning',
              aiService.settings.selfLearningEnabled,
            ),
            _buildStatusRow(
              'Suspicious Detection',
              aiService.settings.suspiciousActivityDetectionEnabled,
            ),
            _buildStatusRow(
              'Auto-Actions',
              aiService.settings.autoActionsEnabled,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusRow(String label, bool isEnabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isEnabled ? Icons.check_circle : Icons.cancel,
            color: isEnabled ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isEnabled ? Colors.black : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'critical':
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  
  Color _getImpactColor(String impact) {
    switch (impact.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow.shade700;
      default:
        return Colors.green;
    }
  }
  
  void _approveAction(AutomatedAction action) {
    // Execute the action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Executing: ${action.description}'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  void _rejectAction(AutomatedAction action) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Action rejected'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
