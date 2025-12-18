import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/terminal_output.dart';
import '../../../../widgets/universal_filter_widget.dart';
import '../../../services/aws_api_service.dart';

class AWSFacilitatorScreen extends StatefulWidget {
  final String searchQuery;
  final String viewType;
  final String selectedCategory;

  const AWSFacilitatorScreen({
    super.key,
    required this.searchQuery,
    required this.viewType,
    required this.selectedCategory,
  });

  @override
  State<AWSFacilitatorScreen> createState() => _AWSFacilitatorScreenState();
}

class _AWSFacilitatorScreenState extends State<AWSFacilitatorScreen> {
  String _selectedService = 'EC2';
  String? _selectedResource;
  String? _selectedAction;
  
  final Map<String, TextEditingController> _controllers = {};
  final TextEditingController _commandController = TextEditingController();
  String _generatedCommand = '';
  String _terminalOutput = '';
  bool _isExecuting = false;

  bool _isTerminalExpanded = false;
  bool _showFilters = true;
  String _filterCommand = '';

  // Categories Data (Moved to Parent, but keeping map for service lookup)
  // Categories Data
  final Map<String, List<String>> _serviceCategories = {
    'Compute': ['EC2', 'Lambda', 'EKS', 'ECS', 'Lightsail', 'Batch', 'Elastic Beanstalk'],
    'Storage': ['S3', 'EBS', 'EFS', 'Glacier', 'Storage Gateway', 'Backup'],
    'Database': ['RDS', 'DynamoDB', 'ElastiCache', 'Redshift', 'Aurora', 'DocumentDB', 'Neptune'],
    'Network': ['VPC', 'Route53', 'CloudFront', 'API Gateway', 'Direct Connect', 'VPN'],
    'Security': ['IAM', 'KMS', 'WAF', 'Secrets Manager', 'Cognito', 'GuardDuty', 'Shield'],
    'Management': ['CloudWatch', 'CloudFormation', 'Config', 'Systems Manager', 'Auto Scaling', 'Organizations'],
    'Developer Tools': ['CodeCommit', 'CodeBuild', 'CodeDeploy', 'CodePipeline', 'X-Ray'],
    'Analytics': ['Athena', 'EMR', 'Kinesis', 'QuickSight', 'Glue', 'OpenSearch'],
    'Machine Learning': ['SageMaker', 'Rekognition', 'Polly', 'Comprehend', 'Translate'],
    'Integration': ['SQS', 'SNS', 'EventBridge', 'Step Functions', 'AppSync'],
  };

  final Map<String, IconData> _serviceIcons = {
    // Compute
    'EC2': Icons.computer,
    'Lambda': Icons.functions,
    'EKS': Icons.grid_4x4,
    'ECS': Icons.view_quilt,
    'Lightsail': Icons.lightbulb_outline,
    'Batch': Icons.schedule,
    'Elastic Beanstalk': Icons.layers,
    
    // Storage
    'S3': Icons.folder_open,
    'EBS': Icons.storage,
    'EFS': Icons.folder_shared,
    'Glacier': Icons.ac_unit,
    'Storage Gateway': Icons.router,
    'Backup': Icons.backup,

    // Database
    'RDS': Icons.storage,
    'DynamoDB': Icons.table_chart,
    'ElastiCache': Icons.memory,
    'Redshift': Icons.analytics,
    'Aurora': Icons.cloud_circle,
    'DocumentDB': Icons.description,
    'Neptune': Icons.share,

    // Network
    'VPC': Icons.cloud_queue,
    'Route53': Icons.alt_route,
    'CloudFront': Icons.public,
    'API Gateway': Icons.api,
    'Direct Connect': Icons.cable,
    'VPN': Icons.vpn_lock,

    // Security
    'IAM': Icons.admin_panel_settings,
    'KMS': Icons.vpn_key,
    'WAF': Icons.security,
    'Secrets Manager': Icons.lock,
    'Cognito': Icons.people_outline,
    'GuardDuty': Icons.shield,
    'Shield': Icons.shield_moon,

    // Management
    'CloudWatch': Icons.monitor_heart,
    'CloudFormation': Icons.code,
    'Config': Icons.settings,
    'Systems Manager': Icons.build,
    'Auto Scaling': Icons.linear_scale,
    'Organizations': Icons.corporate_fare,

    // Developer Tools
    'CodeCommit': Icons.source,
    'CodeBuild': Icons.build_circle,
    'CodeDeploy': Icons.cloud_upload,
    'CodePipeline': Icons.alt_route,
    'X-Ray': Icons.bug_report,

    // Analytics
    'Athena': Icons.search,
    'EMR': Icons.science,
    'Kinesis': Icons.stream,
    'QuickSight': Icons.insights,
    'Glue': Icons.join_inner,
    'OpenSearch': Icons.search,

    // Machine Learning
    'SageMaker': Icons.psychology,
    'Rekognition': Icons.image_search,
    'Polly': Icons.record_voice_over,
    'Comprehend': Icons.text_fields,
    'Translate': Icons.translate,

    // Integration
    'SQS': Icons.queue,
    'SNS': Icons.notifications,
    'EventBridge': Icons.event,
    'Step Functions': Icons.timeline,
    'AppSync': Icons.sync_alt,
  };

