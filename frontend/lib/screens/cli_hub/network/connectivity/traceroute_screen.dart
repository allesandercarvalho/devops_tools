import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/network_tool.dart';
import '../../../../services/network_api_service.dart';
import '../../../../widgets/terminal_output.dart';

class TracerouteScreen extends StatefulWidget {
  const TracerouteScreen({super.key});

  @override
  State<TracerouteScreen> createState() => _TracerouteScreenState();
}

class _TracerouteScreenState extends State<TracerouteScreen> {
  final _targetController = TextEditingController();
  int _maxHops = 30;
  NetworkToolExecution? _execution;
  bool _isRunning = false;
  String _error = '';

  Future<void> _executeTraceroute() async {
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
      final result = await NetworkApiService.executeTraceroute(
        target: _targetController.text,
        maxHops: _maxHops,
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
          Expanded(
            child: Row(
              children: [
                Expanded(flex: 2, child: _buildTerminalOutput()),
                Expanded(flex: 1, child: _buildHopsTable()),
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
          colors: [const Color(0xFF10b981), const Color(0xFF14b8a6)],
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
            child: const Icon(Icons.route, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Traceroute', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Trace network path to destination', style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.8))),
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
              controller: _targetController,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Target Host',
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
            width: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Max Hops: $_maxHops', style: GoogleFonts.inter(color: Colors.white70)),
                Slider(
                  value: _maxHops.toDouble(),
                  min: 5,
                  max: 64,
                  divisions: 59,
                  activeColor: const Color(0xFF10b981),
                  onChanged: (value) => setState(() => _maxHops = value.toInt()),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _isRunning ? null : _executeTraceroute,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              backgroundColor: const Color(0xFF10b981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isRunning
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Row(children: [const Icon(Icons.play_arrow), const SizedBox(width: 8), Text('Execute', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600))]),
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

  Widget _buildHopsTable() {
    if (_execution?.parsedResult == null) {
      return Container(margin: const EdgeInsets.all(16), child: Center(child: Text('Hops will appear here', style: GoogleFonts.inter(color: Colors.white30))));
    }

    final result = _execution!.parsedResult as TracerouteResult;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.list, color: Color(0xFF10b981)),
              const SizedBox(width: 8),
              Text('Hops (${result.hops.length})', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: result.hops.length,
              itemBuilder: (context, index) {
                final hop = result.hops[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0f172a),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF10b981).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10b981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text('${hop.number}', style: GoogleFonts.inter(color: const Color(0xFF10b981), fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(hop.host ?? hop.ip, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                            if (hop.host != null) Text(hop.ip, style: GoogleFonts.jetBrainsMono(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ),
                      Text('${hop.avgRTT.toStringAsFixed(2)} ms', style: GoogleFonts.inter(color: const Color(0xFF10b981), fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
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
