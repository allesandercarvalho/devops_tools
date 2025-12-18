import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KubernetesKnowledgeBaseScreen extends StatelessWidget {
  final String searchQuery;
  final String viewType;
  final String selectedCategory;

  const KubernetesKnowledgeBaseScreen({super.key, required this.searchQuery, required this.viewType, required this.selectedCategory});

  final List<Map<String, String>> _articles = const [
    {
      'title': 'Understanding Pod Lifecycle',
      'category': 'Concepts',
      'desc': 'Deep dive into Pending, Running, Succeeded, Failed, and Unknown states.',
      'content': 'A Pod is the smallest execution unit in Kubernetes. Its lifecycle consists of:\\n1. Pending: Accepted by the cluster, but one or more containers have not been set up.\\n2. Running: The Pod has been bound to a node, and all containers have been created.\\n3. Succeeded: All containers in the Pod have terminated successfully.\\n4. Failed: All containers have terminated, and at least one terminated in failure.',
    },
    {
      'title': 'Debug CrashLoopBackOff',
      'category': 'Troubleshooting',
      'desc': 'Common reasons why pods crash repeatedly and how to fix them.',
      'content': 'CrashLoopBackOff means the pod is starting, crashing, restarting, and crashing again.\\n\\nCommon causes:\\n- Application errors (check logs)\\n- Misconfiguration (env vars, configmaps)\\n- Liveness probe failures\\n- Resource limits (OOMKilled)',
    },
    {
      'title': 'Kubernetes Networking 101',
      'category': 'Network',
      'desc': 'Services, Ingress, CNI plugins and how packets flow.',
      'content': 'Key Concepts:\\n- ClusterIP: Internal service.\\n- NodePort: Exposes service on each Node\'s IP.\\n- LoadBalancer: Exposes service externally using a cloud provider\'s LB.\\n- Ingress: Manages external access to services, typically HTTP.',
    },
     {
      'title': 'Persistent Storage Patterns',
      'category': 'Storage',
      'desc': 'PVs, PVCs, StorageClasses and dynamic provisioning.',
      'content': 'Storage in K8s is managed via Persistent Volumes (PV) and Claims (PVC). StorageClasses allow dynamic provisioning of volumes.',
    },
  ];

  void _showArticle(BuildContext context, Map<String, String> article) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF326CE5).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(article['category']!, style: const TextStyle(color: Color(0xFF326CE5), fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              Text(article['title']!, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(article['content']!, style: GoogleFonts.inter(fontSize: 14, height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _articles.length,
      itemBuilder: (context, index) {
        final article = _articles[index];
        return Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3))),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showArticle(context, article),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     decoration: BoxDecoration(color: const Color(0xFF326CE5).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                     child: Text(article['category']!, style: const TextStyle(color: Color(0xFF326CE5), fontSize: 10, fontWeight: FontWeight.bold)),
                   ),
                   const SizedBox(height: 12),
                   Text(article['title']!, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   Expanded(child: Text(article['desc']!, style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant), overflow: TextOverflow.fade)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
