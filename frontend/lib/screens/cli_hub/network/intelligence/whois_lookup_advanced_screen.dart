import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/network_tool.dart';
import '../../../../services/network_api_service.dart';
import '../../../../widgets/terminal_output.dart';
import '../components/history_dialog.dart';

class WhoisLookupAdvancedScreen extends StatefulWidget {
  const WhoisLookupAdvancedScreen({super.key});
  
  @override
  State<WhoisLookupAdvancedScreen> createState() => _WhoisLookupAdvancedScreenState();
}

class _WhoisLookupAdvancedScreenState extends State<WhoisLookupAdvancedScreen> {
  final _targetController = TextEditingController();
  final _serverController = TextEditingController();
  
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
      final result = await NetworkApiService.executeWhois(
        domain: _targetController.text,
      );
      
      final advancedExecution = NetworkToolExecution(
         id: result.id,
         userId: result.userId,
         tool: 'whois',
         target: result.target,
         args: [_serverController.text.isNotEmpty ? '-h ${_serverController.text}' : ''],
         status: result.status,
         output: result.output,
         parsedResult: result.parsedResult,
         startedAt: result.startedAt,
         durationMs: result.durationMs,
      );

      setState(() {
        _execution = advancedExecution;
        _isRunning = false;
        _history.insert(0, {
          'command': 'whois ${_targetController.text}',
          'timestamp': DateTime.now(),
          'status': 'success',
          'domain': _targetController.text,
        });
      });
    } catch (e) {
      setState(() { _isRunning = false; });
    }
  }

  void _showHistory() {
    showDialog(
      context: context,
      builder: (context) => HistoryDialog(
        title: 'Whois History',
        historyItems: _history,
        onItemSelected: (item) {
          setState(() {
            _targetController.text = item['domain'] ?? '';
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
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 350,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildConfigurationPanel(),
                        const SizedBox(height: 24),
                        _buildExecutionButton(),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: _buildTerminalOutput()),
                    ],
                  ),
                ),
              ],
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
        gradient: LinearGradient(colors: [Color(0xFF10b981), Color(0xFF14b8a6)]),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.info, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Whois Lookup - Advanced', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Domain registration intelligence', style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.8))),
              ],
            ),
          ),
          if (_history.isNotEmpty)
            IconButton(icon: const Icon(Icons.history, color: Colors.white), onPressed: _showHistory),
        ],
      ),
    );
  }

  Widget _buildConfigurationPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Domain / IP', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _targetController,
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'example.com',
            filled: true,
            fillColor: const Color(0xFF1e293b),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 24),
        Text('Server Options', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextField(
          controller: _serverController,
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Specific Whois Server (Optional)',
            filled: true,
            fillColor: const Color(0xFF1e293b),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildExecutionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isRunning ? null : _execute,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 24),
          backgroundColor: const Color(0xFF10b981),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isRunning
            ? const CircularProgressIndicator(color: Colors.white)
            : Text('QUERY WHOIS', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ),
    );
  }

  Widget _buildTerminalOutput() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          margin: const EdgeInsets.fromLTRB(0, 24, 24, 24),
          child: TerminalOutput(
            output: _execution?.output ?? '',
            isRunning: _isRunning,
            onClear: () => setState(() => _execution = null),
            height: constraints.maxHeight - 48, // Subtract margins
          ),
        );
      },
    );
  }
}
