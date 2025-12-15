import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/entities/library_item.dart';
import '../../viewmodel/providers/library_provider.dart';
import '../widgets/library_item_widget.dart';
import '../widgets/filter_bar_widget.dart';
import 'reader_screen.dart';

/// Library screen showing all books and comics.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-scan on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<LibraryProvider>();
      if (provider.items.isEmpty) {
        provider.scanLibrary();
      }
    });
  }

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
          child: Consumer<LibraryProvider>(
            builder: (context, provider, _) {
              return Column(
                children: [
                  _buildHeader(context, provider),
                  const FilterBarWidget(),
                  Expanded(
                    child: _buildContent(context, provider),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, LibraryProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Icon(
            Icons.menu_book_rounded,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Library',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${provider.totalCount} items • ${provider.booksCount} books • ${provider.comicsCount} comics',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: provider.isScanning ? null : () => provider.refresh(),
            icon: provider.isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, LibraryProvider provider) {
    if (provider.isScanning && provider.items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Scanning library...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            Text(
              provider.error!,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => provider.refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final items = provider.filteredItems;
    
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              provider.filter == LibraryFilter.books
                  ? Icons.menu_book
                  : provider.filter == LibraryFilter.comics
                      ? Icons.auto_stories
                      : Icons.library_books,
              color: Colors.white54,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              provider.filter == LibraryFilter.all
                  ? 'No books or comics found'
                  : 'No ${provider.filter.name} found',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Add PDF or CBZ files to your library folder',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return LibraryItemWidget(
          item: item,
          onTap: () => _openReader(context, item),
        );
      },
    );
  }

  void _openReader(BuildContext context, LibraryItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReaderScreen(item: item),
      ),
    );
  }
}
