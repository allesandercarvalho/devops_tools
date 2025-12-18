import 'package:flutter/material.dart';

class KubernetesHistoryScreen extends StatelessWidget {
  final String searchQuery;
  final String viewType;
  final String selectedCategory;

  const KubernetesHistoryScreen({super.key, required this.searchQuery, required this.viewType, required this.selectedCategory});

  @override
  Widget build(BuildContext context) {
    // Mock Data
    final history = [
      {'cmd': 'kubectl get pods -n default', 'status': 'success', 'time': '2m ago'},
      {'cmd': 'kubectl describe pod/frontend-xyz', 'status': 'success', 'time': '5m ago'},
      {'cmd': 'kubectl delete pod/buggy-pod', 'status': 'failed', 'time': '1h ago'},
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = history[index];
        final isSuccess = item['status'] == 'success';
        
        return Card(
           elevation: 0,
           color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
           child: ListTile(
             leading: Icon(
               isSuccess ? Icons.check_circle : Icons.error,
               color: isSuccess ? Colors.green : Colors.red,
             ),
             title: Text(item['cmd']!, style: const TextStyle(fontFamily: 'monospace')),
             subtitle: Text(item['time']!),
             trailing: IconButton(
               icon: const Icon(Icons.copy),
               onPressed: () {},
             ),
           ),
        );
      },
    );
  }
}
