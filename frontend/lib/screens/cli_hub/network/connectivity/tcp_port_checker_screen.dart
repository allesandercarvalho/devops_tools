import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/network_tool.dart';
import '../../../../services/network_api_service.dart';

class TCPPortCheckerScreen extends StatefulWidget {
  const TCPPortCheckerScreen({super.key});

  @override
  State<TCPPortCheckerScreen> createState() => _TCPPortCheckerScreenState();
}

class _TCPPortCheckerScreenState extends State<TCPPortCheckerScreen> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '80');
  int _timeout = 5;
  NetworkToolExecution? _execution;
  bool _isRunning = false;
  String _error = '';

  Future<void> _checkPort() async {
    if (_hostController.text.isEmpty || _portController.text.isEmpty) {
      setState(() => _error = 'Please enter host and port');
      return;
    }

    final port = int.tryParse(_portController.text);
    if (port == null || port < 1 || port > 65535) {
      setState(() => _error = 'Invalid port number (1-65535)');
      return;
    }

    setState(() {
      _isRunning = true;
      _error = '';
      _execution = null;
    });

    try {
      final result = await NetworkApiService.checkTCPPort(
        host: _hostController.text,
        port: port,
        timeout: _timeout,
      );

      setState(() {
        _execution = result;
        _isRunning = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      body: Column(
        children: [
          _buildHeader(),
          _buildInputSection(),
          Expanded(child: _buildResultPanel()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF06b6d4), const Color(0xFF0ea5e9)],
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
            child: const Icon(Icons.power, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TCP Port Checker', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Check if a TCP port is open', style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.8))),
            ],
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
              controller: _hostController,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Host',
                hintText: 'google.com or 8.8.8.8',
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
            child: TextField(
              controller: _portController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Port',
                hintText: '80',
                labelStyle: GoogleFonts.inter(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF1e293b),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.settings_ethernet, color: Colors.white70),
              ),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _isRunning ? null : _checkPort,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              backgroundColor: const Color(0xFF06b6d4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isRunning
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Row(children: [const Icon(Icons.play_arrow), const SizedBox(width: 8), Text('Check', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600))]),
          ),
        ],
      ),
    );
  }

  Widget _buildResultPanel() {
    if (_execution?.parsedResult == null) {
      return Center(child: Text('Results will appear here', style: GoogleFonts.inter(color: Colors.white30, fontSize: 18)));
    }

    final result = _execution!.parsedResult as TCPPortResult;

    return Center(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1e293b),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: result.open ? Colors.green : Colors.red, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: (result.open ? Colors.green : Colors.red).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                result.open ? Icons.check_circle : Icons.cancel,
                color: result.open ? Colors.green : Colors.red,
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              result.open ? 'PORT OPEN' : 'PORT CLOSED',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: result.open ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${result.host}:${result.port}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0f172a),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Icon(Icons.timer, color: Color(0xFF06b6d4)),
                      const SizedBox(height: 8),
                      Text('Response Time', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('${result.timeMs} ms', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(width: 1, height: 60, color: const Color(0xFF334155)),
                  Column(
                    children: [
                      const Icon(Icons.access_time, color: Color(0xFF06b6d4)),
                      const SizedBox(height: 8),
                      Text('Total Time', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('${_execution!.durationMs} ms', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
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
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }
}
