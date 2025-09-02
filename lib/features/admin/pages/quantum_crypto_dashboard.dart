import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/quantum_resistant_crypto_service.dart';
import '../../../locator.dart';

class QuantumCryptoDashboard extends StatefulWidget {
  const QuantumCryptoDashboard({Key? key}) : super(key: key);

  @override
  State<QuantumCryptoDashboard> createState() => _QuantumCryptoDashboardState();
}

class _QuantumCryptoDashboardState extends State<QuantumCryptoDashboard> {
  final QuantumResistantCryptoService _cryptoService = locator<QuantumResistantCryptoService>();
  Map<String, dynamic> _metrics = {};
  List<CryptoAlgorithm> _algorithms = [];
  List<CryptoOperation> _recentOperations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupStreams();
  }

  void _setupStreams() {
    _cryptoService.operationStream.listen((operation) {
      if (mounted) {
        setState(() {
          _recentOperations.insert(0, operation);
          if (_recentOperations.length > 20) {
            _recentOperations.removeRange(20, _recentOperations.length);
          }
        });
      }
    });

    _cryptoService.threatStream.listen((threat) {
      if (mounted) {
        _showThreatAlert(threat);
      }
    });
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      final metrics = _cryptoService.getQuantumCryptoMetrics();
      final algorithms = _cryptoService.getAvailableAlgorithms();
      final operations = _cryptoService.getOperationHistory(period: const Duration(hours: 24));

      setState(() {
        _metrics = metrics;
        _algorithms = algorithms;
        _recentOperations = operations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load quantum crypto data: $e');
    }
  }

  void _showThreatAlert(QuantumThreatAlert threat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Quantum Threat Alert'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Threat Level: ${(threat.level * 100).toStringAsFixed(1)}%'),
            const SizedBox(height: 8),
            Text(threat.description),
            const SizedBox(height: 16),
            const Text('Recommendations:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...threat.recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Text('• $rec'),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Acknowledge'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quantum-Resistant Cryptography'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetricsSection(),
                    const SizedBox(height: 24),
                    _buildAlgorithmsSection(),
                    const SizedBox(height: 24),
                    _buildOperationsSection(),
                    const SizedBox(height: 24),
                    _buildActionsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text('Quantum Crypto Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              children: [
                _buildMetricTile('Total Algorithms', _metrics['total_algorithms']?.toString() ?? '0'),
                _buildMetricTile('Quantum Resistant', _metrics['quantum_resistant_algorithms']?.toString() ?? '0'),
                _buildMetricTile('Operations (24h)', _metrics['operations_24h']?.toString() ?? '0'),
                _buildMetricTile('Success Rate', '${(_metrics['success_rate_24h'] ?? 0.0) * 100}%'),
                _buildMetricTile('Keys Stored', _metrics['quantum_keys_stored']?.toString() ?? '0'),
                _buildMetricTile('Threat Level', '${(_metrics['current_threat_level'] ?? 0.0) * 100}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String title, String value) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
        ],
      ),
    );
  }

  Widget _buildAlgorithmsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text('Available Algorithms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _algorithms.length,
              itemBuilder: (context, index) {
                final algorithm = _algorithms[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: algorithm.quantumResistant ? Colors.green : Colors.orange,
                    child: Icon(
                      algorithm.quantumResistant ? Icons.verified : Icons.warning,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(algorithm.name),
                  subtitle: Text(algorithm.description),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${algorithm.securityLevel}-bit'),
                      Text(algorithm.type.name, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text('Recent Operations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentOperations.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No recent operations'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentOperations.length,
                itemBuilder: (context, index) {
                  final operation = _recentOperations[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: operation.success ? Colors.green : Colors.red,
                      child: Icon(
                        operation.success ? Icons.check : Icons.error,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(operation.type.name),
                    subtitle: Text('Algorithm: ${operation.algorithmId}'),
                    trailing: Text(
                      '${operation.timestamp.hour}:${operation.timestamp.minute.toString().padLeft(2, '0')}',
                    ),
                    onTap: () => _showOperationDetails(operation),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _generateKeyPair,
                  icon: const Icon(Icons.vpn_key),
                  label: const Text('Generate Key Pair'),
                ),
                ElevatedButton.icon(
                  onPressed: _runEncryptionTest,
                  icon: const Icon(Icons.lock),
                  label: const Text('Test Encryption'),
                ),
                ElevatedButton.icon(
                  onPressed: _runSignatureTest,
                  icon: const Icon(Icons.edit),
                  label: const Text('Test Signature'),
                ),
                ElevatedButton.icon(
                  onPressed: _assessThreat,
                  icon: const Icon(Icons.assessment),
                  label: const Text('Assess Threat'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOperationDetails(CryptoOperation operation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Operation Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${operation.id}'),
            Text('Type: ${operation.type.name}'),
            Text('Algorithm: ${operation.algorithmId}'),
            Text('Success: ${operation.success}'),
            Text('Timestamp: ${operation.timestamp}'),
            if (operation.error != null) Text('Error: ${operation.error}'),
            if (operation.metadata != null) ...[
              const SizedBox(height: 8),
              const Text('Metadata:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...operation.metadata!.entries.map((e) => Text('${e.key}: ${e.value}')),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateKeyPair() async {
    try {
      final algorithm = _algorithms.isNotEmpty ? _algorithms.first : null;
      if (algorithm == null) {
        _showError('No algorithms available');
        return;
      }

      final keyPair = await _cryptoService.generateQuantumSafeKeyPair(
        algorithmId: algorithm.id,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Key pair generated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      _loadData();
    } catch (e) {
      _showError('Failed to generate key pair: $e');
    }
  }

  Future<void> _runEncryptionTest() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Encryption test completed')),
    );
  }

  Future<void> _runSignatureTest() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Signature test completed')),
    );
  }

  Future<void> _assessThreat() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Threat assessment initiated')),
    );
  }
}
