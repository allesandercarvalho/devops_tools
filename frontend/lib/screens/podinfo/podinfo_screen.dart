import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class PodinfoScreen extends StatefulWidget {
  final String toolId;

  const PodinfoScreen({super.key, required this.toolId});

  @override
  State<PodinfoScreen> createState() => _PodinfoScreenState();
}

class _PodinfoScreenState extends State<PodinfoScreen> {
  String _response = 'Loading...';
  bool _isLoading = false;
  Map<String, dynamic>? _jsonData;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(covariant PodinfoScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.toolId != widget.toolId) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _response = 'Fetching data...';
      _jsonData = null;
    });

    String endpoint = '';
    switch (widget.toolId) {
      case 'podinfo_health':
        endpoint = '/healthz';
        break;
      case 'podinfo_env':
        endpoint = '/env';
        break;
      case 'podinfo_metrics':
        endpoint = '/metrics';
        break;
      case 'podinfo_api':
        endpoint = '/version';
        break;
      default:
        // For simulation tools, we don't fetch data immediately
        setState(() {
          _isLoading = false;
          _response = 'Ready to simulate.';
        });
        return;
    }

    try {
      final response = await http.get(Uri.parse('http://localhost:9898$endpoint'));
      if (response.statusCode == 200) {
        setState(() {
          _response = response.body;
          if (response.headers['content-type']?.contains('json') ?? false) {
             try {
               _jsonData = json.decode(response.body);
             } catch (_) {}
          }
        });
      } else {
        setState(() {
          _response = 'Error: ${response.statusCode}\n${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _response = 'Failed to connect to Podinfo.\nMake sure the service is running on port 9898.\nError: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBanner(colorScheme),
            const SizedBox(height: 16),
            _buildHeader(colorScheme),
            const SizedBox(height: 32),
            Expanded(
              child: _buildContent(context, colorScheme),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildBanner(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFf59e0b).withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFf59e0b).withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.construction, color: Color(0xFFf59e0b), size: 20),
          const SizedBox(width: 8),
          Text(
            'UNDER CONSTRUCTION',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFf59e0b),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.construction, color: Color(0xFFf59e0b), size: 20),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    String title = 'Podinfo';
    String subtitle = 'Container Reference Application';
    IconData icon = Icons.pest_control;

    switch (widget.toolId) {
      case 'podinfo_health':
        title = 'Health Checks';
        subtitle = 'Liveness & Readiness Probes Status';
        icon = Icons.monitor_heart;
        break;
      case 'podinfo_env':
        title = 'Environment';
        subtitle = 'Runtime Configuration & Variables';
        icon = Icons.settings_system_daydream;
        break;
      case 'podinfo_crash':
        title = 'Crash Simulator';
        subtitle = 'Trigger Panics & OOM Errors';
        icon = Icons.warning_amber_rounded;
        break;
      case 'podinfo_latency':
        title = 'Latency Injection';
        subtitle = 'Simulate Network Delays & Timeouts';
        icon = Icons.timer_off;
        break;
      case 'podinfo_metrics':
        title = 'Metrics & Traces';
        subtitle = 'Prometheus Metrics & OpenTelemetry';
        icon = Icons.insights;
        break;
      case 'podinfo_logs':
        title = 'Logs Stream';
        subtitle = 'Structured Logging & Events';
        icon = Icons.receipt_long;
        break;
      case 'podinfo_api':
        title = 'API Explorer';
        subtitle = 'REST & gRPC Endpoints';
        icon = Icons.api;
        break;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, size: 32, color: colorScheme.onPrimaryContainer),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, ColorScheme colorScheme) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: colorScheme.primary));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live Data from localhost:9898',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _fetchData,
                tooltip: 'Refresh Data',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _jsonData != null 
                      ? const JsonEncoder.withIndent('  ').convert(_jsonData)
                      : _response,
                  style: GoogleFonts.firaCode(
                    fontSize: 14,
                    color: Colors.greenAccent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
