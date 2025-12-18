import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/terminal_output.dart';

// Step Condition Model (for IF/ELSE/CASE logic)
class StepCondition {
  String type; // 'contains', 'equals', 'starts_with', 'ends_with', 'regex', 'exit_code'
  String value;
  String action; // 'continue', 'stop', 'jump_to', 'execute'
  String? targetStepId;

  StepCondition({
    required this.type,
    required this.value,
    required this.action,
    this.targetStepId,
  });
}

// Global Variable Model
class GlobalVariable {
  String name;
  String value;
  String description;

  GlobalVariable({
    required this.name,
    required this.value,
    this.description = '',
  });
}

// Workflow Step Model
class DiagnosticStep {
  String id;
  String title;
  String type; // 'command' or 'workflow'
  String command; // Editable command
  String? workflowId; // If type == 'workflow', reference to another workflow
  Map<String, String> variables; // Detected variables with values
  List<StepCondition> conditions; // Conditional logic
  String? expectedOutput;
  String? failureAction;
  IconData icon;
  bool isEditable; // Allow manual editing
  
  // Facilitator Metadata
  String? category;
  String? service;
  String? resource;
  String? action;
  
  DiagnosticStep({
    required this.id,
    required this.title,
    this.type = 'command',
    required this.command,
    this.workflowId,
    Map<String, String>? variables,
    List<StepCondition>? conditions,
    this.expectedOutput,
    this.failureAction,
    this.icon = Icons.check_circle_outline,
    this.isEditable = true,
    this.category,
    this.service,
    this.resource,
    this.action,
  }) : variables = variables ?? {},
       conditions = conditions ?? [];

  // Extract variables from command (pattern: {VAR_NAME})
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
  Map<String, String> templateVariables; // Variables defined at workflow level
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

class AWSTroubleshooterScreen extends StatefulWidget {
  final String searchQuery;
  final String viewType;
  final String selectedCategory;

  const AWSTroubleshooterScreen({
    super.key,
    required this.searchQuery,
    required this.viewType,
    required this.selectedCategory,
  });

  @override
  State<AWSTroubleshooterScreen> createState() => _AWSTroubleshooterScreenState();
}

class _AWSTroubleshooterScreenState extends State<AWSTroubleshooterScreen> {
  // Current view mode
  String _viewMode = 'library'; // 'library', 'builder', 'running'
  
  // Workflow being edited/run
  DiagnosticWorkflow? _currentWorkflow;
  int _currentStepIndex = -1;
  bool _isRunning = false;
  String _terminalOutput = '';
  
  // Builder state
  final List<DiagnosticStep> _builderSteps = [];
  final TextEditingController _workflowNameController = TextEditingController();
  final TextEditingController _workflowDescController = TextEditingController();
  final TextEditingController _workflowCategoriesController = TextEditingController(); // Comma separated
  IconData _workflowIcon = Icons.build;
  
  // Library Filters (Managed by Parent)
  // String _searchQuery = '';
  // String _selectedFilterCategory = 'All';
  // bool _isGridView = true;

  // Facilitator Data (Restored for UI compatibility)
  final Map<String, List<String>> _serviceCategories = {
    'Compute': ['EC2', 'Lambda', 'EKS', 'ECS', 'Lightsail'],
    'Storage': ['S3', 'EBS', 'EFS', 'Glacier'],
    'Database': ['RDS', 'DynamoDB', 'ElastiCache', 'Redshift'],
    'Network': ['VPC', 'Route53', 'CloudFront', 'API Gateway'],
    'Security': ['IAM', 'KMS', 'WAF', 'Secrets Manager'],
  };

  final Map<String, List<String>> _serviceResources = {
    'EC2': ['Instances', 'Security Groups', 'Volumes', 'Key Pairs'],
    'Lambda': ['Functions', 'Layers', 'Aliases'],
    'EKS': ['Clusters', 'Node Groups'],
    'ECS': ['Clusters', 'Services', 'Tasks'],
    'Lightsail': ['Instances', 'Databases'],
    'S3': ['Buckets', 'Objects', 'Policies'],
    'EBS': ['Volumes', 'Snapshots'],
    'EFS': ['File Systems'],
    'Glacier': ['Vaults'],
    'RDS': ['Instances', 'Snapshots', 'Parameter Groups'],
    'DynamoDB': ['Tables', 'Items'],
    'ElastiCache': ['Clusters'],
    'Redshift': ['Clusters'],
    'VPC': ['VPCs', 'Subnets', 'Route Tables', 'Internet Gateways'],
    'Route53': ['Hosted Zones', 'Records'],
    'CloudFront': ['Distributions'],
    'API Gateway': ['APIs', 'Resources', 'Stages'],
    'IAM': ['Users', 'Roles', 'Policies', 'Groups'],
    'KMS': ['Keys', 'Aliases'],
    'WAF': ['Web ACLs'],
    'Secrets Manager': ['Secrets'],
  };

