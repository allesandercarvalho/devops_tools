import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/network_tool.dart';
import '../../../../services/network_api_service.dart';
import '../components/history_dialog.dart';
import '../components/quick_result_split_view.dart';

class DNSLookupQuickScreen extends StatefulWidget {
  const DNSLookupQuickScreen({super.key});

  @override
  State<DNSLookupQuickScreen> createState() => _DNSLookupQuickScreenState();
}

class _DNSLookupQuickScreenState extends State<DNSLookupQuickScreen> {
  final _targetController = TextEditingController();
  String _queryType = 'A';
  NetworkToolExecution? _execution;
  bool _isRunning = false;
  String _error = '';
  final List<Map<String, dynamic>> _history = [];

  final List<String> _queryTypes = ['A', 'AAAA', 'MX', 'TXT', 'NS', 'CNAME'];

  Future<void> _executeDNSLookup() async {
    if (_targetController.text.isEmpty) {
      setState(() => _error = 'Please enter a domain');
      return;
    }

    setState(() {
      _isRunning = true;
      _error = '';
      _execution = null;
    });

    try {
      final result = await NetworkApiService.executeDNSLookup(
        target: _targetController.text,
        queryType: _queryType,
      );

      setState(() {
        _execution = result;
        _isRunning = false;
        _history.insert(0, {
          'command': 'dig ${_targetController.text} $_queryType',
          'timestamp': DateTime.now(),
          'status': 'success',
          'target': _targetController.text,
          'queryType': _queryType,
        });
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isRunning = false;
        _history.insert(0, {
          'command': 'dig ${_targetController.text} $_queryType',
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
        title: 'DNS Lookup History',
        historyItems: _history,
        onItemSelected: (item) {
          setState(() {
            _targetController.text = item['target'] ?? '';
            _queryType = item['queryType'] ?? 'A';
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
          _buildHeader(),
          _buildInputSection(),
          Expanded(
            child: QuickResultSplitView(
              execution: _execution,
              toolType: 'dig',
              onClear: () => setState(() => _execution = null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8b5cf6), Color(0xFFec4899)],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.dns, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DNS Lookup - Quick', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Fast DNS record queries', style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.8))),
              ],
            ),
          ),
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.history, color: Colors.white),
              tooltip: 'View History',
              onPressed: _showHistory,
            ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _targetController,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Domain',
                hintText: 'google.com',
                labelStyle: GoogleFonts.inter(color: Colors.white70),
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
            child: DropdownButtonFormField<String>(
              value: _queryType,
              dropdownColor: const Color(0xFF1e293b),
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Type',
                filled: true,
                fillColor: const Color(0xFF1e293b),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              items: _queryTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
              onChanged: (value) => setState(() => _queryType = value!),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _isRunning ? null : _executeDNSLookup,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              backgroundColor: const Color(0xFF8b5cf6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isRunning
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Row(children: [const Icon(Icons.play_arrow), const SizedBox(width: 8), Text('Query', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600))]),
          ),
        ],
      ),
    );
  }



  Widget _buildResultsPanel() {
    if (_execution?.parsedResult == null) {
      return Container(margin: const EdgeInsets.all(16), child: Center(child: Text('Results will appear here', style: GoogleFonts.inter(color: Colors.white30))));
    }

    final result = _execution!.parsedResult as DNSResult;

    return Container(
      margin: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1e293b),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF8b5cf6).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.list, color: Color(0xFF8b5cf6)),
                      const SizedBox(width: 8),
                      Text('Answers (${result.answers.length})', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...result.answers.map((answer) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_right, color: Colors.white70, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: SelectableText(answer, style: GoogleFonts.jetBrainsMono(color: Colors.white70, fontSize: 13))),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }
}
