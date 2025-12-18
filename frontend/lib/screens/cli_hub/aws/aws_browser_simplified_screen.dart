import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/aws_browser_api_service.dart';
import '../../../services/aws_api_service.dart';

class AWSBrowserSimplifiedScreen extends StatefulWidget {
  final String searchQuery;
  final String viewType;
  final String selectedCategory;

  const AWSBrowserSimplifiedScreen({
    super.key,
    required this.searchQuery,
    required this.viewType,
    required this.selectedCategory,
  });

  @override
  State<AWSBrowserSimplifiedScreen> createState() => _AWSBrowserSimplifiedScreenState();
}

class _AWSBrowserSimplifiedScreenState extends State<AWSBrowserSimplifiedScreen> {
  // Profile and Region selection
  String? _selectedProfile;
  String _selectedRegion = 'us-east-1';
  List<String> _availableProfiles = [];
  
  // Current view state
  String _currentView = 's3'; // 's3', 'ec2', 'rds', 'lambda'
  bool _isLoading = false;
  String? _error;
  
  // S3 State
  List<Map<String, dynamic>> _s3Buckets = [];
  List<Map<String, dynamic>> _s3Objects = [];
  String? _currentBucket;
  String _currentPrefix = '';
  List<String> _breadcrumbs = [];
  
