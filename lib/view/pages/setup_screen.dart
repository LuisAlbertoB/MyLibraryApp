import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/providers/setup_provider.dart';

/// Setup screen for initial configuration (permissions + library selection).
class SetupScreen extends StatelessWidget {
  final VoidCallback onSetupComplete;

  const SetupScreen({super.key, required this.onSetupComplete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Consumer<SetupProvider>(
            builder: (context, provider, _) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    // App icon
                    const Icon(
                      Icons.menu_book_rounded,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 24),
                    // Title
                    Text(
                      'Mini Reader',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PDF & Comic Book Reader',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    // Step 1: Permissions
                    _buildStepCard(
                      context,
                      icon: Icons.security_rounded,
                      title: 'Step 1: Storage Permission',
                      description: 'Allow access to read your books and comics.',
                      isComplete: provider.hasPermission,
                      onAction: provider.hasPermission
                          ? null
                          : () => provider.requestStoragePermission(),
                      buttonText: provider.hasPermission ? 'Granted ✓' : 'Grant Permission',
                    ),
                    const SizedBox(height: 16),
                    
                    // Step 2: Select directory
                    _buildStepCard(
                      context,
                      icon: Icons.folder_rounded,
                      title: 'Step 2: Choose Library',
                      description: provider.libraryPath ?? 'Select your books folder.',
                      isComplete: provider.libraryPath != null,
                      onAction: provider.hasPermission
                          ? () => provider.selectLibraryDirectory()
                          : null,
                      buttonText: provider.libraryPath != null ? 'Change Folder' : 'Select Folder',
                    ),
                    
                    // Error message
                    if (provider.error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          provider.error!,
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    
                    const Spacer(),
                    
                    // Complete setup button
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: ElevatedButton(
                        onPressed: provider.canComplete
                            ? () async {
                                await provider.completeSetup();
                                onSetupComplete();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF667eea),
                          disabledBackgroundColor: Colors.white30,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: provider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'Start Reading',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required bool isComplete,
    required VoidCallback? onAction,
    required String buttonText,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isComplete ? 0.25 : 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(isComplete ? 0.5 : 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isComplete ? Colors.green : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isComplete ? Icons.check_rounded : icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}
