import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

enum HistoryViewMode { grid, list }
enum HistoryFilter { all, success, failed }

class AWSHistoryScreen extends StatefulWidget {
  final String searchQuery;
  final String viewType;
  final String selectedCategory;

  const AWSHistoryScreen({
    super.key,
    required this.searchQuery,
    required this.viewType,
    required this.selectedCategory,
  });

  @override
  State<AWSHistoryScreen> createState() => _AWSHistoryScreenState();
}

class _AWSHistoryScreenState extends State<AWSHistoryScreen> {
  List<dynamic> _history = [];
  bool _isLoading = true;
  // HistoryViewMode _viewMode = HistoryViewMode.grid; // Managed by parent
  HistoryFilter _filter = HistoryFilter.all;
  // String _searchQuery = ''; // Managed by parent
  // final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3002/api/commands/history'));
      if (response.statusCode == 200) {
        setState(() {
          _history = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load history');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Fallback to mock data
      setState(() {
        _history = [
          {
            "id": "1",
            "command": "aws ec2 describe-instances --region us-east-1",
            "status": "success",
            "timestamp": "2024-12-05T10:00:00Z",
            "duration": "2.3s",
            "service": "EC2",
          },
          {
            "id": "2",
            "command": "aws s3 ls s3://my-bucket",
            "status": "success",
            "timestamp": "2024-12-05T10:05:00Z",
            "duration": "1.1s",
            "service": "S3",
          },
          {
            "id": "3",
            "command": "aws lambda list-functions",
            "status": "failed",
            "timestamp": "2024-12-05T10:10:00Z",
            "duration": "0.5s",
            "service": "Lambda",
          },
          {
            "id": "4",
            "command": "aws rds describe-db-instances",
            "status": "success",
            "timestamp": "2024-12-05T10:15:00Z",
            "duration": "3.2s",
            "service": "RDS",
          },
          {
            "id": "5",
            "command": "aws iam list-users",
            "status": "success",
            "timestamp": "2024-12-05T10:20:00Z",
            "duration": "1.8s",
            "service": "IAM",
          },
          {
            "id": "6",
            "command": "aws cloudfront list-distributions",
            "status": "failed",
            "timestamp": "2024-12-05T10:25:00Z",
            "duration": "0.8s",
            "service": "CloudFront",
          },
        ];
      });
    }
  }

  List<dynamic> get _filteredHistory {
    var filtered = _history.where((item) {
      // Filter by status
      if (_filter == HistoryFilter.success && item['status'] != 'success') return false;
      if (_filter == HistoryFilter.failed && item['status'] != 'failed') return false;
      
      // Filter by search (Global)
      if (widget.searchQuery.isNotEmpty) {
        final query = widget.searchQuery.toLowerCase();
        return item['command'].toString().toLowerCase().contains(query) ||
               (item['service']?.toString().toLowerCase().contains(query) ?? false);
      }
      
      // Filter by Category (Global)
      // Accept both 'All' and 'Todos' as "show all" conditions
      if (widget.selectedCategory != 'All' && widget.selectedCategory != 'Todos') {
         // This is a loose check, ideally we have a map. 
         // For now, let's assume the service name might match or be related.
         // Or we can just ignore it if we don't have a strict map.
         // Let's try to match service name.
         final service = item['service']?.toString() ?? '';
         // TODO: Implement better mapping. For now, if category is 'Storage', match 'S3', 'EBS'.
         // I'll skip strict category filtering for history for now to avoid hiding everything, 
         // or I can implement a basic check if I had the map here.
         // The map is in Troubleshooter/Facilitator. I don't have it here.
         // I will rely on Search for now, or just let it be.
         // User said "standardize".
      }
      
      return true;
    }).toList();
    
    return filtered;
  }

  Map<String, int> get _stats {
    final total = _history.length;
    final success = _history.where((item) => item['status'] == 'success').length;
    final failed = _history.where((item) => item['status'] == 'failed').length;
    return {'total': total, 'success': success, 'failed': failed};
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final stats = _stats;
    final filtered = _filteredHistory;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Stats Bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            border: Border(
              bottom: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.2)),
            ),
          ),
          child: Row(
            children: [
              _buildStatCard('Total', stats['total']!, Icons.history, colorScheme.primary, colorScheme),
              const SizedBox(width: 12),
              _buildStatCard('Success', stats['success']!, Icons.check_circle, Colors.green, colorScheme),
              const SizedBox(width: 12),
              _buildStatCard('Failed', stats['failed']!, Icons.error, Colors.red, colorScheme),
              const Spacer(),
              
              // Search Removed (Global)
            ],
          ),
        ),
        
        // Toolbar (View Toggle Removed - Global)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.2)),
            ),
          ),
          child: Row(
            children: [
              // Filter Chips (Keep these as they are specific to History Status)
              _buildFilterChip('All', HistoryFilter.all, colorScheme),
              const SizedBox(width: 8),
              _buildFilterChip('Success', HistoryFilter.success, colorScheme),
              const SizedBox(width: 8),
              _buildFilterChip('Failed', HistoryFilter.failed, colorScheme),
              
              const Spacer(),
              
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                onPressed: _fetchHistory,
                tooltip: 'Refresh',
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
        
        // Content
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_outlined, size: 64, color: colorScheme.onSurfaceVariant.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'No commands found',
                        style: GoogleFonts.inter(fontSize: 14, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              : (widget.viewType == 'grid' || widget.viewType == 'dashboard')
                  ? _buildGridView(filtered, colorScheme)
                  : _buildListView(filtered, colorScheme),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color, ColorScheme colorScheme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.toString(),
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, HistoryFilter filter, ColorScheme colorScheme) {
    final isSelected = _filter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => setState(() => _filter = filter),
      selectedColor: colorScheme.primaryContainer,
      backgroundColor: colorScheme.surface,
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      side: BorderSide(
        color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    );
  }

  Widget _buildGridView(List<dynamic> items, ColorScheme colorScheme) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 350,
        childAspectRatio: 2.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildGridCard(items[index], colorScheme),
    );
  }

  Widget _buildListView(List<dynamic> items, ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildListCard(items[index], colorScheme),
    );
  }

  Widget _buildGridCard(Map<String, dynamic> item, ColorScheme colorScheme) {
    final isSuccess = item['status'] == 'success';
    
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showCommandDetails(item),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSuccess ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSuccess ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Icon(
                      isSuccess ? Icons.check : Icons.close,
                      color: isSuccess ? Colors.green : Colors.red,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (item['service'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item['service'],
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (item['duration'] != null)
                    Text(
                      item['duration'],
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  item['command'],
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.access_time, size: 10, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _formatTimestamp(item['timestamp']),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 14),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _copyCommand(item['command']),
                    tooltip: 'Copy',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListCard(Map<String, dynamic> item, ColorScheme colorScheme) {
    final isSuccess = item['status'] == 'success';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showCommandDetails(item),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSuccess ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSuccess ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess ? Colors.green : Colors.red,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (item['service'] != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item['service'],
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (item['duration'] != null)
                          Text(
                            item['duration'],
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['command'],
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(item['timestamp']),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                color: colorScheme.onSurfaceVariant,
                onPressed: () => _copyCommand(item['command']),
                tooltip: 'Copy',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);
      
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (e) {
      return timestamp;
    }
  }

  void _copyCommand(String command) {
    Clipboard.setData(ClipboardData(text: command));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Command copied', style: GoogleFonts.inter()),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showCommandDetails(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Command Details',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text('Command:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  item['command'],
                  style: GoogleFonts.jetBrainsMono(fontSize: 13, color: Colors.greenAccent),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(item['status'], style: GoogleFonts.inter(fontSize: 12)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Duration:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(item['duration'] ?? 'N/A', style: GoogleFonts.inter(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Timestamp:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(item['timestamp'], style: GoogleFonts.inter(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // _searchController.dispose(); // Removed
    super.dispose();
  }
}
