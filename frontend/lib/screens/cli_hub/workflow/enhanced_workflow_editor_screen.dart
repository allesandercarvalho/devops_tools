import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../../models/workflow.dart';
import '../../../services/workflow_api_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/app_header.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/workflow/variable_manager_widget.dart';

class EnhancedWorkflowEditorScreen extends StatefulWidget {
  final Workflow? workflow;

  const EnhancedWorkflowEditorScreen({super.key, this.workflow});

  @override
  State<EnhancedWorkflowEditorScreen> createState() => _EnhancedWorkflowEditorScreenState();
}

class _EnhancedWorkflowEditorScreenState extends State<EnhancedWorkflowEditorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;

  List<VariableDefinition> _variables = [];
  List<WorkflowStep> _steps = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    _nameController = TextEditingController(text: widget.workflow?.name ?? '');
    _descriptionController = TextEditingController(text: widget.workflow?.description ?? '');
    _categoryController = TextEditingController(text: widget.workflow?.category ?? 'General');
    
    _variables = widget.workflow?.variables ?? [];
    _steps = widget.workflow?.steps ?? [];
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _saveWorkflow() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nome do workflow é obrigatório')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final workflow = Workflow(
        id: widget.workflow?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim(),
        variables: _variables,
        steps: _steps,
      );

      await WorkflowApiService.saveWorkflow(workflow);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workflow salvo com sucesso!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _addVariable() {
    showDialog(
      context: context,
      builder: (context) => _VariableDialog(
        onSave: (variable) {
          setState(() {
            _variables.add(variable);
          });
        },
      ),
    );
  }

  void _editVariable(int index) {
    showDialog(
      context: context,
      builder: (context) => _VariableDialog(
        variable: _variables[index],
        onSave: (variable) {
          setState(() {
            _variables[index] = variable;
          });
        },
      ),
    );
  }

  void _deleteVariable(int index) {
    setState(() {
      _variables.removeAt(index);
    });
  }

  void _addStep(String type) {
    final step = WorkflowStep(
      id: const Uuid().v4(),
      name: type == 'command' ? 'Novo Comando' : 'Novo Workflow',
      type: type,
      content: '',
      variables: {},
    );

    setState(() {
      _steps.add(step);
    });

    // Open editor for the new step
    _editStep(_steps.length - 1);
  }

  void _editStep(int index) {
    final step = _steps[index];
    
    showDialog(
      context: context,
      builder: (context) => _StepEditorDialog(
        step: step,
        availableVariables: _variables,
        availableSteps: _steps,
        onSave: (updatedStep) {
          setState(() {
            _steps[index] = updatedStep;
          });
        },
      ),
    );
  }

  void _deleteStep(int index) {
    setState(() {
      _steps.removeAt(index);
    });
  }

  void _reorderSteps(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final step = _steps.removeAt(oldIndex);
      _steps.insert(newIndex, step);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          AppHeader(
            title: widget.workflow == null ? 'Novo Workflow' : 'Editar Workflow',
            subtitle: 'Configure steps, variáveis e condições',
            icon: Icons.edit_note,
            gradientColors: const [Color(0xFF6366f1), Color(0xFF8b5cf6)],
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
                type: AppButtonType.ghost,
                isSmall: true,
              ),
              const SizedBox(width: 12),
              AppButton(
                label: 'Salvar',
                icon: Icons.save,
                onPressed: _isSaving ? null : _saveWorkflow,
                isLoading: _isSaving,
                type: AppButtonType.primary,
                isSmall: true,
              ),
            ],
          ),
          
          // Tabs
          Container(
            color: AppTheme.surface,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primary,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textSecondary,
              tabs: const [
                Tab(text: 'Informações', icon: Icon(Icons.info_outline, size: 20)),
                Tab(text: 'Variáveis', icon: Icon(Icons.code, size: 20)),
                Tab(text: 'Steps', icon: Icon(Icons.layers, size: 20)),
                Tab(text: 'Preview', icon: Icon(Icons.visibility, size: 20)),
              ],
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(),
                _buildVariablesTab(),
                _buildStepsTab(),
                _buildPreviewTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informações Básicas',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                
                TextFormField(
                  controller: _nameController,
                  style: GoogleFonts.inter(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Nome do Workflow *',
                    hintText: 'Ex: Deploy de Aplicação',
                    prefixIcon: Icon(Icons.label),
                  ),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _descriptionController,
                  style: GoogleFonts.inter(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    hintText: 'Descreva o que este workflow faz',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _categoryController,
                  style: GoogleFonts.inter(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    hintText: 'Ex: AWS, DevOps, CI/CD',
                    prefixIcon: Icon(Icons.category),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariablesTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.surface,
          child: Row(
            children: [
              Text(
                '${_variables.length} variáveis definidas',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              AppButton(
                label: 'Nova Variável',
                icon: Icons.add,
                onPressed: _addVariable,
                type: AppButtonType.primary,
                isSmall: true,
              ),
            ],
          ),
        ),
        Expanded(
          child: _variables.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.code_off, size: 64, color: AppTheme.textMuted),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma variável definida',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Variáveis serão detectadas automaticamente nos comandos',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: _variables.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final variable = _variables[index];
                    return AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(Icons.code, color: AppTheme.primary, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  variable.name,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                if (variable.description.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    variable.description,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  'Tipo: ${variable.type}${variable.defaultValue != null ? " • Padrão: ${variable.defaultValue}" : ""}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _editVariable(index),
                            color: AppTheme.textSecondary,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            onPressed: () => _deleteVariable(index),
                            color: AppTheme.error,
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStepsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.surface,
          child: Row(
            children: [
              Text(
                '${_steps.length} steps configurados',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              AppButton(
                label: 'Comando',
                icon: Icons.terminal,
                onPressed: () => _addStep('command'),
                type: AppButtonType.secondary,
                isSmall: true,
              ),
              const SizedBox(width: 8),
              AppButton(
                label: 'Workflow',
                icon: Icons.account_tree,
                onPressed: () => _addStep('workflow_ref'),
                type: AppButtonType.primary,
                isSmall: true,
              ),
            ],
          ),
        ),
        Expanded(
          child: _steps.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.layers_clear, size: 64, color: AppTheme.textMuted),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum step adicionado',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Adicione comandos ou workflows para começar',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _steps.length,
                  onReorder: _reorderSteps,
                  itemBuilder: (context, index) {
                    final step = _steps[index];
                    return _buildStepCard(step, index, key: ValueKey(step.id));
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStepCard(WorkflowStep step, int index, {required Key key}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        key: key,
        padding: const EdgeInsets.all(16),
        child: Row(
        children: [
          // Drag Handle
          Icon(Icons.drag_indicator, color: AppTheme.textMuted),
          const SizedBox(width: 12),
          
          // Step Number
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Step Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      step.type == 'command' ? Icons.terminal : Icons.account_tree,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      step.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  step.content.isEmpty ? 'Não configurado' : step.content,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Actions
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () => _editStep(index),
            color: AppTheme.textSecondary,
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20),
            onPressed: () => _deleteStep(index),
            color: AppTheme.error,
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildPreviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: AppCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preview do Workflow',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Workflow Info
            _buildPreviewSection('Nome', _nameController.text.isEmpty ? 'Sem nome' : _nameController.text),
            _buildPreviewSection('Descrição', _descriptionController.text.isEmpty ? 'Sem descrição' : _descriptionController.text),
            _buildPreviewSection('Categoria', _categoryController.text),
            
            const SizedBox(height: 24),
            Divider(color: AppTheme.textMuted.withOpacity(0.2)),
            const SizedBox(height: 24),
            
            // Variables
            Text(
              'Variáveis (${_variables.length})',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (_variables.isEmpty)
              Text(
                'Nenhuma variável definida',
                style: GoogleFonts.inter(color: AppTheme.textMuted),
              )
            else
              ...List.generate(_variables.length, (index) {
                final v = _variables[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '• ${v.name} (${v.type})',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                );
              }),
            
            const SizedBox(height: 24),
            Divider(color: AppTheme.textMuted.withOpacity(0.2)),
            const SizedBox(height: 24),
            
            // Steps
            Text(
              'Fluxo de Execução (${_steps.length} steps)',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (_steps.isEmpty)
              Text(
                'Nenhum step configurado',
                style: GoogleFonts.inter(color: AppTheme.textMuted),
              )
            else
              ...List.generate(_steps.length, (index) {
                final step = _steps[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceHighlight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Step ${index + 1}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            step.type == 'command' ? Icons.terminal : Icons.account_tree,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            step.name,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (step.content.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          step.content,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Variable Dialog
class _VariableDialog extends StatefulWidget {
  final VariableDefinition? variable;
  final Function(VariableDefinition) onSave;

  const _VariableDialog({this.variable, required this.onSave});

  @override
  State<_VariableDialog> createState() => _VariableDialogState();
}

class _VariableDialogState extends State<_VariableDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _defaultController;
  String _type = 'string';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.variable?.name ?? '');
    _descController = TextEditingController(text: widget.variable?.description ?? '');
    _defaultController = TextEditingController(text: widget.variable?.defaultValue ?? '');
    _type = widget.variable?.type ?? 'string';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: Text(
        widget.variable == null ? 'Nova Variável' : 'Editar Variável',
        style: GoogleFonts.inter(color: AppTheme.textPrimary),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              style: GoogleFonts.inter(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Nome',
                hintText: 'AWS_REGION',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              style: GoogleFonts.inter(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Descrição',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _type,
              style: GoogleFonts.inter(color: AppTheme.textPrimary),
              dropdownColor: AppTheme.surface,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: const [
                DropdownMenuItem(value: 'string', child: Text('String')),
                DropdownMenuItem(value: 'number', child: Text('Number')),
                DropdownMenuItem(value: 'boolean', child: Text('Boolean')),
                DropdownMenuItem(value: 'select', child: Text('Select')),
              ],
              onChanged: (value) => setState(() => _type = value!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _defaultController,
              style: GoogleFonts.inter(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Valor Padrão',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(VariableDefinition(
              name: _nameController.text.trim(),
              description: _descController.text.trim(),
              type: _type,
              defaultValue: _defaultController.text.trim(),
            ));
            Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

// Step Editor Dialog
class _StepEditorDialog extends StatefulWidget {
  final WorkflowStep step;
  final List<VariableDefinition> availableVariables;
  final List<WorkflowStep> availableSteps;
  final Function(WorkflowStep) onSave;

  const _StepEditorDialog({
    required this.step,
    required this.availableVariables,
    required this.availableSteps,
    required this.onSave,
  });

  @override
  State<_StepEditorDialog> createState() => _StepEditorDialogState();
}

class _StepEditorDialogState extends State<_StepEditorDialog> {
  late TextEditingController _nameController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.step.name);
    _contentController = TextEditingController(text: widget.step.content);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: Text(
        'Editar Step',
        style: GoogleFonts.inter(color: AppTheme.textPrimary),
      ),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              style: GoogleFonts.inter(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Nome do Step',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              style: GoogleFonts.jetBrainsMono(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: widget.step.type == 'command' ? 'Comando' : 'Workflow ID',
                hintText: widget.step.type == 'command'
                    ? 'aws ec2 describe-instances --region {AWS_REGION}'
                    : 'workflow-id',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(WorkflowStep(
              id: widget.step.id,
              name: _nameController.text.trim(),
              type: widget.step.type,
              content: _contentController.text.trim(),
              variables: widget.step.variables,
            ));
            Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
