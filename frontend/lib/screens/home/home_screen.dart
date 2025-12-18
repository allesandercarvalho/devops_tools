import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/supabase_service.dart';
import '../cli_hub/aws/aws_configs_screen.dart';

import '../cli_hub/azure/azure_configs_screen.dart';
import '../cli_hub/gcp/gcp_configs_screen.dart';
import '../cli_hub/network/connectivity/remote_ping_quick_screen.dart';
import '../cli_hub/network/connectivity/remote_ping_advanced_screen.dart';
import '../cli_hub/network/connectivity/traceroute_quick_screen.dart';
import '../cli_hub/network/connectivity/traceroute_advanced_screen.dart';
import '../cli_hub/network/connectivity/tcp_port_checker_quick_screen.dart';
import '../cli_hub/network/connectivity/tcp_port_checker_advanced_screen.dart';
import '../cli_hub/network/dns/dns_lookup_quick_screen.dart';
import '../cli_hub/network/dns/dns_lookup_advanced_screen.dart';
import '../cli_hub/network/dns/dns_propagation_quick_screen.dart';
import '../cli_hub/network/dns/dns_propagation_advanced_screen.dart';
import '../cli_hub/network/nmap/nmap_quick_scan_screen.dart';
import '../cli_hub/network/nmap/nmap_advanced_screen.dart';
import '../cli_hub/network/intelligence/whois_lookup_quick_screen.dart';
import '../cli_hub/network/intelligence/whois_lookup_advanced_screen.dart';
import '../cli_hub/network/security/tls_inspector_quick_screen.dart';
import '../cli_hub/network/security/tls_inspector_advanced_screen.dart';
import '../cli_hub/network/intelligence/geoip_lookup_quick_screen.dart';
import '../cli_hub/network/intelligence/geoip_lookup_advanced_screen.dart';
import '../cli_hub/network/http/http_client_screen.dart';
import '../cli_hub/network/http/http_client_advanced_screen.dart';
import '../cli_hub/terraform/terraform_screen.dart';
import '../cli_hub/argocd/argocd_screen.dart';
import '../cli_hub/kubernetes/kubernetes_screen.dart';

