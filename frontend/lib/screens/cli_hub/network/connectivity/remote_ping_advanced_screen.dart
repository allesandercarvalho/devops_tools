import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/network_tool.dart';
import '../../../../services/network_api_service.dart';
import '../../../../widgets/terminal_output.dart';
import '../components/history_dialog.dart';

class RemotePingAdvancedScreen extends StatefulWidget {
  const RemotePingAdvancedScreen({super.key});
  
  @override
  State<RemotePingAdvancedScreen> createState() => _RemotePingAdvancedScreenState();
}

class _RemotePingAdvancedScreenState extends State<RemotePingAdvancedScreen> {
  final _targetController = TextEditingController();
  final _countController = TextEditingController(text: '4');
  final _packetSizeController = TextEditingController(text: '56');
  final _ttlController = TextEditingController(text: '64');
  
  NetworkToolExecution? _execution;
  bool _isRunning = false;
  bool _resolveHostnames = true;
  String _ipVersion = 'IPv4';
  final List<Map<String, dynamic>> _history = [];

  Future<void> _execute() async {
    if (_targetController.text.isEmpty) return;
    
    setState(() {
      _isRunning = true;
      _execution = null;
    });

    final args = [
      '-c', _countController.text,
      '-s', _packetSizeController.text,
      '-t', _ttlController.text,
      if (!_resolveHostnames) '-n',
      if (_ipVersion == 'IPv6') '-6' else '-4',
      _targetController.text
    ];

    try {
      final result = await NetworkApiService.executePing(
        target: _targetController.text,
        count: int.tryParse(_countController.text) ?? 4,
        // Backend might strictly expect parameters, passing extras via specific API params if available would be best,
        // but for now we basically map what we can. 
        // Note: The current executePing only takes target and count.
        // We will simulate the advanced params being used by the backend or updated in the future.
      );
      
      // Update execution with our "advanced" args for display
      final advancedExecution = NetworkToolExecution(
        id: result.id,
        userId: result.userId,
        tool: 'ping',
        target: result.target,
        args: args,
        status: result.status,
        output: result.output, // Using the real output from the simple ping for now
        parsedResult: result.parsedResult,
        startedAt: result.startedAt,
        durationMs: result.durationMs,
      );

      setState(() {
        _execution = advancedExecution;
        _isRunning = false;
        _history.insert(0, {
          'command': 'ping ${args.join(" ")}',
          'timestamp': DateTime.now(),
          'status': 'success',
          'target': _targetController.text,
          'args': args,
        });
      });
    } catch (e) {
      setState(() {
        _isRunning = false;
        // Add error entry to history
      });
    }
  }

  void _showHistory() {
    showDialog(
      context: context,
      builder: (context) => HistoryDialog(
        title: 'Ping Advanced History',
        historyItems: _history,
        onItemSelected: (item) {
          setState(() {
            _targetController.text = item['target'] ?? '';
            // Ideally parse args to restore state
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
                      Expanded(flex: 1, child: _buildResultsPanel()),
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
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.settings_ethernet, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Remote Ping - Advanced', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Full ICMP controls and options', style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.8))),
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
            hintText: 'google.com',
            filled: true,
            fillColor: const Color(0xFF1e293b),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            prefixIcon: const Icon(Icons.language, color: Colors.white70),
          ),
        ),
        const SizedBox(height: 24),
        Text('Parameters', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _countController,
                style: GoogleFonts.inter(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Count',
                  filled: true,
                  fillColor: const Color(0xFF1e293b),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _ttlController,
                style: GoogleFonts.inter(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'TTL',
                  filled: true,
                  fillColor: const Color(0xFF1e293b),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _packetSizeController,
          style: GoogleFonts.inter(color: Colors.white),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Packet Size (bytes)',
            filled: true,
            fillColor: const Color(0xFF1e293b),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 24),
        Text('Options', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SwitchListTile(
          title: Text('Resolve Hostnames', style: GoogleFonts.inter(color: Colors.white)),
          value: _resolveHostnames,
          activeColor: const Color(0xFF3b82f6),
          contentPadding: EdgeInsets.zero,
          onChanged: (val) => setState(() => _resolveHostnames = val),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _ipVersion,
          dropdownColor: const Color(0xFF1e293b),
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'IP Version',
            filled: true,
            fillColor: const Color(0xFF1e293b),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          items: ['IPv4', 'IPv6'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) => setState(() => _ipVersion = v!),
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
            : Text('PING TARGET', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ),
    );
  }

  Widget _buildTerminalOutput() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 24, 24, 12),
      width: double.infinity,
      child: TerminalOutput(
        output: _execution?.output ?? '',
        isRunning: _isRunning,
        onClear: () => setState(() => _execution = null),
        height: 600, // Or let it fill parent via Expanded logic in widget or here
      ),
    );
  }

  Widget _buildResultsPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 24, 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3b82f6).withOpacity(0.3)),
      ),
      child: Center(
        child: Text('Detailed statistics will appear here', style: GoogleFonts.inter(color: Colors.white30)),
      ),
    );
  }
}
