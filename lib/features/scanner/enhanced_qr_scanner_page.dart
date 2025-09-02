import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/enhanced_qr_scanner_service.dart';
import '../../locator.dart';

class EnhancedQRScannerPage extends StatefulWidget {
  final Function(String) onQRScanned;

  const EnhancedQRScannerPage({
    super.key,
    required this.onQRScanned,
  });

  @override
  State<EnhancedQRScannerPage> createState() => _EnhancedQRScannerPageState();
}

class _EnhancedQRScannerPageState extends State<EnhancedQRScannerPage>
    with TickerProviderStateMixin {
  late EnhancedQRScannerService _scannerService;
  late AnimationController _animationController;
  late Animation<double> _animation;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  MobileScannerController? controller;
  bool _showHistory = false;
  bool _showSettings = false;

  @override
  void initState() {
    super.initState();
    _scannerService = locator<EnhancedQRScannerService>();
    _scannerService.addListener(_onScannerStateChanged);
    
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
    _animationController.repeat();
    
    _initializeScanner();
  }

  @override
  void dispose() {
    _scannerService.removeListener(_onScannerStateChanged);
    _animationController.dispose();
    controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeScanner() async {
    try {
      await _scannerService.initialize();
      _scannerService.startScanning();
      
      // Listen for scan results
      _scannerService.scanResultStream?.listen((result) {
        if (_scannerService.isValidTOTPQR(result.data)) {
          widget.onQRScanned(result.data);
          Navigator.pop(context);
        } else {
          _showInvalidQRDialog(result.data);
        }
      });
    } catch (e) {
      _showErrorDialog('Failed to initialize scanner: $e');
    }
  }

  void _onScannerStateChanged() {
    if (mounted) setState(() {});
  }

  void _onQRViewCreated(MobileScannerController controller) {
    this.controller = controller;
    _scannerService.setMobileScannerController(controller);
  }

  void _showInvalidQRDialog(String data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invalid QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This QR code is not a valid TOTP code.'),
            const SizedBox(height: 12),
            const Text('Scanned data:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                data,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Scanning'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: data));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('QR data copied to clipboard')),
              );
            },
            child: const Text('Copy Data'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scanner Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _scanFromImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        final result = await _scannerService.scanFromImage(image.path);
        if (result != null) {
          if (_scannerService.isValidTOTPQR(result)) {
            widget.onQRScanned(result);
            Navigator.pop(context);
          } else {
            _showInvalidQRDialog(result);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No QR code found in image')),
          );
        }
      }
    } catch (e) {
      _showErrorDialog('Failed to scan image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildQRView(),
          _buildOverlay(),
          if (_showHistory) _buildHistoryPanel(),
          if (_showSettings) _buildSettingsPanel(),
        ],
      ),
    );
  }

  Widget _buildQRView() {
    return MobileScanner(
      key: qrKey,
      controller: _scannerService.mobileScannerController,
      onDetect: _scannerService.onQRScanned,
    );
  }

  Widget _buildOverlay() {
    return SafeArea(
      child: Column(
        children: [
          _buildTopBar(),
          Expanded(child: _buildScanningArea()),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              'Scan QR Code',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _showSettings = !_showSettings),
            icon: const Icon(Icons.settings, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningArea() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 300), // Space for QR scanner
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Container(
                width: 200,
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.green.withOpacity(_animation.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Position QR code within the frame',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          if (_scannerService.continuousScanning) ...[
            const SizedBox(height: 8),
            const Text(
              'Continuous scanning enabled',
              style: TextStyle(color: Colors.green, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: Icons.photo_library,
            label: 'Gallery',
            onPressed: _scanFromImage,
          ),
          _buildControlButton(
            icon: _scannerService.isFlashOn ? Icons.flash_on : Icons.flash_off,
            label: 'Flash',
            onPressed: _scannerService.toggleFlash,
          ),
          _buildControlButton(
            icon: Icons.flip_camera_ios,
            label: 'Flip',
            onPressed: _scannerService.hasMultipleCameras 
                ? _scannerService.switchCamera 
                : null,
          ),
          _buildControlButton(
            icon: Icons.history,
            label: 'History',
            onPressed: () => setState(() => _showHistory = !_showHistory),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(
            icon,
            color: onPressed != null ? Colors.white : Colors.grey,
            size: 28,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: onPressed != null ? Colors.white70 : Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryPanel() {
    return Positioned(
      right: 0,
      top: 80,
      bottom: 120,
      width: 280,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white24)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Scan History',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _scannerService.clearHistory,
                    icon: const Icon(Icons.clear_all, color: Colors.white70, size: 20),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _scannerService.scanHistory.isEmpty
                  ? const Center(
                      child: Text(
                        'No scan history',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _scannerService.scanHistory.length,
                      itemBuilder: (context, index) {
                        final data = _scannerService.scanHistory[index];
                        return ListTile(
                          dense: true,
                          title: Text(
                            data,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            onPressed: () => _scannerService.removeFromHistory(data),
                            icon: const Icon(Icons.close, color: Colors.white54, size: 16),
                          ),
                          onTap: () {
                            if (_scannerService.isValidTOTPQR(data)) {
                              widget.onQRScanned(data);
                              Navigator.pop(context);
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return Positioned(
      left: 0,
      top: 80,
      bottom: 120,
      width: 280,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white24)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.settings, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Scanner Settings',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSettingTile(
                    'Auto Focus',
                    _scannerService.autoFocus,
                    _scannerService.toggleAutoFocus,
                  ),
                  _buildSettingTile(
                    'Continuous Scanning',
                    _scannerService.continuousScanning,
                    _scannerService.toggleContinuousScanning,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Zoom Level',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Slider(
                    value: _scannerService.zoomLevel,
                    min: 1.0,
                    max: 5.0,
                    divisions: 8,
                    onChanged: _scannerService.setZoom,
                    activeColor: Colors.green,
                  ),
                  Text(
                    '${(_scannerService.zoomLevel * 100).round()}%',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile(String title, bool value, VoidCallback onChanged) {
    return ListTile(
      dense: true,
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      trailing: Switch(
        value: value,
        onChanged: (_) => onChanged(),
        activeColor: Colors.green,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  void _onPermissionSet(BuildContext context, bool p) {
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission denied')),
      );
    }
  }
}
