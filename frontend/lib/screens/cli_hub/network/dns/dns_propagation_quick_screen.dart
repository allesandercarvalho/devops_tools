import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/network_tool.dart';
import '../../../../services/network_api_service.dart';
import '../components/history_dialog.dart';
import '../components/quick_result_split_view.dart';

class DNSPropagationQuickScreen extends StatefulWidget {
  const DNSPropagationQuickScreen({super.key});
  
  @override
  State<DNSPropagationQuickScreen> createState() => _DNSPropagationQuickScreenState();
}

class _DNSPropagationQuickScreenState extends State<DNSPropagationQuickScreen> {
  final _targetController = TextEditingController();
  String _recordType = 'A';
  NetworkToolExecution? _execution;
  bool _isRunning = false;
  final List<Map<String, dynamic>> _history = [];

  void _showHistory() {
    showDialog(
      context: context,
      builder: (context) => HistoryDialog(
        title: 'DNS Propagation History',
        historyItems: _history,
        onItemSelected: (item) {
          setState(() {
            _targetController.text = item['target'] ?? '';
          });
        },
      ),
    );
  }

  Future<void> _execute() async {
    if (_targetController.text.isEmpty) return;
    
    setState(() {
      _isRunning = true;
      _execution = null;
    });

    try {
      final result = await NetworkApiService.executeDNSPropagation(
        domain: _targetController.text,
        type: _recordType,
      );
      
      setState(() {
        _execution = result;
        _isRunning = false;
        _history.insert(0, {
          'command': 'propagation ${_targetController.text} $_recordType',
          'timestamp': DateTime.now(),
          'status': 'success',
          'target': _targetController.text,
        });
      });
    } catch (e) {
      setState(() {
        _isRunning = false;
        _history.insert(0, {
          'command': 'propagation ${_targetController.text} $_recordType',
          'timestamp': DateTime.now(),
          'status': 'error',
        });
      });
    }
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
              gradient: LinearGradient(colors: [Color(0xFF8b5cf6), Color(0xFFec4899)]),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.public, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DNS Propagation - Quick', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('Check DNS propagation globally', style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.8))),
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
                      labelText: 'Domain',
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
                  width: 100,
                  child: DropdownButtonFormField<String>(
                    value: _recordType,
                    dropdownColor: const Color(0xFF1e293b),
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF1e293b),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: ['A', 'MX', 'NS', 'TXT'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setState(() => _recordType = v!),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isRunning ? null : _execute,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    backgroundColor: const Color(0xFF8b5cf6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isRunning 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Check', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Expanded(
            child: QuickResultSplitView(
              execution: _execution,
              toolType: 'dns-propagation',
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
