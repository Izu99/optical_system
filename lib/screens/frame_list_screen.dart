import 'package:flutter/material.dart';
import '../db/frame_helper.dart';
import '../models/frame.dart';
import '../widget/create_frame_dialog.dart';

class FrameListScreen extends StatefulWidget {
  final int branchId;
  final int shopId;
  const FrameListScreen({Key? key, required this.branchId, required this.shopId}) : super(key: key);

  @override
  State<FrameListScreen> createState() => _FrameListScreenState();
}

class _FrameListScreenState extends State<FrameListScreen> {
  late Future<List<Frame>> _framesFuture;

  @override
  void initState() {
    super.initState();
    _framesFuture = _loadFrames();
  }

  Future<List<Frame>> _loadFrames() async {
    final all = await FrameHelper.instance.getAllFrames();
    return all.where((f) => f.branchId == widget.branchId && f.shopId == widget.shopId).toList();
  }

  void _refresh() {
    setState(() {
      _framesFuture = _loadFrames();
    });
  }

  Future<void> _showCreateOrEditDialog({Frame? frame}) async {
    final result = await showDialog<Frame>(
      context: context,
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
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Frames',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCreateOrEditDialog(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Frame'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Frame>>(
                future: _framesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: \\${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.secondary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Icon(Icons.photo_filter_rounded, color: Theme.of(context).colorScheme.onPrimary, size: 32),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No frames yet',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Click the Add button to add your first frame',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final frames = snapshot.data!;
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final table = SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          showCheckboxColumn: false, // Remove selection tick
                          columns: const [
                            DataColumn(label: Text('Brand')),
                            DataColumn(label: Text('Size')),
                            DataColumn(label: Text('Wholesale Price')),
                            DataColumn(label: Text('Color')),
                            DataColumn(label: Text('Model')),
                            DataColumn(label: Text('Selling Price')),
                            DataColumn(label: Text('Stock')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: frames.map((frame) {
                            return DataRow(
                              onSelectChanged: (_) => _showCreateOrEditDialog(frame: frame),
                              cells: [
                                DataCell(Text(frame.brand)),
                                DataCell(Text(frame.size)),
                                DataCell(Text(frame.wholeSalePrice.toString())),
                                DataCell(Text(frame.color)),
                                DataCell(Text(frame.model)),
                                DataCell(Text(frame.sellingPrice.toString())),
                                DataCell(Text(frame.stock.toString())),
                                DataCell(Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_rounded),
                                      onPressed: () => _showCreateOrEditDialog(frame: frame),
                                      tooltip: 'Edit',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_rounded),
                                      color: Colors.red,
                                      tooltip: 'Delete',
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Delete Frame'),
                                            content: const Text('Are you sure you want to delete this frame?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(false),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(true),
                                                style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true && frame.frameId != null) {
                                          await FrameHelper.instance.deleteFrame(frame.frameId!);
                                          _refresh();
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Frame deleted'), backgroundColor: Colors.red),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                )),
                              ],
                            );
                          }).toList(),
                        ),
                      );
                      // Use the same color and border radius as the customer table
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.05), // Match customer table
                          borderRadius: const BorderRadius.all(Radius.circular(12)),
                        ),
                        child: table,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