  // Hierarchy: Service -> Resources
  // Hierarchy: Service -> Resources
  final Map<String, List<String>> _serviceResources = {
    // Compute
    'EC2': ['Instances', 'Security Groups', 'Volumes', 'Key Pairs', 'Snapshots', 'AMIs'],
    'Lambda': ['Functions', 'Layers', 'Aliases', 'Event Source Mappings'],
    'EKS': ['Clusters', 'Node Groups', 'Fargate Profiles'],
    'ECS': ['Clusters', 'Services', 'Tasks', 'Task Definitions'],
    'Lightsail': ['Instances', 'Databases', 'Load Balancers'],
    'Batch': ['Jobs', 'Job Definitions', 'Compute Environments'],
    'Elastic Beanstalk': ['Applications', 'Environments'],

    // Storage
    'S3': ['Buckets', 'Objects', 'Policies', 'CORS'],
    'EBS': ['Volumes', 'Snapshots'],
    'EFS': ['File Systems', 'Mount Targets'],
    'Glacier': ['Vaults'],
    'Storage Gateway': ['Gateways', 'Volumes'],
    'Backup': ['Backup Vaults', 'Backup Plans'],

    // Database
    'RDS': ['Instances', 'Snapshots', 'Parameter Groups', 'Subnet Groups'],
    'DynamoDB': ['Tables', 'Items', 'Backups'],
    'ElastiCache': ['Clusters', 'Replication Groups'],
    'Redshift': ['Clusters', 'Snapshots'],
    'Aurora': ['Clusters', 'Instances'],
    'DocumentDB': ['Clusters', 'Instances'],
    'Neptune': ['Clusters', 'Instances'],

    // Network
    'VPC': ['VPCs', 'Subnets', 'Route Tables', 'Internet Gateways', 'NAT Gateways', 'Peering Connections'],
    'Route53': ['Hosted Zones', 'Records', 'Health Checks'],
    'CloudFront': ['Distributions', 'Origins'],
    'API Gateway': ['APIs', 'Resources', 'Stages', 'Usage Plans'],
    'Direct Connect': ['Connections', 'Virtual Interfaces'],
    'VPN': ['VPN Gateways', 'Customer Gateways', 'VPN Connections'],

    // Security
    'IAM': ['Users', 'Roles', 'Policies', 'Groups', 'Providers'],
    'KMS': ['Keys', 'Aliases'],
    'WAF': ['Web ACLs', 'Rule Groups'],
    'Secrets Manager': ['Secrets'],
    'Cognito': ['User Pools', 'Identity Pools'],
    'GuardDuty': ['Detectors', 'Findings'],
    'Shield': ['Protections'],

    // Management
    'CloudWatch': ['Alarms', 'Dashboards', 'Log Groups', 'Metrics'],
    'CloudFormation': ['Stacks', 'StackSets', 'Change Sets'],
    'Config': ['Rules', 'Recorders'],
    'Systems Manager': ['Parameters', 'Documents', 'Managed Instances', 'Patch Baselines'],
    'Auto Scaling': ['Auto Scaling Groups', 'Launch Configurations'],
    'Organizations': ['Accounts', 'Organizational Units', 'Policies'],

    // Developer Tools
    'CodeCommit': ['Repositories', 'Branches'],
    'CodeBuild': ['Projects', 'Builds'],
    'CodeDeploy': ['Applications', 'Deployment Groups'],
    'CodePipeline': ['Pipelines'],
    'X-Ray': ['Groups', 'Sampling Rules'],

    // Analytics
    'Athena': ['Workgroups', 'Named Queries'],
    'EMR': ['Clusters'],
    'Kinesis': ['Streams', 'Delivery Streams'],
    'QuickSight': ['Dashboards', 'Analyses'],
    'Glue': ['Crawlers', 'Jobs', 'Databases'],
    'OpenSearch': ['Domains'],

    // Machine Learning
    'SageMaker': ['Notebook Instances', 'Training Jobs', 'Models', 'Endpoints'],
    'Rekognition': ['Collections'],
    'Polly': ['Synthesize Speech'],
    'Comprehend': ['Sentiment Analysis', 'Entity Detection'],
    'Translate': ['Translate Text'],

    // Integration
    'SQS': ['Queues'],
    'SNS': ['Topics', 'Subscriptions'],
    'EventBridge': ['Rules', 'Event Buses'],
    'Step Functions': ['State Machines', 'Executions'],
    'AppSync': ['APIs', 'Data Sources'],
  };

