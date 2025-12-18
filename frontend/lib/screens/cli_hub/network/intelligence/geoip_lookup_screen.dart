import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/network_tool.dart';
import '../../../../services/network_api_service.dart';

class GeoIPLookupScreen extends StatefulWidget {
  const GeoIPLookupScreen({super.key});

  @override
  State<GeoIPLookupScreen> createState() => _GeoIPLookupScreenState();
}

class _GeoIPLookupScreenState extends State<GeoIPLookupScreen> {
  final _ipController = TextEditingController();
  NetworkToolExecution? _execution;
  bool _isRunning = false;
  String _error = '';

  Future<void> _lookupGeoIP() async {
    if (_ipController.text.isEmpty) {
      setState(() => _error = 'Please enter an IP address');
      return;
    }

    setState(() {
      _isRunning = true;
      _error = '';
      _execution = null;
    });

    try {
      final result = await NetworkApiService.lookupGeoIP(ip: _ipController.text);

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
        gradient: LinearGradient(colors: [const Color(0xFF06b6d4), const Color(0xFF0ea5e9)]),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.public, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('GeoIP Lookup', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('IP geolocation information', style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.8))),
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
              controller: _ipController,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'IP Address',
                hintText: '8.8.8.8',
                labelStyle: GoogleFonts.inter(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF1e293b),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.location_on, color: Colors.white70),
              ),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _isRunning ? null : _lookupGeoIP,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              backgroundColor: const Color(0xFF06b6d4),
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

  Widget _buildContent() {
    if (_execution?.parsedResult == null) {
      return Center(child: Text('Location info will appear here', style: GoogleFonts.inter(color: Colors.white30, fontSize: 18)));
    }

    final result = _execution!.parsedResult as GeoIPResult;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Map placeholder (would integrate real map in production)
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: const Color(0xFF1e293b),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF06b6d4).withOpacity(0.3)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map, color: Color(0xFF06b6d4), size: 64),
                  const SizedBox(height: 16),
                  Text('${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}', style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 18)),
                  Text('${result.city}, ${result.country}', style: GoogleFonts.inter(color: Colors.white70, fontSize: 16)),
                ],
              ),
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
            childAspectRatio: 2,
            children: [
              _buildInfoCard('IP Address', result.ip, Icons.router),
              _buildInfoCard('Country', '${result.country} (${result.countryCode})', Icons.flag),
              _buildInfoCard('Region', result.region, Icons.location_city),
              _buildInfoCard('City', result.city, Icons.location_on),
              _buildInfoCard('ISP', result.isp, Icons.business),
              _buildInfoCard('Organization', result.organization, Icons.corporate_fare),
            ],
          ),
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
        border: Border.all(color: const Color(0xFF06b6d4).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF06b6d4), size: 20),
          const SizedBox(height: 8),
          Text(title, style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }
}
