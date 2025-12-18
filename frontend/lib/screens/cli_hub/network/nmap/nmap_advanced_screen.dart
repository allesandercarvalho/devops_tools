import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/network_tool.dart';
import '../../../../services/network_api_service.dart';
import '../../../../widgets/terminal_output.dart';

class NmapAdvancedScreen extends StatefulWidget {
  const NmapAdvancedScreen({super.key});

  @override
  State<NmapAdvancedScreen> createState() => _NmapAdvancedScreenState();
}

class _NmapAdvancedScreenState extends State<NmapAdvancedScreen> {
  // Target
  final _targetController = TextEditingController();
  
  // Discovery Options
  bool _disablePing = false;
  bool _arpDiscovery = false;
  bool _udpDiscovery = false;
  bool _tcpSynDiscovery = false;
  bool _icmpEcho = false;
  bool _traceroute = false;
  
  // Scan Types
  String _scanType = '-sS'; // TCP SYN by default
  
  // Ports
  String _portsMode = 'default';
  final _customPortsController = TextEditingController();
  
  // Version & OS Detection
  bool _versionDetection = false;
  bool _osDetection = false;
  
  // Timing
  String _timingTemplate = 'T3';
  
  // Output
  bool _saveOutput = false;
  
  // Results
  String? _commandPreview;
  NetworkToolExecution? _execution;
  bool _isScanning = false;
  String? _error;

  // Expanded sections
  bool _discoveryExpanded = false;
  bool _scanTypesExpanded = false;
  bool _portsExpanded = false;
  bool _versionExpanded = false;
  bool _osExpanded = false;
  bool _timingExpanded = false;
  bool _outputExpanded = false;

  @override
  void initState() {
    super.initState();
    _updateCommandPreview();
    _targetController.addListener(_updateCommandPreview);
    _customPortsController.addListener(_updateCommandPreview);
  }

  void _updateCommandPreview() {
    final parts = ['nmap'];
    
    // Timing
    parts.add('-$_timingTemplate');
    
    // Scan type
    parts.add(_scanType);
    
    // Discovery options
    if (_disablePing) parts.add('-Pn');
    if (_arpDiscovery) parts.add('-PR');
    if (_udpDiscovery) parts.add('-PU');
    if (_tcpSynDiscovery) parts.add('-PS');
    if (_icmpEcho) parts.add('-PE');
    if (_traceroute) parts.add('--traceroute');
    
    // Ports
    if (_portsMode == 'custom' && _customPortsController.text.isNotEmpty) {
      parts.add('-p ${_customPortsController.text}');
    } else if (_portsMode == 'top100') {
      parts.add('--top-ports 100');
    } else if (_portsMode == 'top1000') {
      parts.add('--top-ports 1000');
    } else if (_portsMode == 'all') {
      parts.add('-p-');
    }
    
    // Version & OS
    if (_versionDetection) parts.add('-sV');
    if (_osDetection) parts.add('-O');
    
    // Target
    if (_targetController.text.isNotEmpty) {
      parts.add(_targetController.text);
    }
    
    setState(() => _commandPreview = parts.join(' '));
  }

