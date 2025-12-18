import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/network_tool.dart';
import '../../../../services/network_api_service.dart';
import '../components/history_dialog.dart';
import '../components/quick_result_split_view.dart';

class RemotePingQuickScreen extends StatefulWidget {
  const RemotePingQuickScreen({super.key});
  
  @override
  State<RemotePingQuickScreen> createState() => _RemotePingQuickScreenState();
}

class _RemotePingQuickScreenState extends State<RemotePingQuickScreen> {
  final _targetController = TextEditingController();
  int _count = 4;
  NetworkToolExecution? _execution;
  bool _isRunning = false;
  final List<Map<String, dynamic>> _history = [];

  Future<void> _execute() async {
    if (_targetController.text.isEmpty) return;
    
    setState(() {
      _isRunning = true;
      _execution = null;
    });

    try {
      final result = await NetworkApiService.executePing(
        target: _targetController.text,
        count: _count,
      );
      
      setState(() {
        _execution = result;
        _isRunning = false;
        _history.insert(0, {
          'command': 'ping -c $_count ${_targetController.text}',
          'timestamp': DateTime.now(),
          'status': 'success',
          'target': _targetController.text,
          'count': _count,
        });
      });
    } catch (e) {
      setState(() {
        _isRunning = false;
        _history.insert(0, {
          'command': 'ping -c $_count ${_targetController.text}',
          'timestamp': DateTime.now(),
          'status': 'error',
        });
      });
    }
  }

  void _showHistory() {
    showDialog(
      context: context,
      builder: (context) => HistoryDialog(
        title: 'Ping History',
        historyItems: _history,
        onItemSelected: (item) {
          setState(() {
            _targetController.text = item['target'] ?? '';
            _count = item['count'] ?? 4;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF3b82f6), Color(0xFF06b6d4)]),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.wifi_tethering, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Remote Ping - Quick', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('Test network connectivity', style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.8))),
                    ],
                  ),
                ),
                if (_history.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.history, color: Colors.white),
                    onPressed: _showHistory,
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _targetController,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Host',
                      hintText: 'google.com or 8.8.8.8',
                      filled: true,
                      fillColor: const Color(0xFF1e293b),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.language, color: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 120,
                  child: DropdownButtonFormField<int>(
                    value: _count,
                    dropdownColor: const Color(0xFF1e293b),
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Count',
                      filled: true,
                      fillColor: const Color(0xFF1e293b),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: [1, 4, 10, 20, 50].map((c) => DropdownMenuItem(value: c, child: Text('$c'))).toList(),
                    onChanged: (v) => setState(() => _count = v!),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isRunning ? null : _execute,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    backgroundColor: const Color(0xFF3b82f6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isRunning
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Ping', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Expanded(
            child: QuickResultSplitView(
              execution: _execution,
              toolType: 'ping',
              onClear: () => setState(() => _execution = null),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }
}
