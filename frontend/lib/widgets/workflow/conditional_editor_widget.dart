import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/workflow.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_button.dart';

class ConditionalEditorWidget extends StatefulWidget {
  final List<Condition>? initialConditions;
  final List<WorkflowStep> availableSteps;
  final Function(List<Condition>) onSave;

  const ConditionalEditorWidget({
    super.key,
    this.initialConditions,
    required this.availableSteps,
    required this.onSave,
  });

  @override
  State<ConditionalEditorWidget> createState() => _ConditionalEditorWidgetState();
}

class _ConditionalEditorWidgetState extends State<ConditionalEditorWidget> {
  List<Condition> _conditions = [];

  final List<String> _conditionTypes = [
    'contains',
    'equals',
    'starts_with',
    'ends_with',
    'regex',
    'exit_code',
  ];

  final Map<String, String> _conditionLabels = {
    'contains': 'Contém',
    'equals': 'Igual a',
    'starts_with': 'Começa com',
    'ends_with': 'Termina com',
    'regex': 'Regex Match',
    'exit_code': 'Código de Saída',
  };

  final List<String> _actionTypes = [
    'continue',
    'stop',
    'jump_to',
    'execute_step',
  ];

  final Map<String, String> _actionLabels = {
    'continue': 'Continuar',
    'stop': 'Parar Workflow',
    'jump_to': 'Pular para Step',
    'execute_step': 'Executar Step',
  };

  @override
  void initState() {
    super.initState();
    _conditions = widget.initialConditions ?? [];
  }

  void _addCondition() {
    setState(() {
      _conditions.add(Condition(
        type: 'contains',
        value: '',
        operator: '',
        action: StepAction(type: 'continue', target: ''),
      ));
    });
  }

  void _removeCondition(int index) {
    setState(() {
      _conditions.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      child: Container(
        width: 900,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.alt_route, color: AppTheme.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Condições do Step',
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
              'Defina o que acontece baseado no resultado do step',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Conditions List
            Expanded(
              child: _conditions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline, size: 64, color: AppTheme.textMuted),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhuma condição definida',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Adicione condições para controlar o fluxo do workflow',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _conditions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _buildConditionCard(index);
                      },
                    ),
            ),

            const SizedBox(height: 16),

            // Add Condition Button
            AppButton(
              label: 'Adicionar Condição',
              icon: Icons.add,
              onPressed: _addCondition,
              type: AppButtonType.secondary,
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
                    widget.onSave(_conditions);
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

  Widget _buildConditionCard(int index) {
    final condition = _conditions[index];

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'IF',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Condição ${index + 1}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                onPressed: () => _removeCondition(index),
                color: AppTheme.error,
                tooltip: 'Remover',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Condition Type
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tipo de Verificação',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: condition.type,
                      style: GoogleFonts.inter(color: AppTheme.textPrimary),
                      dropdownColor: AppTheme.surface,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.surfaceHighlight,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _conditionTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(_conditionLabels[type] ?? type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _conditions[index] = Condition(
                              type: value,
                              value: condition.value,
                              operator: condition.operator,
                              action: condition.action,
                            );
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      condition.type == 'exit_code' ? 'Código' : 'Valor',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      initialValue: condition.value,
                      style: GoogleFonts.jetBrainsMono(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: condition.type == 'exit_code' ? '0' : 'success',
                        filled: true,
                        fillColor: AppTheme.surfaceHighlight,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _conditions[index] = Condition(
                            type: condition.type,
                            value: value,
                            operator: condition.operator,
                            action: condition.action,
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Então',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: condition.action.type,
                      style: GoogleFonts.inter(color: AppTheme.textPrimary),
                      dropdownColor: AppTheme.surface,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.surfaceHighlight,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _actionTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(_actionLabels[type] ?? type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _conditions[index] = Condition(
                              type: condition.type,
                              value: condition.value,
                              operator: condition.operator,
                              action: StepAction(
                                type: value,
                                target: condition.action.target,
                              ),
                            );
                          });
                        }
                      },
                    ),
                  ),
                  if (condition.action.type == 'jump_to' || condition.action.type == 'execute_step') ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: condition.action.target.isEmpty ? null : condition.action.target,
                        style: GoogleFonts.inter(color: AppTheme.textPrimary),
                        dropdownColor: AppTheme.surface,
                        decoration: InputDecoration(
                          hintText: 'Selecione o step',
                          filled: true,
                          fillColor: AppTheme.surfaceHighlight,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: widget.availableSteps.map((step) {
                          return DropdownMenuItem(
                            value: step.id,
                            child: Text(step.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _conditions[index] = Condition(
                                type: condition.type,
                                value: condition.value,
                                operator: condition.operator,
                                action: StepAction(
                                  type: condition.action.type,
                                  target: value,
                                ),
                              );
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Update Condition and StepAction models in workflow.dart
class Condition {
  final String type;
  final String value;
  final String operator;
  final StepAction action;

  Condition({
    required this.type,
    required this.value,
    required this.operator,
    required this.action,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'value': value,
      'operator': operator,
      'action': action.toJson(),
    };
  }

  factory Condition.fromJson(Map<String, dynamic> json) {
    return Condition(
      type: json['type'] ?? 'contains',
      value: json['value'] ?? '',
      operator: json['operator'] ?? '',
      action: StepAction.fromJson(json['action'] ?? {}),
    );
  }
}

class StepAction {
  final String type;
  final String target;

  StepAction({
    required this.type,
    required this.target,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'target': target,
    };
  }

  factory StepAction.fromJson(Map<String, dynamic> json) {
    return StepAction(
      type: json['type'] ?? 'continue',
      target: json['target'] ?? '',
    );
  }
}
