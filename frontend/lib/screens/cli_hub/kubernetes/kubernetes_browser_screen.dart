import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KubernetesBrowserScreen extends StatefulWidget {
  final String searchQuery;
  final String viewType;
  final String selectedCategory;

  const KubernetesBrowserScreen({super.key, required this.searchQuery, required this.viewType, required this.selectedCategory});

  @override
  State<KubernetesBrowserScreen> createState() => _KubernetesBrowserScreenState();
}

class _KubernetesBrowserScreenState extends State<KubernetesBrowserScreen> {
  // Mock Data
  final List<Map<String, dynamic>> _resources = [
    {'name': 'frontend-deployment', 'kind': 'Deployment', 'namespace': 'default', 'status': 'Running', 'age': '2d'},
    {'name': 'backend-api', 'kind': 'Deployment', 'namespace': 'default', 'status': 'Running', 'age': '2d'},
    {'name': 'database-statefulset', 'kind': 'StatefulSet', 'namespace': 'data', 'status': 'Running', 'age': '5d'},
    {'name': 'frontend-svc', 'kind': 'Service', 'namespace': 'default', 'status': 'Active', 'age': '2d'},
    {'name': 'ingress-main', 'kind': 'Ingress', 'namespace': 'default', 'status': 'Active', 'age': '2d'},
    {'name': 'redis-cache', 'kind': 'Pod', 'namespace': 'cache', 'status': 'CrashLoopBackOff', 'age': '1h'},
    {'name': 'worker-job-1', 'kind': 'Job', 'namespace': 'batch', 'status': 'Completed', 'age': '4h'},
    {'name': 'config-app', 'kind': 'ConfigMap', 'namespace': 'default', 'status': 'Active', 'age': '10d'},
  ];

  final Map<String, IconData> _icons = {
    'Deployment': Icons.cached,
    'StatefulSet': Icons.layers,
    'Pod': Icons.adjust,
    'Service': Icons.share,
    'Ingress': Icons.input,
    'Job': Icons.work,
    'ConfigMap': Icons.settings,
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Filter
    final filtered = _resources.where((r) {
       final search = widget.searchQuery.toLowerCase();
       final matchesSearch = r['name'].toLowerCase().contains(search) || r['kind'].toLowerCase().contains(search);
       // Simple category mapping (optional/mock)
       return matchesSearch;
    }).toList();
    
    if (widget.viewType == 'grid' || widget.viewType == 'dashboard') {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 250,
          childAspectRatio: 1.0,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: filtered.length,
        itemBuilder: (context, index) => _buildGridCard(filtered[index], colorScheme),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildListCard(filtered[index], colorScheme);
      },
    );
  }

  Widget _buildListCard(Map<String, dynamic> item, ColorScheme colorScheme) {
    final isError = item['status'] != 'Running' && item['status'] != 'Active' && item['status'] != 'Completed';
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF326CE5).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_icons[item['kind']] ?? Icons.widgets, color: const Color(0xFF326CE5)),
        ),
        title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${item['kind']} • ${item['namespace']} • ${item['age']}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isError ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isError ? Colors.red : Colors.green),
          ),
          child: Text(
            item['status'], 
            style: TextStyle(
              color: isError ? Colors.red : Colors.green, 
              fontWeight: FontWeight.bold, 
              fontSize: 12
            )
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard(Map<String, dynamic> item, ColorScheme colorScheme) {
    final isError = item['status'] != 'Running' && item['status'] != 'Active' && item['status'] != 'Completed';
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.2))),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Icon(_icons[item['kind']] ?? Icons.widgets, color: const Color(0xFF326CE5), size: 32),
               const SizedBox(height: 12),
               Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
               Text(item['kind'], style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
               const SizedBox(height: 12),
               Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isError ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item['status'], 
                    style: TextStyle(
                      color: isError ? Colors.red : Colors.green, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 11
                    )
                  ),
               ),
            ],
          ),
        ),
      ),
    );
  }
}
