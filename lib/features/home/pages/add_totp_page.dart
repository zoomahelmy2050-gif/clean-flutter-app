import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../core/services/totp_manager_service.dart';
import '../../../core/models/totp_entry.dart';
import '../../auth/services/totp_service.dart';

class AddTotpPage extends StatefulWidget {
  const AddTotpPage({Key? key}) : super(key: key);

  @override
  State<AddTotpPage> createState() => _AddTotpPageState();
}

class _AddTotpPageState extends State<AddTotpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _issuerController = TextEditingController();
  final _secretController = TextEditingController();
  final _totpService = TotpService();
  
  String? _selectedCategory;
  bool _isScanning = false;
  MobileScannerController? _scannerController;

  @override
  void dispose() {
    _nameController.dispose();
    _issuerController.dispose();
    _secretController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totpManager = Provider.of<TotpManagerService>(context);
    
    if (_isScanning) {
      return _buildQrScanner();
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add TOTP Code'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.qr_code_scanner,
                        size: 64,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Scan QR Code',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Scan a QR code from your authenticator app',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isScanning = true;
                          });
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Scan QR Code'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Manual Entry',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Account Name',
                          hintText: 'e.g., john@example.com',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an account name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _issuerController,
                        decoration: const InputDecoration(
                          labelText: 'Issuer',
                          hintText: 'e.g., Google, GitHub',
                          prefixIcon: Icon(Icons.business),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an issuer';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _secretController,
                        decoration: InputDecoration(
                          labelText: 'Secret Key',
                          hintText: 'Base32 encoded secret',
                          prefixIcon: const Icon(Icons.key),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _generateRandomSecret,
                            tooltip: 'Generate random secret',
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a secret key';
                          }
                          // Basic Base32 validation
                          if (!RegExp(r'^[A-Z2-7]+$').hasMatch(value.toUpperCase())) {
                            return 'Invalid Base32 format';
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category (Optional)',
                          prefixIcon: Icon(Icons.category),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('No Category'),
                          ),
                          ...totpManager.categories.map((category) {
                            return DropdownMenuItem(
                              value: category.id,
                              child: Row(
                                children: [
                                  Text(category.icon ?? '📁'),
                                  const SizedBox(width: 8),
                                  Text(category.name),
                                ],
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveEntry,
                      child: const Text('Add TOTP'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrScanner() {
    _scannerController ??= MobileScannerController();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              _isScanning = false;
            });
          },
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController!,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? code = barcode.rawValue;
                if (code != null && code.startsWith('otpauth://totp/')) {
                  _parseOtpAuth(code);
                  setState(() {
                    _isScanning = false;
                  });
                  break;
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Position QR code within frame',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _parseOtpAuth(String uri) {
    try {
      final parsedUri = Uri.parse(uri);
      final pathSegments = parsedUri.path.split('/');
      final label = pathSegments.last;
      
      // Decode label (might be URL encoded)
      final decodedLabel = Uri.decodeComponent(label);
      
      // Extract parameters
      final secret = parsedUri.queryParameters['secret'] ?? '';
      final issuer = parsedUri.queryParameters['issuer'] ?? '';
      
      // Parse label (format: issuer:account or just account)
      String accountName = decodedLabel;
      String issuerName = issuer;
      
      if (decodedLabel.contains(':')) {
        final parts = decodedLabel.split(':');
        if (issuer.isEmpty) {
          issuerName = parts[0];
        }
        accountName = parts.length > 1 ? parts[1] : parts[0];
      }
      
      // Update form fields
      _nameController.text = accountName;
      _issuerController.text = issuerName;
      _secretController.text = secret;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR code scanned successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to parse QR code: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _generateRandomSecret() {
    final secret = _totpService.generateBase32Secret();
    _secretController.text = secret;
  }

  void _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;
    
    final totpManager = Provider.of<TotpManagerService>(context, listen: false);
    
    try {
      // Verify the secret is valid by trying to generate a code
      final testCode = _totpService.generateCode(_secretController.text);
      
      await totpManager.addEntry(
        name: _nameController.text,
        issuer: _issuerController.text,
        secret: _secretController.text.toUpperCase(),
        category: _selectedCategory,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('TOTP code added successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add TOTP: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
