import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/network_tool.dart';
import '../../../../services/network_api_service.dart';
import '../../../../widgets/terminal_output.dart';

class WhoisLookupScreen extends StatefulWidget {
  const WhoisLookupScreen({super.key});

  @override
  State<WhoisLookupScreen> createState() => _WhoisLookupScreenState();
}

class _WhoisLookupScreenState extends State<WhoisLookupScreen> {
  final _domainController = TextEditingController();
  NetworkToolExecution? _execution;
  bool _isRunning = false;
  String _error = '';

  Future<void> _executeWhois() async {
    if (_domainController.text.isEmpty) {
      setState(() => _error = 'Please enter a domain');
      return;
    }

    setState(() {
      _isRunning = true;
      _error = '';
      _execution = null;
    });

    try {
      final result = await NetworkApiService.executeWhois(
        domain: _domainController.text,
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
                Expanded(flex: 1, child: _buildInfoPanel()),
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
          colors: [const Color(0xFFec4899), const Color(0xFFf43f5e)],
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
            child: const Icon(Icons.info_outline, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Whois Lookup', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Domain registration information', style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.8))),
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
              controller: _domainController,
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
          ElevatedButton(
            onPressed: _isRunning ? null : _executeWhois,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              backgroundColor: const Color(0xFFec4899),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isRunning
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Row(children: [const Icon(Icons.search), const SizedBox(width: 8), Text('Lookup', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600))]),
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

  Widget _buildInfoPanel() {
    if (_execution?.parsedResult == null) {
      return Container(margin: const EdgeInsets.all(16), child: Center(child: Text('Domain info will appear here', style: GoogleFonts.inter(color: Colors.white30))));
    }

    final result = _execution!.parsedResult as WhoisResult;

    return Container(
      margin: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.domain.isNotEmpty) _buildInfoCard('Domain', result.domain, Icons.language),
            const SizedBox(height: 12),
            if (result.registrar.isNotEmpty) _buildInfoCard('Registrar', result.registrar, Icons.business),
            const SizedBox(height: 12),
            if (result.registrant.isNotEmpty) _buildInfoCard('Registrant', result.registrant, Icons.person),
            const SizedBox(height: 12),
            if (result.createdDate.isNotEmpty) _buildInfoCard('Created', result.createdDate, Icons.calendar_today),
            const SizedBox(height: 12),
            if (result.expiryDate.isNotEmpty) _buildInfoCard('Expires', result.expiryDate, Icons.event),
            const SizedBox(height: 12),
            if (result.updatedDate.isNotEmpty) _buildInfoCard('Updated', result.updatedDate, Icons.update),
            const SizedBox(height: 12),
            if (result.nameServers.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1e293b),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFec4899).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.dns, color: Color(0xFFec4899), size: 16),
                        const SizedBox(width: 8),
                        Text('Name Servers (${result.nameServers.length})', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...result.nameServers.map((ns) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_right, color: Colors.white70, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(ns, style: GoogleFonts.jetBrainsMono(color: Colors.white70, fontSize: 11))),
                        ],
                      ),
                    )).toList(),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFec4899).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFec4899), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 4),
                Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _domainController.dispose();
    super.dispose();
  }
}
