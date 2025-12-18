import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/terminal_output.dart';

// Step Condition Model
class StepCondition {
  String type;
  String value;
  String action;
  String? targetStepId;

  StepCondition({required this.type, required this.value, required this.action, this.targetStepId});
}

// Global Variable Model
class GlobalVariable {
  String name;
  String value;
  String description;

  GlobalVariable({required this.name, required this.value, this.description = ''});
}

// Workflow Step Model
class DiagnosticStep {
  String id;
  String title;
  String type;
  String command;
  String? workflowId;
  Map<String, String> variables;
  List<StepCondition> conditions;
  String? expectedOutput;
  IconData icon;
  bool isEditable;

  DiagnosticStep({
    required this.id,
    required this.title,
    this.type = 'command',
    required this.command,
    this.workflowId,
    Map<String, String>? variables,
    List<StepCondition>? conditions,
    this.expectedOutput,
    this.icon = Icons.check_circle_outline,
    this.isEditable = true,
  }) : variables = variables ?? {},
       conditions = conditions ?? [];

  List<String> getDetectedVariables() {
    final regex = RegExp(r'\{([A-Z_][A-Z0-9_]*)\}');
    final matches = regex.allMatches(command);
    return matches.map((m) => m.group(1)!).toSet().toList();
  }
}

// Workflow Model
class DiagnosticWorkflow {
  String id;
  String name;
  String description;
  List<DiagnosticStep> steps;
  Map<String, String> templateVariables;
  List<String> categories;
  IconData icon;
  Color color;

  DiagnosticWorkflow({
    required this.id,
    required this.name,
    required this.description,
    required this.steps,
    Map<String, String>? templateVariables,
    this.categories = const [],
    this.icon = Icons.account_tree,
    this.color = Colors.blue,
  }) : templateVariables = templateVariables ?? {};
}

class KubernetesTroubleshooterScreen extends StatefulWidget {
  final String searchQuery;
  final String viewType;
  final String selectedCategory;

  const KubernetesTroubleshooterScreen({
    super.key,
    required this.searchQuery,
    required this.viewType,
    required this.selectedCategory,
  });

  @override
  State<KubernetesTroubleshooterScreen> createState() => _KubernetesTroubleshooterScreenState();
}

class _KubernetesTroubleshooterScreenState extends State<KubernetesTroubleshooterScreen> {
  String _viewMode = 'library'; // 'library', 'builder', 'running'
  
  DiagnosticWorkflow? _currentWorkflow;
  int _currentStepIndex = -1;
  bool _isRunning = false;
  String _terminalOutput = '';
  
  final List<DiagnosticStep> _builderSteps = [];
  final TextEditingController _workflowNameController = TextEditingController();
  final TextEditingController _workflowDescController = TextEditingController();
  final TextEditingController _workflowCategoriesController = TextEditingController();
  IconData _workflowIcon = Icons.build;
  
  final List<GlobalVariable> _globalVariables = [
    GlobalVariable(name: 'NAMESPACE', value: 'default', description: 'Namespace padrão'),
    GlobalVariable(name: 'KUBECONFIG', value: '~/.kube/config', description: 'Caminho Kubeconfig'),
  ];

