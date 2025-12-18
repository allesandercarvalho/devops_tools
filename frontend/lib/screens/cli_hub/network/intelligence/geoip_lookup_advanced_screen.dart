import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/network_tool.dart';
import '../../../../services/network_api_service.dart';
import '../../../../widgets/terminal_output.dart';
import '../components/history_dialog.dart';

class GeoIPLookupAdvancedScreen extends StatefulWidget {
  const GeoIPLookupAdvancedScreen({super.key});
  
  @override
  State<GeoIPLookupAdvancedScreen> createState() => _GeoIPLookupAdvancedScreenState();
}

class _GeoIPLookupAdvancedScreenState extends State<GeoIPLookupAdvancedScreen> {
  final _ipController = TextEditingController();
  String _provider = 'Default';
  bool _verbose = false;
  
  NetworkToolExecution? _execution;
  bool _isRunning = false;
  final List<Map<String, dynamic>> _history = [];

  Future<void> _execute() async {
    if (_ipController.text.isEmpty) return;
    
    setState(() {
      _isRunning = true;
      _execution = null;
    });

    try {
      await Future.delayed(const Duration(seconds: 1));
      
      final mockExecution = NetworkToolExecution(
         id: 'geoip-adv-${DateTime.now().millisecondsSinceEpoch}',
         userId: 'local',
         tool: 'geoip',
         target: _ipController.text,
         args: [_provider, if(_verbose) '-v'],
         status: 'success',
         output: 'GeoIP Advanced Info for ${_ipController.text}:\n\nCountry: United States (US)\nCity: Mountain View\nRegion: CA\nLat/Long: 37.422, -122.084\nASN: AS15169 Google LLC\nTimezone: America/Los_Angeles\nConfidence: High',
         parsedResult: null,
         startedAt: DateTime.now(),
         durationMs: 400,
      );

      setState(() {
        _execution = mockExecution;
        _isRunning = false;
        _history.insert(0, {
          'command': 'geoiplookup --provider $_provider ${_ipController.text}',
          'timestamp': DateTime.now(),
          'status': 'success',
          'ip': _ipController.text,
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
        title: 'GeoIP History',
        historyItems: _history,
        onItemSelected: (item) {
          setState(() {
            _ipController.text = item['ip'] ?? '';
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
                      Expanded(flex: 1, child: _buildMapPlaceholder()),
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
            child: const Icon(Icons.location_on, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GeoIP Lookup - Advanced', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Deep geolocation and ASN intelligence', style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.8))),
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
        Text('Target Address', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _ipController,
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            hintText: '8.8.8.8',
            filled: true,
            fillColor: const Color(0xFF1e293b),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 24),
        Text('Lookup Options', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _provider,
          dropdownColor: const Color(0xFF1e293b),
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Data Provider',
            filled: true,
            fillColor: const Color(0xFF1e293b),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          items: ['Default', 'MaxMind', 'IPInfo', 'Cloudflare'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) => setState(() => _provider = v!),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: Text('Verbose Data', style: GoogleFonts.inter(color: Colors.white)),
          value: _verbose,
          activeColor: const Color(0xFF10b981),
          contentPadding: EdgeInsets.zero,
          onChanged: (val) => setState(() => _verbose = val),
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
            : Text('LOCATE ADDRESS', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ),
    );
  }

  Widget _buildTerminalOutput() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          margin: const EdgeInsets.fromLTRB(0, 24, 24, 12),
          child: TerminalOutput(
            output: _execution?.output ?? '',
            isRunning: _isRunning,
            onClear: () => setState(() => _execution = null),
            height: constraints.maxHeight - 36, // Subtract margins
          ),
        );
      },
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 24, 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10b981).withOpacity(0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 48, color: Colors.white24),
            SizedBox(height: 12),
            Text('Map Visualization Unavailable', style: GoogleFonts.inter(color: Colors.white30)),
          ],
        ),
      ),
    );
  }
}