  Future<void> _executeScan() async {
    if (_targetController.text.isEmpty) {
        setState(() => _error = 'Please enter a target');
        return;
    }

    setState(() {
      _isScanning = true;
      _execution = null;
      _error = null;
    });

    try {
      // Build options map
      final options = <String, dynamic>{
        'timing': _timingTemplate,
        'scan_type': _scanType,
        'disable_ping': _disablePing,
        'arp_discovery': _arpDiscovery,
        'udp_discovery': _udpDiscovery,
        'tcp_syn_discovery': _tcpSynDiscovery,
        'icmp_echo': _icmpEcho,
        'traceroute': _traceroute,
        'version_detection': _versionDetection,
        'os_detection': _osDetection,
      };

      if (_portsMode == 'custom' && _customPortsController.text.isNotEmpty) {
        options['ports'] = _customPortsController.text;
      } else if (_portsMode != 'default') {
        options['ports_mode'] = _portsMode;
      }

      final execution = await NetworkApiService.executeNmap(
        target: _targetController.text,
        scanType: 'custom',
        options: options,
      );
      
      setState(() {
        _execution = execution;
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      body: Row(
        children: [
          // LEFT PANEL - Configuration
          Expanded(
            flex: 1,
            child: Container(
              color: const Color(0xFF1e293b),
              child: Column(
                children: [
                   _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildTargetSection(),
                          const SizedBox(height: 16),
                          _buildExpandableSection('Discovery Options', Icons.search, const Color(0xFF3b82f6), _discoveryExpanded, () => setState(() => _discoveryExpanded = !_discoveryExpanded), _buildDiscoveryContent()),
                          const SizedBox(height: 12),
                          _buildExpandableSection('Scan Types', Icons.radar, const Color(0xFF10b981), _scanTypesExpanded, () => setState(() => _scanTypesExpanded = !_scanTypesExpanded), _buildScanTypesContent()),
                          const SizedBox(height: 12),
                          _buildExpandableSection('Ports Configuration', Icons.settings_ethernet, const Color(0xFF8b5cf6), _portsExpanded, () => setState(() => _portsExpanded = !_portsExpanded), _buildPortsContent()),
                          const SizedBox(height: 12),
                          _buildExpandableSection('Version Detection', Icons.info, const Color(0xFF06b6d4), _versionExpanded, () => setState(() => _versionExpanded = !_versionExpanded), _buildVersionContent()),
                          const SizedBox(height: 12),
                          _buildExpandableSection('OS Detection', Icons.computer, const Color(0xFFef4444), _osExpanded, () => setState(() => _osExpanded = !_osExpanded), _buildOSContent()),
                          const SizedBox(height: 12),
                          _buildExpandableSection('Timing & Performance', Icons.speed, const Color(0xFFf59e0b), _timingExpanded, () => setState(() => _timingExpanded = !_timingExpanded), _buildTimingContent()),
                          const SizedBox(height: 12),
                          _buildExpandableSection('Output Options', Icons.save, const Color(0xFF64748b), _outputExpanded, () => setState(() => _outputExpanded = !_outputExpanded), _buildOutputContent()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // RIGHT PANEL - Command Preview & Results
          Expanded(
            flex: 1,
            child: Container(
              color: const Color(0xFF0f172a),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Expanded(flex: 1, child: _buildCommandPreviewPanel()),
                  const SizedBox(height: 16),
                  Expanded(flex: 3, child: _buildScanResultsPanel()),
                ],
              ),
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
        gradient: LinearGradient(
          colors: [Color(0xFF8b5cf6), Color(0xFF3b82f6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
            child: const Icon(Icons.security, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nmap Scanner Advanced', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Professional Network Scanner', style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withOpacity(0.9))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTargetSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0f172a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gps_fixed, color: Color(0xFFf59e0b), size: 20),
              const SizedBox(width: 8),
              Text('TARGET', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _targetController,
            style: GoogleFonts.jetBrainsMono(fontSize: 13, color: Colors.white),
            decoration: InputDecoration(
              hintText: 'e.g., 192.168.1.1, scanme.nmap.org, 10.0.0.0/24',
              hintStyle: GoogleFonts.jetBrainsMono(fontSize: 13, color: Colors.white30),
              filled: true,
              fillColor: const Color(0xFF1e293b),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              prefixIcon: Icon(Icons.language, color: Colors.white.withOpacity(0.4), size: 18),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isScanning ? null : _executeScan,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8b5cf6),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: _isScanning
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_arrow, size: 18),
                        const SizedBox(width: 8),
                        Text('START SCAN', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSection(String title, IconData icon, Color iconColor, bool expanded, VoidCallback onTap, Widget content) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0f172a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: expanded ? iconColor.withOpacity(0.3) : const Color(0xFF334155)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(icon, color: iconColor, size: 18),
                  const SizedBox(width: 12),
                  Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                  const Spacer(),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more, color: Colors.white.withOpacity(0.4), size: 20),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(color: Color(0xFF334155), height: 1),
            Padding(padding: const EdgeInsets.all(16), child: content),
          ],
        ],
      ),
    );
  }

  Widget _buildDiscoveryContent() {
    return Column(
      children: [
        _buildCheckbox('Disable Ping (-Pn)', 'Skip host discovery, assume all hosts are up', _disablePing, (v) => setState(() { _disablePing = v!; _updateCommandPreview(); })),
        _buildCheckbox('ARP Discovery (-PR)', 'Use ARP ping for local network', _arpDiscovery, (v) => setState(() { _arpDiscovery = v!; _updateCommandPreview(); })),
        _buildCheckbox('UDP Discovery (-PU)', 'Send UDP packets for discovery', _udpDiscovery, (v) => setState(() { _udpDiscovery = v!; _updateCommandPreview(); })),
        _buildCheckbox('TCP SYN Discovery (-PS)', 'Send TCP SYN packets for discovery', _tcpSynDiscovery, (v) => setState(() { _tcpSynDiscovery = v!; _updateCommandPreview(); })),
        _buildCheckbox('ICMP Echo (-PE)', 'Use ICMP echo request', _icmpEcho, (v) => setState(() { _icmpEcho = v!; _updateCommandPreview(); })),
        _buildCheckbox('Traceroute (--traceroute)', 'Trace path to each host', _traceroute, (v) => setState(() { _traceroute = v!; _updateCommandPreview(); })),
      ],
    );
  }

  Widget _buildScanTypesContent() {
    return Column(
      children: [
        _buildRadio('TCP SYN Scan (-sS)', 'Stealthy, doesn\'t complete TCP handshake', '-sS'),
        _buildRadio('TCP Connect Scan (-sT)', 'Full TCP connection, more detectable', '-sT'),
        _buildRadio('UDP Scan (-sU)', 'Scan UDP ports (slower)', '-sU'),
        _buildRadio('ACK Scan (-sA)', 'Map firewall rulesets', '-sA'),
        _buildRadio('Xmas Scan (-sX)', 'FIN, PSH, URG flags set', '-sX'),
        _buildRadio('Null Scan (-sN)', 'No flags set', '-sN'),
        _buildRadio('FIN Scan (-sF)', 'Only FIN flag set', '-sF'),
        _buildRadio('Idle Scan (-sI)', 'Ultra-stealthy blind scan', '-sI'),
      ],
    );
  }

  Widget _buildPortsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPortsRadio('Default Nmap ports', 'default'),
        _buildPortsRadio('Top 100 Ports', 'top100'),
        _buildPortsRadio('Top 1000 Ports', 'top1000'),
        _buildPortsRadio('All Ports (1-65535)', 'all'),
        _buildPortsRadio('Custom Ports', 'custom'),
        if (_portsMode == 'custom') ...[
          const SizedBox(height: 12),
          TextField(
            controller: _customPortsController,
            style: GoogleFonts.jetBrainsMono(fontSize: 12, color: Colors.white),
            decoration: InputDecoration(
              hintText: 'e.g., 80,443,8080 or 1-1000',
              hintStyle: GoogleFonts.jetBrainsMono(fontSize: 12, color: Colors.white30),
              filled: true,
              fillColor: const Color(0xFF1e293b),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVersionContent() {
    return _buildCheckbox('Enable Version Detection (-sV)', 'Probe open ports to determine service/version info', _versionDetection, (v) => setState(() { _versionDetection = v!; _updateCommandPreview(); }));
  }

  Widget _buildOSContent() {
    return _buildCheckbox('Enable OS Detection (-O)', 'Identify remote operating system', _osDetection, (v) => setState(() { _osDetection = v!; _updateCommandPreview(); }));
  }

  Widget _buildTimingContent() {
    return DropdownButtonFormField<String>(
      value: _timingTemplate,
      dropdownColor: const Color(0xFF1e293b),
      style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Timing Template',
        labelStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white60),
        filled: true,
        fillColor: const Color(0xFF1e293b),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
      items: [
        DropdownMenuItem(value: 'T0', child: Text('T0 - Paranoid (slowest)')),
        DropdownMenuItem(value: 'T1', child: Text('T1 - Sneaky')),
        DropdownMenuItem(value: 'T2', child: Text('T2 - Polite')),
        DropdownMenuItem(value: 'T3', child: Text('T3 - Normal (default)')),
        DropdownMenuItem(value: 'T4', child: Text('T4 - Aggressive')),
        DropdownMenuItem(value: 'T5', child: Text('T5 - Insane (fastest)')),
      ],
      onChanged: (v) => setState(() { _timingTemplate = v!; _updateCommandPreview(); }),
    );
  }

  Widget _buildOutputContent() {
    return SwitchListTile(
      title: Text('Save output to file', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
      value: _saveOutput,
      activeColor: const Color(0xFF64748b),
      contentPadding: EdgeInsets.zero,
      onChanged: (v) => setState(() => _saveOutput = v),
    );
  }

  Widget _buildCheckbox(String title, String subtitle, bool value, Function(bool?) onChanged) {
    return CheckboxListTile(
      title: Text(title, style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: Colors.white60)),
      value: value,
      activeColor: const Color(0xFF3b82f6),
      contentPadding: EdgeInsets.zero,
      onChanged: onChanged,
    );
  }

  Widget _buildRadio(String title, String subtitle, String value) {
    return RadioListTile<String>(
      title: Text(title, style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: Colors.white60)),
      value: value,
      groupValue: _scanType,
      activeColor: const Color(0xFF10b981),
      contentPadding: EdgeInsets.zero,
      onChanged: (v) => setState(() { _scanType = v!; _updateCommandPreview(); }),
    );
  }

  Widget _buildPortsRadio(String title, String value) {
    return RadioListTile<String>(
      title: Text(title, style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
      value: value,
      groupValue: _portsMode,
      activeColor: const Color(0xFF8b5cf6),
      contentPadding: EdgeInsets.zero,
      onChanged: (v) => setState(() { _portsMode = v!; _updateCommandPreview(); }),
    );
  }

  Widget _buildCommandPreviewPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10b981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.code, color: Color(0xFF10b981), size: 18),
              ),
              const SizedBox(width: 12),
              Text('COMMAND PREVIEW', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 1)),
              const Spacer(),
              if (_commandPreview != null) ...[
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  color: Colors.white60,
                  tooltip: 'Copy Command',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _commandPreview!));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Command copied!')));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  color: Colors.white60,
                  tooltip: 'Clear',
                  onPressed: () => setState(() => _commandPreview = null),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0f172a),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: _commandPreview != null
                    ? SelectableText(_commandPreview!, style: GoogleFonts.jetBrainsMono(fontSize: 11, color: const Color(0xFF10b981), height: 1.5))
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.code, color: Colors.white.withOpacity(0.1), size: 48),
                            const SizedBox(height: 12),
                            Text('Command preview will appear here', style: GoogleFonts.inter(fontSize: 12, color: Colors.white30)),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanResultsPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SCAN RESULTS', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 1)),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0f172a),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildResultContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultContent() {
      if (_isScanning) {
          return Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                      const CircularProgressIndicator(color: Color(0xFF3b82f6)),
                      const SizedBox(height: 16),
                      Text('Scanning target...', style: GoogleFonts.inter(color: Colors.white70)),
                  ],
              ),
          );
      }
      
      if (_error != null) {
          return SingleChildScrollView(
              child: Text(_error!, style: GoogleFonts.jetBrainsMono(color: Colors.redAccent, fontSize: 12)),
          );
      }

    if (_execution == null) {
        return Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                Icon(Icons.assessment, color: Colors.white.withOpacity(0.1), size: 48),
                const SizedBox(height: 12),
                Text('No scan results yet', style: GoogleFonts.inter(fontSize: 13, color: Colors.white30)),
                const SizedBox(height: 4),
                Text('Start a scan to see results here', style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withOpacity(0.2))),
                ],
            ),
        );
    }
    
    // Check for parsed result
    if (_execution!.parsedResult is NmapResult) {
        final result = _execution!.parsedResult as NmapResult;
        return ListView.builder(
            itemCount: result.hosts.length,
            itemBuilder: (context, index) {
                final host = result.hosts[index];
                return Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Row(
                                children: [
                                    const Icon(Icons.devices, color: Colors.white70, size: 20),
                                    const SizedBox(width: 10),
                                    Text('Host: ${host.hostname}', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(width: 8),
                                    Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text('UP', style: GoogleFonts.inter(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                            ),
                            if (host.ip != null) ...[
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.only(left: 30),
                                  child: Text(host.ip!, style: GoogleFonts.jetBrainsMono(color: Colors.white54, fontSize: 12)),
                                ),
                            ],
                            if (host.os != null) ...[
                                const SizedBox(height: 8),
                                Padding(
                                    padding: const EdgeInsets.only(left: 30),
                                    child: Row(
                                        children: [
                                            const Icon(Icons.computer, color: Color(0xFFef4444), size: 14),
                                            const SizedBox(width: 8),
                                            Text(host.os!, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                                        ],
                                    ),
                                ),
                            ],
                            const SizedBox(height: 12),
                            // Ports Header
                             Padding(
                                padding: const EdgeInsets.only(left: 0),
                                child: Table(
                                    columnWidths: const {
                                        0: FixedColumnWidth(80), // Port
                                        1: FixedColumnWidth(80), // State
                                        2: FlexColumnWidth(),    // Service
                                    },
                                    children: [
                                        TableRow(
                                            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF334155)))),
                                            children: [
                                                Padding(padding: const EdgeInsets.all(8.0), child: Text('PORT', style: GoogleFonts.inter(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold))),
                                                Padding(padding: const EdgeInsets.all(8.0), child: Text('STATE', style: GoogleFonts.inter(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold))),
                                                Padding(padding: const EdgeInsets.all(8.0), child: Text('SERVICE', style: GoogleFonts.inter(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold))),
                                            ],
                                        ),
                                        ...host.ports.map((port) => TableRow(
                                            children: [
                                                Padding(padding: const EdgeInsets.all(8.0), child: Text('${port.port}/tcp', style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 12))),
                                                Padding(padding: const EdgeInsets.all(8.0), child: Text(port.state, style: GoogleFonts.inter(color: port.state == 'open' ? Colors.green : Colors.red, fontSize: 12))),
                                                Padding(padding: const EdgeInsets.all(8.0), child: Text(port.service, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12))),
                                            ],
                                        )),
                                    ],
                                ),
                            ),
                        ],
                    ),
                );
            },
        );
    }

    // Fallback to raw output if parsing failed or not applicable
    // Fallback to raw output if parsing failed or not applicable
    return SizedBox(
        width: double.infinity,
        child: TerminalOutput(
            output: _execution!.output,
            isRunning: _isScanning,
            onClear: () => setState(() { _execution = null; _error = null; }),
            height: 600, // Or better, let it expand if parent allows
        ),
    );
  }

  @override
  void dispose() {
    _targetController.dispose();
    _customPortsController.dispose();
    super.dispose();
  }
}
