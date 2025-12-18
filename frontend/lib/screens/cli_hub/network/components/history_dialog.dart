import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class HistoryDialog extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> historyItems;
  final Function(Map<String, dynamic>) onItemSelected;

  const HistoryDialog({
    super.key,
    required this.title,
    required this.historyItems,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 800,
        height: 600,
        decoration: BoxDecoration(
          color: const Color(0xFF1e293b),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF3b82f6).withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF3b82f6), const Color(0xFF8b5cf6)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.history, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${historyItems.length} items',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // History List
            Expanded(
              child: historyItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: Colors.white.withOpacity(0.1),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No history yet',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.white30,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: historyItems.length,
                      itemBuilder: (context, index) {
                        final item = historyItems[index];
                        return _buildHistoryItem(context, item, index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, Map<String, dynamic> item, int index) {
    final timestamp = item['timestamp'] as DateTime?;
    final command = item['command'] as String? ?? '';
    final status = item['status'] as String? ?? 'completed';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0f172a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status == 'success' 
              ? const Color(0xFF10b981).withOpacity(0.3)
              : status == 'error'
                  ? const Color(0xFFef4444).withOpacity(0.3)
                  : const Color(0xFF334155),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).pop();
            onItemSelected(item);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Status Indicator
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: status == 'success'
                        ? const Color(0xFF10b981).withOpacity(0.2)
                        : status == 'error'
                            ? const Color(0xFFef4444).withOpacity(0.2)
                            : const Color(0xFF3b82f6).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    status == 'success'
                        ? Icons.check_circle
                        : status == 'error'
                            ? Icons.error
                            : Icons.pending,
                    color: status == 'success'
                        ? const Color(0xFF10b981)
                        : status == 'error'
                            ? const Color(0xFFef4444)
                            : const Color(0xFF3b82f6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        command,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (timestamp != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _formatTimestamp(timestamp),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      color: Colors.white54,
                      tooltip: 'Copy command',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: command));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Command copied!')),
                        );
                      },
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white30, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
