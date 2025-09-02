import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
// import 'package:image/image.dart' as img; // Commented out - package not available
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScanResult {
  final String data;
  final DateTime timestamp;
  final String? format;
  final List<Offset>? corners;

  QRScanResult({
    required this.data,
    required this.timestamp,
    this.format,
    this.corners,
  });
}

class EnhancedQRScannerService extends ChangeNotifier {
  MobileScannerController? _mobileScannerController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isFlashOn = false;
  bool _isScanning = false;
  bool _isInitialized = false;
  StreamController<QRScanResult>? _scanResultController;
  Timer? _focusTimer;
  
  // Scanner settings
  double _zoomLevel = 1.0;
  bool _autoFocus = true;
  bool _continuousScanning = false;
  List<String> _scanHistory = [];
  
  static const int _maxHistoryItems = 50;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isFlashOn => _isFlashOn;
  bool get isScanning => _isScanning;
  double get zoomLevel => _zoomLevel;
  bool get autoFocus => _autoFocus;
  bool get continuousScanning => _continuousScanning;
  List<String> get scanHistory => List.unmodifiable(_scanHistory);
  Stream<QRScanResult>? get scanResultStream => _scanResultController?.stream;
  bool get hasMultipleCameras => _cameras.length > 1;
  int get selectedCameraIndex => _selectedCameraIndex;

  /// Initialize camera system
  Future<void> initialize() async {
    try {
      _mobileScannerController = MobileScannerController(
        facing: CameraFacing.back,
        torchEnabled: false,
      );
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to initialize scanner: $e');
    }
  }

  /// Get mobile scanner controller
  MobileScannerController? get mobileScannerController => _mobileScannerController;

  /// Switch between front and back cameras
  Future<void> switchCamera() async {
    if (_mobileScannerController != null) {
      await _mobileScannerController!.switchCamera();
      notifyListeners();
    }
  }

  /// Toggle flash
  Future<void> toggleFlash() async {
    if (_mobileScannerController != null) {
      await _mobileScannerController!.toggleTorch();
      _isFlashOn = !_isFlashOn;
      notifyListeners();
    }
  }

  /// Set zoom level
  Future<void> setZoom(double zoom) async {
    if (_mobileScannerController != null) {
      _zoomLevel = zoom.clamp(1.0, 5.0);
      await _mobileScannerController!.setZoomScale(_zoomLevel);
      notifyListeners();
    }
  }

  /// Toggle auto focus
  void toggleAutoFocus() {
    _autoFocus = !_autoFocus;
    if (_autoFocus) {
      _startAutoFocus();
    } else {
      _stopAutoFocus();
    }
    notifyListeners();
  }

