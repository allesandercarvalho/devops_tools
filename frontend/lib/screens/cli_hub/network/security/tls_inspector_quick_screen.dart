import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/network_tool.dart';
import '../../../../services/network_api_service.dart';
import '../components/history_dialog.dart';
import '../components/quick_result_split_view.dart';

class TLSInspectorQuickScreen extends StatefulWidget {
  const TLSInspectorQuickScreen({super.key});
  
  @override
  State<TLSInspectorQuickScreen> createState() => _TLSInspectorQuickScreenState();
}

class _TLSInspectorQuickScreenState extends State<TLSInspectorQuickScreen> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '443');
  NetworkToolExecution? _execution;
  bool _isRunning = false;
  final List<Map<String, dynamic>> _history = [];

  Future<void> _execute() async {
    if (_hostController.text.isEmpty) return;
    
    setState(() {
      _isRunning = true;
      _execution = null;
    });

    try {
      final result = await NetworkApiService.inspectTLS(
        host: _hostController.text,
        port: int.tryParse(_portController.text) ?? 443,
      );
      
      setState(() {
        _execution = result;
        _isRunning = false;
        _history.insert(0, {
          'command': 'openssl s_client -connect ${_hostController.text}:${_portController.text}',
          'timestamp': DateTime.now(),
          'status': 'success',
          'host': _hostController.text,
          'port': _portController.text,
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
        title: 'TLS Inspector History',
        historyItems: _history,
        onItemSelected: (item) {
          setState(() {
            _hostController.text = item['host'] ?? '';
            _portController.text = item['port'] ?? '';
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
              gradient: LinearGradient(colors: [Color(0xFFef4444), Color(0xFFf59e0b)]),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.security, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TLS Inspector - Quick', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('Inspect SSL/TLS certificates', style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.8))),
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
                    controller: _hostController,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Host',
                      hintText: 'example.com',
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
                  child: TextField(
                    controller: _portController,
                    style: GoogleFonts.inter(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Port',
                      filled: true,
                      fillColor: const Color(0xFF1e293b),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isRunning ? null : _execute,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    backgroundColor: const Color(0xFFef4444),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isRunning
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Inspect', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Expanded(
            child: QuickResultSplitView(
              execution: _execution,
              toolType: 'tls-inspect',
              onClear: () => setState(() => _execution = null),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }
}
