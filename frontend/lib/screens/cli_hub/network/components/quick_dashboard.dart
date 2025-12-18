import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/network_tool.dart';

class QuickDashboard extends StatelessWidget {
  final NetworkToolExecution execution;
  final String toolType; // 'ping', 'tcp', 'dns', 'http', 'traceroute'

  const QuickDashboard({
    super.key,
    required this.execution,
    required this.toolType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Execution Summary',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: 16),
          _buildContent(context),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final success = execution.status == 'success';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: success ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: success ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(success ? Icons.check_circle : Icons.error, size: 14, color: success ? Colors.greenAccent : Colors.redAccent),
          const SizedBox(width: 6),
          Text(
            success ? 'SUCCESS' : 'FAILED',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: success ? Colors.greenAccent : Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    // Clean output once for all dashboards to use
    final cleanOutput = _stripAnsi(execution.output);
    
    switch (toolType) {
      case 'ping':
        return _buildPingDashboard(context, cleanOutput);
      case 'tcp':
        return _buildTcpDashboard(context, cleanOutput);
      case 'dns':
      case 'dig':
        return _buildDnsDashboard(context, cleanOutput);
      case 'dns-propagation':
        return _buildDnsPropagationDashboard(context, cleanOutput);
      case 'http':
        return _buildHttpDashboard(context, cleanOutput);
      case 'traceroute':
        return _buildTracerouteDashboard(context, cleanOutput);
      case 'whois':
        return _buildWhoisDashboard(context, cleanOutput);
      case 'geoip':
        return _buildGeoIpDashboard(context, cleanOutput);
      case 'tls-inspect':
        return _buildTlsDashboard(context, cleanOutput);
      case 'nmap':
        return _buildNmapDashboard(context, cleanOutput);
      default:
        return const Center(child: Text('No dashboard available'));
    }
  }

  String _stripAnsi(String text) {
    // Regex to strip ANSI escape codes
    final ansiRegex = RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]');
    return text.replaceAll(ansiRegex, '').trim();
  }

  // --- PING DASHBOARD ---
  Widget _buildPingDashboard(BuildContext context, String output) {
    // Attempt to parse output if parsedResult is missing
    double? min, avg, max, mdev;
    double? packetLoss;
    
    // Regex for: rtt min/avg/max/mdev = 13.948/13.948/13.948/0.000 ms
    final rttRegex = RegExp(r'min\/avg\/max\/(?:mdev|stddev)\s*=\s*([\d\.]+)\/([\d\.]+)\/([\d\.]+)\/([\d\.]+)');
    final match = rttRegex.firstMatch(output);
    if (match != null) {
      min = double.tryParse(match.group(1) ?? '');
      avg = double.tryParse(match.group(2) ?? '');
      max = double.tryParse(match.group(3) ?? '');
      mdev = double.tryParse(match.group(4) ?? '');
    }

    // Regex for: 0% packet loss
    final lossRegex = RegExp(r'(\d+)% packet loss');
    final lossMatch = lossRegex.firstMatch(output);
    if (lossMatch != null) {
      packetLoss = double.tryParse(lossMatch.group(1) ?? '');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricCard('Packet Loss', '${packetLoss ?? 0}%', 
              icon: Icons.network_check, 
              color: (packetLoss ?? 0) == 0 ? Colors.green : Colors.red,
              width: (constraints.maxWidth - 16) / 2
            ),
            _buildMetricCard('Average RTT', '${avg ?? "--"} ms', 
              icon: Icons.timer, 
              color: Colors.blue,
              width: (constraints.maxWidth - 16) / 2
            ),
            _buildMetricCard('Min RTT', '${min ?? "--"} ms', 
              icon: Icons.vertical_align_bottom, 
              color: Colors.cyan,
              width: (constraints.maxWidth - 16) / 2
            ),
            _buildMetricCard('Max RTT', '${max ?? "--"} ms', 
              icon: Icons.vertical_align_top, 
              color: Colors.orange,
              width: (constraints.maxWidth - 16) / 2
            ),
          ],
        );
      }
    );
  }

  // --- TCP DASHBOARD ---
  Widget _buildTcpDashboard(BuildContext context, String output) {
    final success = execution.status == 'success';
    final duration = execution.durationMs;
    // Try to find specific latency in output if available, else use total duration
    
    return Column(
      children: [
        _buildMetricCard(
          'Port Status', 
          success ? 'OPEN' : 'CLOSED', 
          icon: success ? Icons.lock_open : Icons.lock, 
          color: success ? Colors.green : Colors.red,
          width: double.infinity
        ),
        const SizedBox(height: 16),
        _buildMetricCard(
          'Latency', 
          '$duration ms', 
          icon: Icons.timer, 
          color: Colors.blue,
          width: double.infinity
        ),
      ],
    );
  }

  // --- DNS DASHBOARD ---
  Widget _buildDnsDashboard(BuildContext context, String output) {
    if (execution.parsedResult is DNSResult) {
      final res = execution.parsedResult as DNSResult;
       return Column(
        children: [
          _buildMetricCard(
            'Answers', 
            '${res.answers.length}', 
            icon: Icons.list_alt, 
            color: Colors.purple,
            width: double.infinity
          ),
          const SizedBox(height: 16),
          _buildMetricCard(
            'Query Time', 
            '${res.queryTime} ms', 
            icon: Icons.timer, 
            color: Colors.blue,
            width: double.infinity
          ),
          const SizedBox(height: 16),
          _buildMetricCard(
            'Server', 
            res.server.isEmpty ? 'Default' : res.server, 
            icon: Icons.dns, 
            color: Colors.teal,
            width: double.infinity
          ),
        ],
      );
    }

    // Fallback regex
    final recordCount = output.split('\n').where((l) => l.contains('IN') && !l.startsWith(';')).length;
    final server = 'Default';

    return Column(
      children: [
        _buildMetricCard(
          'Records Found', 
          '$recordCount', 
          icon: Icons.list_alt, 
          color: Colors.purple,
          width: double.infinity
        ),
        const SizedBox(height: 16),
        _buildMetricCard(
          'Server', 
          server, 
          icon: Icons.dns, 
          color: Colors.teal,
          width: double.infinity
        ),
      ],
    );
  }

  // --- DNS PROPAGATION DASHBOARD ---
  Widget _buildDnsPropagationDashboard(BuildContext context, String output) {
     if (execution.parsedResult is DNSPropagationResult) {
        final res = execution.parsedResult as DNSPropagationResult;
        final total = res.servers.length;
        // Count fully propagated (status == ok or records not empty)
        final resolved = res.servers.values.where((d) => (d.status == 'ok' || d.records.isNotEmpty)).length;
        final percent = total > 0 ? (resolved / total * 100).toStringAsFixed(0) : '0';

        return Column(
          children: [
            _buildMetricCard(
              'Propagated', 
              '$percent%', 
              icon: Icons.public, 
              color: (int.parse(percent) > 80) ? Colors.green : Colors.orange,
              width: double.infinity
            ),
            const SizedBox(height: 16),
            _buildMetricCard(
              'Locations', 
              '$resolved / $total', 
              icon: Icons.map, 
              color: Colors.blueAccent,
              width: double.infinity
            ),
          ],
        );
     }
     
     return const Center(child: Text('No propagation data'));
  }

  // --- HTTP DASHBOARD ---
  Widget _buildHttpDashboard(BuildContext context, String output) {
    // Assumes simple output or parsed result
    // Regex for HTTP/1.1 200 OK
    final statusRegex = RegExp(r'HTTP\/\d\.\d\s(\d{3})');
    final match = statusRegex.firstMatch(output);
    final statusCode = match != null ? match.group(1) : '---';

    return Column(
      children: [
        _buildMetricCard(
          'Status Code', 
          statusCode ?? 'Unknown', 
          icon: Icons.http, 
          color: (statusCode?.startsWith('2') ?? false) ? Colors.green : Colors.orange,
          width: double.infinity
        ),
        const SizedBox(height: 16),
        _buildMetricCard(
          'Duration', 
          '${execution.durationMs} ms', 
          icon: Icons.timer, 
          color: Colors.blue,
          width: double.infinity
        ),
      ],
    );
  }
  
  // --- TRACEROUTE DASHBOARD ---
  Widget _buildTracerouteDashboard(BuildContext context, String output) {
     final hopCount = output.split('\n').where((l) => RegExp(r'^\s*\d+').hasMatch(l)).length;

     return Column(
      children: [
        _buildMetricCard(
          'Hops', 
          '$hopCount', 
          icon: Icons.alt_route, 
          color: Colors.indigo,
          width: double.infinity
        ),
        const SizedBox(height: 16),
        _buildMetricCard(
          'Duration', 
          '${execution.durationMs} ms', 
          icon: Icons.timer, 
          color: Colors.blue,
          width: double.infinity
        ),
      ],
    );
  }


  Widget _buildMetricCard(String label, String value, {required IconData icon, required Color color, double width = 150}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  // --- WHOIS DASHBOARD ---
  Widget _buildWhoisDashboard(BuildContext context, String output) {
    String registrar = 'Unknown';
    String expiry = 'Unknown';

    if (execution.parsedResult is WhoisResult) {
      final res = execution.parsedResult as WhoisResult;
      registrar = res.registrar;
      expiry = res.expiryDate;
    } else {
      // Fallback Regex
      final regMatch = RegExp(r'(?:Registrar|registrar|Registrant Organization):\s*(.+)').firstMatch(output);
      if (regMatch != null) registrar = regMatch.group(1)?.trim() ?? 'Unknown';

      // Broader date match
      final expMatch = RegExp(r'(?:Expiry Date|Expiration Date|Registry Expiry Date|paid-till):\s*(.+)').firstMatch(output);
      if (expMatch != null) expiry = expMatch.group(1)?.trim() ?? 'Unknown';
    }

    if (registrar == 'Unknown' && expiry == 'Unknown') {
       return const Center(child: Text('No structured WHOIS data'));
    }

    return Column(
      children: [
        _buildMetricCard(
          'Registrar', 
          registrar.length > 20 ? '${registrar.substring(0, 17)}...' : registrar, 
          icon: Icons.business, 
          color: Colors.blue,
          width: double.infinity
        ),
        const SizedBox(height: 16),
        _buildMetricCard(
          'Expires', 
          expiry.split('T').first.split(' ').first, 
          icon: Icons.calendar_today, 
          color: Colors.orange,
          width: double.infinity
        ),
      ],
    );
  }

  // --- GEOIP DASHBOARD ---
  Widget _buildGeoIpDashboard(BuildContext context, String output) {
    String location = 'Unknown';
    String isp = 'Unknown';

    if (execution.parsedResult is GeoIPResult) {
      final res = execution.parsedResult as GeoIPResult;
      location = '${res.city}, ${res.countryCode}';
      isp = res.isp;
    } else {
      // Fallback Regex
      final countryMatch = RegExp(r'(?:Country|country):\s*(.+)').firstMatch(output);
      final cityMatch = RegExp(r'(?:City|city):\s*(.+)').firstMatch(output);
      
      String country = countryMatch?.group(1)?.trim() ?? '';
      String city = cityMatch?.group(1)?.trim() ?? '';
      
      if (country.isEmpty) {
        // Try searching for Country Code
        final ccMatch = RegExp(r'(?:Country Code|country code):\s*([A-Za-z]{2})').firstMatch(output);
        if (ccMatch != null) country = ccMatch.group(1) ?? '';
      }
      
      if (country.isNotEmpty || city.isNotEmpty) {
        location = '$city, $country'.trim();
        if (location.startsWith(',')) location = location.substring(1).trim();
        if (location.endsWith(',')) location = location.substring(0, location.length - 1).trim();
      }

      final ispMatch = RegExp(r'(?:ISP|isp|Organization|org):\s*(.+)').firstMatch(output);
      if (ispMatch != null) isp = ispMatch.group(1)?.trim() ?? 'Unknown';
    }

    if (location == 'Unknown' && isp == 'Unknown') {
       return const Center(child: Text('No structured GeoIP data'));
    }

    return Column(
      children: [
        _buildMetricCard(
          'Location', 
          location, 
          icon: Icons.location_on, 
          color: Colors.red,
          width: double.infinity
        ),
        const SizedBox(height: 16),
        _buildMetricCard(
          'ISP', 
          isp.length > 20 ? '${isp.substring(0, 17)}...' : isp, 
          icon: Icons.router, 
          color: Colors.blue,
          width: double.infinity
        ),
      ],
    );
  }

  // --- TLS DASHBOARD ---
  Widget _buildTlsDashboard(BuildContext context, String output) {
    bool? isValid;
    String expiry = 'Unknown';
    String issuer = 'Unknown';

    if (execution.parsedResult is TLSResult) {
      final res = execution.parsedResult as TLSResult;
      isValid = res.isValid;
      expiry = '${res.daysToExpiry} days';
      issuer = res.issuer.split(',').firstWhere((e) => e.startsWith('O='), orElse: () => res.issuer).replaceAll('O=', '');
    } else {
      // Fallback Regex
      if (output.contains('Certificate is valid') || output.contains('Verify return code: 0 (ok)')) {
        isValid = true;
      } else if (output.contains('Verify return code:')) {
        isValid = false;
      }

      final expMatch = RegExp(r'Not After\s*:\s*(.+)').firstMatch(output);
      if (expMatch != null) {
         try {
           // Parse standard OpenSSL date format if possible, else just show string
           expiry = expMatch.group(1)?.trim() ?? 'Unknown';
         } catch (e) {
           expiry = expMatch.group(1)?.trim() ?? 'Unknown';
         }
      }

      final issuerMatch = RegExp(r'(?:Issuer|issuer):\s*(.+)').firstMatch(output);
      if (issuerMatch != null) {
        String fullIssuer = issuerMatch.group(1)?.trim() ?? '';
        // Try to extract O=...
        final oMatch = RegExp(r'O\s*=\s*([^,/]+)').firstMatch(fullIssuer);
        if (oMatch != null) {
          issuer = oMatch.group(1)?.trim() ?? fullIssuer;
        } else {
          // If no O=, try CN=
          final cnMatch = RegExp(r'CN\s*=\s*([^,/]+)').firstMatch(fullIssuer);
           if (cnMatch != null) {
             issuer = cnMatch.group(1)?.trim() ?? fullIssuer;
           } else {
             issuer = fullIssuer;
           }
        }
      }
    }

    if (isValid == null && expiry == 'Unknown' && issuer == 'Unknown') {
       return const Center(child: Text('No structured TLS data'));
    }

    return Column(
      children: [
        _buildMetricCard(
          'Valid', 
          isValid == true ? 'YES' : (isValid == false ? 'NO' : '?'), 
          icon: isValid == true ? Icons.check_circle : (isValid == false ? Icons.error : Icons.help), 
          color: isValid == true ? Colors.green : (isValid == false ? Colors.red : Colors.grey),
          width: double.infinity
        ),
        const SizedBox(height: 16),
        _buildMetricCard(
          'Expires', 
          expiry, 
          icon: Icons.timer, 
          color: Colors.blue,
          width: double.infinity
        ),
           const SizedBox(height: 16),
           _buildMetricCard(
            'Issuer', 
            issuer.length > 15 ? '${issuer.substring(0, 12)}...' : issuer, 
            icon: Icons.verified_user, 
            color: Colors.teal,
            width: double.infinity
          ),
      ],
    );
  }
  // --- NMAP DASHBOARD ---
  Widget _buildNmapDashboard(BuildContext context, String output) {
    if (execution.parsedResult is NmapResult) {
       final res = execution.parsedResult as NmapResult;
       int totalPorts = 0;
       res.hosts.forEach((h) => totalPorts += h.ports.where((p) => p.state == 'open').length);

       return Column(
         children: [
            _buildMetricCard(
              'Hosts Up', 
              '${res.hosts.length}', 
              icon: Icons.computer, 
              color: Colors.green,
              width: double.infinity
            ),
          const SizedBox(height: 16),
          _buildMetricCard(
            'Open Ports', 
            '$totalPorts', 
            icon: Icons.lock_open, 
            color: Colors.orange,
            width: double.infinity
          ),
         ],
       );
    }

    // Fallback Regex
    // Handle "Nmap done: 1 IP address (1 host up)" OR "Nmap done: 256 IP addresses (10 hosts up)"
    final hostsMatch = RegExp(r'Nmap done: \d+ IP address(?:es)? \((\d+) hosts? up\)').firstMatch(output);
    final hostsUp = hostsMatch?.group(1) ?? '0';

    final openPortsMatch = RegExp(r'(\d+)\/tcp\s+open').allMatches(output).length;

    return Column(
         children: [
            _buildMetricCard(
              'Hosts Up', 
              hostsUp, 
              icon: Icons.computer, 
              color: Colors.green,
              width: double.infinity
            ),
          const SizedBox(height: 16),
          _buildMetricCard(
            'Open Ports', 
            '$openPortsMatch', 
            icon: Icons.lock_open, 
            color: Colors.orange,
            width: double.infinity
          ),
         ],
       );
  }
}
