import 'package:flutter/material.dart';
import '../../features/home/widgets/floating_totp_widget.dart';

class TotpOverlayService {
  static final TotpOverlayService _instance = TotpOverlayService._internal();
  factory TotpOverlayService() => _instance;
  TotpOverlayService._internal();

  OverlayEntry? _overlayEntry;
  bool _isShowing = false;

  bool get isShowing => _isShowing;

  void showFloatingTotp(BuildContext context) {
    if (_isShowing) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => const FloatingTotpWidget(),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isShowing = true;
  }

  void hideFloatingTotp() {
    if (!_isShowing || _overlayEntry == null) return;

    _overlayEntry!.remove();
    _overlayEntry = null;
    _isShowing = false;
  }

  void toggleFloatingTotp(BuildContext context) {
    if (_isShowing) {
      hideFloatingTotp();
    } else {
      showFloatingTotp(context);
    }
  }
}
