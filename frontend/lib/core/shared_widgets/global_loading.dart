import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/config/theme.dart';

/// Full-screen blur overlay used while AI requests, uploads, or payments
/// are processing. Insert via [GlobalLoading.show] / [GlobalLoading.hide]
/// so only one instance is ever active at a time.
class GlobalLoading {
  GlobalLoading._();

  static OverlayEntry? _entry;

  static void show(BuildContext context, {String message = 'Loading...'}) {
    if (_entry != null) return;
    final overlay = Overlay.of(context);
    _entry =
        OverlayEntry(builder: (_) => _GlobalLoadingOverlay(message: message));
    overlay.insert(_entry!);
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
  }
}

class _GlobalLoadingOverlay extends StatelessWidget {
  final String message;

  const _GlobalLoadingOverlay({required this.message});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        color: Colors.black.withOpacity(0.35),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Padding(
                padding: EdgeInsets.all(18.0),
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 3),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
