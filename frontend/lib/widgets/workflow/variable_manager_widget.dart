import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/workflow.dart';
import '../../../services/workflow_api_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_button.dart';

class VariableManagerWidget extends StatefulWidget {
  const VariableManagerWidget({super.key});

  @override
  State<VariableManagerWidget> createState() => _VariableManagerWidgetState();
}

class _VariableManagerWidgetState extends State<VariableManagerWidget> {
  List<GlobalVariable> _variables = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadVariables();
  }

  Future<void> _loadVariables() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final variables = await WorkflowApiService.listGlobalVariables();
      setState(() {
        _variables = variables;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddEditDialog([GlobalVariable? variable]) async {
    final nameController = TextEditingController(text: variable?.name ?? '');
    final valueController = TextEditingController(text: variable?.value ?? '');
    final descController = TextEditingController(text: variable?.description ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          variable == null ? 'Nova Variável Global' : 'Editar Variável',
          style: GoogleFonts.inter(color: AppTheme.textPrimary),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: GoogleFonts.inter(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  hintText: 'AWS_REGION',
                  prefixIcon: Icon(Icons.label),
                ),
                enabled: variable == null, // Can't change name on edit
              ),
              const SizedBox(height: 16),
              TextField(
                controller: valueController,
                style: GoogleFonts.inter(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  hintText: 'us-east-1',
                  prefixIcon: Icon(Icons.text_fields),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                style: GoogleFonts.inter(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'Região AWS padrão',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final newVariable = GlobalVariable(
          name: nameController.text.trim(),
          value: valueController.text.trim(),
          description: descController.text.trim(),
          createdAt: variable?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await WorkflowApiService.saveGlobalVariable(newVariable);
        _loadVariables();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Variável salva com sucesso!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao salvar: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteVariable(String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Confirmar Exclusão', style: GoogleFonts.inter(color: AppTheme.textPrimary)),
        content: Text(
          'Deseja realmente excluir a variável "$name"?',
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await WorkflowApiService.deleteGlobalVariable(name);
        _loadVariables();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Variável excluída!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir: $e')),
          );
        }
      }
    }
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
                Icon(Icons.public, color: AppTheme.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Variáveis Globais',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                AppButton(
                  label: 'Nova Variável',
                  icon: Icons.add,
                  onPressed: () => _showAddEditDialog(),
                  type: AppButtonType.primary,
                  isSmall: true,
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Variáveis reutilizáveis em todos os workflows',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Content
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
                                onPressed: _loadVariables,
                                type: AppButtonType.secondary,
                              ),
                            ],
                          ),
                        )
                      : _variables.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inbox, size: 64, color: AppTheme.textMuted),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Nenhuma variável global definida',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Crie variáveis para reutilizar em seus workflows',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: _variables.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final variable = _variables[index];
                                return AppCard(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
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
                                            const SizedBox(height: 4),
                                            Text(
                                              variable.value,
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                color: AppTheme.textPrimary,
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
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20),
                                        onPressed: () => _showAddEditDialog(variable),
                                        color: AppTheme.textSecondary,
                                        tooltip: 'Editar',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, size: 20),
                                        onPressed: () => _deleteVariable(variable.name),
                                        color: AppTheme.error,
                                        tooltip: 'Excluir',
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
