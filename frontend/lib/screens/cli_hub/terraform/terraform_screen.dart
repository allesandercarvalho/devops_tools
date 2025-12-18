import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/terraform.dart';
import '../../../../services/terraform_api_service.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/app_header.dart';
import '../../../../widgets/common/app_card.dart';
import '../../../../widgets/common/app_button.dart';

class TerraformScreen extends StatefulWidget {
  const TerraformScreen({super.key});

  @override
  State<TerraformScreen> createState() => _TerraformScreenState();
}

class _TerraformScreenState extends State<TerraformScreen> with SingleTickerProviderStateMixin {
  final _workDirController = TextEditingController();
  late TabController _tabController;
  bool _isLoading = false;
  String _error = '';
  TerraformState? _currentState;
  TerraformExecution? _lastExecution;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _loadState() async {
    if (_workDirController.text.isEmpty) {
      setState(() => _error = 'Please enter a working directory');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final state = await TerraformApiService.getState(_workDirController.text);
      setState(() {
        _currentState = state;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _executeCommand(String command, [List<String> args = const []]) async {
    if (_workDirController.text.isEmpty) {
      setState(() => _error = 'Please enter a working directory');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
      _lastExecution = null;
    });

    try {
      final execution = await TerraformApiService.executeCommand(
        workDir: _workDirController.text,
        command: command,
        args: args,
      );

      setState(() {
        _lastExecution = execution;
        _isLoading = false;
      });

      if (command == 'apply' || command == 'destroy') {
        _loadState(); // Reload state after changes
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          const AppHeader(
            title: 'Terraform Manager',
            subtitle: 'Infrastructure as Code',
            icon: Icons.cloud_circle,
            gradientColors: [Color(0xFF7c3aed), Color(0xFF8b5cf6)],
          ),
          _buildWorkDirInput(),
          Expanded(
            child: Column(
              children: [
                Container(
                  color: AppTheme.surface,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppTheme.primary,
                    labelColor: AppTheme.primary,
                    unselectedLabelColor: AppTheme.textSecondary,
                    tabs: const [
                      Tab(text: 'State Viewer', icon: Icon(Icons.data_object)),
                      Tab(text: 'Plan & Apply', icon: Icon(Icons.play_arrow)),
                      Tab(text: 'Output', icon: Icon(Icons.terminal)),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildStateViewer(),
                      _buildPlanApply(),
                      _buildOutput(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkDirInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.surface,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _workDirController,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Working Directory',
                hintText: '/path/to/terraform/project',
                prefixIcon: Icon(Icons.folder),
              ),
            ),
          ),
          const SizedBox(width: 16),
          AppButton(
            label: 'Load State',
            icon: Icons.refresh,
            onPressed: _isLoading ? null : _loadState,
          ),
        ],
      ),
    );
  }

  Widget _buildStateViewer() {
    if (_currentState == null) {
      return Center(child: Text('Load a state to view resources', style: GoogleFonts.inter(color: AppTheme.textMuted)));
    }

    final resources = _getAllResources(_currentState!.values?.rootModule);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: resources.length,
      itemBuilder: (context, index) {
        final resource = resources[index];
        return AppCard(
          padding: EdgeInsets.zero,
          child: ExpansionTile(
            leading: Icon(_getResourceIcon(resource.type), color: AppTheme.primary),
            title: Text(resource.address, style: GoogleFonts.jetBrainsMono(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
            subtitle: Text('${resource.type} • ${resource.providerName}', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                color: AppTheme.background,
                child: SelectableText(
                  resource.values.toString(),
                  style: AppTheme.codeStyle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<TerraformResource> _getAllResources(TerraformModule? module) {
    if (module == null) return [];
    List<TerraformResource> all = [...module.resources];
    for (var child in module.childModules) {
      all.addAll(_getAllResources(child));
    }
    return all;
  }

  IconData _getResourceIcon(String type) {
    if (type.contains('aws_instance')) return Icons.computer;
    if (type.contains('s3')) return Icons.storage;
    if (type.contains('vpc') || type.contains('subnet')) return Icons.network_check;
    if (type.contains('security_group')) return Icons.security;
    return Icons.extension;
  }

  Widget _buildPlanApply() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 200,
            child: AppButton(label: 'Init', icon: Icons.start, onPressed: () => _executeCommand('init')),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 200,
            child: AppButton(label: 'Plan', icon: Icons.visibility, onPressed: () => _executeCommand('plan')),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 200,
            child: AppButton(
              label: 'Apply',
              icon: Icons.play_circle_fill,
              onPressed: () => _executeCommand('apply', ['-auto-approve']),
              type: AppButtonType.success,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 200,
            child: AppButton(
              label: 'Destroy',
              icon: Icons.delete_forever,
              onPressed: () => _executeCommand('destroy', ['-auto-approve']),
              type: AppButtonType.destructive,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutput() {
    if (_lastExecution == null) {
      return Center(child: Text('No execution output yet', style: GoogleFonts.inter(color: AppTheme.textMuted)));
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _lastExecution!.status == 'failed' ? AppTheme.error : AppTheme.success),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${_lastExecution!.command.toUpperCase()} OUTPUT', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const Spacer(),
              Text('${_lastExecution!.durationMs}ms', style: GoogleFonts.jetBrainsMono(color: AppTheme.textSecondary)),
            ],
          ),
          Divider(color: Colors.white.withOpacity(0.1)),
          Expanded(
            child: SingleChildScrollView(
              child: SelectableText(
                _lastExecution!.output.isEmpty ? _lastExecution!.error : _lastExecution!.output,
                style: AppTheme.codeStyle.copyWith(
                  color: _lastExecution!.status == 'failed' ? AppTheme.error : AppTheme.success,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _workDirController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}
