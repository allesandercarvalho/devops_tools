import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/network_tool.dart';
import '../../../../services/network_api_service.dart';
import '../../../../widgets/terminal_output.dart';
import '../components/history_dialog.dart';

class TracerouteAdvancedScreen extends StatefulWidget {
  const TracerouteAdvancedScreen({super.key});
  
  @override
  State<TracerouteAdvancedScreen> createState() => _TracerouteAdvancedScreenState();
}

class _TracerouteAdvancedScreenState extends State<TracerouteAdvancedScreen> {
  final _targetController = TextEditingController();
  final _maxHopsController = TextEditingController(text: '30');
  final _waitTimeController = TextEditingController(text: '3');
  
  NetworkToolExecution? _execution;
  bool _isRunning = false;
  bool _resolveHostnames = false;
  String _method = 'UDP';
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
        maxHops: int.tryParse(_maxHopsController.text) ?? 30,
      );
      
      final args = [
        '-m', _maxHopsController.text,
        '-w', _waitTimeController.text,
        if (_method == 'ICMP') '-I',
        if (_method == 'TCP') '-T',
        _targetController.text
      ];

      final advancedExecution = NetworkToolExecution(
         id: result.id,
         userId: result.userId,
         tool: 'traceroute',
         target: result.target,
         args: args,
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
          'command': 'traceroute ${args.join(" ")}',
          'timestamp': DateTime.now(),
          'status': 'success',
          'target': _targetController.text,
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
        title: 'Traceroute Advanced History',
        historyItems: _history,
        onItemSelected: (item) {
          setState(() {
            _targetController.text = item['target'] ?? '';
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
                      Expanded(flex: 2, child: _buildTerminalOutput()),
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
        gradient: LinearGradient(colors: [Color(0xFF3b82f6), Color(0xFF06b6d4)]),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.alt_route, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Traceroute - Advanced', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Deep route analysis and path visualization', style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.8))),
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
        Text('Target', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold)),
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
        Text('Parameters', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _maxHopsController,
                style: GoogleFonts.inter(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Max Hops',
                  filled: true,
                  fillColor: const Color(0xFF1e293b),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _waitTimeController,
                style: GoogleFonts.inter(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Wait Time (s)',
                  filled: true,
                  fillColor: const Color(0xFF1e293b),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Advanced Options', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _method,
          dropdownColor: const Color(0xFF1e293b),
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Probe Method',
            filled: true,
            fillColor: const Color(0xFF1e293b),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          items: ['UDP', 'ICMP', 'TCP'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) => setState(() => _method = v!),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: Text('Resolve IPs', style: GoogleFonts.inter(color: Colors.white)),
          value: _resolveHostnames,
          activeColor: const Color(0xFF3b82f6),
          contentPadding: EdgeInsets.zero,
          onChanged: (val) => setState(() => _resolveHostnames = val),
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
          backgroundColor: const Color(0xFF3b82f6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isRunning
            ? const CircularProgressIndicator(color: Colors.white)
            : Text('START TRACE', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ),
    );
  }

  Widget _buildTerminalOutput() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 24, 24, 24),
      width: double.infinity,
      child: TerminalOutput(
        output: _execution?.output ?? '',
        isRunning: _isRunning,
        onClear: () => setState(() => _execution = null),
        height: 600,
      ),
    );
  }
}
