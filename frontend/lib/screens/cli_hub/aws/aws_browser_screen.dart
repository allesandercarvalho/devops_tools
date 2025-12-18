import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Resource Type Enum
enum ResourceType { bucket, folder, file, ec2Instance, rdsInstance, lambdaFunction }

// View Mode Enum
enum ViewMode { grid, list }

// Sort Mode Enum
enum SortMode { name, date, size }

// Resource Model
class AWSResource {
  final String name;
  final ResourceType type;
  final String? size;
  final String? lastModified;
  final IconData icon;
  final Color color;
  final List<AWSResource>? children;
  
  AWSResource({
    required this.name,
    required this.type,
    this.size,
    this.lastModified,
    required this.icon,
    required this.color,
    this.children,
  });
}

class AWSBrowserScreen extends StatefulWidget {
  final String searchQuery;
  final String viewType;
  final String selectedCategory;

  const AWSBrowserScreen({
    super.key,
    required this.searchQuery,
    required this.viewType,
    required this.selectedCategory,
  });

  @override
  State<AWSBrowserScreen> createState() => _AWSBrowserScreenState();
}

class _AWSBrowserScreenState extends State<AWSBrowserScreen> {
  String _currentView = 's3'; // 's3', 'ec2', 'rds', 'lambda'
  List<String> _breadcrumbs = ['S3'];
  AWSResource? _currentFolder;
  bool _isLoading = false;
  SortMode _sortMode = SortMode.name;
  
  // Profile and Region selection
  String? _selectedProfile;
  String _selectedRegion = 'us-east-1';
  List<String> _availableProfiles = [];
  
  // Real data from API
  List<Map<String, dynamic>> _s3Buckets = [];
  List<Map<String, dynamic>> _s3Objects = [];
  List<Map<String, dynamic>> _ec2Instances = [];
  List<Map<String, dynamic>> _rdsInstances = [];
  List<Map<String, dynamic>> _lambdaFunctions = [];
  
  String? _currentS3Bucket;
  String _currentS3Prefix = '';
  
  final List<String> _awsRegions = [
    'us-east-1',
    'us-east-2',
    'us-west-1',
    'us-west-2',
    'eu-west-1',
    'eu-central-1',
    'ap-southeast-1',
    'ap-northeast-1',
    'sa-east-1',
  ];
  final List<AWSResource> _s3Buckets = [
    AWSResource(
      name: 'my-app-production',
      type: ResourceType.bucket,
      size: '2.4 GB',
      lastModified: '2024-11-28',
      icon: Icons.storage,
      color: Colors.green,
      children: [
        AWSResource(
          name: 'assets/',
          type: ResourceType.folder,
          icon: Icons.folder,
          color: Colors.amber,
          children: [
            AWSResource(
              name: 'logo.png',
              type: ResourceType.file,
              size: '45 KB',
              lastModified: '2024-11-20',
              icon: Icons.image,
              color: Colors.blue,
            ),
            AWSResource(
              name: 'banner.jpg',
              type: ResourceType.file,
              size: '128 KB',
              lastModified: '2024-11-22',
              icon: Icons.image,
              color: Colors.blue,
            ),
          ],
        ),
        AWSResource(
          name: 'uploads/',
          type: ResourceType.folder,
          icon: Icons.folder,
          color: Colors.amber,
          children: [
            AWSResource(
              name: 'user-avatar-123.jpg',
              type: ResourceType.file,
              size: '89 KB',
              lastModified: '2024-11-28',
              icon: Icons.image,
              color: Colors.blue,
            ),
          ],
        ),
        AWSResource(
          name: 'config.json',
          type: ResourceType.file,
          size: '2 KB',
          lastModified: '2024-11-15',
          icon: Icons.description,
          color: Colors.orange,
        ),
      ],
    ),
    AWSResource(
      name: 'my-app-staging',
      type: ResourceType.bucket,
      size: '1.1 GB',
      lastModified: '2024-11-27',
      icon: Icons.storage,
      color: Colors.green,
      children: [],
    ),
    AWSResource(
      name: 'backups-2024',
      type: ResourceType.bucket,
      size: '15.8 GB',
      lastModified: '2024-11-29',
      icon: Icons.storage,
      color: Colors.green,
      children: [],
    ),
  ];
  
