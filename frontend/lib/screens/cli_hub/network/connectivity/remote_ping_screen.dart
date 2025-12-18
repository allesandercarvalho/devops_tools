import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/network_tool.dart';
import '../../../../services/network_api_service.dart';
import '../../../../widgets/terminal_output.dart';

class RemotePingScreen extends StatefulWidget {
  const RemotePingScreen({super.key});

  @override
  State<RemotePingScreen> createState() => _RemotePingScreenState();
}

class _RemotePingScreenState extends State<RemotePingScreen> {
  final _targetController = TextEditingController();
  int _count = 4;
  int _timeout = 5;
  NetworkToolExecution? _execution;
  bool _isRunning = false;
  String _error = '';

  Future<void> _executePing() async {
    if (_targetController.text.isEmpty) {
      setState(() => _error = 'Please enter a target');
      return;
    }

    setState(() {
      _isRunning = true;
      _error = '';
      _execution = null;
    });

    try {
      final result = await NetworkApiService.executePing(
        target: _targetController.text,
        count: _count,
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
          // Header with gradient
          _buildHeader(),
          
          // Input section
          _buildInputSection(),
          
          // Split screen: Terminal + Stats
          Expanded(
            child: Row(
              children: [
                // Terminal output
                Expanded(
                  flex: 2,
                  child: _buildTerminalOutput(),
                ),
                
                // Statistics
                Expanded(
                  flex: 1,
                  child: _buildStatsPanel(),
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3b82f6),
            const Color(0xFF8b5cf6),
          ],
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
            child: const Icon(
              Icons.network_ping,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Remote Ping',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Test network connectivity and latency',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Target input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _targetController,
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Target Host',
                    hintText: 'google.com or 8.8.8.8',
                    labelStyle: GoogleFonts.inter(color: Colors.white70),
                    hintStyle: GoogleFonts.inter(color: Colors.white30),
                    filled: true,
                    fillColor: const Color(0xFF1e293b),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.language, color: Colors.white70),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Count slider
              SizedBox(
                width: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Packets: $_count',
                      style: GoogleFonts.inter(color: Colors.white70),
                    ),
                    Slider(
                      value: _count.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      activeColor: const Color(0xFF3b82f6),
                      onChanged: (value) {
                        setState(() => _count = value.toInt());
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Execute button
              ElevatedButton(
                onPressed: _isRunning ? null : _executePing,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  backgroundColor: const Color(0xFF3b82f6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isRunning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        children: [
                          const Icon(Icons.play_arrow),
                          const SizedBox(width: 8),
                          Text(
                            'Execute',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
          
          // Error message
          if (_error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error,
                        style: GoogleFonts.inter(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTerminalOutput() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TerminalOutput(
        output: _execution?.output ?? '',
        isRunning: _isRunning,
        onClear: () => setState(() => _execution = null),
      ),
    );
  }

  Widget _buildStatsPanel() {
    if (_execution?.parsedResult == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'Statistics will appear here',
            style: GoogleFonts.inter(color: Colors.white30),
          ),
        ),
      );
    }

    final result = _execution!.parsedResult as PingResult;

    return Container(
      margin: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildStatCard(
              'Packets',
              '${result.packetsReceived}/${result.packetsSent}',
              Icons.inventory_2_outlined,
              const Color(0xFF3b82f6),
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              'Packet Loss',
              '${result.packetLoss.toStringAsFixed(1)}%',
              Icons.warning_amber_outlined,
              result.packetLoss > 0 ? Colors.red : Colors.green,
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              'Min RTT',
              '${result.minRTT.toStringAsFixed(2)} ms',
              Icons.speed,
              const Color(0xFF10b981),
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              'Avg RTT',
              '${result.avgRTT.toStringAsFixed(2)} ms',
              Icons.analytics_outlined,
              const Color(0xFF8b5cf6),
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              'Max RTT',
              '${result.maxRTT.toStringAsFixed(2)} ms',
              Icons.trending_up,
              const Color(0xFFf59e0b),
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              'Duration',
              '${_execution!.durationMs} ms',
              Icons.timer_outlined,
              const Color(0xFF06b6d4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
