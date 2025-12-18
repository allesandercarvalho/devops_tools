import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/network_tool.dart';
import '../../../../services/network_api_service.dart';
import '../components/history_dialog.dart';
import '../components/quick_result_split_view.dart';

class TracerouteQuickScreen extends StatefulWidget {
  const TracerouteQuickScreen({super.key});
  
  @override
  State<TracerouteQuickScreen> createState() => _TracerouteQuickScreenState();
}

class _TracerouteQuickScreenState extends State<TracerouteQuickScreen> {
  final _targetController = TextEditingController();
  int _maxHops = 30;
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
      final result = await NetworkApiService.executeTraceroute(
        target: _targetController.text,
        maxHops: _maxHops,
      );
      
      setState(() {
        _execution = result;
        _isRunning = false;
        _history.insert(0, {
          'command': 'traceroute -m $_maxHops ${_targetController.text}',
          'timestamp': DateTime.now(),
          'status': 'success',
          'target': _targetController.text,
          'maxHops': _maxHops,
        });
      });
    } catch (e) {
      setState(() {
        _isRunning = false;
      });
    }
  }

  void _showHistory() {
    showDialog(
      context: context,
      builder: (context) => HistoryDialog(
        title: 'Traceroute History',
        historyItems: _history,
        onItemSelected: (item) {
          setState(() {
            _targetController.text = item['target'] ?? '';
            _maxHops = item['maxHops'] ?? 30;
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
                  child: const Icon(Icons.route, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Traceroute - Quick', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('Trace network path to host', style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.8))),
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
                      labelText: 'Target',
                      hintText: 'google.com',
                      filled: true,
                      fillColor: const Color(0xFF1e293b),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.language, color: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<int>(
                    value: _maxHops,
                    dropdownColor: const Color(0xFF1e293b),
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Max Hops',
                      filled: true,
                      fillColor: const Color(0xFF1e293b),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: [10, 20, 30, 50].map((h) => DropdownMenuItem(value: h, child: Text('$h'))).toList(),
                    onChanged: (v) => setState(() => _maxHops = v!),
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
                      : Text('Trace', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Expanded(
            child: QuickResultSplitView(
              execution: _execution,
              toolType: 'traceroute',
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
