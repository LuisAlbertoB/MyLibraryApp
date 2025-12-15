import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'view/pages/setup_screen.dart';
import 'view/pages/library_screen.dart';
import 'viewmodel/providers/setup_provider.dart';
import 'viewmodel/providers/library_provider.dart';
import 'viewmodel/providers/reader_provider.dart';

/// Main application widget with Provider configuration.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SetupProvider()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
        ChangeNotifierProvider(create: (_) => ReaderProvider()),
      ],
      child: MaterialApp(
        title: 'Mini Reader',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF667eea),
            brightness: Brightness.light,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF667eea),
            brightness: Brightness.dark,
          ),
        ),
        themeMode: ThemeMode.system,
        home: const _AppRouter(),
      ),
    );
  }
}

/// Handles routing between Setup and Library screens.
class _AppRouter extends StatefulWidget {
  const _AppRouter();

  @override
  State<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<_AppRouter> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initApp();
    });
  }

  Future<void> _initApp() async {
    final setupProvider = context.read<SetupProvider>();
    await setupProvider.init();
    
    // If setup is complete, load library path
    if (setupProvider.setupComplete && setupProvider.libraryPath != null) {
      final libraryProvider = context.read<LibraryProvider>();
      libraryProvider.setLibraryPath(setupProvider.libraryPath!);
    }
    
    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  void _onSetupComplete() {
    final setupProvider = context.read<SetupProvider>();
    if (setupProvider.libraryPath != null) {
      final libraryProvider = context.read<LibraryProvider>();
      libraryProvider.setLibraryPath(setupProvider.libraryPath!);
      libraryProvider.scanLibrary();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final setupProvider = context.watch<SetupProvider>();
    
    if (!setupProvider.setupComplete) {
      return SetupScreen(onSetupComplete: _onSetupComplete);
    }

    return const LibraryScreen();
  }
}
