import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/terminal_output.dart';
import '../../../../widgets/universal_filter_widget.dart';

class KubernetesFacilitatorScreen extends StatefulWidget {
  final String searchQuery;
  final String viewType;
  final String selectedCategory;

  const KubernetesFacilitatorScreen({
    super.key,
    required this.searchQuery,
    required this.viewType,
    required this.selectedCategory,
  });

  @override
  State<KubernetesFacilitatorScreen> createState() => _KubernetesFacilitatorScreenState();
}

class _KubernetesFacilitatorScreenState extends State<KubernetesFacilitatorScreen> {
  String _selectedGroup = 'Workloads';
  String? _selectedResource;
  String? _selectedAction;
  
  final Map<String, TextEditingController> _controllers = {};
  final TextEditingController _commandController = TextEditingController();
  final TextEditingController _namespaceController = TextEditingController(text: 'default');
  
  String _generatedCommand = '';
  String _terminalOutput = '';
  String _filterCommand = ''; // For UniversalFilterWidget

  bool _isExecuting = false;
  bool _isTerminalExpanded = false;

  // Icons Configuration
  final Map<String, IconData> _resourceIcons = {
    'Pod': Icons.adjust,
    'Deployment': Icons.cached,
    'StatefulSet': Icons.layers,
    'Job': Icons.work,
    'CronJob': Icons.schedule,
    'Service': Icons.share,
    'Ingress': Icons.input,
    'NetworkPolicy': Icons.security,
    'ConfigMap': Icons.settings,
    'Secret': Icons.lock,
    'Node': Icons.computer,
    'Namespace': Icons.view_quilt,
  };

  final Map<String, List<String>> _groupResources = {
    'Workloads': ['Pod', 'Deployment', 'StatefulSet', 'Job', 'CronJob'],
    'Network': ['Service', 'Ingress', 'NetworkPolicy', 'Endpoint'],
    'Storage': ['PersistentVolume', 'PersistentVolumeClaim', 'StorageClass'],
    'Config': ['ConfigMap', 'Secret', 'ServiceAccount'],
    'Access': ['Role', 'ClusterRole', 'RoleBinding'],
    'Cluster': ['Node', 'Namespace', 'Event'],
  };