  final List<DiagnosticWorkflow> _templates = [
    DiagnosticWorkflow(
      id: 'pod_crash',
      name: 'Pod Crash Diagnosis',
      description: 'Check Pod status, logs, and events for crash reasons',
      icon: Icons.adjust,
      color: Colors.red,
      categories: ['Workloads', 'Troubleshooting'],
      steps: [
        DiagnosticStep(
          id: 'step1', 
          title: 'Check Pod Status', 
          command: 'kubectl get pod {POD_NAME} -n {NAMESPACE} -o jsonpath="{.status.phase}"', 
          icon: Icons.info
        ),
        DiagnosticStep(
          id: 'step2', 
          title: 'Get Last Events', 
          command: 'kubectl get events -n {NAMESPACE} --field-selector involvedObject.name={POD_NAME} --sort-by=.lastTimestamp', 
          icon: Icons.notifications
        ),
        DiagnosticStep(
          id: 'step3', 
          title: 'Fetch Logs (Previous)', 
          command: 'kubectl logs {POD_NAME} -n {NAMESPACE} --previous --tail=50', 
          icon: Icons.article
        ),
      ],
    ),
    DiagnosticWorkflow(
      id: 'svc_connectivity',
      name: 'Service Connectivity Check',
      description: 'Validate Service Endpoints and DNS',
      icon: Icons.share,
      color: Colors.blue,
      categories: ['Network', 'Troubleshooting'],
      steps: [
        DiagnosticStep(
          id: 'step1', 
          title: 'Get Service Details', 
          command: 'kubectl describe svc {SVC_NAME} -n {NAMESPACE}', 
          icon: Icons.info
        ),
         DiagnosticStep(
          id: 'step2', 
          title: 'Check Endpoints', 
          command: 'kubectl get endpoints {SVC_NAME} -n {NAMESPACE}', 
          icon: Icons.hub
        ),
      ],
    ),
    DiagnosticWorkflow(
      id: 'pvc_fix',
      name: 'PVC Pending Fix',
      description: 'Diagnose PersistentVolumeClaim binding issues',
      icon: Icons.storage,
      color: Colors.orange,
      categories: ['Storage', 'Troubleshooting'],
      steps: [
        DiagnosticStep(
          id: 'step1', 
          title: 'Describe PVC', 
          command: 'kubectl describe pvc {PVC_NAME} -n {NAMESPACE}', 
          icon: Icons.info
        ),
         DiagnosticStep(
          id: 'step2', 
          title: 'Check StorageClass', 
          command: 'kubectl get sc', 
          icon: Icons.storage
        ),
      ],
    ),
  ];

  final List<DiagnosticWorkflow> _customWorkflows = [];

  Future<void> _runWorkflow(DiagnosticWorkflow workflow) async {
    setState(() {
      _viewMode = 'running';
      _currentWorkflow = workflow;
      _currentStepIndex = 0;
      _isRunning = true;
      _terminalOutput = '🚀 Starting diagnostic: ${workflow.name}\n\n';
    });

    for (int i = 0; i < workflow.steps.length; i++) {
        final step = workflow.steps[i];
        
        // Simple variable substitution simulation
        String processedCommand = step.command;
        // In a real app, prompt for variables here. For now, use global default or mock.
        processedCommand = processedCommand.replaceAll('{NAMESPACE}', 'default');
        processedCommand = processedCommand.replaceAll('{POD_NAME}', 'my-app-pod');
        processedCommand = processedCommand.replaceAll('{SVC_NAME}', 'my-service');
        processedCommand = processedCommand.replaceAll('{PVC_NAME}', 'data-pvc');

        setState(() {
          _currentStepIndex = i;
          _terminalOutput += '📋 Step ${i + 1}/${workflow.steps.length}: ${step.title}\n';
          _terminalOutput += '\$ $processedCommand\n';
        });

        await Future.delayed(const Duration(seconds: 2));

        setState(() {
          _terminalOutput += '✅ [OK] Step completed successfully\n';
          _terminalOutput += '[Mock Output] Command "$processedCommand" executed.\n\n';
        });
    }

    setState(() {
      _isRunning = false;
      _terminalOutput += '🎉 Diagnostic completed! All checks passed.\n';
    });
  }

  void _startBuilder({DiagnosticWorkflow? template}) {
    setState(() {
      _viewMode = 'builder';
      _builderSteps.clear();
      
      if (template != null) {
        _workflowNameController.text = '${template.name} (Copy)';
        _workflowDescController.text = template.description;
        _workflowCategoriesController.text = template.categories.join(', ');
        _workflowIcon = template.icon;
        _builderSteps.addAll(template.steps.map((s) => DiagnosticStep(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: s.title,
          command: s.command,
          icon: s.icon,
        )));
      } else {
        _workflowNameController.clear();
        _workflowDescController.clear();
        _workflowCategoriesController.clear();
        _workflowIcon = Icons.build;
      }
    });
  }

  void _addStep() {
    setState(() {
      _builderSteps.add(DiagnosticStep(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'New Step',
        type: 'command',
        command: 'kubectl get all',
        icon: Icons.check_circle_outline,
        variables: {},
        conditions: [],
        isEditable: true,
      ));
    });
  }

