import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/supabase_service.dart';
import 'kubernetes_facilitator_screen.dart';
import 'kubernetes_knowledge_base_screen.dart';
import 'kubernetes_troubleshooter_screen.dart';
import 'kubernetes_browser_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'kubernetes_history_screen.dart';

// Helper class for Tab definition
class K8sTab {
  final String id;
  final IconData icon;
  final String label;

  K8sTab({required this.id, required this.icon, required this.label});
}

class KubernetesScreen extends StatefulWidget {
  const KubernetesScreen({super.key});

  @override
  State<KubernetesScreen> createState() => _KubernetesScreenState();
}

class _KubernetesScreenState extends State<KubernetesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _profiles = [];
  bool _isLoading = true;
  
  // Tab ordering
  List<K8sTab> _tabs = [
    K8sTab(id: 'facilitator', icon: Icons.terminal, label: 'Facilitator'),
    K8sTab(id: 'workflow', icon: Icons.medical_services_outlined, label: 'Workflow'),
    K8sTab(id: 'history', icon: Icons.history, label: 'History'),
    K8sTab(id: 'browser', icon: Icons.view_quilt_outlined, label: 'Browser'),
    K8sTab(id: 'knowledge', icon: Icons.menu_book_outlined, label: 'Knowledge Base'),
    K8sTab(id: 'config', icon: Icons.settings_outlined, label: 'Configs'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    try {
      final supabaseService = Provider.of<SupabaseService>(context, listen: false);
      final configs = await supabaseService.getToolConfigs();
      setState(() {
        _profiles = configs.where((c) => c['tool_type'] == 'kubernetes').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        // Suppress error for now
      }
    }
  }

  void _showCreateProfileDialog() {
    final nameController = TextEditingController();
    final kubeconfigController = TextEditingController();
    final contextController = TextEditingController(text: 'default');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Kubernetes Cluster'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Cluster Name',
                    hintText: 'e.g., production-cluster',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: kubeconfigController,
                  decoration: const InputDecoration(
                    labelText: 'Kubeconfig Path',
                    hintText: '~/.kube/config',
                    border: OutlineInputBorder(),
                  ),
                ),
                 const SizedBox(height: 16),
                TextField(
                  controller: contextController,
                  decoration: const InputDecoration(
                    labelText: 'Context Name',
                    hintText: 'default',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                final supabaseService = Provider.of<SupabaseService>(context, listen: false);
                await supabaseService.createToolConfig({
                  'tool_type': 'kubernetes',
                  'profile_name': nameController.text,
                  'config_data': {
                    'kubeconfig': kubeconfigController.text,
                    'context': contextController.text,
                  },
                  'tags': ['k8s', 'kubectl'],
                });
                Navigator.pop(context);
                _loadProfiles();
              } catch (e) {
                if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Add Cluster'),
          ),
        ],
      ),
    );
  }

  // Global State for Children
  String _searchQuery = '';
  String _viewType = 'grid'; 
  String _selectedCategory = 'Todos';
  final TextEditingController _searchController = TextEditingController();

  final Map<String, IconData> _categoryIcons = {
    'Todos': Icons.grid_view,
    'Workloads': Icons.widgets,
    'Network': Icons.hub,
    'Storage': Icons.storage,
    'Config': Icons.settings_applications,
    'Access': Icons.security,
    'Cluster': Icons.cloud,
  };

  final List<String> _categories = [
    'Workloads', 
    'Network', 
    'Storage', 
    'Config', 
    'Access',
    'Cluster'
  ];

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _getTabContent(String id) {
    switch (id) {
      case 'facilitator':
        return KubernetesFacilitatorScreen(
          searchQuery: _searchQuery,
          viewType: _viewType,
          selectedCategory: _selectedCategory,
        );
      case 'workflow':
        return KubernetesTroubleshooterScreen(
          searchQuery: _searchQuery,
          viewType: _viewType,
          selectedCategory: _selectedCategory,
        );
      case 'history':
        return KubernetesHistoryScreen(
          searchQuery: _searchQuery,
          viewType: _viewType,
          selectedCategory: _selectedCategory,
        );
      case 'browser':
        return KubernetesBrowserScreen(
          searchQuery: _searchQuery,
          viewType: _viewType,
          selectedCategory: _selectedCategory,
        );
      case 'knowledge':
        return KubernetesKnowledgeBaseScreen(
          searchQuery: _searchQuery,
          viewType: _viewType,
          selectedCategory: _selectedCategory,
        );
      case 'config':
        return _buildConfigurationsTab();
      default:
        return const Center(child: Text('Unknown tab'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final k8sBlue = const Color(0xFF326CE5); // Official K8s Blue

    return Column(
      children: [
        // Header
        Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                k8sBlue.withOpacity(0.15),
                colorScheme.surface,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.2))),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [k8sBlue, const Color(0xFF3970E4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: k8sBlue.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.anchor, color: Colors.white, size: 24), // Anchor usually represents K8s wheel
              ),
              const SizedBox(width: 16),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kubernetes',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Container Orchestrator',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 32),
              Container(width: 1, height: 32, color: colorScheme.outlineVariant.withOpacity(0.3)),
              const SizedBox(width: 32),
              
              // Tabs
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _tabs.asMap().entries.map((entry) {
                      final index = entry.key;
                      final tab = entry.value;
                      final isSelected = _tabController.index == index;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: InkWell(
                          onTap: () => _tabController.animateTo(index),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? k8sBlue.withOpacity(0.1) : null,
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected ? Border.all(color: k8sBlue.withOpacity(0.5)) : Border.all(color: Colors.transparent),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  tab.icon,
                                  size: 18,
                                  color: isSelected ? k8sBlue : colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  tab.label,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    color: isSelected ? k8sBlue : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Controls
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.2))),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Search
              SizedBox(
                width: 300,
                height: 36,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search resources...',
                    prefixIcon: const Icon(Icons.search, size: 16),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 16),
              Container(width: 1, height: 24, color: colorScheme.outlineVariant.withOpacity(0.3)),
              const SizedBox(width: 16),

              // Categories
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // 'Todos'
                       _buildCategoryChip('Todos', isFirst: true),
                       Container(width: 1, height: 20, color: colorScheme.outlineVariant.withOpacity(0.3), margin: const EdgeInsets.symmetric(horizontal: 10)),
                       ..._categories.map((c) => _buildCategoryChip(c)),
                    ],
                  ),
                ),
              ),

              // View Types & Settings
               Row(
                children: [
                  _buildViewTypeButton('list', Icons.list, colorScheme),
                  const SizedBox(width: 4),
                  _buildViewTypeButton('dashboard', Icons.dashboard, colorScheme),
                  const SizedBox(width: 4),
                  _buildViewTypeButton('grid', Icons.grid_view, colorScheme),
                   const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, size: 20),
                    onPressed: _showCreateProfileDialog,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: Container(
            color: colorScheme.surfaceContainerLowest,
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map<Widget>((tab) => _getTabContent(tab.id)).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String category, {bool isFirst = false}) {
     final isSelected = _selectedCategory == category;
     final colorScheme = Theme.of(context).colorScheme;
     final k8sBlue = const Color(0xFF326CE5);

     return Padding(
       padding: const EdgeInsets.only(right: 10),
       child: InkWell(
         onTap: () => setState(() => _selectedCategory = category),
         borderRadius: BorderRadius.circular(20),
         child: AnimatedContainer(
           duration: const Duration(milliseconds: 200),
           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
           decoration: BoxDecoration(
             color: isSelected ? k8sBlue : colorScheme.surfaceContainerHighest.withOpacity(0.3),
             borderRadius: BorderRadius.circular(20),
             border: Border.all(color: isSelected ? k8sBlue : colorScheme.outlineVariant.withOpacity(0.2)),
           ),
           child: Row(
             children: [
               Icon(
                 _categoryIcons[category] ?? Icons.category,
                 size: 16,
                 color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
               ),
               const SizedBox(width: 8),
               Text(
                 category,
                 style: GoogleFonts.inter(
                   fontSize: 13,
                   fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                   color: isSelected ? Colors.white : colorScheme.onSurface,
                 ),
               ),
             ],
           ),
         ),
       ),
     );
  }

  Widget _buildViewTypeButton(String type, IconData icon, ColorScheme colorScheme) {
    final isSelected = _viewType == type;
    final k8sBlue = const Color(0xFF326CE5);
    return IconButton(
      icon: Icon(icon, size: 18),
      onPressed: () => setState(() => _viewType = type),
      color: isSelected ? k8sBlue : colorScheme.onSurfaceVariant,
      style: IconButton.styleFrom(
        backgroundColor: isSelected ? k8sBlue.withOpacity(0.1) : null,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildConfigurationsTab() {
     final colorScheme = Theme.of(context).colorScheme;
    if (_profiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 48, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('No Kubernetes clusters configured', style: GoogleFonts.inter(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            FilledButton(onPressed: _showCreateProfileDialog, child: const Text('Add Cluster')),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _profiles.length,
      itemBuilder: (context, index) {
        final profile = _profiles[index];
        final data = profile['config_data'] ?? {};
        return Card(
          child: ListTile(
            leading: const Icon(Icons.anchor, color: Color(0xFF326CE5)),
            title: Text(profile['profile_name'] ?? 'Unnamed Cluster'),
            subtitle: Text('Context: ${data['context'] ?? 'default'}'),
            trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () {}), 
          ),
        );
      },
    );
  }
}