  final Map<String, List<Map<String, dynamic>>> _resourceActions = {
    'Instances': [
      {'label': 'Launch Instance', 'command': 'aws ec2 run-instances --image-id {AMI_ID} --instance-type {INSTANCE_TYPE} --key-name {KEY_PAIR}'},
      {'label': 'Start Instance', 'command': 'aws ec2 start-instances --instance-ids {INSTANCE_ID}'},
      {'label': 'Stop Instance', 'command': 'aws ec2 stop-instances --instance-ids {INSTANCE_ID}'},
      {'label': 'Reboot Instance', 'command': 'aws ec2 reboot-instances --instance-ids {INSTANCE_ID}'},
      {'label': 'Describe Instances', 'command': 'aws ec2 describe-instances --instance-ids {INSTANCE_ID}'},
    ],
    'Security Groups': [
      {'label': 'Create', 'icon': Icons.security, 'command': 'aws ec2 create-security-group --group-name {SG Name} --description "{Description}"'},
      {'label': 'Authorize Inbound', 'command': 'aws ec2 authorize-security-group-ingress --group-id {SG_ID} --protocol tcp --port {PORT} --cidr {CIDR}'},
      {'label': 'Describe SGs', 'command': 'aws ec2 describe-security-groups --group-ids {SG_ID}'},
    ],
    'Buckets': [
      {'label': 'Create Bucket', 'command': 'aws s3 mb s3://{BUCKET_NAME} --region {REGION}'},
      {'label': 'List Buckets', 'command': 'aws s3 ls'},
      {'label': 'Delete Bucket', 'command': 'aws s3 rb s3://{BUCKET_NAME} --force'},
      {'label': 'Get Bucket Policy', 'command': 'aws s3api get-bucket-policy --bucket {BUCKET_NAME}'},
    ],
    'Functions': [
      {'label': 'Create Function', 'command': 'aws lambda create-function --function-name {FUNCTION_NAME} --runtime {RUNTIME} --role {ROLE_ARN} --handler {HANDLER} --zip-file fileb://function.zip'},
      {'label': 'Invoke Function', 'command': 'aws lambda invoke --function-name {FUNCTION_NAME} response.json'},
      {'label': 'Get Function Config', 'command': 'aws lambda get-function-configuration --function-name {FUNCTION_NAME}'},
    ],
    // Add generic fallbacks for others to avoid null errors
    'Clusters': [{'label': 'List Clusters', 'command': 'aws eks list-clusters'}],
    'Tables': [{'label': 'List Tables', 'command': 'aws dynamodb list-tables'}],
    'VPCs': [{'label': 'Describe VPCs', 'command': 'aws ec2 describe-vpcs'}],
    'Users': [{'label': 'List Users', 'command': 'aws iam list-users'}],
    'Distributions': [{'label': 'List Distributions', 'command': 'aws cloudfront list-distributions'}],
  };
  final List<GlobalVariable> _globalVariables = [
    GlobalVariable(name: 'AWS_REGION', value: 'us-east-1', description: 'Região AWS padrão'),
    GlobalVariable(name: 'AWS_PROFILE', value: 'default', description: 'Profile AWS'),
  ];
  
  // Template workflows
  final List<DiagnosticWorkflow> _templates = [
    DiagnosticWorkflow(
      id: 'ec2_connectivity',
      name: 'EC2 Connectivity Check',
      description: 'Diagnose SSH/HTTP connection issues to EC2 instances',
      icon: Icons.computer,
      color: Colors.orange,
      categories: ['Compute', 'Network'],
      steps: [
        DiagnosticStep(
          id: 'step1',
          title: 'Check Security Group Rules',
          command: 'aws ec2 describe-security-groups --group-ids {SG_ID}',
          icon: Icons.security,
        ),
        DiagnosticStep(
          id: 'step2',
          title: 'Verify Instance Status',
          command: 'aws ec2 describe-instance-status --instance-ids {INSTANCE_ID}',
          icon: Icons.health_and_safety,
        ),
        DiagnosticStep(
          id: 'step3',
          title: 'Check Network ACLs',
          command: 'aws ec2 describe-network-acls --filters "Name=association.subnet-id,Values={SUBNET_ID}"',
          icon: Icons.network_check,
        ),
      ],
    ),
    DiagnosticWorkflow(
      id: 's3_access',
      name: 'S3 Access Troubleshooter',
      description: 'Resolve 403 Forbidden and permission errors',
      icon: Icons.storage,
      color: Colors.green,
      categories: ['Storage', 'Security'],
      steps: [
        DiagnosticStep(
          id: 'step1',
          title: 'Check Bucket Policy',
          command: 'aws s3api get-bucket-policy --bucket {BUCKET_NAME}',
          icon: Icons.policy,
        ),
        DiagnosticStep(
          id: 'step2',
          title: 'Verify IAM Permissions',
          command: 'aws iam get-user-policy --user-name {USER_NAME} --policy-name {POLICY_NAME}',
          icon: Icons.person,
        ),
        DiagnosticStep(
          id: 'step3',
          title: 'Check Public Access Block',
          command: 'aws s3api get-public-access-block --bucket {BUCKET_NAME}',
          icon: Icons.block,
        ),
      ],
    ),
    DiagnosticWorkflow(
      id: 'lambda_performance',
      name: 'Lambda Performance Analysis',
      description: 'Diagnose timeouts, cold starts, and memory issues',
      icon: Icons.flash_on,
      color: Colors.amber,
      categories: ['Compute', 'Serverless'],
      steps: [
        DiagnosticStep(
          id: 'step1',
          title: 'Get Function Configuration',
          command: 'aws lambda get-function-configuration --function-name {FUNCTION_NAME}',
          icon: Icons.settings,
        ),
        DiagnosticStep(
          id: 'step2',
          title: 'Check CloudWatch Metrics',
          command: 'aws cloudwatch get-metric-statistics --namespace AWS/Lambda --metric-name Duration --dimensions Name=FunctionName,Value={FUNCTION_NAME} --start-time {START_TIME} --end-time {END_TIME} --period 3600 --statistics Average,Maximum',
          icon: Icons.analytics,
        ),
      ],
    ),
  ];
  
