import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/workflow.dart';
import '../../../../services/workflow_api_service.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/app_header.dart';
import '../../../../widgets/common/app_card.dart';
import '../../../../widgets/common/app_button.dart';
import '../../../widgets/terminal_output.dart';

class WorkflowRunnerScreen extends StatefulWidget {
  final Workflow workflow;

  const WorkflowRunnerScreen({super.key, required this.workflow});

  @override
  State<WorkflowRunnerScreen> createState() => _WorkflowRunnerScreenState();
}

class _WorkflowRunnerScreenState extends State<WorkflowRunnerScreen> {
  final Map<String, TextEditingController> _controllers = {};
  String _terminalOutput = '';
  bool _isExecuting = false;
  String _status = 'Ready';

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (var v in widget.workflow.variables) {
      _controllers[v.name] = TextEditingController(text: v.defaultValue ?? '');
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _executeWorkflow() async {
    setState(() {
      _isExecuting = true;
      _status = 'Running...';
      _terminalOutput = 'Starting workflow: ${widget.workflow.name}\n';
    });

    try {
      final variables = _controllers.map((key, value) => MapEntry(key, value.text));
      
      // In a real implementation, we would subscribe to a WebSocket for real-time logs.
      // For now, we'll simulate streaming by polling or just showing the final result.
      // Since the backend implementation currently returns the execution object after completion (synchronous for now in the API wrapper),
      // we will just show the result. 
      // TODO: Implement real-time WebSocket streaming in frontend service.

      final execution = await WorkflowApiService.executeWorkflow(widget.workflow.id, variables);
      
      setState(() {
        _isExecuting = false;
        _status = execution.status == 'completed' ? 'Success' : 'Failed';
        // Append logs
        // Since the backend mock implementation might not return logs in the response immediately if async, 
        // we'll simulate some output or use what's returned.
        // The current backend implementation returns the execution object which has logs.
        if (execution.logs.isNotEmpty) {
           _terminalOutput += execution.logs.join('\n');
        } else {
           _terminalOutput += 'Workflow executed successfully (no logs returned).\n';
        }
        _terminalOutput += '\nStatus: ${execution.status}';
      });

    } catch (e) {
      setState(() {
        _isExecuting = false;
        _status = 'Error';
        _terminalOutput += '\nError executing workflow: $e\n';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          AppHeader(
            title: 'Run: ${widget.workflow.name}',
            subtitle: widget.workflow.description,
            icon: Icons.play_circle_filled,
            gradientColors: const [Color(0xFF8b5cf6), Color(0xFFd946ef)],
          ),
          Expanded(
            child: Row(
              children: [
                // Left: Configuration
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.white.withOpacity(0.1))),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Configuration', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        const SizedBox(height: 24),
                        if (widget.workflow.variables.isEmpty)
                          Text('No variables required for this workflow.', style: GoogleFonts.inter(color: AppTheme.textMuted))
                        else
                          Expanded(
                            child: ListView.separated(
                              itemCount: widget.workflow.variables.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final variable = widget.workflow.variables[index];
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(variable.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                                    if (variable.description.isNotEmpty)
                                      Text(variable.description, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                                    const SizedBox(height: 8),
                                    if (variable.type == 'select' && variable.options != null)
                                      DropdownButtonFormField<String>(
                                        value: _controllers[variable.name]?.text.isNotEmpty == true ? _controllers[variable.name]?.text : null,
                                        items: variable.options!.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                                        onChanged: (v) => _controllers[variable.name]?.text = v!,
                                        decoration: const InputDecoration(filled: true),
                                      )
                                    else
                                      TextFormField(
                                        controller: _controllers[variable.name],
                                        decoration: const InputDecoration(filled: true),
                                        style: GoogleFonts.inter(color: AppTheme.textPrimary),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: AppButton(
                            label: _isExecuting ? 'Running...' : 'Execute Workflow',
                            icon: _isExecuting ? null : Icons.play_arrow,
                            onPressed: _isExecuting ? null : _executeWorkflow,
                            type: AppButtonType.primary,
                            isLoading: _isExecuting,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Right: Terminal
                Expanded(
                  flex: 1,
                  child: Container(
                    color: const Color(0xFF121212),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Execution Log', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold)),
                            _buildStatusBadge(),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: TerminalOutput(
                            output: _terminalOutput,
                            isRunning: _isExecuting,
                            height: double.infinity,
                            onClear: () => setState(() => _terminalOutput = ''),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    switch (_status) {
      case 'Running...':
        color = AppTheme.info;
        break;
      case 'Success':
        color = AppTheme.success;
        break;
      case 'Failed':
      case 'Error':
        color = AppTheme.error;
        break;
      default:
        color = AppTheme.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        _status,
        style: GoogleFonts.inter(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
