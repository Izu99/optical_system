import 'package:flutter/material.dart';
import '../db/frame_helper.dart';
import '../models/frame.dart';
import '../widget/create_frame_dialog.dart';
import '../widget/pagination.dart'; // Import the pagination widget

class FrameListScreen extends StatefulWidget {
  final int branchId;
  final int shopId;
  const FrameListScreen({Key? key, required this.branchId, required this.shopId}) : super(key: key);

  @override
  State<FrameListScreen> createState() => _FrameListScreenState();
}

class _FrameListScreenState extends State<FrameListScreen> {
  List<Frame> _frames = [];
  List<Frame> _filteredFrames = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  int _currentPage = 0;
  static const int _pageSize = 10;

  int get _totalPages => (_filteredFrames.length / _pageSize).ceil();

  List<Frame> get _currentPageFrames {
    final start = _currentPage * _pageSize;
    final end = (_currentPage + 1) * _pageSize;
    return _filteredFrames.sublist(
      start,
      end > _filteredFrames.length ? _filteredFrames.length : end,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadFrames();
    _searchController.addListener(_filterFrames);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFrames() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final all = await FrameHelper.instance.getAllFrames();
      final frames = all.where((f) => f.branchId == widget.branchId && f.shopId == widget.shopId).toList();
      setState(() {
        _frames = frames;
        _filteredFrames = frames;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading frames: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterFrames() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFrames = _frames.where((frame) {
        return frame.brand.toLowerCase().contains(query) ||
            frame.model.toLowerCase().contains(query) ||
            frame.color.toLowerCase().contains(query) ||
            frame.size.toLowerCase().contains(query);
      }).toList();
      _currentPage = 0; // Reset to first page on search
    });
  }

  Future<void> _showCreateOrEditDialog({Frame? frame}) async {
    final result = await showDialog<Frame>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreateFrameDialog(
        frame: frame,
        isEdit: frame != null,
        branchId: widget.branchId,
        shopId: widget.shopId,
      ),
    );
    if (result != null) {
      if (frame == null) {
        await FrameHelper.instance.createFrame(result);
      } else {
        await FrameHelper.instance.updateFrame(result);
      }
      await _loadFrames();
    }
  }

  Future<void> _deleteFrame(Frame frame) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Frame'),
        content: Text('Are you sure you want to delete this frame (${frame.brand} ${frame.model})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && frame.frameId != null) {
      try {
        await FrameHelper.instance.deleteFrame(frame.frameId!);
        await _loadFrames();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Frame deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting frame: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _onPageChanged(int pageIndex) {
    setState(() {
      _currentPage = pageIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                // Search Bar and Header
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search frames',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showCreateOrEditDialog(),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Frame'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                // Frames Table
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Card(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _filteredFrames.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.photo_filter_rounded,
                                        size: 64,
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _frames.isEmpty ? 'No frames yet' : 'No matching frames',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _frames.isEmpty 
                                            ? 'Click the Add Frame button to add your first frame'
                                            : 'Try adjusting your search terms',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  children: [
                                    // Table Header
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          topRight: Radius.circular(12),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 40,
                                            child: Text(
                                              '#',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              'Brand',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              'Model',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              'Size',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              'Color',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              'Wholesale',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              'Selling',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              'Stock',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 100), // Actions column
                                        ],
                                      ),
                                    ),
                                    // Table Body
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: _currentPageFrames.length,
                                        itemBuilder: (context, index) {
                                          final frame = _currentPageFrames[index];
                                          final serial = _currentPage * _pageSize + index + 1;
                                          return Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: 40,
                                                  child: Text(
                                                    serial.toString(),
                                                    textAlign: TextAlign.center,
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    frame.brand,
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    frame.model,
                                                    style: Theme.of(context).textTheme.bodyMedium,
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    frame.size,
                                                    style: Theme.of(context).textTheme.bodyMedium,
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    frame.color,
                                                    style: Theme.of(context).textTheme.bodyMedium,
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    frame.wholeSalePrice.toString(),
                                                    style: Theme.of(context).textTheme.bodyMedium,
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    frame.sellingPrice.toString(),
                                                    style: Theme.of(context).textTheme.bodyMedium,
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    frame.stock.toString(),
                                                    style: Theme.of(context).textTheme.bodyMedium,
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 100,
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                    children: [
                                                      IconButton(
                                                        onPressed: () {
                                                          _showCreateOrEditDialog(frame: frame);
                                                        },
                                                        icon: const Icon(Icons.edit_rounded),
                                                        iconSize: 18,
                                                        tooltip: 'Edit',
                                                      ),
                                                      IconButton(
                                                        onPressed: () => _deleteFrame(frame),
                                                        icon: const Icon(Icons.delete_rounded),
                                                        iconSize: 18,
                                                        color: Colors.red,
                                                        tooltip: 'Delete',
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    // Pagination Controls
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: SmartPaginationControls(
                                        currentPage: _currentPage,
                                        totalPages: _totalPages,
                                        totalItems: _filteredFrames.length,
                                        itemsPerPage: _pageSize,
                                        onFirst: _currentPage > 0 ? () => _onPageChanged(0) : null,
                                        onPrevious: _currentPage > 0 ? () => _onPageChanged(_currentPage - 1) : null,
                                        onNext: _currentPage < _totalPages - 1 ? () => _onPageChanged(_currentPage + 1) : null,
                                        onLast: _currentPage < _totalPages - 1 ? () => _onPageChanged(_totalPages - 1) : null,
                                        onPageSelect: _onPageChanged,
                                        showItemsInfo: true,
                                      ),
                                    ),
                                  ],
                                ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}