  // Mock EC2 data
  final List<AWSResource> _ec2Instances = [
    AWSResource(
      name: 'web-server-prod-01',
      type: ResourceType.ec2Instance,
      size: 't3.medium',
      lastModified: 'Running',
      icon: Icons.computer,
      color: Colors.blue,
    ),
    AWSResource(
      name: 'api-server-prod-01',
      type: ResourceType.ec2Instance,
      size: 't3.large',
      lastModified: 'Running',
      icon: Icons.computer,
      color: Colors.blue,
    ),
    AWSResource(
      name: 'worker-01',
      type: ResourceType.ec2Instance,
      size: 't3.small',
      lastModified: 'Stopped',
      icon: Icons.computer,
      color: Colors.grey,
    ),
  ];
  
  // Mock RDS data
  final List<AWSResource> _rdsInstances = [
    AWSResource(
      name: 'postgres-production',
      type: ResourceType.rdsInstance,
      size: 'db.t3.medium',
      lastModified: 'Available',
      icon: Icons.dns,
      color: Colors.purple,
    ),
    AWSResource(
      name: 'mysql-staging',
      type: ResourceType.rdsInstance,
      size: 'db.t3.small',
      lastModified: 'Available',
      icon: Icons.dns,
      color: Colors.purple,
    ),
  ];
  
  // Mock Lambda data
  final List<AWSResource> _lambdaFunctions = [
    AWSResource(
      name: 'image-processor',
      type: ResourceType.lambdaFunction,
      size: 'Python 3.9',
      lastModified: '256 MB',
      icon: Icons.flash_on,
      color: Colors.amber,
    ),
    AWSResource(
      name: 'email-sender',
      type: ResourceType.lambdaFunction,
      size: 'Node.js 18',
      lastModified: '128 MB',
      icon: Icons.flash_on,
      color: Colors.amber,
    ),
    AWSResource(
      name: 'data-sync',
      type: ResourceType.lambdaFunction,
      size: 'Python 3.9',
      lastModified: '512 MB',
      icon: Icons.flash_on,
      color: Colors.amber,
    ),
  ];

  List<AWSResource> _getCurrentResources() {
    List<AWSResource> resources;
    
    if (_currentFolder != null) {
      resources = _currentFolder!.children ?? [];
    } else {
      switch (_currentView) {
        case 's3':
          resources = _s3Buckets;
        case 'ec2':
          resources = _ec2Instances;
        case 'rds':
          resources = _rdsInstances;
        case 'lambda':
          resources = _lambdaFunctions;
        default:
          resources = [];
      }
    }
    
    // Apply sorting
    final sorted = List<AWSResource>.from(resources);
    switch (_sortMode) {
      case SortMode.name:
        sorted.sort((a, b) => a.name.compareTo(b.name));
      case SortMode.date:
        sorted.sort((a, b) => (b.lastModified ?? '').compareTo(a.lastModified ?? ''));
      case SortMode.size:
        sorted.sort((a, b) => (b.size ?? '').compareTo(a.size ?? ''));
    }
    
    // Apply Global Search
    if (widget.searchQuery.isNotEmpty) {
      final query = widget.searchQuery.toLowerCase();
      return sorted.where((r) => r.name.toLowerCase().contains(query)).toList();
    }

    return sorted;
  }
  
  @override
  void didUpdateWidget(AWSBrowserScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // React to Category Change
    if (widget.selectedCategory != oldWidget.selectedCategory) {
      _mapCategoryToView(widget.selectedCategory);
    }
  }

