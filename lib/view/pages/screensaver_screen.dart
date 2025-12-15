import 'dart:async';
import 'package:flutter/material.dart';

class ScreensaverScreen extends StatefulWidget {
  const ScreensaverScreen({super.key});

  @override
  State<ScreensaverScreen> createState() => _ScreensaverScreenState();
}

class _ScreensaverScreenState extends State<ScreensaverScreen>
    with SingleTickerProviderStateMixin {
  
  // Hardcoded list of assets we moved
  final List<String> _images = [
    'assets/screensaver/1e0301da2ec2ef00b9ade362d1e68c0f.jpg',
    'assets/screensaver/666f1cd53aecdb0bbd0cad043eb03a64.jpg',
    'assets/screensaver/7606c730aa37177c9abbf05bdcfb17fe.jpg',
    'assets/screensaver/88cdf541fc36914021e27632afdd6a3e.jpg',
  ];

  late int _currentIndex;
  late int _nextIndex;
  
  // Timer for switching images
  Timer? _timer;
  
  // Animation controller for fade transition
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _currentIndex = 0;
    _nextIndex = 1 % _images.length;
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // "Burn" duration (fade)
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // Initial fade in
    _fadeController.forward();

    // Start slideshow timer
    _startSlideshow();
  }

  void _startSlideshow() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _startTransition();
    });
  }

  void _startTransition() {
    if (!mounted) return;
    
    // We want to crossfade. 
    // Ideally we stack images. 
    // Current is visible. Next is behind? Or fade out current to reveal next?
    // Let's fade IN the next one over the current one.
    
    setState(() {
      _nextIndex = (_currentIndex + 1) % _images.length;
      _fadeController.reset();
      _fadeController.forward().then((_) {
         // Animation completed
         setState(() {
           _currentIndex = _nextIndex; // Lock in the new image
         });
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  void _onInteraction() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _onInteraction,
        onPanDown: (_) => _onInteraction(),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Current Background Image
            Image.asset(
              _images[_currentIndex],
              fit: BoxFit.cover,
            ),
            
            // Next Image (Fading In)
            FadeTransition(
              opacity: _fadeController,
              child: Image.asset(
                _images[_nextIndex], // The image we are transitioning TO
                fit: BoxFit.cover,
              ),
            ),
            
            // NOTE: The logic above is slightly tricky for continuous looping.
            // Behaivor:
            // State A: Show Image 0. Controller at 0 or 1?
            // If we use Stack [Current, Next], and fade IN Next.
            // At start: Current=0, Next=1. Controller=0 (Next is invisible).
            // Timer fires -> Controller goes 0->1. Next fades IN.
            // On completion -> Set Current=1, Next=2 (computed later), Controller=0 (Next=2 is invisible).
            // This works perfect.
          ],
        ),
      ),
    );
  }
}