  // Hierarchy: Resource -> Actions (Macros)
  final Map<String, List<Map<String, dynamic>>> _resourceActions = {
    // EC2
    'Instances': [
      {'label': 'Launch', 'icon': Icons.rocket_launch, 'command': 'aws ec2 run-instances --image-id {AMI ID} --instance-type {Instance Type} --key-name {Key Pair} --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value={Instance Name}]"'},
      {'label': 'Start', 'icon': Icons.play_arrow, 'command': 'aws ec2 start-instances --instance-ids {Instance ID}'},
      {'label': 'Stop', 'icon': Icons.stop, 'command': 'aws ec2 stop-instances --instance-ids {Instance ID}'},
      {'label': 'Reboot', 'icon': Icons.restart_alt, 'command': 'aws ec2 reboot-instances --instance-ids {Instance ID}'},
      {'label': 'Describe', 'icon': Icons.info_outline, 'command': 'aws ec2 describe-instances --instance-ids {Instance ID}'},
    ],
    'Security Groups': [
      {'label': 'Create', 'icon': Icons.security, 'command': 'aws ec2 create-security-group --group-name {SG Name} --description "{Description}"'},
      {'label': 'Auth Inbound', 'icon': Icons.login, 'command': 'aws ec2 authorize-security-group-ingress --group-id {SG ID} --protocol tcp --port {Port} --cidr {CIDR}'},
      {'label': 'List', 'icon': Icons.list, 'command': 'aws ec2 describe-security-groups'},
    ],
    
    // S3
    'Buckets': [
      {'label': 'Create', 'icon': Icons.add_box, 'command': 'aws s3 mb s3://{Bucket Name} --region {Region}'},
      {'label': 'List', 'icon': Icons.list, 'command': 'aws s3 ls'},
      {'label': 'Delete', 'icon': Icons.delete_outline, 'command': 'aws s3 rb s3://{Bucket Name} --force'},
      {'label': 'Sync', 'icon': Icons.sync, 'command': 'aws s3 sync {Source} s3://{Bucket Name}'},
    ],

    // Lambda
    'Functions': [
      {'label': 'Create', 'icon': Icons.code, 'command': 'aws lambda create-function --function-name {Function Name} --runtime {Runtime} --role {Role ARN} --handler {Handler} --zip-file fileb://function.zip'},
      {'label': 'Invoke', 'icon': Icons.play_circle_outline, 'command': 'aws lambda invoke --function-name {Function Name} response.json'},
      {'label': 'List', 'icon': Icons.list, 'command': 'aws lambda list-functions'},
    ],

    // ECS
    'Clusters': [
        {'label': 'Create', 'icon': Icons.add_box, 'command': 'aws ecs create-cluster --cluster-name {Cluster Name}'},
        {'label': 'List', 'icon': Icons.list, 'command': 'aws ecs list-clusters'},
    ],
    'Services': [
        {'label': 'Update', 'icon': Icons.update, 'command': 'aws ecs update-service --cluster {Cluster Name} --service {Service Name} --force-new-deployment'},
    ],

    // RDS
    'RDS Instances': [ // Disambiguated
        {'label': 'Create', 'icon': Icons.add_box, 'command': 'aws rds create-db-instance --db-instance-identifier {DB Identifier} --db-instance-class {DB Class} --engine {Engine}'},
        {'label': 'Stop', 'icon': Icons.stop, 'command': 'aws rds stop-db-instance --db-instance-identifier {DB Identifier}'},
        {'label': 'Start', 'icon': Icons.play_arrow, 'command': 'aws rds start-db-instance --db-instance-identifier {DB Identifier}'},
    ],

    // VPC
    'VPCs': [
        {'label': 'Create', 'icon': Icons.add_box, 'command': 'aws ec2 create-vpc --cidr-block {CIDR}'},
        {'label': 'List', 'icon': Icons.list, 'command': 'aws ec2 describe-vpcs'},
    ],

    // IAM
    'Users': [
        {'label': 'Create', 'icon': Icons.person_add, 'command': 'aws iam create-user --user-name {User Name}'},
        {'label': 'List', 'icon': Icons.list, 'command': 'aws iam list-users'},
    ],
    'Roles': [
        {'label': 'Create', 'icon': Icons.admin_panel_settings, 'command': 'aws iam create-role --role-name {Role Name} --assume-role-policy-document file://trust-policy.json'},
        {'label': 'List', 'icon': Icons.list, 'command': 'aws iam list-roles'},
    ],

    // CloudWatch
    'Log Groups': [
        {'label': 'Create', 'icon': Icons.add_box, 'command': 'aws logs create-log-group --log-group-name {Log Group Name}'},
        {'label': 'List', 'icon': Icons.list, 'command': 'aws logs describe-log-groups'},
    ],

    // SQS
    'Queues': [
        {'label': 'Create', 'icon': Icons.queue, 'command': 'aws sqs create-queue --queue-name {Queue Name}'},
        {'label': 'List', 'icon': Icons.list, 'command': 'aws sqs list-queues'},
        {'label': 'Send Message', 'icon': Icons.message, 'command': 'aws sqs send-message --queue-url {Queue URL} --message-body "{Message Body}"'},
    ],

    // SNS
    'Topics': [
        {'label': 'Create', 'icon': Icons.notifications, 'command': 'aws sns create-topic --name {Topic Name}'},
        {'label': 'Publish', 'icon': Icons.send, 'command': 'aws sns publish --topic-arn {Topic ARN} --message "{Message}"'},
    ],
  };