  // Other resources
  List<Map<String, dynamic>> _ec2Instances = [];
  List<Map<String, dynamic>> _rdsInstances = [];
  List<Map<String, dynamic>> _lambdaFunctions = [];
  
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

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    try {
      final profiles = await AWSApiService.listProfiles();
      setState(() {
        _availableProfiles = profiles;
        if (profiles.isNotEmpty && _selectedProfile == null) {
          _selectedProfile = profiles.first;
        }
      });
      // Auto-load data after profiles are loaded
      if (_selectedProfile != null) {
        _loadCurrentViewData();
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load AWS profiles: $e';
      });
    }
  }

  Future<void> _loadCurrentViewData() async {
    switch (_currentView) {
      case 's3':
        await _loadS3Buckets();
        break;
      case 'ec2':
        await _loadEC2Instances();
        break;
      case 'rds':
        await _loadRDSInstances();
        break;
      case 'lambda':
        await _loadLambdaFunctions();
        break;
    }
  }

  Future<void> _loadS3Buckets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final buckets = await AWSBrowserApiService.listS3Buckets(
        profile: _selectedProfile,
      );
      setState(() {
        _s3Buckets = buckets;
        _currentBucket = null;
        _currentPrefix = '';
        _breadcrumbs = ['S3'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load S3 buckets: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadS3Objects(String bucket, {String prefix = ''}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final objects = await AWSBrowserApiService.listS3Objects(
        bucket: bucket,
        prefix: prefix,
        profile: _selectedProfile,
      );
      setState(() {
        _s3Objects = objects;
        _currentBucket = bucket;
        _currentPrefix = prefix;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load S3 objects: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEC2Instances() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final instances = await AWSBrowserApiService.listEC2Instances(
        profile: _selectedProfile,
        region: _selectedRegion,
      );
      setState(() {
        _ec2Instances = instances;
        _breadcrumbs = ['EC2'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load EC2 instances: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRDSInstances() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final instances = await AWSBrowserApiService.listRDSInstances(
        profile: _selectedProfile,
        region: _selectedRegion,
      );
      setState(() {
        _rdsInstances = instances;
        _breadcrumbs = ['RDS'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load RDS instances: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLambdaFunctions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final functions = await AWSBrowserApiService.listLambdaFunctions(
        profile: _selectedProfile,
        region: _selectedRegion,
      );
      setState(() {
        _lambdaFunctions = functions;
        _breadcrumbs = ['Lambda'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load Lambda functions: $e';
        _isLoading = false;
      });
    }
  }

  void _switchView(String view) {
    setState(() {
      _currentView = view;
      _currentBucket = null;
      _currentPrefix = '';
      _s3Objects = [];
    });
    _loadCurrentViewData();
  }

  void _navigateToS3Bucket(String bucket) {
    setState(() {
      _breadcrumbs = ['S3', bucket];
    });
    _loadS3Objects(bucket);
  }

  void _navigateToS3Folder(String folder) {
    setState(() {
      _breadcrumbs.add(folder);
    });
    _loadS3Objects(_currentBucket!, prefix: _currentPrefix + folder);
  }

  void _navigateBack() {
    if (_breadcrumbs.length > 1) {
      setState(() {
        _breadcrumbs.removeLast();
      });
      
      if (_breadcrumbs.length == 1) {
        // Back to buckets list
        _loadS3Buckets();
      } else {
        // Back to parent folder
        final newPrefix = _breadcrumbs.skip(2).join('');
        _loadS3Objects(_currentBucket!, prefix: newPrefix);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Toolbar with Profile, Region, and View selectors
        _buildToolbar(colorScheme),
        
        // Breadcrumbs
        if (_breadcrumbs.isNotEmpty) _buildBreadcrumbs(colorScheme),
        
        // Content
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildError(colorScheme)
                  : _buildContent(colorScheme),
        ),
      ],
    );
  }

  Widget _buildToolbar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          // Profile Selector
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AWS Profile',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedProfile,
                    isExpanded: true,
                    underline: const SizedBox(),
                    hint: Text('Select Profile'),
                    items: _availableProfiles.map((profile) {
                      return DropdownMenuItem(
                        value: profile,
                        child: Text(profile),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedProfile = value;
                      });
                      _loadCurrentViewData();
                    },
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Region Selector (only for EC2, RDS, Lambda)
          if (_currentView != 's3')
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Region',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedRegion,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: _awsRegions.map((region) {
                        return DropdownMenuItem(
                          value: region,
                          child: Text(region),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedRegion = value!;
                        });
                        _loadCurrentViewData();
                      },
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(width: 16),
          
          // View Selector
          Row(
            children: [
              _buildViewButton('S3', 's3', Icons.storage, colorScheme),
              const SizedBox(width: 8),
              _buildViewButton('EC2', 'ec2', Icons.computer, colorScheme),
              const SizedBox(width: 8),
              _buildViewButton('RDS', 'rds', Icons.dns, colorScheme),
              const SizedBox(width: 8),
              _buildViewButton('Lambda', 'lambda', Icons.flash_on, colorScheme),
            ],
          ),
          
          const SizedBox(width: 16),
          
          // Refresh Button
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadCurrentViewData,
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildViewButton(String label, String view, IconData icon, ColorScheme colorScheme) {
    final isSelected = _currentView == view;
    return Material(
      color: isSelected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _switchView(view),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumbs(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          if (_breadcrumbs.length > 1)
            IconButton(
              icon: Icon(Icons.arrow_back, size: 20),
              onPressed: _navigateBack,
              tooltip: 'Back',
            ),
          Expanded(
            child: Row(
              children: _breadcrumbs.asMap().entries.map((entry) {
                final index = entry.key;
                final crumb = entry.value;
                return Row(
                  children: [
                    if (index > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.chevron_right, size: 16, color: colorScheme.onSurfaceVariant),
                      ),
                    Text(
                      crumb,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: index == _breadcrumbs.length - 1 ? FontWeight.w600 : FontWeight.w400,
                        color: index == _breadcrumbs.length - 1 ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colorScheme.error),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadCurrentViewData,
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ColorScheme colorScheme) {
    switch (_currentView) {
      case 's3':
        return _buildS3Content(colorScheme);
      case 'ec2':
        return _buildEC2Content(colorScheme);
      case 'rds':
        return _buildRDSContent(colorScheme);
      case 'lambda':
        return _buildLambdaContent(colorScheme);
      default:
        return Center(child: Text('Unknown view'));
    }
  }

  Widget _buildS3Content(ColorScheme colorScheme) {
    final items = _currentBucket == null ? _s3Buckets : _s3Objects;
    
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storage, size: 64, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              _currentBucket == null ? 'No S3 buckets found' : 'No objects in this bucket',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        
        if (_currentBucket == null) {
          // Bucket item
          return _buildS3BucketCard(item, colorScheme);
        } else {
          // Object/Folder item
          return _buildS3ObjectCard(item, colorScheme);
        }
      },
    );
  }

  Widget _buildS3BucketCard(Map<String, dynamic> bucket, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(Icons.storage, color: Colors.green),
        title: Text(
          bucket['name'] ?? '',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Created: ${bucket['creation_date'] ?? 'Unknown'}',
          style: GoogleFonts.inter(fontSize: 12),
        ),
        trailing: Icon(Icons.chevron_right),
        onTap: () => _navigateToS3Bucket(bucket['name']),
      ),
    );
  }

  Widget _buildS3ObjectCard(Map<String, dynamic> object, ColorScheme colorScheme) {
    final isFolder = object['is_folder'] == true;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          isFolder ? Icons.folder : Icons.insert_drive_file,
          color: isFolder ? Colors.amber : Colors.blue,
        ),
        title: Text(
          object['key'] ?? '',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        subtitle: !isFolder
            ? Text(
                'Size: ${_formatBytes(object['size'] ?? 0)} • Modified: ${object['last_modified'] ?? 'Unknown'}',
                style: GoogleFonts.inter(fontSize: 12),
              )
            : null,
        trailing: isFolder ? Icon(Icons.chevron_right) : null,
        onTap: isFolder ? () => _navigateToS3Folder(object['key']) : null,
      ),
    );
  }

  Widget _buildEC2Content(ColorScheme colorScheme) {
    if (_ec2Instances.isEmpty) {
      return Center(
        child: Text(
          'No EC2 instances found in $_selectedRegion',
          style: GoogleFonts.inter(fontSize: 16, color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _ec2Instances.length,
      itemBuilder: (context, index) {
        final instance = _ec2Instances[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(Icons.computer, color: Colors.orange),
            title: Text(
              instance['name'] ?? instance['instance_id'] ?? 'Unknown',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Type: ${instance['instance_type']} • State: ${instance['state']} • IP: ${instance['public_ip'] ?? instance['private_ip'] ?? 'N/A'}',
              style: GoogleFonts.inter(fontSize: 12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRDSContent(ColorScheme colorScheme) {
    if (_rdsInstances.isEmpty) {
      return Center(
        child: Text(
          'No RDS instances found in $_selectedRegion',
          style: GoogleFonts.inter(fontSize: 16, color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _rdsInstances.length,
      itemBuilder: (context, index) {
        final instance = _rdsInstances[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(Icons.dns, color: Colors.purple),
            title: Text(
              instance['db_instance_identifier'] ?? 'Unknown',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Engine: ${instance['engine']} ${instance['engine_version']} • Status: ${instance['status']} • Storage: ${instance['allocated_storage']}GB',
              style: GoogleFonts.inter(fontSize: 12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLambdaContent(ColorScheme colorScheme) {
    if (_lambdaFunctions.isEmpty) {
      return Center(
        child: Text(
          'No Lambda functions found in $_selectedRegion',
          style: GoogleFonts.inter(fontSize: 16, color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _lambdaFunctions.length,
      itemBuilder: (context, index) {
        final function = _lambdaFunctions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(Icons.flash_on, color: Colors.amber),
            title: Text(
              function['function_name'] ?? 'Unknown',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Runtime: ${function['runtime']} • Memory: ${function['memory_size']}MB • Timeout: ${function['timeout']}s',
              style: GoogleFonts.inter(fontSize: 12),
            ),
          ),
        );
      },
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