  final Map<String, List<Map<String, dynamic>>> _resourceActions = {
    'Pod': [
      {'label': 'Get Pods', 'command': 'kubectl get pods -n {Namespace}'},
      {'label': 'Describe Pod', 'command': 'kubectl describe pod {Pod Name} -n {Namespace}'},
      {'label': 'Logs', 'command': 'kubectl logs {Pod Name} -n {Namespace} -f'},
      {'label': 'Exec', 'command': 'kubectl exec -it {Pod Name} -n {Namespace} -- /bin/sh'},
      {'label': 'Delete', 'command': 'kubectl delete pod {Pod Name} -n {Namespace}'},
    ],
    'Deployment': [
      {'label': 'Get Deployments', 'command': 'kubectl get deployments -n {Namespace}'},
      {'label': 'Scale', 'command': 'kubectl scale deployment {Deploy Name} --replicas={Replicas} -n {Namespace}'},
      {'label': 'Rollout Restart', 'command': 'kubectl rollout restart deployment/{Deploy Name} -n {Namespace}'},
      {'label': 'Edit', 'command': 'kubectl edit deployment {Deploy Name} -n {Namespace}'},
    ],
    'Service': [
      {'label': 'Get Services', 'command': 'kubectl get svc -n {Namespace}'},
      {'label': 'Describe Service', 'command': 'kubectl describe svc {Svc Name} -n {Namespace}'},
      {'label': 'Port Forward', 'command': 'kubectl port-forward svc/{Svc Name} {LocalPort}:{RemotePort} -n {Namespace}'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _updateSelection();
    _initializeControllers();
    _controllers['Namespace'] = _namespaceController; // Link namespace controller
  }

  @override
  void didUpdateWidget(KubernetesFacilitatorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      _updateSelection();
    }
  }

  void _updateSelection() {
    if (widget.selectedCategory == 'Todos') {
       setState(() {
         _selectedGroup = 'Workloads';
         _selectedResource = _groupResources['Workloads']?.first;
       });
    } else if (_groupResources.containsKey(widget.selectedCategory)) {
      setState(() {
        _selectedGroup = widget.selectedCategory;
        _selectedResource = _groupResources[widget.selectedCategory]?.first;
      });
    }
  }

  void _initializeControllers() {
    // Basic defaults
    _controllers['Replicas'] = TextEditingController(text: '1');
    _controllers['LocalPort'] = TextEditingController(text: '8080');
    _controllers['RemotePort'] = TextEditingController(text: '80');
  }

  void _generateCommand(Map<String, dynamic> action) {
    String command = action['command'];
    setState(() {
      _selectedAction = action['label'];
    });
    
    // Ensure we capture all needed variables from the command string
    final regex = RegExp(r'\{([a-zA-Z0-9_ ]+)\}');
    final matches = regex.allMatches(command);
    
    for (final match in matches) {
      final key = match.group(1)!;
      if (!_controllers.containsKey(key)) {
        _controllers[key] = TextEditingController();
      }
    }

    // Replace
    _controllers.forEach((key, controller) {
      command = command.replaceAll('{$key}', controller.text.isEmpty ? '<$key>' : controller.text);
    });
    
    setState(() {
      _generatedCommand = command;
      _commandController.text = command;
    });
  }

  Future<void> _executeCommand() async {
    if (_generatedCommand.isEmpty) return;
    setState(() {
      _isExecuting = true;
      _terminalOutput += '\n\$ ${_commandController.text}\n';
    });
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isExecuting = false;
      _terminalOutput += 'Executing command...\n[Mock Output] Successfully executed: $_selectedAction\n';
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resources = _groupResources[_selectedGroup] ?? [];
    
    final allActions = _resourceActions[_selectedResource] ?? [
        {'label': 'Get Info', 'command': 'kubectl get ${_selectedResource?.toLowerCase() ?? 'pods'} -n {Namespace}'}
    ];
    
    final actions = widget.searchQuery.isEmpty 
        ? allActions 
        : allActions.where((a) => a['label'].toString().toLowerCase().contains(widget.searchQuery.toLowerCase())).toList();

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_isTerminalExpanded)
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Refine Results / Global Filter
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.filter_list, size: 16, color: colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Text('Refine Scope', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: colorScheme.primary)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _namespaceController,
                                      decoration: const InputDecoration(
                                        labelText: 'Namespace',
                                        prefixIcon: Icon(Icons.dns, size: 16),
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (val) {
                                        // Update command if exists
                                        if (_selectedAction != null && _generatedCommand.isNotEmpty) {
                                           // Re-generate
                                           final currentAction = allActions.firstWhere((a) => a['label'] == _selectedAction, orElse: () => allActions.first);
                                           _generateCommand(currentAction);
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: resources.contains(_selectedResource) ? _selectedResource : null,
                                      decoration: const InputDecoration(labelText: 'Resource', border: OutlineInputBorder(), isDense: true),
                                      items: resources.map((r) => DropdownMenuItem(value: r, 
                                        child: Row(
                                          children: [
                                            Icon(_resourceIcons[r] ?? Icons.widgets, size: 16, color: colorScheme.onSurfaceVariant),
                                            const SizedBox(width: 8),
                                            Text(r),
                                          ],
                                        )
                                      )).toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() { 
                                           _selectedResource = val;
                                           _selectedAction = null;
                                           _generatedCommand = '';
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Actions Grid
                        Text('Actions', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: actions.map((action) {
                             final isSelected = _selectedAction == action['label'];
                             return InkWell(
                               onTap: () => _generateCommand(action),
                               borderRadius: BorderRadius.circular(8),
                               child: Container(
                                 width: 160,
                                 padding: const EdgeInsets.all(12),
                                 decoration: BoxDecoration(
                                   color: isSelected ? const Color(0xFF326CE5).withOpacity(0.15) : colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                   borderRadius: BorderRadius.circular(8),
                                   border: Border.all(color: isSelected ? const Color(0xFF326CE5) : colorScheme.outlineVariant.withOpacity(0.2)),
                                 ),
                                 child: Column(
                                   mainAxisAlignment: MainAxisAlignment.center,
                                   children: [
                                     Icon(Icons.terminal, color: isSelected ? const Color(0xFF326CE5) : colorScheme.onSurfaceVariant),
                                     const SizedBox(height: 8),
                                     Text(action['label'], textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                   ],
                                 ),
                               ),
                             );
                          }).toList(),
                        ),

                        const SizedBox(height: 32),

                        // Parameters
                        if (_selectedAction != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(12),
                              color: colorScheme.surface,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Parameters', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 16,
                                  children: _controllers.keys.where((k) => k != 'Namespace').map((v) {
                                    // Skip namespace as it is in the global scope now
                                     return SizedBox(
                                       width: 240,
                                       child: TextField(
                                         controller: _controllers[v],
                                         decoration: InputDecoration(
                                           labelText: v,
                                           border: const OutlineInputBorder(),
                                           isDense: true,
                                         ),
                                         onChanged: (_) {
                                            if (_selectedAction != null) {
                                              // Re-trigger generation to update command
                                               final action = actions.firstWhere((a) => a['label'] == _selectedAction);
                                               _generateCommand(action);
                                            }
                                         },
                                       ),
                                     );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          
                        if (_selectedAction != null)
                          Container(
                            margin: const EdgeInsets.only(top: 24),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: UniversalFilterWidget(
                              onFilterChanged: (cmd) => setState(() => _filterCommand = cmd),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              
              if (!_isTerminalExpanded) VerticalDivider(width: 1, color: colorScheme.outlineVariant.withOpacity(0.3)),

              // Terminal
              Expanded(
                flex: _isTerminalExpanded ? 1 : 4,
                child: Container(
                  color: const Color(0xFF0F111A),
                  child: Column(
                    children: [
                       Container(
                         height: 40,
                         padding: const EdgeInsets.symmetric(horizontal: 12),
                         color: const Color(0xFF1A1D26),
                         child: Row(
                           children: [
                             const Text('Terminal', style: TextStyle(color: Colors.grey, fontSize: 12)),
                             const Spacer(),
                             IconButton(
                               icon: Icon(_isTerminalExpanded ? Icons.close_fullscreen : Icons.open_in_full, size: 16, color: Colors.grey),
                               onPressed: () => setState(() => _isTerminalExpanded = !_isTerminalExpanded),
                             ),
                           ],
                         ),
                       ),
                       Padding(
                         padding: const EdgeInsets.all(8.0),
                         child: Row(
                           children: [
                              Expanded(
                                child: TextField(
                                  controller: _commandController,
                                  style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                                  decoration: const InputDecoration(border: InputBorder.none, hintText: '\$', hintStyle: TextStyle(color: Colors.grey)),
                                  onChanged: (val) => setState(() => _generatedCommand = val),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.play_arrow, color:  Color(0xFF326CE5)),
                                onPressed: _executeCommand,
                              ),
                           ],
                         ),
                       ),
                       Expanded(
                         child: TerminalOutput(
                           output: _terminalOutput,
                           isRunning: _isExecuting,
                           height: double.infinity,
                           filterCommand: _filterCommand,
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
    );
  }
}
