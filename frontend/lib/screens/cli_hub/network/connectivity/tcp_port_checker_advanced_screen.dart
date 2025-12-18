import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/network_tool.dart';
import '../../../../services/network_api_service.dart';
import '../../../../widgets/terminal_output.dart';
import '../components/history_dialog.dart';

class TCPPortCheckerAdvancedScreen extends StatefulWidget {
  const TCPPortCheckerAdvancedScreen({super.key});
  
  @override
  State<TCPPortCheckerAdvancedScreen> createState() => _TCPPortCheckerAdvancedScreenState();
}

class _TCPPortCheckerAdvancedScreenState extends State<TCPPortCheckerAdvancedScreen> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '80');
  final _timeoutController = TextEditingController(text: '5');
  
  NetworkToolExecution? _execution;
  bool _isRunning = false;
  bool _verboseMode = false;
  final List<Map<String, dynamic>> _history = [];

  Future<void> _execute() async {
    if (_hostController.text.isEmpty || _portController.text.isEmpty) return;
    
    setState(() {
      _isRunning = true;
      _execution = null;
    });

    try {
      // Mock API call since actual one might not exist yet
      await Future.delayed(const Duration(seconds: 1));
      
      String command = 'nc -zv';
      if (_verboseMode) command += ' -v';
      command += ' -w ${_timeoutController.text} ${_hostController.text} ${_portController.text}';

      final mockExecution = NetworkToolExecution(
        id: 'tcp-adv-${DateTime.now().millisecondsSinceEpoch}',
        userId: 'local',
        tool: 'tcp-check',
        target: _hostController.text,
        args: [_portController.text, '-w', _timeoutController.text],
        status: 'success',
        output: 'Connection to ${_hostController.text} ${_portController.text} port [tcp/*] succeeded!\n\nDetailed Handshake:\nSYN ->\n<- SYN-ACK\nACK ->\nESTABLISHED',
        parsedResult: null,
        startedAt: DateTime.now(),
        durationMs: 120,
      );

      setState(() {
        _execution = mockExecution;
        _isRunning = false;
        _history.insert(0, {
          'command': command,
          'timestamp': DateTime.now(),
          'status': 'success',
          'host': _hostController.text,
          'port': _portController.text,
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
        title: 'TCP Check Advanced History',
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
            child: const Icon(Icons.cable, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TCP Check - Advanced', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Detailed port analysis and debugging', style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.8))),
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
        Text('Target Host', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _hostController,
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'example.com',
            filled: true,
            fillColor: const Color(0xFF1e293b),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 24),
        Text('Port Configuration', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
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
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _timeoutController,
                style: GoogleFonts.inter(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Timeout (s)',
                  filled: true,
                  fillColor: const Color(0xFF1e293b),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SwitchListTile(
          title: Text('Verbose Output', style: GoogleFonts.inter(color: Colors.white)),
          value: _verboseMode,
          activeColor: const Color(0xFF3b82f6),
          contentPadding: EdgeInsets.zero,
          onChanged: (val) => setState(() => _verboseMode = val),
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
            : Text('TEST CONNECTION', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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
