import 'package:flutter/material.dart';

class SmartPaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onFirst;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onLast;
  final Function(int)? onPageSelect;
  final int itemsPerPage;
  final int totalItems;
  final bool showItemsInfo;
  final Color? primaryColor;
  final double? buttonSize;
  final int maxVisiblePages;

  const SmartPaginationControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    this.onFirst,
    this.onPrevious,
    this.onNext,
    this.onLast,
    this.onPageSelect,
    this.itemsPerPage = 10,
    this.totalItems = 0,
    this.showItemsInfo = true,
    this.primaryColor,
    this.buttonSize = 36.0,
    this.maxVisiblePages = 7,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final effectivePrimaryColor = primaryColor ?? theme.colorScheme.primary;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Items info row
          if (showItemsInfo && totalItems > 0) ...[
            _buildItemsInfo(context),
            const SizedBox(height: 12),
          ],
          
          // Pagination controls
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // First page button
                _buildNavigationButton(
                  context: context,
                  icon: Icons.first_page,
                  tooltip: 'First page',
                  onPressed: currentPage > 0 ? onFirst : null,
                  color: effectivePrimaryColor,
                ),
                
                const SizedBox(width: 4),
                
                // Previous page button
                _buildNavigationButton(
                  context: context,
                  icon: Icons.chevron_left,
                  tooltip: 'Previous page',
                  onPressed: currentPage > 0 ? onPrevious : null,
                  color: effectivePrimaryColor,
                ),
                
                const SizedBox(width: 16),
                
                // Smart page numbers
                ..._buildSmartPageNumbers(context, effectivePrimaryColor),
                
                const SizedBox(width: 16),
                
                // Next page button
                _buildNavigationButton(
                  context: context,
                  icon: Icons.chevron_right,
                  tooltip: 'Next page',
                  onPressed: currentPage < totalPages - 1 ? onNext : null,
                  color: effectivePrimaryColor,
                ),
                
                const SizedBox(width: 4),
                
                // Last page button
                _buildNavigationButton(
                  context: context,
                  icon: Icons.last_page,
                  tooltip: 'Last page',
                  onPressed: currentPage < totalPages - 1 ? onLast : null,
                  color: effectivePrimaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsInfo(BuildContext context) {
    final startItem = currentPage * itemsPerPage + 1;
    final endItem = ((currentPage + 1) * itemsPerPage).clamp(1, totalItems);
    
    return Text(
      'Showing $startItem-$endItem of $totalItems items',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
      ),
    );
  }

  Widget _buildNavigationButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        iconSize: 18,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: onPressed != null 
              ? color.withOpacity(0.1) 
              : Colors.transparent,
          foregroundColor: onPressed != null 
              ? color 
              : Theme.of(context).disabledColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(
              color: onPressed != null 
                  ? color.withOpacity(0.3) 
                  : Theme.of(context).disabledColor.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSmartPageNumbers(BuildContext context, Color primaryColor) {
    List<Widget> widgets = [];
    
    // Calculate which pages to show
    List<int> pagesToShow = _calculatePagesToShow();
    
    for (int i = 0; i < pagesToShow.length; i++) {
      int pageNumber = pagesToShow[i];
      
      // Check if we need to add ellipsis before this page
      if (i > 0 && pagesToShow[i] - pagesToShow[i - 1] > 1) {
        widgets.add(_buildEllipsis(context));
        widgets.add(const SizedBox(width: 4));
      }
      
      // Add the page button
      widgets.add(_buildPageButton(context, pageNumber, primaryColor));
      
      // Add spacing between buttons (except for the last one)
      if (i < pagesToShow.length - 1) {
        widgets.add(const SizedBox(width: 4));
      }
    }
    
    return widgets;
  }

  List<int> _calculatePagesToShow() {
    // Handle edge cases
    if (totalPages <= 1) return [0];
    if (totalPages <= maxVisiblePages) {
      return List.generate(totalPages, (index) => index);
    }
    
    Set<int> pages = <int>{};
    
    // Always show first page
    pages.add(0);
    
    // Always show last page
    pages.add(totalPages - 1);
    
    // Show pages around current page (current ± 1)
    int startRange = (currentPage - 1).clamp(0, totalPages - 1);
    int endRange = (currentPage + 1).clamp(0, totalPages - 1);
    
    for (int i = startRange; i <= endRange; i++) {
      pages.add(i);
    }
    
    // Add strategic navigation points based on total pages
    _addStrategicPages(pages);
    
    // Convert to sorted list and limit if needed
    List<int> sortedPages = pages.toList()..sort();
    
    // If we have too many pages, keep the most important ones
    if (sortedPages.length > maxVisiblePages) {
      sortedPages = _selectMostImportantPages(sortedPages);
    }
    
    return sortedPages;
  }

  void _addStrategicPages(Set<int> pages) {
    // For small number of pages, show more pages around current
    if (totalPages <= 20) {
      // Show 2 pages on each side of current
      for (int i = (currentPage - 2).clamp(0, totalPages - 1); 
           i <= (currentPage + 2).clamp(0, totalPages - 1); 
           i++) {
        pages.add(i);
      }
      
      // Show first few and last few pages
      for (int i = 0; i < 3.clamp(0, totalPages); i++) {
        pages.add(i);
      }
      for (int i = (totalPages - 3).clamp(0, totalPages - 1); i < totalPages; i++) {
        pages.add(i);
      }
      return;
    }
    
    // For larger pagination, use strategic points
    double currentPosition = currentPage / (totalPages - 1);
    
    // Add pages from opposite end for quick navigation
    if (currentPosition < 0.3) {
      // We're in first third - show pages from end
      _addPagesFromEnd(pages, 3);
    } else if (currentPosition > 0.7) {
      // We're in last third - show pages from beginning
      _addPagesFromStart(pages, 3);
    } else {
      // We're in middle - show pages from both ends
      _addPagesFromStart(pages, 2);
      _addPagesFromEnd(pages, 2);
    }
    
    // Add milestone pages for very large pagination
    if (totalPages >= 100) {
      _addMilestonePages(pages);
    }
  }

  void _addPagesFromStart(Set<int> pages, int count) {
    for (int i = 1; i <= count.clamp(1, totalPages - 1); i++) {
      pages.add(i);
    }
  }

  void _addPagesFromEnd(Set<int> pages, int count) {
    for (int i = (totalPages - count - 1).clamp(0, totalPages - 2); 
         i < totalPages - 1; 
         i++) {
      pages.add(i);
    }
  }

  void _addMilestonePages(Set<int> pages) {
    // Add strategic milestone pages based on powers of 10 and position
    List<int> milestones = [];
    
    // Calculate meaningful milestones
    if (totalPages >= 100) {
      // Add every 10th or 100th page near current position
      int magnitude = totalPages >= 1000 ? 100 : 10;
      
      // Find milestones around current page
      int nearestMilestone = (currentPage ~/ magnitude) * magnitude;
      
      // Add milestone before and after current position
      if (nearestMilestone > 0) milestones.add(nearestMilestone - 1);
      if (nearestMilestone < totalPages - 1) milestones.add(nearestMilestone);
      if (nearestMilestone + magnitude < totalPages - 1) {
        milestones.add(nearestMilestone + magnitude - 1);
      }
    }
    
    // Add quarter, half, three-quarter points for very large sets
    if (totalPages >= 1000) {
      int quarter = totalPages ~/ 4;
      int half = totalPages ~/ 2;
      int threeQuarter = (totalPages * 3) ~/ 4;
      
      // Only add these if they're far from current page
      if ((currentPage - quarter).abs() > 50) milestones.add(quarter);
      if ((currentPage - half).abs() > 50) milestones.add(half);
      if ((currentPage - threeQuarter).abs() > 50) milestones.add(threeQuarter);
    }
    
    // Add valid milestones
    for (int milestone in milestones) {
      if (milestone >= 0 && milestone < totalPages) {
        pages.add(milestone);
      }
    }
  }

  List<int> _selectMostImportantPages(List<int> allPages) {
    // Priority order: current page and neighbors, first/last pages, then strategic pages
    Set<int> essential = <int>{};
    
    // Must have: first, last, current, and immediate neighbors
    essential.add(0);
    essential.add(totalPages - 1);
    essential.add(currentPage);
    if (currentPage > 0) essential.add(currentPage - 1);
    if (currentPage < totalPages - 1) essential.add(currentPage + 1);
    
    // Add as many strategic pages as we can fit
    List<int> remaining = allPages.where((p) => !essential.contains(p)).toList();
    int remainingSlots = maxVisiblePages - essential.length;
    
    if (remainingSlots > 0 && remaining.isNotEmpty) {
      // Prefer pages that are further from current page for better navigation
      remaining.sort((a, b) {
        int distanceA = (a - currentPage).abs();
        int distanceB = (b - currentPage).abs();
        return distanceB.compareTo(distanceA); // Further pages first
      });
      
      essential.addAll(remaining.take(remainingSlots));
    }
    
    return essential.toList()..sort();
  }

  Widget _buildPageButton(BuildContext context, int pageIndex, Color primaryColor) {
    final isCurrentPage = pageIndex == currentPage;
    final displayNumber = pageIndex + 1; // Convert to 1-based display
    
    return SizedBox(
      width: displayNumber >= 100 ? buttonSize! + 12 : buttonSize, // Wider for 3-digit numbers
      height: buttonSize,
      child: TextButton(
        onPressed: isCurrentPage ? null : () => onPageSelect?.call(pageIndex),
        style: TextButton.styleFrom(
          backgroundColor: isCurrentPage 
              ? primaryColor 
              : Colors.transparent,
          foregroundColor: isCurrentPage 
              ? Colors.white 
              : primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(
              color: isCurrentPage 
                  ? primaryColor 
                  : primaryColor.withOpacity(0.3),
            ),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          '$displayNumber',
          style: TextStyle(
            fontSize: displayNumber >= 100 ? 10 : 12, // Smaller font for 3-digit numbers
            fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEllipsis(BuildContext context) {
    return SizedBox(
      width: buttonSize! * 0.8,
      height: buttonSize,
      child: Center(
        child: Text(
          '...',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// Enhanced Simple Pagination with smart page numbers
class SmartSimplePagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final Color? accentColor;

  const SmartSimplePagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return SmartPaginationControls(
      currentPage: currentPage,
      totalPages: totalPages,
      onFirst: currentPage > 0 ? () => onPageChanged(0) : null,
      onPrevious: currentPage > 0 ? () => onPageChanged(currentPage - 1) : null,
      onNext: currentPage < totalPages - 1 ? () => onPageChanged(currentPage + 1) : null,
      onLast: currentPage < totalPages - 1 ? () => onPageChanged(totalPages - 1) : null,
      onPageSelect: onPageChanged,
      primaryColor: accentColor,
      showItemsInfo: false,
    );
  }
}

// Example usage widget that demonstrates different page counts
class PaginationExample extends StatefulWidget {
  const PaginationExample({super.key});

  @override
  _PaginationExampleState createState() => _PaginationExampleState();
}

class _PaginationExampleState extends State<PaginationExample> {
  int currentPage = 0;
  int totalPages = 100; // Default: 100 pages
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Pagination - Any Size')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Current Page: ${currentPage + 1} of $totalPages',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            
            // Page count selector
            Text('Test with different page counts:', 
                 style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPageCountButton(5, '5 pages'),
                _buildPageCountButton(10, '10 pages'),
                _buildPageCountButton(50, '50 pages'),
                _buildPageCountButton(100, '100 pages'),
                _buildPageCountButton(500, '500 pages'),
                _buildPageCountButton(1000, '1K pages'),
                _buildPageCountButton(5000, '5K pages'),
                _buildPageCountButton(10000, '10K pages'),
              ],
            ),
            
            const SizedBox(height: 30),
            
            Text(
              _getExampleText(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 40),
            
            // The pagination widget
            SmartSimplePagination(
              currentPage: currentPage,
              totalPages: totalPages,
              onPageChanged: (page) {
                setState(() {
                  currentPage = page;
                });
              },
              accentColor: Colors.blue,
            ),
            
            const SizedBox(height: 30),
            
            // Quick jump buttons for testing current page count
            Text('Quick navigation tests:', 
                 style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _buildQuickJumpButtons(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPageCountButton(int pages, String label) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          totalPages = pages;
          currentPage = 0; // Reset to first page
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: totalPages == pages ? Colors.blue : null,
        foregroundColor: totalPages == pages ? Colors.white : null,
      ),
      child: Text(label),
    );
  }
  
  List<Widget> _buildQuickJumpButtons() {
    List<Widget> buttons = [];
    
    // Always add first page
    buttons.add(ElevatedButton(
      onPressed: () => setState(() => currentPage = 0),
      child: const Text('Page 1'),
    ));
    
    // Add strategic test pages based on total pages
    if (totalPages >= 10) {
      int middlePage = totalPages ~/ 2;
      buttons.add(ElevatedButton(
        onPressed: () => setState(() => currentPage = middlePage),
        child: Text('Page ${middlePage + 1}'),
      ));
    }
    
    if (totalPages >= 100) {
      int page90 = totalPages >= 100 ? 89 : totalPages - 10;
      buttons.add(ElevatedButton(
        onPressed: () => setState(() => currentPage = page90),
        child: Text('Page ${page90 + 1}'),
      ));
    }
    
    if (totalPages >= 1000) {
      int page500 = totalPages >= 1000 ? 499 : totalPages - 100;
      buttons.add(ElevatedButton(
        onPressed: () => setState(() => currentPage = page500),
        child: Text('Page ${page500 + 1}'),
      ));
    }
    
    // Always add last page
    buttons.add(ElevatedButton(
      onPressed: () => setState(() => currentPage = totalPages - 1),
      child: const Text('Last Page'),
    ));
    
    return buttons;
  }
  
  String _getExampleText() {
    if (totalPages <= 10) {
      return 'Small pagination: Shows all pages directly';
    } else if (totalPages <= 100) {
      return 'Medium pagination:\n'
             '• Page 1: Shows 1, 2, 3, ..., ${totalPages-1}, $totalPages\n'
             '• Middle pages: Shows strategic pages for quick navigation\n'
             '• Last page: Shows 1, 2, ..., ${totalPages-2}, ${totalPages-1}, $totalPages';
    } else if (totalPages <= 1000) {
      return 'Large pagination ($totalPages pages):\n'
             '• Uses milestone pages (every 10th/100th)\n'
             '• Smart strategic positioning\n'
             '• Quick jumps from any position';
    } else {
      return 'Very large pagination ($totalPages pages):\n'
             '• Uses major milestones (every 100th page)\n'
             '• Quarter/half/three-quarter navigation points\n'
             '• Optimized for massive datasets';
    }
  }
}