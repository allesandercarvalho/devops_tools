import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/network_tool.dart';
import '../../../../services/network_api_service.dart';

class TLSInspectorScreen extends StatefulWidget {
  const TLSInspectorScreen({super.key});

  @override
  State<TLSInspectorScreen> createState() => _TLSInspectorScreenState();
}

class _TLSInspectorScreenState extends State<TLSInspectorScreen> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '443');
  NetworkToolExecution? _execution;
  bool _isRunning = false;
  String _error = '';

  Future<void> _inspectTLS() async {
    if (_hostController.text.isEmpty) {
      setState(() => _error = 'Please enter a host');
      return;
    }

    final port = int.tryParse(_portController.text);
    if (port == null || port < 1 || port > 65535) {
      setState(() => _error = 'Invalid port');
      return;
    }

    setState(() {
      _isRunning = true;
      _error = '';
      _execution = null;
    });

    try {
      final result = await NetworkApiService.inspectTLS(
        host: _hostController.text,
        port: port,
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
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF10b981), const Color(0xFF14b8a6)]),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.security, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TLS Inspector', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('SSL/TLS certificate analysis', style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.8))),
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
            width: 120,
            child: TextField(
              controller: _portController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Port',
                labelStyle: GoogleFonts.inter(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF1e293b),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _isRunning ? null : _inspectTLS,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              backgroundColor: const Color(0xFF10b981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isRunning
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Row(children: [const Icon(Icons.search), const SizedBox(width: 8), Text('Inspect', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600))]),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_execution?.parsedResult == null) {
      return Center(child: Text('Certificate info will appear here', style: GoogleFonts.inter(color: Colors.white30, fontSize: 18)));
    }

    final result = _execution!.parsedResult as TLSResult;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Status card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: result.isValid ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: result.isValid ? Colors.green : Colors.red, width: 2),
            ),
            child: Row(
              children: [
                Icon(result.isValid ? Icons.check_circle : Icons.error, color: result.isValid ? Colors.green : Colors.red, size: 48),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(result.isValid ? 'VALID CERTIFICATE' : 'INVALID CERTIFICATE', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: result.isValid ? Colors.green : Colors.red)),
                      Text('${result.host}:${result.port}', style: GoogleFonts.jetBrainsMono(color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Info grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2.5,
            children: [
              _buildInfoCard('Protocol', result.version, Icons.vpn_lock),
              _buildInfoCard('Cipher', result.cipher, Icons.lock),
              _buildInfoCard('Valid From', result.validFrom, Icons.calendar_today),
              _buildInfoCard('Valid To', result.validTo, Icons.event),
            ],
          ),
          const SizedBox(height: 24),
          _buildDetailCard('Issuer', result.issuer, Icons.business),
          const SizedBox(height: 16),
          _buildDetailCard('Subject', result.subject, Icons.person),
          if (result.dnsNames.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1e293b),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10b981).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.dns, color: Color(0xFF10b981)),
                      const SizedBox(width: 12),
                      Text('DNS Names (${result.dnsNames.length})', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...result.dnsNames.map((name) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_right, color: Colors.white70, size: 16),
                        const SizedBox(width: 8),
                        Text(name, style: GoogleFonts.jetBrainsMono(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10b981).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF10b981), size: 20),
          const SizedBox(height: 8),
          Text(title, style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10b981).withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF10b981)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 8),
                Text(value, style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        ],
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