  /// Start auto focus timer
  void _startAutoFocus() {
    _stopAutoFocus();
    _focusTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _performAutoFocus();
    });
  }

  /// Stop auto focus timer
  void _stopAutoFocus() {
    _focusTimer?.cancel();
    _focusTimer = null;
  }

  /// Perform auto focus
  Future<void> _performAutoFocus() async {
    // Auto focus is handled automatically by mobile_scanner
  }

  /// Manual focus at point
  Future<void> focusAtPoint(Offset point) async {
    // Manual focus is handled automatically by mobile_scanner
  }

  /// Start scanning
  void startScanning() {
    if (!_isScanning) {
      _isScanning = true;
      _scanResultController = StreamController<QRScanResult>.broadcast();
      notifyListeners();
    }
  }

  /// Stop scanning
  void stopScanning() {
    if (_isScanning) {
      _isScanning = false;
      _scanResultController?.close();
      _scanResultController = null;
      notifyListeners();
    }
  }

  /// Set mobile scanner controller
  void setMobileScannerController(MobileScannerController controller) {
    _mobileScannerController = controller;
  }

  /// Handle QR scan result
  void onQRScanned(BarcodeCapture capture) {
    if (!_isScanning || capture.barcodes.isEmpty) return;
    
    final barcode = capture.barcodes.first;
    if (barcode.rawValue == null) return;
    
    final result = QRScanResult(
      data: barcode.rawValue!,
      timestamp: DateTime.now(),
      format: barcode.format.name,
    );

    // Add to history
    _addToHistory(result.data);
    
    // Emit result
    _scanResultController?.add(result);
    
    // Stop scanning if not continuous
    if (!_continuousScanning) {
      stopScanning();
    }
    
    // Provide haptic feedback
    HapticFeedback.lightImpact();
  }

  /// Add scan result to history
  void _addToHistory(String data) {
    _scanHistory.removeWhere((item) => item == data);
    _scanHistory.insert(0, data);
    
    if (_scanHistory.length > _maxHistoryItems) {
      _scanHistory = _scanHistory.take(_maxHistoryItems).toList();
    }
    
    notifyListeners();
  }

  /// Toggle continuous scanning
  void toggleContinuousScanning() {
    _continuousScanning = !_continuousScanning;
    notifyListeners();
  }

  /// Clear scan history
  void clearHistory() {
    _scanHistory.clear();
    notifyListeners();
  }

  /// Remove item from history
  void removeFromHistory(String data) {
    _scanHistory.remove(data);
    notifyListeners();
  }

  /// Scan from image file
  Future<String?> scanFromImage(String imagePath) async {
    try {
      // For now, return null as image scanning requires additional setup
      // This feature can be implemented when needed
      return null;
    } catch (e) {
      throw Exception('Failed to scan image: $e');
    }
  }

  /// Get camera info
  Map<String, dynamic> getCameraInfo() {
    return {
      'isInitialized': _isInitialized,
      'hasFlash': true, // Most cameras have flash
      'zoomLevel': _zoomLevel,
      'autoFocus': _autoFocus,
      'isScanning': _isScanning,
    };
  }

  /// Validate QR code format
  bool isValidTOTPQR(String data) {
    try {
      final uri = Uri.parse(data);
      return uri.scheme == 'otpauth' && 
             uri.host == 'totp' && 
             uri.queryParameters.containsKey('secret');
    } catch (e) {
      return false;
    }
  }

  /// Extract TOTP data from QR
  Map<String, String>? extractTOTPData(String qrData) {
    try {
      final uri = Uri.parse(qrData);
      if (uri.scheme != 'otpauth' || uri.host != 'totp') {
        return null;
      }
      
      final pathSegments = uri.pathSegments;
      final issuerAndAccount = pathSegments.isNotEmpty ? pathSegments.first : '';
      
      String issuer = '';
      String account = '';
      
      if (issuerAndAccount.contains(':')) {
        final parts = issuerAndAccount.split(':');
        issuer = parts[0];
        account = parts.length > 1 ? parts[1] : '';
      } else {
        account = issuerAndAccount;
      }
      
      return {
        'secret': uri.queryParameters['secret'] ?? '',
        'issuer': uri.queryParameters['issuer'] ?? issuer,
        'account': account,
        'algorithm': uri.queryParameters['algorithm'] ?? 'SHA1',
        'digits': uri.queryParameters['digits'] ?? '6',
        'period': uri.queryParameters['period'] ?? '30',
      };
    } catch (e) {
      return null;
    }
  }

  /// Get scan statistics
  Map<String, dynamic> getScanStatistics() {
    return {
      'totalScans': _scanHistory.length,
      'isScanning': _isScanning,
      'continuousMode': _continuousScanning,
      'autoFocus': _autoFocus,
      'flashEnabled': _isFlashOn,
      'zoomLevel': _zoomLevel,
      'cameraCount': _cameras.length,
      'selectedCamera': _selectedCameraIndex,
    };
  }

  @override
  void dispose() {
    _stopAutoFocus();
    _mobileScannerController?.dispose();
    _scanResultController?.close();
    super.dispose();
  }
}
