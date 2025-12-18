import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../../../models/workflow.dart';
import '../../../../services/workflow_api_service.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/app_header.dart';
import '../../../../widgets/common/app_card.dart';
import '../../../../widgets/common/app_button.dart';

class WorkflowEditorScreen extends StatefulWidget {
  final Workflow? workflow;

  const WorkflowEditorScreen({super.key, this.workflow});

  @override
  State<WorkflowEditorScreen> createState() => _WorkflowEditorScreenState();
}

class _WorkflowEditorScreenState extends State<WorkflowEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;
  
  List<VariableDefinition> _variables = [];
  List<WorkflowStep> _steps = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.workflow?.name ?? '');
    _descriptionController = TextEditingController(text: widget.workflow?.description ?? '');
    _categoryController = TextEditingController(text: widget.workflow?.category ?? 'General');
    
    if (widget.workflow != null) {
      _variables = List.from(widget.workflow!.variables);
      _steps = List.from(widget.workflow!.steps);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _saveWorkflow() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final workflow = Workflow(
        id: widget.workflow?.id ?? '',
        name: _nameController.text,
        description: _descriptionController.text,
        category: _categoryController.text,
        variables: _variables,
        steps: _steps,
      );

      await WorkflowApiService.saveWorkflow(workflow);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workflow saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save workflow: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addVariable() {
    showDialog(
      context: context,
      builder: (context) => _VariableDialog(
        onSave: (variable) {
          setState(() => _variables.add(variable));
        },
      ),
    );
  }

  void _addStep() {
    showDialog(
      context: context,
      builder: (context) => _StepDialog(
        availableVariables: _variables,
        onSave: (step) {
          setState(() => _steps.add(step));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          AppHeader(
            title: widget.workflow == null ? 'New Workflow' : 'Edit Workflow',
            subtitle: 'Design your automation',
            icon: Icons.edit_note,
            gradientColors: const [Color(0xFF8b5cf6), Color(0xFFd946ef)],
            actions: [
              AppButton(
                label: 'Save',
                icon: Icons.save,
                onPressed: _isSaving ? null : _saveWorkflow,
                type: AppButtonType.primary,
                isLoading: _isSaving,
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicInfo(),
                    const SizedBox(height: 24),
                    _buildVariablesSection(),
                    const SizedBox(height: 24),
                    _buildStepsSection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Basic Information', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            style: GoogleFonts.inter(color: AppTheme.textPrimary),
            decoration: const InputDecoration(labelText: 'Workflow Name'),
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            style: GoogleFonts.inter(color: AppTheme.textPrimary),
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _categoryController,
            style: GoogleFonts.inter(color: AppTheme.textPrimary),
            decoration: const InputDecoration(labelText: 'Category'),
          ),
        ],
      ),
    );
  }

  Widget _buildVariablesSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Variables', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              IconButton(icon: const Icon(Icons.add, color: AppTheme.primary), onPressed: _addVariable),
            ],
          ),
          const SizedBox(height: 16),
          if (_variables.isEmpty)
            Text('No variables defined', style: GoogleFonts.inter(color: AppTheme.textMuted))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _variables.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final variable = _variables[index];
                return ListTile(
                  title: Text(variable.name, style: GoogleFonts.inter(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: Text('${variable.type} - ${variable.description}', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: AppTheme.error),
                    onPressed: () => setState(() => _variables.removeAt(index)),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStepsSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Steps', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              IconButton(icon: const Icon(Icons.add, color: AppTheme.primary), onPressed: _addStep),
            ],
          ),
          const SizedBox(height: 16),
          if (_steps.isEmpty)
            Text('No steps defined', style: GoogleFonts.inter(color: AppTheme.textMuted))
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _steps.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final item = _steps.removeAt(oldIndex);
                  _steps.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final step = _steps[index];
                return ListTile(
                  key: ValueKey(step.id),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppTheme.surfaceHighlight, borderRadius: BorderRadius.circular(8)),
                    child: Text('${index + 1}', style: GoogleFonts.inter(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(step.name, style: GoogleFonts.inter(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: Text(step.content, style: GoogleFonts.jetBrainsMono(color: AppTheme.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppTheme.error),
                        onPressed: () => setState(() => _steps.removeAt(index)),
                      ),
                      const Icon(Icons.drag_handle, color: AppTheme.textMuted),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _VariableDialog extends StatefulWidget {
  final Function(VariableDefinition) onSave;

  const _VariableDialog({required this.onSave});

  @override
  State<_VariableDialog> createState() => _VariableDialogState();
}

class _VariableDialogState extends State<_VariableDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _type = 'string';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: Text('Add Variable', style: GoogleFonts.inter(color: AppTheme.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name'), style: GoogleFonts.inter(color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Description'), style: GoogleFonts.inter(color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _type,
            items: ['string', 'number', 'boolean'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _type = v!),
            decoration: const InputDecoration(labelText: 'Type'),
            dropdownColor: AppTheme.surface,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty) {
              widget.onSave(VariableDefinition(
                name: _nameController.text,
                description: _descController.text,
                type: _type,
              ));
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _StepDialog extends StatefulWidget {
  final List<VariableDefinition> availableVariables;
  final Function(WorkflowStep) onSave;

  const _StepDialog({required this.availableVariables, required this.onSave});

  @override
  State<_StepDialog> createState() => _StepDialogState();
}

class _StepDialogState extends State<_StepDialog> {
  final _nameController = TextEditingController();
  final _contentController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: Text('Add Step', style: GoogleFonts.inter(color: AppTheme.textPrimary)),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Step Name'), style: GoogleFonts.inter(color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Command (use {var} for variables)'),
              style: GoogleFonts.jetBrainsMono(color: AppTheme.textPrimary),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: widget.availableVariables.map((v) => ActionChip(
                label: Text('{${v.name}}'),
                onPressed: () {
                  _contentController.text += '{${v.name}}';
                },
              )).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty && _contentController.text.isNotEmpty) {
              widget.onSave(WorkflowStep(
                id: const Uuid().v4(),
                name: _nameController.text,
                type: 'command',
                content: _contentController.text,
              ));
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
