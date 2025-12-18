import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/network_tool.dart';
import '../../../../services/network_api_service.dart';
import '../components/quick_result_split_view.dart';

class NmapQuickScanScreen extends StatefulWidget {
  const NmapQuickScanScreen({super.key});

  @override
  State<NmapQuickScanScreen> createState() => _NmapQuickScanScreenState();
}

class _NmapQuickScanScreenState extends State<NmapQuickScanScreen> {
  final _targetController = TextEditingController();
  String _scanType = 'quick';
  NetworkToolExecution? _execution;
  bool _isRunning = false;
  String _error = '';

  final List<Map<String, String>> _scanTypes = [
    {'value': 'quick', 'label': 'Quick Scan (-F)'},
    {'value': 'full', 'label': 'Full Scan (-p-)'},
    {'value': 'version', 'label': 'Version Detection (-sV)'},
    {'value': 'os', 'label': 'OS Detection (-O)'},
  ];

  Future<void> _executeNmap() async {
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
      final result = await NetworkApiService.executeNmap(
        target: _targetController.text,
        scanType: _scanType,
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
            child: QuickResultSplitView(
              execution: _execution,
              toolType: 'nmap',
              onClear: () => setState(() => _execution = null),
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
          colors: [const Color(0xFF3b82f6), const Color(0xFF8b5cf6)],
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
            child: const Icon(Icons.radar, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nmap Scanner', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Network port and service scanner', style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.8))),
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
                labelText: 'Target',
                hintText: 'scanme.nmap.org',
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
            width: 250,
            child: DropdownButtonFormField<String>(
              value: _scanType,
              dropdownColor: const Color(0xFF1e293b),
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Scan Type',
                filled: true,
                fillColor: const Color(0xFF1e293b),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              items: _scanTypes.map((type) => DropdownMenuItem(value: type['value'], child: Text(type['label']!))).toList(),
              onChanged: (value) => setState(() => _scanType = value!),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _isRunning ? null : _executeNmap,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              backgroundColor: const Color(0xFF3b82f6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isRunning
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Row(children: [const Icon(Icons.play_arrow), const SizedBox(width: 8), Text('Scan', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600))]),
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