  // Custom workflows (saved by user)
  final List<DiagnosticWorkflow> _customWorkflows = [];

  @override
  void initState() {
    super.initState();
  }

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
      setState(() {
        _currentStepIndex = i;
        _terminalOutput += '📋 Step ${i + 1}/${workflow.steps.length}: ${step.title}\n';
        _terminalOutput += '\$ ${step.command}\n';
      });

      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _terminalOutput += '✅ [OK] Step completed successfully\n';
        _terminalOutput += '[Mock Output] Command executed without errors\n\n';
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
        command: 'aws ',
        icon: Icons.check_circle_outline,
        variables: {},
        conditions: [],
        isEditable: true,
      ));
    });
  }

  void _saveWorkflow() {
    if (_workflowNameController.text.isEmpty || _builderSteps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a name and at least one step')),
      );
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Workflow "${workflow.name}" saved!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Top Navigation Bar REMOVED (Handled by Global Header)
        // _buildTopBar(colorScheme),
        
        // Action Bar for Builder/Running modes or "New Workflow"
        if (_viewMode == 'library')
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Text(
                  'Workflow Library',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _startBuilder(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Workflow'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9900),
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          )
        else
          _buildLocalActionBar(colorScheme),
        
        // Main Content
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
          if (_viewMode == 'builder') ...[
            Text('Workflow Builder', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () => setState(() => _viewMode = 'library'),
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _saveWorkflow,
              icon: const Icon(Icons.save, size: 16),
              label: const Text('Save'),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF9900), foregroundColor: Colors.black),
            ),
          ] else if (_viewMode == 'running') ...[
             Text('Running Diagnostic', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
             const Spacer(),
             OutlinedButton.icon(
              onPressed: () => setState(() => _viewMode = 'library'),
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Close'),
            ),
          ]
        ],
      ),
    );
  }

  void _showGlobalVariablesDialog() {
    // Implementation kept simple for brevity
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Global Variables'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: ListView.builder(
            itemCount: _globalVariables.length,
            itemBuilder: (context, index) {
              final v = _globalVariables[index];
              return ListTile(
                title: Text(v.name),
                subtitle: Text(v.value),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildLibraryView(ColorScheme colorScheme) {
    final allWorkflows = [..._templates, ..._customWorkflows];
    final allCategories = {'All', ...allWorkflows.expand((w) => w.categories).toSet()};
    
    final filteredWorkflows = allWorkflows.where((w) {
      final matchesSearch = w.name.toLowerCase().contains(widget.searchQuery.toLowerCase());
      // Filter by Global Category - Accept both 'All' and 'Todos' as "show all"
      final matchesCategory = widget.selectedCategory == 'All' || 
                              widget.selectedCategory == 'Todos' || 
                              w.categories.contains(widget.selectedCategory);
      return matchesSearch && matchesCategory;
    }).toList();

    // Determine view mode from parent
    final isGridView = widget.viewType == 'grid' || widget.viewType == 'dashboard';

    return Column(
      children: [
        // Local Filters Removed (Using Global)
        
        // Content
        Expanded(
          child: filteredWorkflows.isEmpty
              ? Center(child: Text('Nenhum workflow encontrado', style: GoogleFonts.inter(color: colorScheme.onSurfaceVariant)))
              : isGridView
                  ? GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 350,
                        childAspectRatio: 1.4,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filteredWorkflows.length,
                      itemBuilder: (context, index) {
                        final workflow = filteredWorkflows[index];
                        // Check if it's a template based on ID or list membership
                        final isTemplate = _templates.contains(workflow);
                        return _buildWorkflowCard(workflow, colorScheme, isTemplate: isTemplate);
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredWorkflows.length,
                      itemBuilder: (context, index) {
                        final workflow = filteredWorkflows[index];
                        final isTemplate = _templates.contains(workflow);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildWorkflowListTile(workflow, colorScheme, isTemplate: isTemplate),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildWorkflowCard(DiagnosticWorkflow workflow, ColorScheme colorScheme, {bool isTemplate = false}) {
    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _runWorkflow(workflow),
        hoverColor: colorScheme.primary.withOpacity(0.05),
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
                      gradient: LinearGradient(
                        colors: [
                          workflow.color.withOpacity(0.2),
                          workflow.color.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: workflow.color.withOpacity(0.3)),
                    ),
                    child: Icon(workflow.icon, color: workflow.color, size: 28),
                  ),
                  const Spacer(),
                  if (isTemplate)
                    Tooltip(
                      message: 'Usar como modelo',
                      child: IconButton(
                        icon: const Icon(Icons.copy_all, size: 20),
                        onPressed: () => _startBuilder(template: workflow),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        style: IconButton.styleFrom(
                          foregroundColor: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                workflow.name,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  workflow.description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.layers_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      '${workflow.steps.length} passos',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkflowListTile(DiagnosticWorkflow workflow, ColorScheme colorScheme, {bool isTemplate = false}) {
    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: workflow.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: workflow.color.withOpacity(0.3)),
          ),
          child: Icon(workflow.icon, color: workflow.color),
        ),
        title: Text(
          workflow.name,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          workflow.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.layers_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${workflow.steps.length}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isTemplate)
              Tooltip(
                message: 'Usar como modelo',
                child: IconButton(
                  icon: const Icon(Icons.copy_all, size: 20),
                  onPressed: () => _startBuilder(template: workflow),
                  style: IconButton.styleFrom(
                    foregroundColor: colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.play_arrow_rounded),
                onPressed: () => _runWorkflow(workflow),
                style: IconButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  backgroundColor: colorScheme.primaryContainer.withOpacity(0.2),
                ),
              ),
          ],
        ),
        onTap: () => _runWorkflow(workflow),
      ),
    );
  }

  Widget _buildBuilderView(ColorScheme colorScheme) {
    return Row(
      children: [
        // Left: Builder Form
        Expanded(
          flex: 3,
          child: Container(
            color: colorScheme.surface,
            child: ListView(
              padding: const EdgeInsets.all(32),
              children: [
                // Workflow Info Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informações do Workflow',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _workflowNameController,
                        decoration: InputDecoration(
                          labelText: 'Nome do Workflow',
                          hintText: 'Ex: Verificação de Saúde EC2',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          prefixIcon: const Icon(Icons.title, size: 20),
                        ),
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _workflowDescController,
                        decoration: InputDecoration(
                          labelText: 'Descrição',
                          hintText: 'O que este workflow diagnostica?',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          prefixIcon: const Icon(Icons.description, size: 20),
                        ),
                        style: GoogleFonts.inter(fontSize: 14),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      
                      // Categories and Icon
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _workflowCategoriesController,
                              decoration: InputDecoration(
                                labelText: 'Categorias',
                                hintText: 'Compute, Network, Troubleshooting',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                prefixIcon: const Icon(Icons.category, size: 20),
                              ),
                              style: GoogleFonts.inter(fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: colorScheme.outlineVariant),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<IconData>(
                                value: _workflowIcon,
                                items: [
                                  Icons.build, Icons.computer, Icons.storage, Icons.cloud, 
                                  Icons.security, Icons.network_check, Icons.bug_report,
                                  Icons.health_and_safety, Icons.speed, Icons.analytics
                                ].map((icon) => DropdownMenuItem(
                                  value: icon,
                                  child: Icon(icon, color: colorScheme.primary),
                                )).toList(),
                                onChanged: (v) => setState(() => _workflowIcon = v!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Steps Section Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.list_alt, color: colorScheme.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Passos do Diagnóstico',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _addStep,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Adicionar Passo'),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primaryContainer,
                        foregroundColor: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Steps List
                if (_builderSteps.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(48),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withOpacity(0.3),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(Icons.add_task, size: 48, color: colorScheme.primary.withOpacity(0.5)),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Comece adicionando passos',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Clique no botão "Adicionar Passo" para construir seu workflow.',
                            style: GoogleFonts.inter(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._builderSteps.asMap().entries.map((entry) {
                    final index = entry.key;
                    final step = entry.value;
                    return _buildStepEditor(step, index, colorScheme);
                  }).toList(),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        
        // Right: Preview
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              border: Border(left: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.terminal, color: Colors.white70, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Preview da Execução',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F0F0F),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _builderSteps.length,
                      itemBuilder: (context, index) {
                        final step = _builderSteps[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.blue),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: GoogleFonts.jetBrainsMono(
                                          color: Colors.blue,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (index < _builderSteps.length - 1)
                                    Container(
                                      width: 2,
                                      height: 40,
                                      color: Colors.white.withOpacity(0.1),
                                      margin: const EdgeInsets.only(top: 8),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      step.title.isEmpty ? 'Sem título' : step.title,
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '\$ ${step.command}',
                                        style: GoogleFonts.jetBrainsMono(
                                          color: const Color(0xFF4CAF50),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepEditor(DiagnosticStep step, int index, ColorScheme colorScheme) {
    final commandController = TextEditingController(text: step.command);
    commandController.addListener(() {
      step.command = commandController.text;
      // Update variables based on command
      final detectedVars = step.getDetectedVariables();
      // Remove variables that are no longer in command
      step.variables.removeWhere((key, _) => !detectedVars.contains(key));
      // Add new variables
      for (final v in detectedVars) {
        if (!step.variables.containsKey(v)) {
          step.variables[v] = '';
        }
      }
    });

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.3))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Passo ${index + 1}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: step.title)
                      ..addListener(() {
                        step.title = step.title; // Controller needs to update step
                      }),
                    onChanged: (value) => step.title = value,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Título do Passo (Ex: Verificar Instância)',
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () {
                    setState(() {
                      _builderSteps.removeAt(index);
                    });
                  },
                  tooltip: 'Remover Passo',
                  color: colorScheme.error,
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.errorContainer.withOpacity(0.2),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type Selector
                Row(
                  children: [
                    Text(
                      'Tipo de Ação:',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 16),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'command',
                          label: Text('Comando AWS'),
                          icon: Icon(Icons.terminal, size: 16),
                        ),
                        ButtonSegment(
                          value: 'workflow',
                          label: Text('Sub-Workflow'),
                          icon: Icon(Icons.account_tree, size: 16),
                        ),
                      ],
                      selected: {step.type == 'facilitator' ? 'command' : step.type},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          step.type = newSelection.first;
                          step.category = null;
                          step.service = null;
                          step.resource = null;
                          step.action = null;
                        });
                      },
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: MaterialStateProperty.all(GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Facilitator Category Selector (Optional)
                if (step.type == 'command') ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_fix_high, size: 16, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Assistente de Comandos (Facilitador)',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: step.category,
                          decoration: InputDecoration(
                            labelText: 'Selecione uma categoria para gerar o comando',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            filled: true,
                            fillColor: colorScheme.surface,
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Nenhuma (Digitar comando manualmente)')),
                            ..._serviceCategories.keys.map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c),
                            )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              if (value == null) {
                                step.category = null;
                                step.type = 'command';
                              } else {
                                step.type = 'facilitator';
                                step.category = value;
                                step.service = null;
                                step.resource = null;
                                step.action = null;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Content based on Type
                if (step.type == 'command') ...[
                  TextField(
                    controller: commandController,
                    decoration: InputDecoration(
                      labelText: 'Comando AWS CLI',
                      hintText: 'aws ec2 describe-instances ...',
                      helperText: 'Use {VAR_NAME} para variáveis dinâmicas',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      prefixIcon: const Icon(Icons.terminal, size: 20, color: Colors.white70),
                      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                      hintStyle: TextStyle(color: Colors.white30),
                      helperStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    style: GoogleFonts.jetBrainsMono(fontSize: 13, color: Colors.white),
                    maxLines: 3,
                  ),
                ] else if (step.type == 'workflow') ...[
                  DropdownButtonFormField<String>(
                    value: step.workflowId,
                    decoration: InputDecoration(
                      labelText: 'Selecione o Workflow',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.account_tree, size: 20),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    ),
                    items: [..._templates, ..._customWorkflows].map((t) => DropdownMenuItem(
                      value: t.id,
                      child: Text(t.name),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        step.workflowId = value;
                        final selectedWorkflow = [..._templates, ..._customWorkflows].firstWhere((t) => t.id == value);
                        step.title = selectedWorkflow.name;
                      });
                    },
                  ),
                ] else if (step.type == 'facilitator' && step.category != null) ...[
                  // Facilitator UI
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: step.service,
                          decoration: InputDecoration(
                            labelText: 'Serviço',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: colorScheme.surface,
                          ),
                          items: (_serviceCategories[step.category!] ?? []).map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) => setState(() {
                            step.service = v;
                            step.resource = null;
                            step.action = null;
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: step.resource,
                          decoration: InputDecoration(
                            labelText: 'Recurso',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: colorScheme.surface,
                          ),
                          items: (_serviceResources[step.service] ?? []).map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                          onChanged: (v) => setState(() {
                            step.resource = v;
                            step.action = null;
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (step.resource != null)
                    DropdownButtonFormField<String>(
                      value: step.action,
                      decoration: InputDecoration(
                        labelText: 'Ação',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: colorScheme.surface,
                      ),
                      items: (_resourceActions[step.resource] ?? []).map((a) => DropdownMenuItem<String>(
                        value: a['label'], 
                        child: Text(a['label']),
                      )).toList(),
                      onChanged: (v) {
                        setState(() {
                          step.action = v;
                          // Auto-generate command
                          final actionData = _resourceActions[step.resource]!.firstWhere((a) => a['label'] == v);
                          step.command = actionData['command'];
                          step.title = '$v ${step.resource}';
                          commandController.text = step.command; // Update controller
                        });
                      },
                    ),
                  
                  // Show variables for the selected action
                  if (step.command.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: commandController,
                      decoration: InputDecoration(
                        labelText: 'Comando Gerado',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: const Color(0xFF1E1E1E),
                        prefixIcon: const Icon(Icons.terminal, size: 20, color: Colors.white70),
                      ),
                      style: GoogleFonts.jetBrainsMono(fontSize: 13, color: Colors.white),
                      maxLines: 2,
                    ),
                  ],
                ],
                
                const SizedBox(height: 24),
                
                // Variables Preview
                if (step.getDetectedVariables().isNotEmpty) ...[
                  Text('Variáveis Detectadas:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: step.getDetectedVariables().map((v) {
                      final isGlobal = _globalVariables.any((g) => g.name == v);
                      return Chip(
                        label: Text(v),
                        backgroundColor: isGlobal ? colorScheme.secondaryContainer : colorScheme.surfaceContainerHighest,
                        labelStyle: TextStyle(
                          fontSize: 11,
                          color: isGlobal ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                        avatar: Icon(
                          isGlobal ? Icons.public : Icons.tag,
                          size: 14,
                          color: isGlobal ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant,
                        ),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Conditions
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ExpansionTile(
                    title: Text('Condições (Lógica IF/ELSE)', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                    leading: Icon(Icons.alt_route, size: 20, color: colorScheme.tertiary),
                    shape: const RoundedRectangleBorder(),
                    childrenPadding: const EdgeInsets.all(16),
                    children: [
                      if (step.conditions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            'Nenhuma condição definida. O workflow continuará se o comando for bem-sucedido.',
                            style: GoogleFonts.inter(color: colorScheme.onSurfaceVariant, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        ...step.conditions.map((c) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            dense: true,
                            title: Text('SE output ${c.type} "${c.value}"', style: GoogleFonts.jetBrainsMono(fontSize: 12)),
                            subtitle: Text('ENTÃO ${c.action}', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, size: 18),
                              onPressed: () {
                                setState(() {
                                  step.conditions.remove(c);
                                });
                              },
                            ),
                          ),
                        )),
                      FilledButton.tonal(
                        onPressed: () => _showConditionDialog(step),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.add, size: 18),
                            SizedBox(width: 8),
                            Text('Adicionar Condição'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Advanced Options
                _buildAdvancedOptions(step, colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCommandWizard(DiagnosticStep step, ColorScheme colorScheme) {
    // Same data structures as Facilitator
    final Map<String, List<String>> serviceCategories = {
      'Compute': ['EC2', 'Lambda', 'EKS', 'ECS'],
      'Storage': ['S3', 'EBS', 'EFS'],
      'Database': ['RDS', 'DynamoDB'],
      'Network': ['VPC', 'Route53', 'CloudFront'],
      'Security': ['IAM', 'KMS', 'WAF'],
    };

    final Map<String, List<String>> serviceResources = {
      'EC2': ['Instances', 'Security Groups', 'Volumes', 'AMIs'],
      'Lambda': ['Functions', 'Layers', 'Aliases'],
      'S3': ['Buckets', 'Objects', 'Policies'],
      'RDS': ['Instances', 'Snapshots', 'Parameter Groups'],
      'VPC': ['VPCs', 'Subnets', 'Route Tables', 'Security Groups'],
      'IAM': ['Users', 'Roles', 'Policies', 'Groups'],
    };

    final Map<String, List<Map<String, String>>> resourceActions = {
      'Instances': [
        {'label': 'Describe Instance', 'command': 'aws ec2 describe-instances --instance-ids {INSTANCE_ID}'},
        {'label': 'Instance Status', 'command': 'aws ec2 describe-instance-status --instance-ids {INSTANCE_ID}'},
        {'label': 'Get Console Output', 'command': 'aws ec2 get-console-output --instance-id {INSTANCE_ID}'},
      ],
      'Security Groups': [
        {'label': 'Describe Security Group', 'command': 'aws ec2 describe-security-groups --group-ids {SG_ID}'},
        {'label': 'List Rules', 'command': 'aws ec2 describe-security-group-rules --filters "Name=group-id,Values={SG_ID}"'},
      ],
      'Buckets': [
        {'label': 'List Buckets', 'command': 'aws s3 ls'},
        {'label': 'Get Bucket Policy', 'command': 'aws s3api get-bucket-policy --bucket {BUCKET_NAME}'},
        {'label': 'Get Bucket ACL', 'command': 'aws s3api get-bucket-acl --bucket {BUCKET_NAME}'},
        {'label': 'Get Public Access Block', 'command': 'aws s3api get-public-access-block --bucket {BUCKET_NAME}'},
      ],
      'Functions': [
        {'label': 'Get Function Config', 'command': 'aws lambda get-function-configuration --function-name {FUNCTION_NAME}'},
        {'label': 'List Functions', 'command': 'aws lambda list-functions'},
        {'label': 'Get Function Policy', 'command': 'aws lambda get-policy --function-name {FUNCTION_NAME}'},
      ],
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.auto_fix_high, color: colorScheme.onPrimaryContainer, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Assistente de Comandos',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selecione uma categoria para explorar os comandos disponíveis:',
                style: GoogleFonts.inter(color: colorScheme.onSurfaceVariant, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: serviceCategories.keys.map((category) {
                  return InkWell(
                    onTap: () {
                       Navigator.pop(context); // Close wizard dialog first
                      _showServicePicker(category, serviceCategories[category]!, step, serviceResources, resourceActions);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            category == 'Compute' ? Icons.computer :
                            category == 'Storage' ? Icons.storage :
                            category == 'Database' ? Icons.dns :
                            category == 'Network' ? Icons.lan :
                            Icons.security,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            category,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showConditionDialog(DiagnosticStep step) {
    String type = 'contains';
    String value = '';
    String action = 'continue';
    
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.alt_route, color: colorScheme.onTertiaryContainer, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Adicionar Condição',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: type,
                decoration: InputDecoration(
                  labelText: 'Tipo de Condição',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.2),
                ),
                items: const [
                  DropdownMenuItem(value: 'contains', child: Text('Output contém')),
                  DropdownMenuItem(value: 'equals', child: Text('Output é igual a')),
                  DropdownMenuItem(value: 'starts_with', child: Text('Output começa com')),
                  DropdownMenuItem(value: 'ends_with', child: Text('Output termina com')),
                  DropdownMenuItem(value: 'regex', child: Text('Regex match')),
                  DropdownMenuItem(value: 'exit_code', child: Text('Exit code igual a')),
                ],
                onChanged: (v) => setState(() => type = v!),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Valor',
                  hintText: 'Valor a ser verificado',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.2),
                ),
                onChanged: (v) => value = v,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: action,
                decoration: InputDecoration(
                  labelText: 'Ação se Verdadeiro',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.2),
                ),
                items: const [
                  DropdownMenuItem(value: 'continue', child: Text('Continuar (Padrão)')),
                  DropdownMenuItem(value: 'stop', child: Text('Parar Workflow')),
                  DropdownMenuItem(value: 'execute_step', child: Text('Executar Passo...')),
                ],
                onChanged: (v) => setState(() => action = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (value.isNotEmpty) {
                  this.setState(() {
                    step.conditions.add(StepCondition(
                      type: type,
                      value: value,
                      action: action,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showServicePicker(String category, List<String> services, DiagnosticStep step, 
      Map<String, List<String>> serviceResources, Map<String, List<Map<String, String>>> resourceActions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cloud, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Text('$category Services', style: GoogleFonts.outfit()),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return ListTile(
                leading: const Icon(Icons.cloud_queue),
                title: Text(service, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _showResourcePicker(service, serviceResources[service] ?? [], step, resourceActions);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showResourcePicker(String service, List<String> resources, DiagnosticStep step,
      Map<String, List<Map<String, String>>> resourceActions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.category, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Text('$service Resources', style: GoogleFonts.outfit()),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: resources.length,
            itemBuilder: (context, index) {
              final resource = resources[index];
              return ListTile(
                leading: const Icon(Icons.folder),
                title: Text(resource, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _showActionPicker(resource, resourceActions[resource] ?? [], step);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showActionPicker(String resource, List<Map<String, String>> actions, DiagnosticStep step) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.play_circle, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Text('$resource Actions', style: GoogleFonts.outfit()),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: const Icon(Icons.check_circle_outline, size: 20),
                  ),
                  title: Text(
                    action['label']!,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      action['command']!,
                      style: GoogleFonts.jetBrainsMono(fontSize: 10, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      step.command = action['command']!;
                    });
                    Navigator.pop(context);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }


  Widget _buildAdvancedOptions(DiagnosticStep step, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(Icons.tune, color: colorScheme.primary, size: 20),
            const SizedBox(width: 12),
            Text(
              'Opções Avançadas',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        shape: const RoundedRectangleBorder(),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          // Expected Output
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Output Esperado (Validação)',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Ex: "running" ou "available"',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.2),
                  prefixIcon: const Icon(Icons.check_circle_outline, size: 18),
                  helperText: 'O diagnóstico validará se este texto aparece no output',
                ),
                style: GoogleFonts.inter(fontSize: 12),
                controller: TextEditingController(text: step.expectedOutput),
                onChanged: (value) => setState(() => step.expectedOutput = value.isEmpty ? null : value),
                maxLines: 1,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Failure Action
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ação em Caso de Falha',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Ex: "Verificar se a instância está rodando"',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.2),
                  prefixIcon: const Icon(Icons.warning_amber, size: 18),
                  helperText: 'Mensagem de orientação para o usuário se falhar',
                ),
                style: GoogleFonts.inter(fontSize: 12),
                controller: TextEditingController(text: step.failureAction),
                onChanged: (value) => setState(() => step.failureAction = value.isEmpty ? null : value),
                maxLines: 1,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Info Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 16, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Dica: Use estas opções para criar diagnósticos inteligentes que validam automaticamente os resultados.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
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

  Widget _buildVariableInputsAdvanced(DiagnosticStep step, ColorScheme colorScheme) {
    final regex = RegExp(r'\{([^}]+)\}');
    final matches = regex.allMatches(step.command);
    final variables = matches.map((m) => m.group(1)!).toSet().toList();

    if (variables.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.input, size: 16, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Variáveis do Comando',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: variables.map((variable) {
            return SizedBox(
              width: 220,
              child: TextField(
                decoration: InputDecoration(
                  labelText: variable,
                  hintText: _getVariableHint(variable),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  filled: true,
                  fillColor: colorScheme.surface,
                  prefixIcon: Icon(_getVariableIcon(variable), size: 16),
                ),
                style: GoogleFonts.jetBrainsMono(fontSize: 12),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.tertiaryContainer.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: colorScheme.tertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Valores opcionais - serão solicitados durante a execução se não preenchidos',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getVariableHint(String variable) {
    final hints = {
      'INSTANCE_ID': 'i-1234567890abcdef0',
      'BUCKET_NAME': 'my-bucket-name',
      'FUNCTION_NAME': 'my-function',
      'SG_ID': 'sg-1234567890abcdef0',
      'VPC_ID': 'vpc-1234567890abcdef0',
      'USER_NAME': 'my-user',
      'ROLE_NAME': 'my-role',
    };
    return hints[variable] ?? 'Digite o valor';
  }

  IconData _getVariableIcon(String variable) {
    if (variable.contains('INSTANCE')) return Icons.computer;
    if (variable.contains('BUCKET')) return Icons.storage;
    if (variable.contains('FUNCTION')) return Icons.flash_on;
    if (variable.contains('SG') || variable.contains('SECURITY')) return Icons.security;
    if (variable.contains('VPC') || variable.contains('NETWORK')) return Icons.lan;
    if (variable.contains('USER') || variable.contains('ROLE')) return Icons.person;
    return Icons.edit;
  }


  Widget _buildRunningView(ColorScheme colorScheme) {
    return Row(
      children: [
        // Left: Step Progress Timeline
        Expanded(
          flex: 2,
          child: Container(
            color: colorScheme.surface,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progresso da Execução',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.builder(
                    itemCount: _currentWorkflow?.steps.length ?? 0,
                    itemBuilder: (context, index) {
                      final step = _currentWorkflow!.steps[index];
                      final isCompleted = index < _currentStepIndex;
                      final isCurrent = index == _currentStepIndex;
                      final isPending = index > _currentStepIndex;
                      
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: isCompleted ? Colors.green : (isCurrent ? colorScheme.primary : colorScheme.surfaceContainerHighest),
                                    shape: BoxShape.circle,
                                    border: isCurrent ? Border.all(color: colorScheme.primaryContainer, width: 4) : null,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      isCompleted ? Icons.check : (isCurrent ? Icons.play_arrow : Icons.circle),
                                      size: 14,
                                      color: isPending ? colorScheme.onSurfaceVariant : Colors.white,
                                    ),
                                  ),
                                ),
                                if (index < (_currentWorkflow?.steps.length ?? 0) - 1)
                                  Expanded(
                                    child: Container(
                                      width: 2,
                                      color: isCompleted ? Colors.green.withOpacity(0.5) : colorScheme.outlineVariant.withOpacity(0.3),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      step.title,
                                      style: GoogleFonts.inter(
                                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                        fontSize: 14,
                                        color: isPending ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        step.command,
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 11,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isCurrent)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: LinearProgressIndicator(
                                          backgroundColor: colorScheme.surfaceContainerHighest,
                                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                                          minHeight: 2,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
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
        ),
        
        // Right: Terminal Output
        Expanded(
          flex: 3,
          child: Container(
            color: const Color(0xFF1E1E1E),
            child: Column(
              children: [
                // Terminal Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252526),
                    border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.2))),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.terminal, color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Terminal Output',
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.white54, size: 16),
                        onPressed: () => setState(() => _terminalOutput = ''),
                        tooltip: 'Limpar',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: TerminalOutput(
                      output: _terminalOutput,
                      isRunning: _isRunning,
                      height: double.infinity,
                      onClear: () => setState(() => _terminalOutput = ''),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _workflowNameController.dispose();
    _workflowDescController.dispose();
    super.dispose();
  }
}
