import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../../../../models/http_request.dart';
import '../../../../services/network_api_service.dart';
import '../../../../utils/file_saver/file_saver.dart';
import '../../../../widgets/terminal_output.dart';

class HttpClientAdvancedScreen extends StatefulWidget {
  const HttpClientAdvancedScreen({super.key});

  @override
  State<HttpClientAdvancedScreen> createState() => _HttpClientAdvancedScreenState();
}

class _HttpClientAdvancedScreenState extends State<HttpClientAdvancedScreen> {
  // Request configuration
  final _urlController = TextEditingController();
  String _selectedMethod = 'GET';
  final List<String> _methods = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS'];
  
  final List<Map<String, String>> _headers = [];
  final List<Map<String, String>> _queryParams = [];
  final _bodyController = TextEditingController();
  String _bodyType = 'NONE';
  String _authType = 'No Auth';
  String _tlsVersion = 'TLS 1.2';
  bool _useProxy = false;
  bool _enableCookies = false;
  bool _followRedirects = true;
  int _timeout = 30;
  
  // Auth controllers
  final _basicUserCtrl = TextEditingController();
  final _basicPassCtrl = TextEditingController();
  final _bearerTokenCtrl = TextEditingController();
  final _apiKeyKeyCtrl = TextEditingController();
  final _apiKeyValueCtrl = TextEditingController();
  
  // Response data
  String? _terminalOutput;
  String? _responseBody;
  int? _statusCode;
  String? _statusText;
  int? _responseTime;
  bool _isLoading = false;

  // Expanded sections
  bool _headersExpanded = false;
  bool _queryExpanded = false;
  bool _bodyExpanded = false;
  bool _authExpanded = false;
  bool _tlsExpanded = false;
  bool _proxyExpanded = false;
  bool _cookiesExpanded = false;
  bool _optionsExpanded = false;

  Future<void> _executeRequest() async {
    if (_urlController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _terminalOutput = null;
      _responseBody = null;
    });

