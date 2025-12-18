import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/network_tool.dart';
import '../../../../services/network_api_service.dart';
import '../../../../widgets/terminal_output.dart';
import '../components/history_dialog.dart';

class TLSInspectorAdvancedScreen extends StatefulWidget {
  const TLSInspectorAdvancedScreen({super.key});
  
  @override
  State<TLSInspectorAdvancedScreen> createState() => _TLSInspectorAdvancedScreenState();
}

class _TLSInspectorAdvancedScreenState extends State<TLSInspectorAdvancedScreen> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '443');
  final _servernameController = TextEditingController();
  
  NetworkToolExecution? _execution;
  bool _isRunning = false;
  bool _showChain = true;
  final List<Map<String, dynamic>> _history = [];

  Future<void> _execute() async {
    if (_hostController.text.isEmpty) return;
    
    setState(() {
      _isRunning = true;
      _execution = null;
    });

    try {
      await Future.delayed(const Duration(seconds: 1));
      
      final mockExecution = NetworkToolExecution(
         id: 'tls-adv-${DateTime.now().millisecondsSinceEpoch}',
         userId: 'local',
         tool: 'tls-inspector',
         target: _hostController.text,
         args: [_portController.text, if(_showChain) '-showcerts'],
         status: 'success',
         output: 'CONNECTED(00000003)\n---\nCertificate chain\n 0 s:/C=US/ST=California/L=San Francisco/O=Example/CN=${_hostController.text}\n   i:/C=US/O=DigiCert Inc/OU=www.digicert.com/CN=DigiCert Global Root CA\n---\nServer certificate\n-----BEGIN CERTIFICATE-----\nMIIDdzCCAl+gAwIBAgIEAgAAAjANBgkqhkiG9w0BAQsFADBaMQswCQYDVQQGEwJJ\n...\n-----END CERTIFICATE-----\nsubject=/C=US/ST=California/L=San Francisco/O=Example/CN=${_hostController.text}\nissuer=/C=US/O=DigiCert Inc/OU=www.digicert.com/CN=DigiCert Global Root CA\n---\nNo client certificate CA names sent\n---\nSSL handshake has read 1634 bytes and written 447 bytes\n---\nNew, TLSv1/SSLv3, Cipher is ECDHE-RSA-AES128-GCM-SHA256\nServer public key is 2048 bit\nSecure Renegotiation IS supported\nCompression: NONE\nExpansion: NONE\nNo ALPN negotiated\nSSL-Session:\n    Protocol  : TLSv1.2\n    Cipher    : ECDHE-RSA-AES128-GCM-SHA256\n',
         parsedResult: null,
         startedAt: DateTime.now(),
         durationMs: 800,
      );

      setState(() {
        _execution = mockExecution;
        _isRunning = false;
        _history.insert(0, {
          'command': 'openssl s_client -connect ${_hostController.text}:${_portController.text} ${_showChain ? "-showcerts" : ""}',
          'timestamp': DateTime.now(),
          'status': 'success',
          'host': _hostController.text,
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
        title: 'TLS Inspection History',
        historyItems: _history,
        onItemSelected: (item) {
          setState(() {
            _hostController.text = item['host'] ?? '';
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
        gradient: LinearGradient(colors: [Color(0xFFef4444), Color(0xFFf59e0b)]),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.verified_user, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TLS Inspector - Advanced', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Deep SSL/TLS chain and handshake analysis', style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.8))),
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
        Text('Connection Details', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold)),
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
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _servernameController,
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'SNI Servername (Optional)',
            filled: true,
            fillColor: const Color(0xFF1e293b),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 24),
        SwitchListTile(
          title: Text('Show Certificate Chain', style: GoogleFonts.inter(color: Colors.white)),
          value: _showChain,
          activeColor: const Color(0xFFef4444),
          contentPadding: EdgeInsets.zero,
          onChanged: (val) => setState(() => _showChain = val),
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
          backgroundColor: const Color(0xFFef4444),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isRunning
            ? const CircularProgressIndicator(color: Colors.white)
            : Text('INSPECT CERTIFICATE', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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
