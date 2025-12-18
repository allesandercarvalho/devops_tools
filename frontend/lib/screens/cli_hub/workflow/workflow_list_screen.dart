import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/workflow.dart';
import '../../../services/workflow_api_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/app_header.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/workflow/variable_manager_widget.dart';
import 'enhanced_workflow_editor_screen.dart';
import 'workflow_runner_screen.dart';

class WorkflowListScreen extends StatefulWidget {
  const WorkflowListScreen({super.key});

  @override
  State<WorkflowListScreen> createState() => _WorkflowListScreenState();
}

class _WorkflowListScreenState extends State<WorkflowListScreen> {
  List<Workflow> _workflows = [];
  bool _isLoading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadWorkflows();
  }

  Future<void> _loadWorkflows() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final workflows = await WorkflowApiService.listWorkflows();
      setState(() {
        _workflows = workflows;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _navigateToEditor([Workflow? workflow]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EnhancedWorkflowEditorScreen(workflow: workflow)),
    );

    if (result == true) {
      _loadWorkflows();
    }
  }

  void _navigateToRunner(Workflow workflow) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WorkflowRunnerScreen(workflow: workflow)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          AppHeader(
            title: 'Workflow Engine',
            subtitle: 'Automate your DevOps tasks',
            icon: Icons.account_tree,
            gradientColors: const [Color(0xFF8b5cf6), Color(0xFFd946ef)],
            actions: [
              AppButton(
                label: 'Variáveis Globais',
                icon: Icons.public,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const VariableManagerWidget(),
                  );
                },
                type: AppButtonType.secondary,
                isSmall: true,
              ),
              const SizedBox(width: 12),
              AppButton(
                label: 'New Workflow',
                icon: Icons.add,
                onPressed: () => _navigateToEditor(),
                type: AppButtonType.primary,
                isSmall: true,
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(Icons.refresh, color: AppTheme.textPrimary),
                onPressed: _loadWorkflows,
              ),
            ],
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppTheme.error, size: 48),
            const SizedBox(height: 16),
            Text(_error, style: GoogleFonts.inter(color: AppTheme.error)),
            const SizedBox(height: 16),
            AppButton(label: 'Retry', onPressed: _loadWorkflows, type: AppButtonType.secondary),
          ],
        ),
      );
    }

    if (_workflows.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_tree_outlined, size: 64, color: AppTheme.textMuted.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'No workflows found',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first workflow to get started',
              style: GoogleFonts.inter(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Create Workflow',
              icon: Icons.add,
              onPressed: () => _navigateToEditor(),
              type: AppButtonType.primary,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 1.5,
      ),
      itemCount: _workflows.length,
      itemBuilder: (context, index) {
        return _buildWorkflowCard(_workflows[index]);
      },
    );
  }

  Widget _buildWorkflowCard(Workflow workflow) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.play_circle_outline, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workflow.name,
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      workflow.category,
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: AppTheme.textSecondary),
                onSelected: (value) {
                  if (value == 'edit') _navigateToEditor(workflow);
                  // TODO: Implement delete
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Text(
              workflow.description,
              style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildBadge('${workflow.steps.length} Steps', AppTheme.info),
              const SizedBox(width: 8),
              _buildBadge('${workflow.variables.length} Vars', AppTheme.secondary),
              const Spacer(),
              AppButton(
                label: 'Run',
                icon: Icons.play_arrow,
                onPressed: () => _navigateToRunner(workflow),
                type: AppButtonType.primary,
                isSmall: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