  void _saveWorkflow() {
    if (_workflowNameController.text.isEmpty || _builderSteps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a name and at least one step')));
      return;
    }

    final workflow = DiagnosticWorkflow(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _workflowNameController.text,
      description: _workflowDescController.text,
      categories: _workflowCategoriesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      steps: List.from(_builderSteps),
      icon: _workflowIcon,
      color: Colors.purple,
    );

    setState(() {
      _customWorkflows.add(workflow);
      _viewMode = 'library';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Workflow "${workflow.name}" saved!')));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        if (_viewMode == 'library')
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Text('Workflow Library', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _startBuilder(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Workflow'),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF326CE5)),
                ),
              ],
            ),
          )
        else
          _buildLocalActionBar(colorScheme),
        
        Expanded(
          child: _viewMode == 'library' 
            ? _buildLibraryView(colorScheme)
            : _viewMode == 'builder' 
              ? _buildBuilderView(colorScheme) 
              : _buildRunningView(colorScheme),
        ),
      ],
    );
  }

  Widget _buildLocalActionBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          Text(_viewMode == 'builder' ? 'Workflow Builder' : 'Running Diagnostic', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () => setState(() => _viewMode = 'library'),
            icon: const Icon(Icons.close, size: 16),
            label: Text(_viewMode == 'running' ? 'Close' : 'Cancel'),
          ),
          if (_viewMode == 'builder') ...[
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _saveWorkflow,
              icon: const Icon(Icons.save, size: 16),
              label: const Text('Save'),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF326CE5)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLibraryView(ColorScheme colorScheme) {
    final allWorkflows = [..._templates, ..._customWorkflows];
     
    final filtered = allWorkflows.where((w) {
       final search = widget.searchQuery.toLowerCase();
       final matchName = w.name.toLowerCase().contains(search);
       final matchCat = widget.selectedCategory == 'Todos' || w.categories.contains(widget.selectedCategory);
       return matchName && matchCat;
    }).toList();

    final isGrid = widget.viewType == 'grid' || widget.viewType == 'dashboard';

    if (filtered.isEmpty) {
      return Center(child: Text('Nenhum workflow encontrado.', style: TextStyle(color: colorScheme.onSurfaceVariant)));
    }

    if (isGrid) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 350, childAspectRatio: 1.4, crossAxisSpacing: 16, mainAxisSpacing: 16),
        itemCount: filtered.length,
        itemBuilder: (_, i) => _buildWorkflowCard(filtered[i], colorScheme, isTemplate: _templates.contains(filtered[i])),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (_, i) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildWorkflowListTile(filtered[i], colorScheme, isTemplate: _templates.contains(filtered[i]))),
    );
  }

  Widget _buildWorkflowCard(DiagnosticWorkflow workflow, ColorScheme colorScheme, {bool isTemplate = false}) {
    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.3))),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _runWorkflow(workflow),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Row(
                 children: [
                   Container(
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: workflow.color.withOpacity(0.1),
                       borderRadius: BorderRadius.circular(12),
                       border: Border.all(color: workflow.color.withOpacity(0.3)),
                     ),
                     child: Icon(workflow.icon, color: workflow.color, size: 28),
                   ),
                   const Spacer(),
                   if (isTemplate)
                     IconButton(icon: const Icon(Icons.copy_all), onPressed: () => _startBuilder(template: workflow), tooltip: 'Clone Template'),
                 ],
               ),
               const SizedBox(height: 16),
               Text(workflow.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
               const SizedBox(height: 8),
               Expanded(child: Text(workflow.description, style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant), maxLines: 3, overflow: TextOverflow.ellipsis)),
               const SizedBox(height: 12),
               Text('${workflow.steps.length} steps', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkflowListTile(DiagnosticWorkflow workflow, ColorScheme colorScheme, {bool isTemplate = false}) {
    return Card(
      elevation: 0,
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.3))),
       child: ListTile(
         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
         leading: Container(
           padding: const EdgeInsets.all(10),
           decoration: BoxDecoration(color: workflow.color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
           child: Icon(workflow.icon, color: workflow.color),
         ),
         title: Text(workflow.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
         subtitle: Text(workflow.description, maxLines: 1, overflow: TextOverflow.ellipsis),
         trailing: Row(
           mainAxisSize: MainAxisSize.min,
           children: [
             Chip(label: Text('${workflow.steps.length} steps')),
             const SizedBox(width: 8),
             if (isTemplate) 
               IconButton(icon: const Icon(Icons.copy_all), onPressed: () => _startBuilder(template: workflow))
             else
               IconButton(icon: const Icon(Icons.play_arrow), onPressed: () => _runWorkflow(workflow)),
           ],
         ),
         onTap: () => _runWorkflow(workflow),
       ),
    );
  }

  Widget _buildBuilderView(ColorScheme colorScheme) {
    return Row(
      children: [
        // Left Panel: Settings
        Expanded(
          flex: 3,
          child: ListView(
            padding: const EdgeInsets.all(32),
            children: [
               Text('Workflow Info', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
               const SizedBox(height: 24),
               TextField(
                 controller: _workflowNameController,
                 decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
               ),
               const SizedBox(height: 16),
               TextField(
                 controller: _workflowDescController,
                 decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                 maxLines: 2,
               ),
               const SizedBox(height: 16),
               TextField(
                 controller: _workflowCategoriesController,
                 decoration: const InputDecoration(labelText: 'Categories (comma separated)', border: OutlineInputBorder()),
               ),
               const SizedBox(height: 32),
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text('Steps', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                   FilledButton.icon(onPressed: _addStep, icon: const Icon(Icons.add), label: const Text('Add Step')),
                 ],
               ),
               const SizedBox(height: 16),
               ..._builderSteps.asMap().entries.map((entry) {
                 final i = entry.key;
                 final step = entry.value;
                 return Card(
                   margin: const EdgeInsets.only(bottom: 12),
                   child: ExpansionTile(
                     leading: CircleAvatar(child: Text('${i+1}')),
                     title: TextFormField(
                       initialValue: step.title,
                       decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                       style: const TextStyle(fontWeight: FontWeight.bold),
                       onChanged: (v) => step.title = v,
                     ),
                     children: [
                       Padding(
                         padding: const EdgeInsets.all(16.0),
                         child: Column(
                           children: [
                             TextFormField(
                               initialValue: step.command,
                               decoration: const InputDecoration(labelText: 'Command', border: OutlineInputBorder()),
                               onChanged: (v) => step.command = v,
                             ),
                             const SizedBox(height: 8),
                             Align(alignment: Alignment.centerRight, child: TextButton.icon(icon: const Icon(Icons.delete, size: 16, color: Colors.red), label: const Text('Remove', style: TextStyle(color: Colors.red)), onPressed: () {
                               setState(() => _builderSteps.removeAt(i));
                             })),
                           ],
                         ),
                       ),
                     ],
                   ),
                 );
               }).toList(),
            ],
          ),
        ),
        VerticalDivider(width: 1, color: colorScheme.outlineVariant),
        // Right Panel: Preview (Placeholder)
        Expanded(
          flex: 2,
          child: Center(
            child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 Icon(Icons.preview, size: 64, color: colorScheme.onSurfaceVariant.withOpacity(0.2)),
                 const SizedBox(height: 16),
                 Text('Preview Mode', style: TextStyle(color: colorScheme.onSurfaceVariant)),
               ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRunningView(ColorScheme colorScheme) {
    return Column(
      children: [
        // Steps Progress
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _currentWorkflow!.steps.length,
            itemBuilder: (context, index) {
              final step = _currentWorkflow!.steps[index];
              final isActive = index == _currentStepIndex;
              final isCompleted = index < _currentStepIndex;
              final color = isCompleted ? Colors.green : (isActive ? Colors.blue : Colors.grey);
              
              return Container(
                margin: const EdgeInsets.only(right: 16, top: 16, bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  border: Border.all(color: color),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Row(
                  children: [
                    if (_isRunning && isActive) 
                      SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: color))
                    else
                      Icon(isCompleted ? Icons.check : Icons.circle_outlined, size: 16, color: color),
                    const SizedBox(width: 8),
                    Text(step.title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          ),
        ),
        
        Expanded(
          child: TerminalOutput(
            output: _terminalOutput,
            isRunning: _isRunning,
            height: double.infinity,
          ),
        ),
      ],
    );
  }
}
