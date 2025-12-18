import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/network_tool.dart';
import '../../../../services/network_api_service.dart';
import '../../../../widgets/terminal_output.dart';
import '../components/history_dialog.dart';

class DNSLookupAdvancedScreen extends StatefulWidget {
  const DNSLookupAdvancedScreen({super.key});

  @override
  State<DNSLookupAdvancedScreen> createState() => _DNSLookupAdvancedScreenState();
}


class _DNSLookupAdvancedScreenState extends State<DNSLookupAdvancedScreen> {
  final _targetController = TextEditingController();
  final _serverController = TextEditingController();
  String _queryType = 'A';
  NetworkToolExecution? _execution;
  bool _isRunning = false;
  String _error = '';
  final List<Map<String, dynamic>> _history = [];

  final List<String> _queryTypes = [
    'A', 'AAAA', 'MX', 'TXT', 'NS', 'CNAME', 'SOA', 'PTR'
  ];

  Future<void> _executeDNSLookup() async {
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
      final result = await NetworkApiService.executeDNSLookup(
        target: _targetController.text,
        queryType: _queryType,
        server: _serverController.text,
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
                Expanded(flex: 1, child: _buildResultsPanel()),
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
          colors: [const Color(0xFF8b5cf6), const Color(0xFFec4899)],
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DNS Lookup', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Query DNS records', style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.8))),
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
          SizedBox(
            width: 200,
            child: TextField(
              controller: _serverController,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'DNS Server (optional)',
                hintText: '8.8.8.8',
                labelStyle: GoogleFonts.inter(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF1e293b),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
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
                : Row(children: [const Icon(Icons.play_arrow), const SizedBox(width: 8), Text('Execute', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600))]),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalOutput() {
    return Container(
      margin: const EdgeInsets.all(16),
      width: double.infinity,
      child: TerminalOutput(
        output: _execution?.output ?? '',
        isRunning: _isRunning,
        onClear: () => setState(() => _execution = null),
        height: 600,
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
            _buildInfoCard('Query Type', result.queryType, Icons.info_outline),
            const SizedBox(height: 16),
            _buildInfoCard('Server', result.server, Icons.dns),
            const SizedBox(height: 16),
            _buildInfoCard('Query Time', '${result.queryTime} ms', Icons.timer),
            const SizedBox(height: 16),
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
                        IconButton(
                          icon: const Icon(Icons.copy, size: 16),
                          color: Colors.white70,
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: answer));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
                          },
                        ),
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

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8b5cf6).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8b5cf6)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
    _serverController.dispose();
    super.dispose();
  }
}
