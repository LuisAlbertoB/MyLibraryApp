import 'dart:async';
import 'package:flutter/material.dart';
import '../pages/screensaver_screen.dart';

/// Wraps child widget to detect inactivity and trigger screensaver
class InactivityDetector extends StatefulWidget {
  final Widget child;
  final Duration timeout;

  const InactivityDetector({
    super.key,
    required this.child,
    this.timeout = const Duration(seconds: 90), // 1.5 minutes
  });

  @override
  State<InactivityDetector> createState() => _InactivityDetectorState();
}

class _InactivityDetectorState extends State<InactivityDetector> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(widget.timeout, _triggerScreensaver);
  }

  void _triggerScreensaver() {
    // Only trigger if we are at the top level (Context check might be tricky)
    // Or just push the screen.
    // If screensaver is already shown, do nothing? (Navigator logic handles this naturally usually,
    // but better check if current route is screensaver)
    
    // Simple approach: Push route.
    if (!mounted) return;
    
    // Only trigger if this screen is currently visible (top of stack)
    // This prevents triggering when ReaderScreen is open
    if (ModalRoute.of(context)?.isCurrent == false) {
       // Reset timer anyway so we don't keep checking rapidly? 
       // Or just return and let it fire again? 
       // Better to reset it to avoid loop without interaction
       _resetTimer();
       return;
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const ScreensaverScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(seconds: 1), // "Burn" transition to screensaver
      ),
    ).then((_) {
      // When screensaver pops, reset timer
      _resetTimer();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _resetTimer(),
      onPointerMove: (_) => _resetTimer(),
      onPointerUp: (_) => _resetTimer(),
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