  // Smart Variables Mapping
  // Smart Variables Mapping
  final Map<String, List<String>> _actionVariables = {
    'Launch': ['AMI ID', 'Instance Type', 'Key Pair', 'Instance Name'],
    'Start': ['Instance ID', 'DB Identifier'],
    'Stop': ['Instance ID', 'DB Identifier'],
    'Reboot': ['Instance ID'],
    'Describe': ['Instance ID'],
    'Create': ['SG Name', 'Description', 'Bucket Name', 'Region', 'Function Name', 'Runtime', 'Role ARN', 'Handler', 'Cluster Name', 'DB Identifier', 'DB Class', 'Engine', 'CIDR', 'User Name', 'Role Name', 'Log Group Name', 'Queue Name', 'Topic Name'],
    'Auth Inbound': ['SG ID', 'Port', 'CIDR'],
    'Sync': ['Source', 'Bucket Name'],
    'Invoke': ['Function Name'],
    'Delete': ['Bucket Name'],
    'Update': ['Cluster Name', 'Service Name'],
    'Send Message': ['Queue URL', 'Message Body'],
    'Publish': ['Topic ARN', 'Message'],
  };

  @override
  void initState() {
    super.initState();
    _updateSelection();
    _initializeControllers();
  }

  @override
  void didUpdateWidget(AWSFacilitatorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory || oldWidget.searchQuery != widget.searchQuery) {
      _updateSelection();
    }
  }

  void _updateSelection() {
    // Filter services based on category and search
    List<String> services = [];
    if (widget.selectedCategory == 'Todos') {
       // Flatten all categories
       services = _serviceCategories.values.expand((x) => x).toSet().toList();
    } else {
       services = _serviceCategories[widget.selectedCategory] ?? [];
    }
    
    if (widget.searchQuery.isNotEmpty) {
      services = services.where((s) => s.toLowerCase().contains(widget.searchQuery.toLowerCase())).toList();
    }

    if (services.isNotEmpty) {
      setState(() {
        _selectedService = services.first;
        _selectedResource = _serviceResources[_selectedService]?.first;
        _selectedAction = null;
        _generatedCommand = '';
      });
    }
  }

  void _initializeControllers() {
    final allVars = _actionVariables.values.expand((element) => element).toSet();
    for (var v in allVars) {
      if (!_controllers.containsKey(v)) {
        _controllers[v] = TextEditingController();
      }
    }
    // Pre-fill defaults
    _controllers['Instance Type']?.text = 't3.micro';
    _controllers['Region']?.text = 'us-east-1';
    _controllers['Runtime']?.text = 'python3.9';
    _controllers['Port']?.text = '443';
    _controllers['CIDR']?.text = '10.0.0.0/16';
    _controllers['Engine']?.text = 'mysql';
    _controllers['DB Class']?.text = 'db.t3.micro';
  }

  void _generateCommand(Map<String, dynamic> action) {
    String command = action['command'];
    setState(() {
      _selectedAction = action['label'];
    });
    
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
      final cmdToRun = _commandController.text;
      _terminalOutput += '\n\$ $cmdToRun\n';
    });

    try {
      // Call real AWS API
      final result = await AWSApiService.executeCommand(
        command: _commandController.text,
        profile: null, // TODO: Get from selected profile
        region: null,  // TODO: Get from selected region
      );

      setState(() {
        _isExecuting = false;
        
        // Display execution info
        _terminalOutput += '⏱️  Duration: ${result['duration']?.toStringAsFixed(2) ?? '0'}s\n';
        _terminalOutput += '📊 Exit Code: ${result['exit_code']}\n\n';
        
        // Display output
        if (result['success'] == true && result['stdout'] != null && result['stdout'].toString().isNotEmpty) {
          _terminalOutput += '✅ Success:\n';
          _terminalOutput += '${result['stdout']}\n';
        } else if (result['stderr'] != null && result['stderr'].toString().isNotEmpty) {
          _terminalOutput += '❌ Error:\n';
          _terminalOutput += '${result['stderr']}\n';
        } else {
          _terminalOutput += '✅ Command executed successfully (no output)\n';
        }
      });
    } catch (e) {
      setState(() {
        _isExecuting = false;
        _terminalOutput += '❌ Error executing command:\n$e\n';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    List<String> services = [];
    if (widget.selectedCategory == 'Todos') {
       services = _serviceCategories.values.expand((x) => x).toSet().toList();
       services.sort(); // Sort alphabetically for better UX when mixed
    } else {
       services = _serviceCategories[widget.selectedCategory] ?? [];
    }
    final resources = _serviceResources[_selectedService] ?? [];
    
    // Filter actions based on search query passed from parent
    final allActions = _resourceActions[_selectedResource] ?? [];
    final actions = widget.searchQuery.isEmpty 
        ? allActions 
        : allActions.where((a) => a['label'].toString().toLowerCase().contains(widget.searchQuery.toLowerCase())).toList();

    final variables = _selectedAction != null ? (_actionVariables[_selectedAction] ?? []) : <String>[];

    return Column(
      children: [
        // Filter Bar removed (handled by parent)

        // 3. Content Area
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Content (Actions & Config)
              if (!_isTerminalExpanded)
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Service & Resource Selection (Compact Row)
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Service', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant)),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: services.contains(_selectedService) ? _selectedService : null,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                      filled: true,
                                      fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                    ),
                                    style: GoogleFonts.inter(fontSize: 14, color: colorScheme.onSurface),
                                    items: services.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectedService = value;
                                          _selectedResource = _serviceResources[value]?.first;
                                          _selectedAction = null;
                                          _generatedCommand = '';
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
                                  Text('Resource', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant)),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _selectedResource,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                      filled: true,
                                      fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                    ),
                                    style: GoogleFonts.inter(fontSize: 14, color: colorScheme.onSurface),
                                    items: resources.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectedResource = value;
                                          _selectedAction = null;
                                          _generatedCommand = '';
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),

                        const SizedBox(height: 8),

                        // Actions Display
                        if (actions.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text('No actions found', style: GoogleFonts.inter(color: colorScheme.onSurfaceVariant)),
                            ),
                          )
                        else if (widget.viewType == 'grid')
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 140,
                              childAspectRatio: 1.1,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: actions.length,
                            itemBuilder: (context, index) => _buildActionCard(actions[index], colorScheme),
                          )
                        else if (widget.viewType == 'list')
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: actions.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) => _buildActionListTile(actions[index], colorScheme),
                          )
                        else // Dashboard view (simplified for now as grid with more info)
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 200,
                              childAspectRatio: 1.5,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: actions.length,
                            itemBuilder: (context, index) => _buildActionCard(actions[index], colorScheme, isDashboard: true),
                          ),

                        const SizedBox(height: 32),

                        // Configuration Area (if action selected)
                        if (_selectedAction != null && variables.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.2)),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.tune, size: 20, color: colorScheme.primary),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Configuração: $_selectedAction',
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        Text(
                                          'Defina os parâmetros para executar esta ação',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 3.5,
                                    crossAxisSpacing: 24,
                                    mainAxisSpacing: 20,
                                  ),
                                  itemCount: variables.length,
                                  itemBuilder: (context, index) {
                                    final v = variables[index];
                                    return TextField(
                                      controller: _controllers[v],
                                      decoration: InputDecoration(
                                        labelText: v,
                                        labelStyle: GoogleFonts.inter(fontSize: 13, color: colorScheme.onSurfaceVariant),
                                        floatingLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.primary),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                                        ),
                                        filled: true,
                                        fillColor: colorScheme.surfaceContainerLowest,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                        prefixIcon: Icon(Icons.input, size: 16, color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
                                      ),
                                      style: GoogleFonts.inter(fontSize: 14),
                                      onChanged: (_) {
                                        if (_selectedAction != null) {
                                          final action = actions.firstWhere((a) => a['label'] == _selectedAction);
                                          _generateCommand(action);
                                        }
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Filters (Moved below Configuration)
                        if (_showFilters)
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

              // Vertical Divider
              if (!_isTerminalExpanded)
                VerticalDivider(width: 1, thickness: 1, color: colorScheme.outlineVariant.withOpacity(0.3)),

              // Terminal Area
              Expanded(
                flex: _isTerminalExpanded ? 1 : 4,
                child: Container(
                  color: const Color(0xFF0F111A),
                  child: Column(
                    children: [
                      // Terminal Header
                      Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        color: const Color(0xFF1A1D26),
                        child: Row(
                          children: [
                            Icon(Icons.terminal, size: 14, color: Colors.grey.shade400),
                            const SizedBox(width: 8),
                            Text('Terminal', style: GoogleFonts.jetBrainsMono(fontSize: 12, color: Colors.grey.shade400)),
                            const Spacer(),
                            // Filter toggle removed from here as it's now in main content
                            IconButton(
                              icon: Icon(_isTerminalExpanded ? Icons.close_fullscreen : Icons.open_in_full, size: 16, color: Colors.grey.shade400),
                              onPressed: () => setState(() => _isTerminalExpanded = !_isTerminalExpanded),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      
                      // Filters Section Removed from here

                      // Command Preview & Execute
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
                        ),
                        child: Row(
                          children: [
                            Text('\$', style: GoogleFonts.jetBrainsMono(color: const Color(0xFF4EC9B0), fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _commandController,
                                style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 13),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  hintText: 'Command preview...',
                                  hintStyle: TextStyle(color: Colors.grey),
                                ),
                                onChanged: (val) => setState(() => _generatedCommand = val),
                              ),
                            ),
                            IconButton(
                              onPressed: _generatedCommand.isEmpty || _isExecuting ? null : _executeCommand,
                              icon: _isExecuting 
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4EC9B0))) 
                                  : const Icon(Icons.play_arrow, size: 18, color: Color(0xFF4EC9B0)),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),

                      // Output
                      Expanded(
                        child: TerminalOutput(
                          output: _terminalOutput,
                          isRunning: _isExecuting,
                          height: double.infinity,
                          onClear: () => setState(() => _terminalOutput = ''),
                          filterCommand: _filterCommand,
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



  Widget _buildActionCard(Map<String, dynamic> action, ColorScheme colorScheme, {bool isDashboard = false}) {
    final isSelected = _selectedAction == action['label'];
    return InkWell(
      onTap: () => _generateCommand(action),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              action['icon'],
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              size: isDashboard ? 32 : 24,
            ),
            const SizedBox(height: 8),
            Text(
              action['label'],
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (isDashboard) ...[
              const SizedBox(height: 4),
              Text(
                'Click to configure',
                style: GoogleFonts.inter(fontSize: 10, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionListTile(Map<String, dynamic> action, ColorScheme colorScheme) {
    final isSelected = _selectedAction == action['label'];
    return InkWell(
      onTap: () => _generateCommand(action),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              action['icon'],
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 16),
            Text(
              action['label'],
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle, size: 16, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commandController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}

