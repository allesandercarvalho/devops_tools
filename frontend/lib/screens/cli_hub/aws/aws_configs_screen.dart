import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/supabase_service.dart';
import 'aws_facilitator_screen.dart';
import 'aws_knowledge_base_screen.dart';
import 'aws_troubleshooter_screen.dart';
// import 'aws_browser_screen.dart'; // Old version with mocks - not used
import 'aws_browser_simplified_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'aws_history_screen.dart';

class AWSConfigsScreen extends StatefulWidget {
  const AWSConfigsScreen({super.key});

  @override
  State<AWSConfigsScreen> createState() => _AWSConfigsScreenState();
}

class _AWSConfigsScreenState extends State<AWSConfigsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _profiles = [];
  bool _isLoading = true;
  
  // Tab ordering
  List<AWSTab> _tabs = [
    AWSTab(id: 'facilitator', icon: Icons.rocket_launch_outlined, label: 'Facilitador'),
    AWSTab(id: 'workflow', icon: Icons.medical_services_outlined, label: 'Workflow'),
    AWSTab(id: 'history', icon: Icons.history, label: 'Histórico'),
    AWSTab(id: 'browser', icon: Icons.folder_special_outlined, label: 'Navegador'),
    AWSTab(id: 'knowledge', icon: Icons.menu_book_outlined, label: 'Base de Conhecimento'),
    AWSTab(id: 'config', icon: Icons.settings_outlined, label: 'Configurações'),
  ];
  bool _isReordering = false;

  @override
  void initState() {
    super.initState();
    _loadTabOrder();
    _tabController = TabController(length: 6, vsync: this);
    _loadProfiles();
  }



  Future<void> _loadTabOrder() async {
    try {
      final supabaseService = Provider.of<SupabaseService>(context, listen: false);
      final prefs = await supabaseService.getUserPreferences();
      final savedOrder = prefs?['aws_tab_order'] as List<dynamic>?;
      
      if (savedOrder != null && savedOrder.length == 6) {
        setState(() {
          _tabs = savedOrder.map((id) {
            return _tabs.firstWhere((tab) => tab.id == id);
          }).toList();
        });
      }
    } catch (e) {
      // Use default order if loading fails
    }
  }

  Future<void> _saveTabOrder() async {
    try {
      final supabaseService = Provider.of<SupabaseService>(context, listen: false);
      await supabaseService.saveUserPreferences({
        'aws_tab_order': _tabs.map((t) => t.id).toList(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving tab order: $e')),
        );
      }
    }
  }

  void _reorderTab(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final tab = _tabs.removeAt(oldIndex);
      _tabs.insert(newIndex, tab);
    });
    _saveTabOrder();
  }



  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    try {
      final supabaseService = Provider.of<SupabaseService>(context, listen: false);
      final configs = await supabaseService.getToolConfigs();
      setState(() {
        _profiles = configs.where((c) => c['tool_type'] == 'aws').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profiles: $e')),
        );
      }
    }
  }

  void _showCreateProfileDialog() {
    final nameController = TextEditingController();
    final regionController = TextEditingController(text: 'us-east-1');
    
    // Credentials
    final accessKeyController = TextEditingController();
    final secretKeyController = TextEditingController();
    
    // SSO
    final ssoStartUrlController = TextEditingController();
    final ssoRegionController = TextEditingController(text: 'us-east-1');
    final ssoAccountIdController = TextEditingController();
    final ssoRoleNameController = TextEditingController();
    
    String authType = 'credentials'; // credentials, sso

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create AWS Profile'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Profile Name',
                      hintText: 'e.g., production',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Auth Type Selector
                  Center(
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'credentials',
                          label: Text('Static Credentials'),
                          icon: Icon(Icons.key),
                        ),
                        ButtonSegment(
                          value: 'sso',
                          label: Text('SSO (Identity Center)'),
                          icon: Icon(Icons.badge),
                        ),
                      ],
                      selected: {authType},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          authType = newSelection.first;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  if (authType == 'credentials') ...[
                    TextField(
                      controller: regionController,
                      decoration: const InputDecoration(
                        labelText: 'Region',
                        hintText: 'e.g., us-east-1',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: accessKeyController,
                      decoration: const InputDecoration(
                        labelText: 'Access Key ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: secretKeyController,
                      decoration: const InputDecoration(
                        labelText: 'Secret Access Key',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                  ] else ...[
                    TextField(
                      controller: ssoStartUrlController,
                      decoration: const InputDecoration(
                        labelText: 'SSO Start URL',
                        hintText: 'https://my-sso-portal.awsapps.com/start',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: ssoRegionController,
                      decoration: const InputDecoration(
                        labelText: 'SSO Region',
                        hintText: 'e.g., us-east-1',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: ssoAccountIdController,
                      decoration: const InputDecoration(
                        labelText: 'Account ID',
                        hintText: '123456789012',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: ssoRoleNameController,
                      decoration: const InputDecoration(
                        labelText: 'Role Name',
                        hintText: 'e.g., AdministratorAccess',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
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
                  
                  final Map<String, dynamic> configData = {
                    'auth_type': authType,
                  };
                  
                  if (authType == 'credentials') {
                    configData['region'] = regionController.text;
                    configData['access_key_id'] = accessKeyController.text;
                    // TODO: Encrypt secret key
                    configData['secret_access_key'] = secretKeyController.text;
                  } else {
                    configData['sso_start_url'] = ssoStartUrlController.text;
                    configData['sso_region'] = ssoRegionController.text;
                    configData['sso_account_id'] = ssoAccountIdController.text;
                    configData['sso_role_name'] = ssoRoleNameController.text;
                    configData['region'] = ssoRegionController.text; // Main region for client
                  }

                  await supabaseService.createToolConfig({
                    'tool_type': 'aws',
                    'profile_name': nameController.text,
                    'config_data': configData,
                    'tags': ['aws', authType],
                  });
                  
                  Navigator.pop(context);
                  _loadProfiles();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile created successfully')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  // Global State for Children
  String _searchQuery = '';
  String _viewType = 'grid'; // list, dashboard, grid
  String _selectedCategory = 'Todos';
  final TextEditingController _searchController = TextEditingController();

  // Categories Data (Lifted from Facilitator)
  final Map<String, IconData> _categoryIcons = {
    'Todos': Icons.grid_view,
    'Compute': Icons.memory,
    'Storage': Icons.storage,
    'Database': Icons.dns,
    'Network': Icons.hub,
    'Security': Icons.security,
    'Analytics': Icons.analytics,
    'ML': Icons.psychology,
    'DevTools': Icons.build,
    'Management': Icons.admin_panel_settings,
    'Media': Icons.play_circle,
  };

  final List<String> _categories = [
    'Compute', 
    'Storage', 
    'Database', 
    'Network', 
    'Security',
    'Analytics',
    'ML',
    'DevTools',
    'Management',
    'Media'
  ];

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ... (keep existing methods like _loadTabOrder, _saveTabOrder, _reorderTab)

  Widget _getTabContent(String id) {
    switch (id) {
      case 'facilitator':
        return AWSFacilitatorScreen(
          searchQuery: _searchQuery,
          viewType: _viewType,
          selectedCategory: _selectedCategory,
        );
      case 'workflow':
        return AWSTroubleshooterScreen(
          searchQuery: _searchQuery,
          viewType: _viewType,
          selectedCategory: _selectedCategory,
        );
      case 'history':
        return AWSHistoryScreen(
          searchQuery: _searchQuery,
          viewType: _viewType,
          selectedCategory: _selectedCategory,
        );
      case 'browser':
        return AWSBrowserSimplifiedScreen(
          searchQuery: _searchQuery,
          viewType: _viewType,
          selectedCategory: _selectedCategory,
        );
      case 'knowledge':
        return AWSKnowledgeBaseScreen(
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

  // ... (keep _loadProfiles, _showCreateProfileDialog)

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // ROW 1: Branding & Navigation Tabs
        Container(
          height: 80, // Increased height
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFF9900).withOpacity(0.15), // AWS Orange tint
                colorScheme.surface,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.2))),
          ),
          child: Row(
            children: [
              // 1. Identifier
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9900), Color(0xFFFFAC30)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF9900).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.cloud_queue, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AWS',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Cloud Manager',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 32),
              
              // Vertical Divider
              Container(width: 1, height: 32, color: colorScheme.outlineVariant.withOpacity(0.3)),
              const SizedBox(width: 32),

              // 2. Submenus (Tabs)
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
                              color: isSelected ? const Color(0xFFFF9900).withOpacity(0.1) : null,
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected ? Border.all(color: const Color(0xFFFF9900).withOpacity(0.5)) : Border.all(color: Colors.transparent),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  tab.icon,
                                  size: 18,
                                  color: isSelected ? const Color(0xFFD17B00) : colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  tab.label,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    color: isSelected ? const Color(0xFFD17B00) : colorScheme.onSurfaceVariant,
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

        // ROW 2: Global Controls (Categories | Search | View | Settings)
        Container(
          height: 64, // Increased height
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

              // 1. Search (Left - Fixed Width)
              Row(
                children: [
                  SizedBox(
                    width: 300, 
                    height: 36,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search resources...',
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
                        prefixIcon: Icon(Icons.search, size: 16, color: colorScheme.onSurfaceVariant),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFFF9900), width: 1.5),
                        ),
                      ),
                      style: GoogleFonts.inter(fontSize: 13),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(width: 1, height: 24, color: colorScheme.outlineVariant.withOpacity(0.3)),
                  const SizedBox(width: 16), // Spacing after divider
                ],
              ),

              // 2. Categories (Center - Expanded to fill space)
              // Fixed "Todos" + Divider + Scrollable Others
              Expanded(
                child: Row(
                  children: [
                    // Fixed "Todos"
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: InkWell(
                        onTap: () => setState(() => _selectedCategory = 'Todos'),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedCategory == 'Todos' ? const Color(0xFFFF9900) : colorScheme.surfaceContainerHighest.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _selectedCategory == 'Todos' ? const Color(0xFFFF9900) : colorScheme.outlineVariant.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: _selectedCategory == 'Todos' ? [
                              BoxShadow(
                                color: const Color(0xFFFF9900).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ] : [],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.grid_view,
                                size: 16,
                                color: _selectedCategory == 'Todos' ? Colors.white : colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Todos',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: _selectedCategory == 'Todos' ? FontWeight.w600 : FontWeight.w500,
                                  color: _selectedCategory == 'Todos' ? Colors.white : colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Divider
                    Container(width: 1, height: 20, color: colorScheme.outlineVariant.withOpacity(0.3)),
                    const SizedBox(width: 10),

                    // Scrollable Others
                    Expanded(
                      child: ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.white.withOpacity(0.05),
                              Colors.white,
                              Colors.white,
                              Colors.white.withOpacity(0.05),
                            ],
                            stops: const [0.0, 0.05, 0.95, 1.0],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.dstIn,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: _categories.map((category) {
                              final isSelected = _selectedCategory == category;
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: InkWell(
                                  onTap: () => setState(() => _selectedCategory = category),
                                  borderRadius: BorderRadius.circular(20),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFFFF9900) : colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFFFF9900) : colorScheme.outlineVariant.withOpacity(0.2),
                                        width: 1,
                                      ),
                                      boxShadow: isSelected ? [
                                        BoxShadow(
                                          color: const Color(0xFFFF9900).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        )
                                      ] : [],
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
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. View Types & Settings (Right - Fixed Width)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 16),
                  Container(width: 1, height: 24, color: colorScheme.outlineVariant.withOpacity(0.3)),
                  const SizedBox(width: 16),
                  
                  _buildViewTypeButton('list', Icons.list, colorScheme),
                  const SizedBox(width: 4),
                  _buildViewTypeButton('dashboard', Icons.dashboard, colorScheme),
                  const SizedBox(width: 4),
                  _buildViewTypeButton('grid', Icons.grid_view, colorScheme),
                  
                  const SizedBox(width: 16),
                  Container(width: 1, height: 24, color: colorScheme.outlineVariant.withOpacity(0.3)),
                  const SizedBox(width: 16),

                  IconButton(
                    icon: const Icon(Icons.settings_outlined, size: 20),
                    onPressed: _showCreateProfileDialog,
                    tooltip: 'Settings',
                    style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: colorScheme.primary,
                    child: Text(
                      'A',
                      style: GoogleFonts.outfit(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
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

  Widget _buildViewTypeButton(String type, IconData icon, ColorScheme colorScheme) {
    final isSelected = _viewType == type;
    return IconButton(
      icon: Icon(icon, size: 18),
      onPressed: () => setState(() => _viewType = type),
      color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      style: IconButton.styleFrom(
        backgroundColor: isSelected ? colorScheme.primaryContainer.withOpacity(0.3) : null,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _buildCompactTab(IconData icon, String text) {
    return Tab(
      height: 40,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildConfigurationsTab() {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_profiles.isEmpty) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_off_outlined,
                  size: 80,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Nenhum perfil AWS configurado',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Crie seu primeiro perfil para começar a gerenciar seus recursos AWS de forma simples e eficiente.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _showCreateProfileDialog,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Criar Primeiro Perfil'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        childAspectRatio: 2.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _profiles.length,
      itemBuilder: (context, index) {
        final profile = _profiles[index];
        final configData = profile['config_data'] as Map<String, dynamic>? ?? {};
        final isSSO = configData['auth_type'] == 'sso';
        
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.3)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // TODO: Show profile details
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isSSO
                            ? [colorScheme.tertiaryContainer, colorScheme.tertiaryContainer.withOpacity(0.5)]
                            : [colorScheme.primaryContainer, colorScheme.primaryContainer.withOpacity(0.5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isSSO ? Icons.badge_outlined : Icons.vpn_key_outlined,
                      size: 28,
                      color: isSSO ? colorScheme.onTertiaryContainer : colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          profile['profile_name'] ?? 'Unnamed',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.public,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              configData['region'] ?? 'Not set',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        if (isSSO) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.tertiaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'SSO',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onTertiaryContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${configData['sso_role_name']}',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Actions
                  PopupMenuButton<void>(
                    icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18, color: colorScheme.primary),
                            const SizedBox(width: 12),
                            const Text('Editar'),
                          ],
                        ),
                        onTap: () {
                          // TODO: Implement edit
                        },
                      ),
                      PopupMenuItem(
                        child: Row(
                          children: [
                            Icon(Icons.content_copy_outlined, size: 18, color: colorScheme.onSurface),
                            const SizedBox(width: 12),
                            const Text('Duplicar'),
                          ],
                        ),
                        onTap: () {
                          // TODO: Implement duplicate
                        },
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: colorScheme.error),
                            const SizedBox(width: 12),
                            Text('Excluir', style: TextStyle(color: colorScheme.error)),
                          ],
                        ),
                        onTap: () async {
                          // Delay to allow menu to close
                          await Future.delayed(const Duration(milliseconds: 100));
                          
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: colorScheme.error),
                                  const SizedBox(width: 12),
                                  const Text('Excluir Perfil'),
                                ],
                              ),
                              content: Text(
                                'Tem certeza que deseja excluir o perfil "${profile['profile_name']}"? Esta ação não pode ser desfeita.',
                                style: GoogleFonts.inter(),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancelar'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: colorScheme.error,
                                  ),
                                  child: const Text('Excluir'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true && mounted) {
                            try {
                              final supabaseService = Provider.of<SupabaseService>(context, listen: false);
                              await supabaseService.deleteToolConfig(profile['id']);
                              _loadProfiles();
                              
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Perfil excluído com sucesso'),
                                    backgroundColor: colorScheme.primary,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erro ao excluir: $e'),
                                    backgroundColor: colorScheme.error,
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class AWSTab {
  final String id;
  final IconData icon;
  final String label;

  AWSTab({
    required this.id,
    required this.icon,
    required this.label,
  });
}