    try {
      final headers = Map<String, String>.fromEntries(
        _headers.where((h) => h['key']!.isNotEmpty).map((h) => MapEntry(h['key']!, h['value']!))
      );
      
      final queryParams = Map<String, String>.fromEntries(
        _queryParams.where((q) => q['key']!.isNotEmpty).map((q) => MapEntry(q['key']!, q['value']!))
      );

      final request = HttpRequestModel(
        method: _selectedMethod,
        url: _urlController.text,
        headers: headers,
        queryParams: queryParams,
        body: _bodyType != 'NONE' ? _bodyController.text : '',
        bodyType: _bodyType.toLowerCase(),
        auth: _buildAuthConfig(),
      );

      final execution = await NetworkApiService.executeCurlRequest(request.toJson());
      
      setState(() {
        _terminalOutput = execution.output;
        if (execution.parsedResult != null) {
          final response = execution.parsedResult as Map<String, dynamic>;
          _statusCode = response['status_code'];
          _statusText = response['status_text'];
          _responseTime = response['time_ms'];
          _responseBody = response['body'];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _terminalOutput = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  AuthConfig? _buildAuthConfig() {
    if (_authType == 'No Auth') return null;

    return AuthConfig(
      type: _authType.toLowerCase().replaceAll(' ', ''),
      username: _authType == 'Basic' ? _basicUserCtrl.text : null,
      password: _authType == 'Basic' ? _basicPassCtrl.text : null,
      token: _authType == 'Bearer Token' ? _bearerTokenCtrl.text : null,
      apiKey: _authType == 'API Key' ? _apiKeyValueCtrl.text : null,
      apiKeyHeader: _authType == 'API Key' ? _apiKeyKeyCtrl.text : null,
    );
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
                          _buildExpandableSection('Headers', Icons.list_alt, const Color(0xFF3b82f6), _headersExpanded, () => setState(() => _headersExpanded = !_headersExpanded), _buildHeadersContent()),
                          const SizedBox(height: 12),
                          _buildExpandableSection('Query Parameters', Icons.search, const Color(0xFF10b981), _queryExpanded, () => setState(() => _queryExpanded = !_queryExpanded), _buildQueryContent()),
                          const SizedBox(height: 12),
                          _buildExpandableSection('Request Body', Icons.code, const Color(0xFFf59e0b), _bodyExpanded, () => setState(() => _bodyExpanded = !_bodyExpanded), _buildBodyContent()),
                          const SizedBox(height: 12),
                          _buildExpandableSection('Authentication', Icons.lock, const Color(0xFFef4444), _authExpanded, () => setState(() => _authExpanded = !_authExpanded), _buildAuthContent()),
                          const SizedBox(height: 12),
                          _buildExpandableSection('TLS/SSL', Icons.security, const Color(0xFF8b5cf6), _tlsExpanded, () => setState(() => _tlsExpanded = !_tlsExpanded), _buildTLSContent()),
                          const SizedBox(height: 12),
                          _buildExpandableSection('Proxy', Icons.vpn_lock, const Color(0xFF06b6d4), _proxyExpanded, () => setState(() => _proxyExpanded = !_proxyExpanded), _buildProxyContent()),
                          const SizedBox(height: 12),
                          _buildExpandableSection('Cookies', Icons.cookie, const Color(0xFFf97316), _cookiesExpanded, () => setState(() => _cookiesExpanded = !_cookiesExpanded), _buildCookiesContent()),
                          const SizedBox(height: 12),
                          _buildExpandableSection('Options', Icons.settings, const Color(0xFF64748b), _optionsExpanded, () => setState(() => _optionsExpanded = !_optionsExpanded), _buildOptionsContent()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // RIGHT PANEL - Output & Response
          Expanded(
            flex: 1,
            child: Container(
              color: const Color(0xFF0f172a),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Terminal Output
                  Expanded(
                    child: _buildTerminalOutput(),
                  ),
                  const SizedBox(height: 16),
                  // Response Panel
                  Expanded(
                    child: _buildResponsePanel(),
                  ),
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
          colors: [Color(0xFFf59e0b), Color(0xFFef4444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.rocket_launch, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('HTTP Client Professional', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Advanced API Testing Tool', style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.9))),
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
              const Icon(Icons.http, color: Color(0xFFf59e0b), size: 20),
              const SizedBox(width: 8),
              Text('TARGET & METHOD', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1e293b),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: DropdownButton<String>(
                  value: _selectedMethod,
                  underline: const SizedBox(),
                  dropdownColor: const Color(0xFF1e293b),
                  style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w700, color: _getMethodColor(_selectedMethod)),
                  items: _methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) => setState(() => _selectedMethod = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _urlController,
                  style: GoogleFonts.jetBrainsMono(fontSize: 13, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'https://api.example.com/endpoint',
                    hintStyle: GoogleFonts.jetBrainsMono(fontSize: 13, color: Colors.white30),
                    filled: true,
                    fillColor: const Color(0xFF1e293b),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    prefixIcon: Icon(Icons.link, color: Colors.white.withValues(alpha: 0.4), size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _executeRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFf59e0b),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send, size: 18),
                        const SizedBox(width: 8),
                        Text('SEND REQUEST', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method) {
      case 'GET': return const Color(0xFF3b82f6);
      case 'POST': return const Color(0xFF10b981);
      case 'PUT': return const Color(0xFFf59e0b);
      case 'PATCH': return const Color(0xFF8b5cf6);
      case 'DELETE': return const Color(0xFFef4444);
      default: return Colors.grey;
    }
  }

  Widget _buildExpandableSection(String title, IconData icon, Color iconColor, bool expanded, VoidCallback onTap, Widget content) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0f172a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: expanded ? iconColor.withValues(alpha: 0.3) : const Color(0xFF334155)),
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
                  Icon(expanded ? Icons.expand_less : Icons.expand_more, color: Colors.white.withValues(alpha: 0.4), size: 20),
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

  Widget _buildHeadersContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._headers.asMap().entries.map((entry) {
          final index = entry.key;
          final header = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: header['key']),
                    onChanged: (v) => _headers[index]['key'] = v,
                    style: GoogleFonts.jetBrainsMono(fontSize: 12, color: Colors.white),
                    decoration: _inputDecoration('Key'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: header['value']),
                    onChanged: (v) => _headers[index]['value'] = v,
                    style: GoogleFonts.jetBrainsMono(fontSize: 12, color: Colors.white),
                    decoration: _inputDecoration('Value'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 16, color: Colors.white.withValues(alpha: 0.4)),
                  onPressed: () => setState(() => _headers.removeAt(index)),
                ),
              ],
            ),
          );
        }).toList(),
        TextButton.icon(
          onPressed: () => setState(() => _headers.add({'key': '', 'value': ''})),
          icon: const Icon(Icons.add, size: 16, color: Color(0xFF3b82f6)),
          label: Text('Add Header', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF3b82f6))),
        ),
      ],
    );
  }

  Widget _buildQueryContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._queryParams.asMap().entries.map((entry) {
          final index = entry.key;
          final param = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: param['key']),
                    onChanged: (v) => _queryParams[index]['key'] = v,
                    style: GoogleFonts.jetBrainsMono(fontSize: 12, color: Colors.white),
                    decoration: _inputDecoration('Key'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: param['value']),
                    onChanged: (v) => _queryParams[index]['value'] = v,
                    style: GoogleFonts.jetBrainsMono(fontSize: 12, color: Colors.white),
                    decoration: _inputDecoration('Value'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 16, color: Colors.white.withValues(alpha: 0.4)),
                  onPressed: () => setState(() => _queryParams.removeAt(index)),
                ),
              ],
            ),
          );
        }).toList(),
        TextButton.icon(
          onPressed: () => setState(() => _queryParams.add({'key': '', 'value': ''})),
          icon: const Icon(Icons.add, size: 16, color: Color(0xFF10b981)),
          label: Text('Add Parameter', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF10b981))),
        ),
      ],
    );
  }

  Widget _buildBodyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _bodyType,
          dropdownColor: const Color(0xFF1e293b),
          style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
          decoration: _inputDecoration('Body Type'),
          items: ['NONE', 'RAW', 'JSON', 'XML', 'FORM', 'FILE'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) => setState(() => _bodyType = v!),
        ),
        if (_bodyType != 'NONE') ...[
          const SizedBox(height: 12),
          TextField(
            controller: _bodyController,
            maxLines: 8,
            style: GoogleFonts.jetBrainsMono(fontSize: 12, color: Colors.white),
            decoration: _inputDecoration('Request Body'),
          ),
        ],
      ],
    );
  }

  Widget _buildAuthContent() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _authType,
          dropdownColor: const Color(0xFF1e293b),
          style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
          decoration: _inputDecoration('Auth Type'),
          items: ['No Auth', 'Basic', 'Bearer Token', 'API Key'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) => setState(() => _authType = v!),
        ),
        if (_authType == 'Basic') ...[
          const SizedBox(height: 12),
          TextField(
            controller: _basicUserCtrl,
            style: GoogleFonts.jetBrainsMono(fontSize: 12, color: Colors.white),
            decoration: _inputDecoration('Username'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _basicPassCtrl,
            obscureText: true,
            style: GoogleFonts.jetBrainsMono(fontSize: 12, color: Colors.white),
            decoration: _inputDecoration('Password'),
          ),
        ] else if (_authType == 'Bearer Token') ...[
          const SizedBox(height: 12),
          TextField(
            controller: _bearerTokenCtrl,
            style: GoogleFonts.jetBrainsMono(fontSize: 12, color: Colors.white),
            decoration: _inputDecoration('Token'),
          ),
        ] else if (_authType == 'API Key') ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _apiKeyKeyCtrl,
                  style: GoogleFonts.jetBrainsMono(fontSize: 12, color: Colors.white),
                  decoration: _inputDecoration('Key (Header)'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _apiKeyValueCtrl,
                  style: GoogleFonts.jetBrainsMono(fontSize: 12, color: Colors.white),
                  decoration: _inputDecoration('Value'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTLSContent() {
    return DropdownButtonFormField<String>(
      value: _tlsVersion,
      dropdownColor: const Color(0xFF1e293b),
      style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
      decoration: _inputDecoration('TLS Version'),
      items: ['TLS 1.0', 'TLS 1.1', 'TLS 1.2', 'TLS 1.3'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
      onChanged: (v) => setState(() => _tlsVersion = v!),
    );
  }

  Widget _buildProxyContent() {
    return SwitchListTile(
      title: Text('Use Proxy', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
      value: _useProxy,
      activeColor: const Color(0xFF06b6d4),
      contentPadding: EdgeInsets.zero,
      onChanged: (v) => setState(() => _useProxy = v),
    );
  }

  Widget _buildCookiesContent() {
    return SwitchListTile(
      title: Text('Enable Cookies', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
      value: _enableCookies,
      activeColor: const Color(0xFFf97316),
      contentPadding: EdgeInsets.zero,
      onChanged: (v) => setState(() => _enableCookies = v),
    );
  }

  Widget _buildOptionsContent() {
    return Column(
      children: [
        SwitchListTile(
          title: Text('Follow Redirects', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
          value: _followRedirects,
          activeColor: const Color(0xFF64748b),
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => setState(() => _followRedirects = v),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: TextEditingController(text: _timeout.toString()),
          keyboardType: TextInputType.number,
          style: GoogleFonts.jetBrainsMono(fontSize: 12, color: Colors.white),
          decoration: _inputDecoration('Timeout (seconds)'),
          onChanged: (v) => _timeout = int.tryParse(v) ?? 30,
        ),
      ],
    );
  }

  Widget _buildTerminalOutput() {
    // Standardized TerminalOutput using shared widget
    if (_terminalOutput == null && !_isLoading) {
       // Show placeholder consistent with shared widget's behavior or empty state?
       // The shared widget handles empty state but maybe we want to keep the "No output yet" placeholder if it's really empty/null initially?
       // Shared widget shows "Waiting for command..." if running, or "No matches found" if filtered.
       // If completely empty string, it shows "Waiting for command..." inside its build.
       // Here _terminalOutput is null initially.
       // Let's pass empty string.
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return TerminalOutput(
          output: _terminalOutput ?? '',
          isRunning: _isLoading,
          onClear: () => setState(() => _terminalOutput = null),
          height: constraints.maxHeight,
        );
      },
    );
  }

  Widget _buildResponsePanel() {
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
                  color: const Color(0xFF3b82f6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.data_object, color: Color(0xFF3b82f6), size: 18),
              ),
              const SizedBox(width: 12),
              Text('RESPONSE PANEL', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 1)),
              if (_statusCode != null) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusCode! >= 200 && _statusCode! < 300 ? const Color(0xFF10b981).withValues(alpha: 0.15) : const Color(0xFFef4444).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _statusCode! >= 200 && _statusCode! < 300 ? const Color(0xFF10b981).withValues(alpha: 0.3) : const Color(0xFFef4444).withValues(alpha: 0.3)),
                  ),
                  child: Text('$_statusCode $_statusText', style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w600, color: _statusCode! >= 200 && _statusCode! < 300 ? const Color(0xFF10b981) : const Color(0xFFef4444))),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFf59e0b).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, size: 12, color: Color(0xFFf59e0b)),
                      const SizedBox(width: 4),
                      Text('${_responseTime}ms', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: const Color(0xFFf59e0b))),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              if (_responseBody != null) ...[
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  color: Colors.white60,
                  tooltip: 'Copy Response',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _responseBody!));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Response copied!')));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.download, size: 16),
                  color: Colors.white60,
                  tooltip: 'Download Response',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download feature coming soon!')));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  color: Colors.white60,
                  tooltip: 'Clear Response',
                  onPressed: () => setState(() {
                    _responseBody = null;
                    _statusCode = null;
                    _statusText = null;
                    _responseTime = null;
                  }),
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
                child: _responseBody != null
                    ? SelectableText(_formatJson(_responseBody!), style: GoogleFonts.jetBrainsMono(fontSize: 11, color: Colors.white70, height: 1.5))
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.data_object, color: Colors.white.withValues(alpha: 0.1), size: 48),
                            const SizedBox(height: 12),
                            Text('No responses yet', style: GoogleFonts.inter(fontSize: 13, color: Colors.white30)),
                            const SizedBox(height: 4),
                            Text('Run a request to see the responses here', style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withValues(alpha: 0.2))),
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white30),
      filled: true,
      fillColor: const Color(0xFF1e293b),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
    );
  }

  String _formatJson(String body) {
    try {
      final decoded = jsonDecode(body);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (e) {
      return body;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _bodyController.dispose();
    _basicUserCtrl.dispose();
    _basicPassCtrl.dispose();
    _bearerTokenCtrl.dispose();
    _apiKeyKeyCtrl.dispose();
    _apiKeyValueCtrl.dispose();
    super.dispose();
  }
}
