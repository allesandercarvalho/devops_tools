import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/network_tool.dart';
import '../../../../services/network_api_service.dart';
import '../components/history_dialog.dart';

class DNSPropagationAdvancedScreen extends StatefulWidget {
  const DNSPropagationAdvancedScreen({super.key});

  @override
  State<DNSPropagationAdvancedScreen> createState() => _DNSPropagationAdvancedScreenState();
}


class _DNSPropagationAdvancedScreenState extends State<DNSPropagationAdvancedScreen> {
  final _domainController = TextEditingController();
  String _selectedType = 'A';
  NetworkToolExecution? _execution;
  bool _isRunning = false;
  String _error = '';
  final List<Map<String, dynamic>> _history = [];

  final List<String> _recordTypes = ['A', 'AAAA', 'CNAME', 'MX', 'NS', 'TXT', 'SOA'];

  Future<void> _checkPropagation() async {
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
      final result = await NetworkApiService.executeDNSPropagation(
        domain: _domainController.text,
        type: _selectedType,
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
        gradient: LinearGradient(colors: [const Color(0xFF8b5cf6), const Color(0xFFec4899)]),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.public_off, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DNS Propagation', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Global DNS status checker', style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.8))),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1e293b),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedType,
                dropdownColor: const Color(0xFF1e293b),
                style: GoogleFonts.inter(color: Colors.white),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                items: _recordTypes.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() => _selectedType = newValue!);
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _isRunning ? null : _checkPropagation,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              backgroundColor: const Color(0xFF8b5cf6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isRunning
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Row(children: [const Icon(Icons.search), const SizedBox(width: 8), Text('Check', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600))]),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_execution?.parsedResult == null) {
      return Center(child: Text('Propagation status will appear here', style: GoogleFonts.inter(color: Colors.white30, fontSize: 18)));
    }

    final result = _execution!.parsedResult as DNSPropagationResult;

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: result.servers.length,
      itemBuilder: (context, index) {
        final serverName = result.servers.keys.elementAt(index);
        final detail = result.servers[serverName]!;
        final isSuccess = detail.status == 'success';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1e293b),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSuccess ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(isSuccess ? Icons.check_circle : Icons.error, color: isSuccess ? Colors.green : Colors.red),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(serverName, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (isSuccess)
                      ...detail.records.map((r) => Text(r, style: GoogleFonts.jetBrainsMono(color: Colors.white70, fontSize: 12)))
                    else
                      Text(detail.error, style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _domainController.dispose();
    super.dispose();
  }
}
