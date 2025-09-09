import 'package:flutter/material.dart';
import 'package:clean_flutter/features/admin/services/ai_automation_workflows.dart';
import 'package:clean_flutter/features/admin/services/ai_models.dart';

void main() {
  runApp(TestApp());
}

class TestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Workflows Test',
      theme: ThemeData.dark(),
      home: WorkflowTestPage(),
    );
  }
}

class WorkflowTestPage extends StatefulWidget {
  @override
  _WorkflowTestPageState createState() => _WorkflowTestPageState();
}

class _WorkflowTestPageState extends State<WorkflowTestPage> {
  final AIAutomationWorkflows _workflowService = AIAutomationWorkflows();
  List<Workflow> _workflows = [];
  List<WorkflowExecution> _history = [];
  String _status = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      await _workflowService.initialize();
      setState(() {
        _workflows = _workflowService.getWorkflows();
        _history = _workflowService.getExecutionHistory();
        _status = 'Ready - ${_workflows.length} workflows loaded';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _runWorkflow(String workflowId) async {
    setState(() {
      _status = 'Executing workflow...';
    });

    try {
      await _workflowService.executeWorkflow(workflowId, {
        'source': 'manual_test',
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Wait for execution
      await Future.delayed(Duration(seconds: 3));
      
      setState(() {
        _history = _workflowService.getExecutionHistory();
        _status = 'Workflow executed successfully';
      });
    } catch (e) {
      setState(() {
        _status = 'Execution error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Workflows Test'),
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: Colors.blue.shade900,
            child: Text(
              _status,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          
          // Workflows section
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                Text(
                  'Available Workflows',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 16),
                ..._workflows.map((workflow) => Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(workflow.name),
                    subtitle: Text('${workflow.type} - ${workflow.description}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(workflow.enabled ? 'Enabled' : 'Disabled'),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: workflow.enabled 
                            ? () => _runWorkflow(workflow.id)
                            : null,
                          child: Text('Run'),
                        ),
                      ],
                    ),
                  ),
                )),
                
                SizedBox(height: 32),
                Text(
                  'Execution History',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 16),
                
                if (_history.isEmpty)
                  Text('No executions yet')
                else
                  ..._history.take(5).map((execution) => Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text('Workflow: ${execution.workflowId}'),
                      subtitle: Text(
                        'Status: ${execution.status}\n'
                        'Started: ${execution.startTime}\n'
                        '${execution.endTime != null ? 'Duration: ${execution.endTime!.difference(execution.startTime).inSeconds}s' : 'Running...'}'
                      ),
                      isThreeLine: true,
                    ),
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _workflowService.dispose();
    super.dispose();
  }
}
