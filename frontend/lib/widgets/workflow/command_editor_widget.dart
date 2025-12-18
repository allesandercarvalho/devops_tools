import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/workflow.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_button.dart';

class CommandEditorWidget extends StatefulWidget {
  final WorkflowStep? step;
  final List<VariableDefinition> availableVariables;
  final Function(WorkflowStep) onSave;

  const CommandEditorWidget({
    super.key,
    this.step,
    required this.availableVariables,
    required this.onSave,
  });

  @override
  State<CommandEditorWidget> createState() => _CommandEditorWidgetState();
}

class _CommandEditorWidgetState extends State<CommandEditorWidget> {
  late TextEditingController _nameController;
  late TextEditingController _commandController;
  List<String> _detectedVariables = [];
  Map<String, TextEditingController> _variableControllers = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.step?.name ?? '');
    _commandController = TextEditingController(text: widget.step?.content ?? '');
    
    _commandController.addListener(_onCommandChanged);
    _detectVariables();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commandController.dispose();
    _commandController.removeListener(_onCommandChanged);
    for (var controller in _variableControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onCommandChanged() {
    _detectVariables();
  }

  void _detectVariables() {
    final regex = RegExp(r'\{([A-Z_][A-Z0-9_]*)\}');
    final matches = regex.allMatches(_commandController.text);
    
    final Set<String> newVariables = {};
    for (var match in matches) {
      if (match.groupCount > 0) {
        newVariables.add(match.group(1)!);
      }
    }

    setState(() {
      _detectedVariables = newVariables.toList()..sort();
      
      // Create controllers for new variables
      for (var varName in _detectedVariables) {
        if (!_variableControllers.containsKey(varName)) {
          _variableControllers[varName] = TextEditingController();
        }
      }
      
      // Remove controllers for variables no longer in use
      _variableControllers.removeWhere((key, value) {
        if (!_detectedVariables.contains(key)) {
          value.dispose();
          return true;
        }
        return false;
      });
    });
  }

  String _getPreview() {
    String preview = _commandController.text;
    
    for (var varName in _detectedVariables) {
      final value = _variableControllers[varName]?.text ?? '';
      if (value.isNotEmpty) {
        preview = preview.replaceAll('{$varName}', value);
      }
    }
    
    return preview;
  }

  void _insertVariable(String varName) {
    final text = _commandController.text;
    final selection = _commandController.selection;
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      '{$varName}',
    );
    
    _commandController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + varName.length + 2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      child: Container(
        width: 800,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.edit_note, color: AppTheme.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Editar Comando',
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
            const SizedBox(height: 24),
            
            // Step Name
            TextFormField(
              controller: _nameController,
              style: GoogleFonts.inter(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Nome do Step',
                hintText: 'Ex: Criar Instância EC2',
                prefixIcon: const Icon(Icons.label_outline),
                filled: true,
                fillColor: AppTheme.surfaceHighlight,
              ),
            ),
            const SizedBox(height: 16),
            
            // Command Editor
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Command Input
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Comando',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Tooltip(
                              message: 'Use {NOME_VARIAVEL} para criar variáveis',
                              child: Icon(Icons.help_outline, size: 16, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: AppCard(
                            padding: const EdgeInsets.all(12),
                            child: TextField(
                              controller: _commandController,
                              style: GoogleFonts.jetBrainsMono(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                              ),
                              maxLines: null,
                              expands: true,
                              decoration: InputDecoration(
                                hintText: 'aws ec2 run-instances --image-id {AMI_ID} --instance-type {INSTANCE_TYPE}',
                                hintStyle: GoogleFonts.jetBrainsMono(color: AppTheme.textMuted),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Variable Chips
                        if (widget.availableVariables.isNotEmpty) ...[
                          Text(
                            'Variáveis Disponíveis (clique para inserir)',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: widget.availableVariables.map((v) {
                              return ActionChip(
                                label: Text('{${v.name}}'),
                                onPressed: () => _insertVariable(v.name),
                                backgroundColor: AppTheme.primary.withOpacity(0.1),
                                labelStyle: GoogleFonts.jetBrainsMono(
                                  color: AppTheme.primary,
                                  fontSize: 12,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Right: Detected Variables & Preview
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Detected Variables
                        Text(
                          'Variáveis Detectadas',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: AppCard(
                            padding: const EdgeInsets.all(12),
                            child: _detectedVariables.isEmpty
                                ? Center(
                                    child: Text(
                                      'Nenhuma variável detectada\n\nUse {NOME} no comando',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        color: AppTheme.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: _detectedVariables.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final varName = _detectedVariables[index];
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            varName,
                                            style: GoogleFonts.jetBrainsMono(
                                              color: AppTheme.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          TextField(
                                            controller: _variableControllers[varName],
                                            style: GoogleFonts.inter(
                                              color: AppTheme.textPrimary,
                                              fontSize: 12,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'Valor para preview',
                                              hintStyle: GoogleFonts.inter(
                                                color: AppTheme.textMuted,
                                                fontSize: 11,
                                              ),
                                              filled: true,
                                              fillColor: AppTheme.background,
                                              contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 6,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(6),
                                                borderSide: BorderSide.none,
                                              ),
                                            ),
                                            onChanged: (_) => setState(() {}),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Preview
                        Text(
                          'Preview',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AppCard(
                          padding: const EdgeInsets.all(12),
                          child: SelectableText(
                            _getPreview(),
                            style: GoogleFonts.jetBrainsMono(
                              color: AppTheme.success,
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
            
            const SizedBox(height: 24),
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  label: 'Cancelar',
                  onPressed: () => Navigator.pop(context),
                  type: AppButtonType.ghost,
                ),
                const SizedBox(width: 12),
                AppButton(
                  label: 'Salvar',
                  icon: Icons.check,
                  onPressed: () {
                    // TODO: Create WorkflowStep and call onSave
                    Navigator.pop(context);
                  },
                  type: AppButtonType.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
