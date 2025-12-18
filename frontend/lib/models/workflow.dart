class Workflow {
  final String id;
  final String name;
  final String description;
  final String category;
  final List<VariableDefinition> variables;
  final List<WorkflowStep> steps;

  Workflow({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.variables,
    required this.steps,
  });

  factory Workflow.fromJson(Map<String, dynamic> json) {
    return Workflow(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      variables: (json['variables'] as List<dynamic>?)
              ?.map((e) => VariableDefinition.fromJson(e))
              .toList() ??
          [],
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => WorkflowStep.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'variables': variables.map((e) => e.toJson()).toList(),
      'steps': steps.map((e) => e.toJson()).toList(),
    };
  }
}

class VariableDefinition {
  final String name;
  final String description;
  final String type; // string, number, boolean, select
  final String? defaultValue;
  final List<String>? options;

  VariableDefinition({
    required this.name,
    required this.description,
    required this.type,
    this.defaultValue,
    this.options,
  });

  factory VariableDefinition.fromJson(Map<String, dynamic> json) {
    return VariableDefinition(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? 'string',
      defaultValue: json['default_value'],
      options: (json['options'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'type': type,
      'default_value': defaultValue,
      'options': options,
    };
  }
}

class WorkflowStep {
  final String id;
  final String name;
  final String type; // command, workflow_ref
  final String content;
  final Map<String, String> variables;
  final StepCondition? condition;

  WorkflowStep({
    required this.id,
    required this.name,
    required this.type,
    required this.content,
    this.variables = const {},
    this.condition,
  });

  factory WorkflowStep.fromJson(Map<String, dynamic> json) {
    return WorkflowStep(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'command',
      content: json['content'] ?? '',
      variables: Map<String, String>.from(json['variables'] ?? {}),
      condition: json['condition'] != null ? StepCondition.fromJson(json['condition']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'content': content,
      'variables': variables,
      'condition': condition?.toJson(),
    };
  }
}

class StepCondition {
  final String type; // contains, equals, regex, exit_code
  final String value;
  final String action; // continue, stop, jump_to_step
  final String? target;

  StepCondition({
    required this.type,
    required this.value,
    required this.action,
    this.target,
  });

  factory StepCondition.fromJson(Map<String, dynamic> json) {
    return StepCondition(
      type: json['type'] ?? 'contains',
      value: json['value'] ?? '',
      action: json['action'] ?? 'continue',
      target: json['target'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'value': value,
      'action': action,
      'target': target,
    };
  }
}

class WorkflowExecution {
  final String id;
  final String workflowId;
  final String status;
  final List<String> logs;
  final Map<String, String> variables;
  final String startTime;
  final String? endTime;

  WorkflowExecution({
    required this.id,
    required this.workflowId,
    required this.status,
    required this.logs,
    required this.variables,
    required this.startTime,
    this.endTime,
  });

  factory WorkflowExecution.fromJson(Map<String, dynamic> json) {
    return WorkflowExecution(
      id: json['id'] ?? '',
      workflowId: json['workflow_id'] ?? '',
      status: json['status'] ?? 'pending',
      logs: (json['logs'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      variables: Map<String, String>.from(json['variables'] ?? {}),
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'],
    );
  }
}

class GlobalVariable {
  final String name;
  final String value;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  GlobalVariable({
    required this.name,
    required this.value,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GlobalVariable.fromJson(Map<String, dynamic> json) {
    return GlobalVariable(
      name: json['name'] ?? '',
      value: json['value'] ?? '',
      description: json['description'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
