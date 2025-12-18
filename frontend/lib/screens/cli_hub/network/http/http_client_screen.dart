import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../../../../models/http_request.dart';
import '../../../../services/network_api_service.dart';

class HttpClientScreen extends StatefulWidget {
  const HttpClientScreen({super.key});

  @override
  State<HttpClientScreen> createState() => _HttpClientScreenState();
}

class _HttpClientScreenState extends State<HttpClientScreen> {
  final _urlController = TextEditingController();
  String _selectedMethod = 'GET';
  final List<String> _methods = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS'];
  
  // Request data
  final Map<String, String> _headers = {};
  final Map<String, String> _queryParams = {};
  final _bodyController = TextEditingController();
  String _bodyType = 'json';
  String _authType = 'none';
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _tokenController = TextEditingController();
  
  // Response data
  HttpResponseModel? _response;
  String? _rawResponse;
  bool _isLoading = false;
  String _error = '';
  
  // UI state
  bool _showHeaders = false;
  bool _showParams = false;
  bool _showBody = false;
  bool _showAuth = false;

  Future<void> _sendRequest() async {
    if (_urlController.text.isEmpty) {
      setState(() => _error = 'URL is required');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
      _response = null;
    });

    try {
      final request = HttpRequestModel(
        method: _selectedMethod,
        url: _urlController.text,
        headers: _headers,
        queryParams: _queryParams,
        body: _bodyController.text,
        bodyType: _bodyType,
        auth: _authType != 'none' ? AuthConfig(
          type: _authType,
          username: _usernameController.text.isNotEmpty ? _usernameController.text : null,
          password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
          token: _tokenController.text.isNotEmpty ? _tokenController.text : null,
        ) : null,
      );

      final execution = await NetworkApiService.executeCurlRequest(request.toJson());
      
      if (execution.parsedResult != null) {
        setState(() {
          _response = HttpResponseModel.fromJson(execution.parsedResult as Map<String, dynamic>);
          _rawResponse = execution.output;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = execution.error ?? 'Unknown error';
          _rawResponse = execution.output;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
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
          _buildRequestSection(),
          Expanded(
            child: Row(
              children: [
                Expanded(flex: 2, child: _buildResponsePanel()),
                Expanded(flex: 1, child: _buildStatsPanel()),
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
        gradient: LinearGradient(
          colors: [Color(0xFFf59e0b), Color(0xFFef4444)],
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
            child: const Icon(Icons.http, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('HTTP Client', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Test APIs and HTTP endpoints', style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequestSection() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // URL Bar
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1e293b),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedMethod,
                    underline: const SizedBox(),
                    dropdownColor: const Color(0xFF1e293b),
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFFf59e0b)),
                    items: _methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setState(() => _selectedMethod = v!),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _urlController,
                  style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'https://api.example.com/endpoint',
                    hintStyle: GoogleFonts.jetBrainsMono(color: Colors.white30),
                    filled: true,
                    fillColor: const Color(0xFF1e293b),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.link, color: Colors.white70),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isLoading ? null : _sendRequest,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  backgroundColor: const Color(0xFFf59e0b),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Row(children: [const Icon(Icons.send), const SizedBox(width: 8), Text('Send', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600))]),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Quick options
          Wrap(
            spacing: 8,
            children: [
              _buildOptionChip('Params', _showParams, () => setState(() => _showParams = !_showParams)),
              _buildOptionChip('Headers', _showHeaders, () => setState(() => _showHeaders = !_showHeaders)),
              _buildOptionChip('Body', _showBody, () => setState(() => _showBody = !_showBody)),
              _buildOptionChip('Auth', _showAuth, () => setState(() => _showAuth = !_showAuth)),
            ],
          ),
          
          // Expandable sections
          if (_showParams) _buildParamsSection(),
          if (_showHeaders) _buildHeadersSection(),
          if (_showBody) _buildBodySection(),
          if (_showAuth) _buildAuthSection(),
          
          // Error
          if (_error.isNotEmpty) _buildErrorBanner(),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionChip(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFf59e0b).withValues(alpha: 0.2) : const Color(0xFF1e293b),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? const Color(0xFFf59e0b) : const Color(0xFF334155)),
        ),
        child: Text(label, style: GoogleFonts.inter(color: selected ? const Color(0xFFf59e0b) : Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildParamsSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Query Parameters', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildKeyValueInput('param_key', 'param_value', _queryParams),
          if (_queryParams.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._queryParams.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(child: Text(e.key, style: GoogleFonts.jetBrainsMono(color: Colors.white70, fontSize: 12))),
                  const SizedBox(width: 8),
                  Expanded(child: Text(e.value, style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 12))),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16),
                    color: Colors.red,
                    onPressed: () => setState(() => _queryParams.remove(e.key)),
                  ),
                ],
              ),
            )).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeadersSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Headers', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildKeyValueInput('header_key', 'header_value', _headers),
          if (_headers.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._headers.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(child: Text(e.key, style: GoogleFonts.jetBrainsMono(color: Colors.white70, fontSize: 12))),
                  const SizedBox(width: 8),
                  Expanded(child: Text(e.value, style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 12))),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16),
                    color: Colors.red,
                    onPressed: () => setState(() => _headers.remove(e.key)),
                  ),
                ],
              ),
            )).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildBodySection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
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
              Text('Body', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w600)),
              const Spacer(),
              DropdownButton<String>(
                value: _bodyType,
                dropdownColor: const Color(0xFF0f172a),
                style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                underline: const SizedBox(),
                items: ['json', 'xml', 'form', 'raw'].map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
                onChanged: (v) => setState(() => _bodyType = v!),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyController,
            maxLines: 6,
            style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: '{"key": "value"}',
              hintStyle: GoogleFonts.jetBrainsMono(color: Colors.white30),
              filled: true,
              fillColor: const Color(0xFF0f172a),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Authentication', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _authType,
            dropdownColor: const Color(0xFF0f172a),
            style: GoogleFonts.inter(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0f172a),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
            items: ['none', 'basic', 'bearer'].map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
            onChanged: (v) => setState(() => _authType = v!),
          ),
          if (_authType == 'basic') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _usernameController,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Username',
                labelStyle: GoogleFonts.inter(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF0f172a),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: GoogleFonts.inter(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF0f172a),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
          ],
          if (_authType == 'bearer') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _tokenController,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Token',
                labelStyle: GoogleFonts.inter(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF0f172a),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKeyValueInput(String keyHint, String valueHint, Map<String, String> map) {
    final controller1 = TextEditingController();
    final controller2 = TextEditingController();
    
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller1,
            style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Key',
              hintStyle: GoogleFonts.jetBrainsMono(color: Colors.white30),
              filled: true,
              fillColor: const Color(0xFF0f172a),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller2,
            style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Value',
              hintStyle: GoogleFonts.jetBrainsMono(color: Colors.white30),
              filled: true,
              fillColor: const Color(0xFF0f172a),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: Color(0xFFf59e0b)),
          onPressed: () {
            if (controller1.text.isNotEmpty) {
              setState(() => map[controller1.text] = controller2.text);
              controller1.clear();
              controller2.clear();
            }
          },
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(child: Text(_error, style: GoogleFonts.inter(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _buildResponsePanel() {
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
              const Icon(Icons.terminal, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text('Response', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (_response != null)
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  color: Colors.white70,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _response!.curlCommand));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('cURL command copied')));
                  },
                  tooltip: 'Copy as cURL',
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: _response != null
                  ? SelectableText(
                      _formatBody(_response!.body, _response!.contentType),
                      style: GoogleFonts.jetBrainsMono(color: Colors.greenAccent, fontSize: 12),
                    )
                  : Center(child: Text('No response yet. Send a request to see results.', style: GoogleFonts.inter(color: Colors.white30))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsPanel() {
    if (_response == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        child: Center(child: Text('Statistics will appear here', style: GoogleFonts.inter(color: Colors.white30))),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildStatCard('Status', '${_response!.statusCode} ${_response!.statusText}', Icons.check_circle_outline, _response!.isSuccess ? Colors.green : Colors.red),
            const SizedBox(height: 16),
            _buildStatCard('Time', '${_response!.timeMs} ms', Icons.timer_outlined, const Color(0xFF3b82f6)),
            const SizedBox(height: 16),
            _buildStatCard('Size', _formatBytes(_response!.contentLength), Icons.storage_outlined, const Color(0xFF8b5cf6)),
            const SizedBox(height: 16),
            _buildStatCard('Type', _response!.contentType.split(';').first, Icons.description_outlined, const Color(0xFFf59e0b)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
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

  String _formatBody(String body, String contentType) {
    if (contentType.contains('json')) {
      try {
        final decoded = jsonDecode(body);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      } catch (e) {
        return body;
      }
    }
    return body;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  void dispose() {
    _urlController.dispose();
    _bodyController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _tokenController.dispose();
    super.dispose();
  }
}
