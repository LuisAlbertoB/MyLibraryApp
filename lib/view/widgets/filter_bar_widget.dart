import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/providers/library_provider.dart';

/// Filter bar widget for switching between All, Books, and Comics.
class FilterBarWidget extends StatelessWidget {
  const FilterBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                count: provider.totalCount,
                isSelected: provider.filter == LibraryFilter.all,
                onTap: () => provider.setFilter(LibraryFilter.all),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Books',
                count: provider.booksCount,
                color: const Color(0xFF2196F3),
                isSelected: provider.filter == LibraryFilter.books,
                onTap: () => provider.setFilter(LibraryFilter.books),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Comics',
                count: provider.comicsCount,
                color: const Color(0xFFF44336),
                isSelected: provider.filter == LibraryFilter.comics,
                onTap: () => provider.setFilter(LibraryFilter.comics),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? (color ?? Colors.white).withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? (color ?? Colors.white).withOpacity(0.6)
                    : Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.3)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
