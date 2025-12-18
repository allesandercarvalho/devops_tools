import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/workflow.dart';
import '../../../services/workflow_api_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_button.dart';

class WorkflowSelectorWidget extends StatefulWidget {
  final Function(String workflowId, String workflowName) onSelect;

  const WorkflowSelectorWidget({
    super.key,
    required this.onSelect,
  });

  @override
  State<WorkflowSelectorWidget> createState() => _WorkflowSelectorWidgetState();
}

class _WorkflowSelectorWidgetState extends State<WorkflowSelectorWidget> {
  List<Workflow> _workflows = [];
  bool _isLoading = true;
  String _error = '';
  String _searchQuery = '';

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

  List<Workflow> get _filteredWorkflows {
    if (_searchQuery.isEmpty) return _workflows;
    
    return _workflows.where((w) {
      return w.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             w.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             w.category.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      child: Container(
        width: 700,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.account_tree, color: AppTheme.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Selecionar Workflow',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Escolha um workflow para adicionar como step',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Search
            TextField(
              style: GoogleFonts.inter(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Buscar workflows...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppTheme.surfaceHighlight,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Workflows List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, color: AppTheme.error, size: 48),
                              const SizedBox(height: 16),
                              Text(_error, style: GoogleFonts.inter(color: AppTheme.error)),
                              const SizedBox(height: 16),
                              AppButton(
                                label: 'Tentar Novamente',
                                onPressed: _loadWorkflows,
                                type: AppButtonType.secondary,
                              ),
                            ],
                          ),
                        )
                      : _filteredWorkflows.isEmpty
                          ? Center(
                              child: Text(
                                _searchQuery.isEmpty
                                    ? 'Nenhum workflow disponível'
                                    : 'Nenhum workflow encontrado',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _filteredWorkflows.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final workflow = _filteredWorkflows[index];
                                return _buildWorkflowCard(workflow);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkflowCard(Workflow workflow) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () {
          widget.onSelect(workflow.id, workflow.name);
          Navigator.pop(context);
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.account_tree,
                color: AppTheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workflow.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (workflow.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      workflow.description,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceHighlight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          workflow.category,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.layers, size: 14, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${workflow.steps.length} steps',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.code, size: 14, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${workflow.variables.length} vars',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
