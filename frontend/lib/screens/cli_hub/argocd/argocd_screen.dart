import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/argocd.dart';
import '../../../../services/argocd_api_service.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/app_header.dart';
import '../../../../widgets/common/app_card.dart';

class ArgoCDScreen extends StatefulWidget {
  const ArgoCDScreen({super.key});

  @override
  State<ArgoCDScreen> createState() => _ArgoCDScreenState();
}

class _ArgoCDScreenState extends State<ArgoCDScreen> {
  List<ArgoAppDetail> _apps = [];
  bool _isLoading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final apps = await ArgoCDApiService.listApplications();
      setState(() {
        _apps = apps;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _syncApp(String name) async {
    try {
      await ArgoCDApiService.syncApplication(name);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync started for $name')));
      _loadApps(); // Refresh status
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to sync: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          AppHeader(
            title: 'ArgoCD Dashboard',
            subtitle: 'GitOps Continuous Delivery',
            icon: Icons.anchor,
            gradientColors: const [Color(0xFF0ea5e9), Color(0xFF38bdf8)],
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadApps,
              ),
            ],
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppTheme.error, size: 48),
            const SizedBox(height: 16),
            Text(_error, style: GoogleFonts.inter(color: AppTheme.error)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadApps, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_apps.isEmpty) {
      return Center(child: Text('No applications found', style: GoogleFonts.inter(color: AppTheme.textMuted)));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 1.2,
      ),
      itemCount: _apps.length,
      itemBuilder: (context, index) {
        return _buildAppCard(_apps[index]);
      },
    );
  }

  Widget _buildAppCard(ArgoAppDetail app) {
    final isHealthy = app.health.status == 'Healthy';
    final isSynced = app.sync.status == 'Synced';

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.apps, color: AppTheme.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    app.name,
                    style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: AppTheme.textSecondary),
                  onSelected: (value) {
                    if (value == 'sync') _syncApp(app.name);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'sync', child: Text('Sync')),
                    const PopupMenuItem(value: 'details', child: Text('Details')),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.1), height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStatusRow('Health', app.health.status, isHealthy ? AppTheme.success : AppTheme.warning),
                const SizedBox(height: 8),
                _buildStatusRow('Sync', app.sync.status, isSynced ? AppTheme.success : AppTheme.warning),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.link, size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 8),
                    Expanded(child: Text(app.source.repoURL, style: GoogleFonts.jetBrainsMono(color: AppTheme.textMuted, fontSize: 11), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(app.destination.namespace, style: GoogleFonts.jetBrainsMono(color: AppTheme.textSecondary, fontSize: 12)),
                Text(app.source.targetRevision, style: GoogleFonts.jetBrainsMono(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Row(
      children: [
        Text(label, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(value, style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
