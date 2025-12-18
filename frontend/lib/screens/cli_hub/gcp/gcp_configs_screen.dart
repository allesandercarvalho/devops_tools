import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GCPConfigsScreen extends StatefulWidget {
  const GCPConfigsScreen({super.key});

  @override
  State<GCPConfigsScreen> createState() => _GCPConfigsScreenState();
}

class _GCPConfigsScreenState extends State<GCPConfigsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Tab ordering
  final List<Map<String, dynamic>> _tabs = [
    {'id': 'dashboard', 'icon': Icons.dashboard_outlined, 'label': 'Dashboard'},
    {'id': 'compute', 'icon': Icons.computer, 'label': 'Compute Engine'},
    {'id': 'storage', 'icon': Icons.storage, 'label': 'Cloud Storage'},
    {'id': 'kubernetes', 'icon': Icons.anchor, 'label': 'Kubernetes Engine'},
    {'id': 'bigquery', 'icon': Icons.table_chart_outlined, 'label': 'BigQuery'},
  ];

  // Global State
  String _searchQuery = '';
  String _viewType = 'grid';
  String _selectedCategory = 'Compute';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = ['Compute', 'Storage', 'Databases', 'Networking', 'AI/ML', 'DevOps'];
  final Map<String, IconData> _categoryIcons = {
    'Compute': Icons.memory,
    'Storage': Icons.cloud_upload_outlined,
    'Databases': Icons.storage,
    'Networking': Icons.hub,
    'AI/ML': Icons.psychology,
    'DevOps': Icons.build,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Google Blue: #4285F4
    const googleBlue = Color(0xFF4285F4);

    return Column(
      children: [
        // ROW 1: Branding & Navigation Tabs
        Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                googleBlue.withOpacity(0.15),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Simple Google Colors Icon Mock
                    Icon(Icons.cloud, color: googleBlue, size: 24),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Google Cloud',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Platform Console',
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
                              color: isSelected ? googleBlue.withOpacity(0.1) : null,
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected ? Border.all(color: googleBlue.withOpacity(0.5)) : Border.all(color: Colors.transparent),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  tab['icon'],
                                  size: 18,
                                  color: isSelected ? googleBlue : colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  tab['label'],
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    color: isSelected ? googleBlue : colorScheme.onSurfaceVariant,
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

        // ROW 2: Global Controls
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
              // 1. Categories
              Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => setState(() => _selectedCategory = category),
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? googleBlue : colorScheme.surfaceContainerHighest.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: isSelected ? [
                                BoxShadow(
                                  color: googleBlue.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ] : null,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _categoryIcons[category] ?? Icons.category,
                                  size: 16,
                                  color: isSelected ? Colors.white : colorScheme.onSurface,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  category,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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

              // 2. Search
              SizedBox(
                width: 450,
                height: 40,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search resources, services, docs...',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
                    prefixIcon: Icon(Icons.search, size: 18, color: colorScheme.onSurfaceVariant),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: googleBlue, width: 1.5),
                    ),
                  ),
                  style: GoogleFonts.inter(fontSize: 13),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),

              // 3. View Types & Settings
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildViewTypeButton('list', Icons.list, colorScheme, googleBlue),
                    const SizedBox(width: 4),
                    _buildViewTypeButton('dashboard', Icons.dashboard, colorScheme, googleBlue),
                    const SizedBox(width: 4),
                    _buildViewTypeButton('grid', Icons.grid_view, colorScheme, googleBlue),
                    
                    const SizedBox(width: 16),
                    Container(width: 1, height: 24, color: colorScheme.outlineVariant.withOpacity(0.3)),
                    const SizedBox(width: 16),

                    IconButton(
                      icon: const Icon(Icons.settings_outlined, size: 20),
                      onPressed: () {},
                      tooltip: 'Settings',
                      style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: googleBlue,
                      child: Text(
                        'A',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Content Placeholder
        Expanded(
          child: Container(
            color: colorScheme.surfaceContainerLowest,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.construction, size: 64, color: colorScheme.onSurfaceVariant.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'GCP Mock Interface',
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                  ),
                  Text(
                    'This is a visual mock demonstrating the standardized header pattern.',
                    style: GoogleFonts.inter(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewTypeButton(String type, IconData icon, ColorScheme colorScheme, Color activeColor) {
    final isSelected = _viewType == type;
    return IconButton(
      icon: Icon(icon, size: 18),
      onPressed: () => setState(() => _viewType = type),
      color: isSelected ? activeColor : colorScheme.onSurfaceVariant,
      style: IconButton.styleFrom(
        backgroundColor: isSelected ? activeColor.withOpacity(0.1) : null,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.all(8),
      ),
    );
  }
}