  void _mapCategoryToView(String category) {
    switch (category) {
      case 'Storage':
        _changeView('s3');
        break;
      case 'Compute':
        _changeView('ec2');
        break;
      case 'Database':
        _changeView('rds');
        break;
      case 'Serverless':
        _changeView('lambda');
        break;
      // Add more mappings as needed
    }
  }

  void _navigateInto(AWSResource resource) {
    if (resource.type == ResourceType.bucket || resource.type == ResourceType.folder) {
      setState(() {
        _currentFolder = resource;
        _breadcrumbs.add(resource.name);
      });
    }
  }

  void _navigateBack() {
    if (_breadcrumbs.length > 1) {
      setState(() {
        _breadcrumbs.removeLast();
        if (_breadcrumbs.length == 1) {
          _currentFolder = null;
        } else {
          _currentFolder = null;
        }
      });
    }
  }

  void _changeView(String view) {
    setState(() {
      _currentView = view;
      _breadcrumbs = [
        view == 's3' ? 'S3' :
        view == 'ec2' ? 'EC2' :
        view == 'rds' ? 'RDS' :
        'Lambda'
      ];
      _currentFolder = null;
    });
  }

  Future<void> _refreshResources() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
  }

  String _getStatusBadgeText(AWSResource resource) {
    if (resource.type == ResourceType.ec2Instance || 
        resource.type == ResourceType.rdsInstance) {
      return resource.lastModified ?? '';
    }
    return '';
  }

  Color _getStatusBadgeColor(String status, ColorScheme colorScheme) {
    switch (status.toLowerCase()) {
      case 'running':
        return Colors.green;
      case 'stopped':
        return Colors.red;
      case 'available':
        return Colors.green;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resources = _getCurrentResources();

    return Row(
      children: [
        // Sidebar de Serviços
        Container(
          width: 72,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            border: Border(
              right: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.2)),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildSidebarItem('S3', Icons.storage, 's3', colorScheme),
              _buildSidebarItem('EC2', Icons.computer, 'ec2', colorScheme),
              _buildSidebarItem('RDS', Icons.dns, 'rds', colorScheme),
              _buildSidebarItem('Lambda', Icons.flash_on, 'lambda', colorScheme),
            ],
          ),
        ),
        
        // Main Content
        Expanded(
          child: Column(
            children: [
              // Top Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.2)),
                  ),
                ),
                child: Row(
                  children: [
                    // Breadcrumb
                    if (_breadcrumbs.isNotEmpty) ...[
                      if (_breadcrumbs.length > 1)
                        IconButton(
                          icon: const Icon(Icons.arrow_back, size: 18),
                          onPressed: _navigateBack,
                          tooltip: 'Back',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(_breadcrumbs.length, (index) {
                              final isLast = index == _breadcrumbs.length - 1;
                              return Row(
                                children: [
                                  if (index > 0) Icon(Icons.chevron_right, size: 14, color: colorScheme.onSurfaceVariant),
                                  TextButton(
                                    onPressed: isLast ? null : () {
                                      setState(() {
                                        _breadcrumbs = _breadcrumbs.sublist(0, index + 1);
                                        _currentFolder = null;
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      _breadcrumbs[index],
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
                                        color: isLast ? colorScheme.primary : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(width: 16),
                    
                    // View Options REMOVED (Global)
                    
                    const SizedBox(width: 8),
                    
                    // Sort Dropdown
                    PopupMenuButton<SortMode>(
                      icon: Icon(Icons.sort, size: 18, color: colorScheme.onSurfaceVariant),
                      tooltip: 'Sort',
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (mode) => setState(() => _sortMode = mode),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: SortMode.name,
                          child: Row(
                            children: [
                              Icon(Icons.sort_by_alpha, size: 18, color: _sortMode == SortMode.name ? colorScheme.primary : null),
                              const SizedBox(width: 12),
                              Text('Name', style: TextStyle(color: _sortMode == SortMode.name ? colorScheme.primary : null)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: SortMode.date,
                          child: Row(
                            children: [
                              Icon(Icons.access_time, size: 18, color: _sortMode == SortMode.date ? colorScheme.primary : null),
                              const SizedBox(width: 12),
                              Text('Date', style: TextStyle(color: _sortMode == SortMode.date ? colorScheme.primary : null)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: SortMode.size,
                          child: Row(
                            children: [
                              Icon(Icons.data_usage, size: 18, color: _sortMode == SortMode.size ? colorScheme.primary : null),
                              const SizedBox(width: 12),
                              Text('Size', style: TextStyle(color: _sortMode == SortMode.size ? colorScheme.primary : null)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Refresh Button
                    IconButton(
                      icon: _isLoading
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary),
                            )
                          : Icon(Icons.refresh, size: 18),
                      onPressed: _refreshResources,
                      tooltip: 'Refresh',
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              
              // Resource Grid/List
              Expanded(
                child: resources.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 64,
                              color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No resources found',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : (widget.viewType == 'grid' || widget.viewType == 'dashboard')
                        ? _buildGridView(resources, colorScheme)
                        : _buildListView(resources, colorScheme),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarItem(String label, IconData icon, String view, ColorScheme colorScheme) {
    final isSelected = _currentView == view;
    return Tooltip(
      message: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: InkWell(
          onTap: () => _changeView(view),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? colorScheme.primary.withOpacity(0.3) : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridView(List<AWSResource> resources, ColorScheme colorScheme) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        childAspectRatio: 1.1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: resources.length,
      itemBuilder: (context, index) {
        return _buildGridCard(resources[index], colorScheme);
      },
    );
  }

  Widget _buildListView(List<AWSResource> resources, ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: resources.length,
      itemBuilder: (context, index) {
        return _buildListCard(resources[index], colorScheme);
      },
    );
  }

  Widget _buildGridCard(AWSResource resource, ColorScheme colorScheme) {
    final isNavigable = resource.type == ResourceType.bucket || resource.type == ResourceType.folder;
    final statusText = _getStatusBadgeText(resource);
    
    return MouseRegion(
      cursor: isNavigable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: Card(
        elevation: 0,
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.3)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isNavigable ? () => _navigateInto(resource) : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        resource.color.withOpacity(0.2),
                        resource.color.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(resource.icon, color: resource.color, size: 32),
                ),
                const SizedBox(height: 12),
                
                // Name
                Text(
                  resource.name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 6),
                
                // Status Badge or Size
                if (statusText.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getStatusBadgeColor(statusText, colorScheme).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _getStatusBadgeColor(statusText, colorScheme).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      statusText,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getStatusBadgeColor(statusText, colorScheme),
                      ),
                    ),
                  )
                else if (resource.size != null)
                  Text(
                    resource.size!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListCard(AWSResource resource, ColorScheme colorScheme) {
    final isNavigable = resource.type == ResourceType.bucket || resource.type == ResourceType.folder;
    final statusText = _getStatusBadgeText(resource);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isNavigable ? () => _navigateInto(resource) : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      resource.color.withOpacity(0.2),
                      resource.color.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(resource.icon, color: resource.color, size: 22),
              ),
              const SizedBox(width: 12),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource.name,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (resource.size != null) ...[
                          Icon(Icons.data_usage, size: 11, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            resource.size!,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (resource.size != null && resource.lastModified != null && statusText.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text('•', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11)),
                          ),
                        if (resource.lastModified != null && statusText.isEmpty) ...[
                          Icon(Icons.access_time, size: 11, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            resource.lastModified!,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Status Badge
              if (statusText.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusBadgeColor(statusText, colorScheme).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _getStatusBadgeColor(statusText, colorScheme).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getStatusBadgeColor(statusText, colorScheme),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              
              // Actions
              if (isNavigable)
                Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant, size: 20)
              else
                PopupMenuButton(
                  icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant, size: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'download',
                      child: Row(
                        children: [
                          Icon(Icons.download, size: 18),
                          SizedBox(width: 12),
                          Text('Download'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'copy',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 18),
                          SizedBox(width: 12),
                          Text('Copy URL'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