import '../../models/navigation_model.dart';
import '../../widgets/collapsible_sidebar.dart';
import '../podinfo/podinfo_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _selectedTool;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      title: 'CLI Hub',
      icon: Icons.terminal,
      children: [
        NavigationGroup(
          title: 'Cloud',
          icon: Icons.cloud,
          items: [
            NavigationChild(id: 'aws', title: 'AWS', icon: Icons.cloud_queue),
            NavigationChild(id: 'azure', title: 'Azure', icon: Icons.window),
            NavigationChild(id: 'gcp', title: 'GCP', icon: Icons.grid_view),
          ],
        ),
        NavigationGroup(
          title: 'Container Orchestration',
          icon: Icons.anchor,
          items: [
            NavigationChild(id: 'kubernetes', title: 'Kubernetes', icon: Icons.view_quilt),
            NavigationChild(id: 'docker', title: 'Docker', icon: Icons.directions_boat),
          ],
        ),

        NavigationGroup(
          title: 'IaC',
          icon: Icons.architecture,
          items: [
            NavigationChild(id: 'terraform', title: 'Terraform', icon: Icons.layers),
            NavigationChild(id: 'ansible', title: 'Ansible', icon: Icons.settings_applications),
          ],
        ),
        NavigationGroup(
          title: 'GitOps',
          icon: Icons.published_with_changes,
          items: [
            NavigationChild(id: 'argocd', title: 'ArgoCD', icon: Icons.sync),
            NavigationChild(id: 'flux', title: 'Flux', icon: Icons.sync_alt),
          ],
        ),
      ],
    ),
    NavigationItem(
      title: 'Network Tools',
      icon: Icons.network_check,
      children: [
        NavigationGroup(
          title: 'HTTP',
          icon: Icons.http,
          items: [
            NavigationChild(id: 'net_http', title: 'HTTP Client', icon: Icons.http),
            NavigationChild(id: 'net_http_advanced', title: 'HTTP Client Advanced', icon: Icons.rocket_launch),
          ],
        ),
        NavigationGroup(
          title: 'Connectivity',
          icon: Icons.link,
          items: [
            NavigationChild(id: 'net_ping', title: 'Remote Ping - Quick', icon: Icons.network_ping),
            NavigationChild(id: 'net_ping_advanced', title: 'Remote Ping - Advanced', icon: Icons.settings_ethernet),
            NavigationChild(id: 'net_tcp', title: 'TCP Check - Quick', icon: Icons.power),
            NavigationChild(id: 'net_tcp_advanced', title: 'TCP Check - Advanced', icon: Icons.cable),
            NavigationChild(id: 'net_trace', title: 'Traceroute - Quick', icon: Icons.route),
            NavigationChild(id: 'net_trace_advanced', title: 'Traceroute - Advanced', icon: Icons.alt_route),
          ],
        ),
        NavigationGroup(
          title: 'DNS',
          icon: Icons.dns,
          items: [
            NavigationChild(id: 'net_dns', title: 'DNS Lookup - Quick', icon: Icons.search),
            NavigationChild(id: 'net_dns_advanced', title: 'DNS Lookup - Advanced', icon: Icons.manage_search),
            NavigationChild(id: 'net_dns_prop', title: 'DNS Propagation - Quick', icon: Icons.public_off),
            NavigationChild(id: 'net_dns_prop_advanced', title: 'DNS Propagation - Advanced', icon: Icons.public),
          ],
        ),
        NavigationGroup(
          title: 'Scanner',
          icon: Icons.radar,
          items: [
            NavigationChild(id: 'net_nmap', title: 'Nmap Quick Scan', icon: Icons.radar),
            NavigationChild(id: 'net_nmap_advanced', title: 'Nmap Advanced', icon: Icons.troubleshoot),
          ],
        ),
        NavigationGroup(
          title: 'Intelligence',
          icon: Icons.info,
          items: [
            NavigationChild(id: 'net_whois', title: 'Whois Lookup - Quick', icon: Icons.info_outline),
            NavigationChild(id: 'net_whois_advanced', title: 'Whois Lookup - Advanced', icon: Icons.info),
            NavigationChild(id: 'net_geoip', title: 'GeoIP Lookup - Quick', icon: Icons.public),
            NavigationChild(id: 'net_geoip_advanced', title: 'GeoIP Lookup - Advanced', icon: Icons.location_on),
          ],
        ),
        NavigationGroup(
          title: 'Security',
          icon: Icons.security,
          items: [
            NavigationChild(id: 'net_tls', title: 'TLS Inspector - Quick', icon: Icons.security),
            NavigationChild(id: 'net_tls_advanced', title: 'TLS Inspector - Advanced', icon: Icons.verified_user),
          ],
        ),
      ],
    ),
    NavigationItem(
      title: 'Podinfo Suite',
      icon: Icons.pest_control, // Represents the "bug" or "pod" nature
      children: [
        NavigationGroup(
          title: 'Diagnostics',
          icon: Icons.analytics,
          items: [
            NavigationChild(id: 'podinfo_health', title: 'Health Checks', icon: Icons.monitor_heart),
            NavigationChild(id: 'podinfo_env', title: 'Environment', icon: Icons.settings_system_daydream),
          ],
        ),
        NavigationGroup(
          title: 'Chaos Engineering',
          icon: Icons.warning_amber,
          items: [
            NavigationChild(id: 'podinfo_crash', title: 'Crash Simulator', icon: Icons.error_outline),
            NavigationChild(id: 'podinfo_latency', title: 'Latency Injection', icon: Icons.timer_off),
          ],
        ),
        NavigationGroup(
          title: 'Observability',
          icon: Icons.visibility,
          items: [
            NavigationChild(id: 'podinfo_metrics', title: 'Metrics & Traces', icon: Icons.insights),
            NavigationChild(id: 'podinfo_logs', title: 'Logs Stream', icon: Icons.receipt_long),
          ],
        ),
        NavigationGroup(
          title: 'API Testing',
          icon: Icons.api,
          items: [
            NavigationChild(id: 'podinfo_api', title: 'API Explorer', icon: Icons.http),
          ],
        ),
      ],
    ),
  ];

  Widget _getContentWidget() {
    if (_selectedTool == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.developer_board, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Select a tool from the sidebar',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    switch (_selectedTool) {
      case 'aws':
        return const AWSConfigsScreen();
      case 'azure':
        return const AzureConfigsScreen();
      case 'gcp':
        return const GCPConfigsScreen();
      case 'kubernetes':
        return const KubernetesScreen();
      case 'docker':
        return const Center(child: Text('Docker Tool (Coming Soon)'));
      case 'terraform':
        return const TerraformScreen();

      // Network Tools
      case 'net_http':
        return const HttpClientScreen();
      case 'net_http_advanced':
        return const HttpClientAdvancedScreen();
      // Connectivity
      case 'net_ping':
        return const RemotePingQuickScreen();
      case 'net_ping_advanced':
        return const RemotePingAdvancedScreen();
      case 'net_trace':
        return const TracerouteQuickScreen();
      case 'net_trace_advanced':
        return const TracerouteAdvancedScreen();
      case 'net_tcp':
        return const TCPPortCheckerQuickScreen();
      case 'net_tcp_advanced':
        return const TCPPortCheckerAdvancedScreen();
      // DNS
      case 'net_dns':
        return const DNSLookupQuickScreen();
      case 'net_dns_advanced':
        return const DNSLookupAdvancedScreen();
      case 'net_dns_prop':
        return const DNSPropagationQuickScreen();
      case 'net_dns_prop_advanced':
        return const DNSPropagationAdvancedScreen();
      // Scanner
      case 'net_nmap':
        return const NmapQuickScanScreen();
      case 'net_nmap_advanced':
        return const NmapAdvancedScreen();
      // Intelligence
      case 'net_whois':
        return const WhoisLookupQuickScreen();
      case 'net_whois_advanced':
        return const WhoisLookupAdvancedScreen();
      case 'net_geoip':
        return const GeoIPLookupQuickScreen();
      case 'net_geoip_advanced':
        return const GeoIPLookupAdvancedScreen();
      // Security
      case 'net_tls':
        return const TLSInspectorQuickScreen();
      case 'net_tls_advanced':
        return const TLSInspectorAdvancedScreen();
      // Placeholders
      case 'argocd_apps':
        return const ArgoCDScreen();

      
      // Podinfo Suite
      case 'podinfo_health':
      case 'podinfo_env':
      case 'podinfo_crash':
      case 'podinfo_latency':
      case 'podinfo_metrics':
      case 'podinfo_logs':
      case 'podinfo_api':
        return PodinfoScreen(toolId: _selectedTool!);
        
      default:
        return Center(
          child: Column(children: [Text('Tool not implemented yet')]));
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Row(
        children: [
          // Collapsible Sidebar
          CollapsibleSidebar(
            items: _navigationItems,
            selectedIndex: _selectedIndex,
            selectedToolId: _selectedTool,
            onItemSelected: (index, toolId) {
              setState(() {
                _selectedIndex = index;
                _selectedTool = toolId;
              });
            },
          ),

          // Main Content
          Expanded(
            child: Container(
              color: colorScheme.surfaceContainerLowest,
              child: _getContentWidget(),
            ),
          ),
        ],
      ),
    );
  }
}
