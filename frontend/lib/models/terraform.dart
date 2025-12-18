class TerraformExecution {
  final String id;
  final String command;
  final String workDir;
  final List<String> args;
  final String status;
  final String output;
  final String error;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int durationMs;

  TerraformExecution({
    required this.id,
    required this.command,
    required this.workDir,
    required this.args,
    required this.status,
    required this.output,
    this.error = '',
    required this.startedAt,
    this.completedAt,
    required this.durationMs,
  });

  factory TerraformExecution.fromJson(Map<String, dynamic> json) {
    return TerraformExecution(
      id: json['id'] ?? '',
      command: json['command'] ?? '',
      workDir: json['work_dir'] ?? '',
      args: List<String>.from(json['args'] ?? []),
      status: json['status'] ?? '',
      output: json['output'] ?? '',
      error: json['error'] ?? '',
      startedAt: DateTime.parse(json['started_at']),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      durationMs: json['duration_ms'] ?? 0,
    );
  }
}

class TerraformState {
  final String formatVersion;
  final String terraformVersion;
  final TerraformValues? values;

  TerraformState({
    required this.formatVersion,
    required this.terraformVersion,
    this.values,
  });

  factory TerraformState.fromJson(Map<String, dynamic> json) {
    return TerraformState(
      formatVersion: json['format_version'] ?? '',
      terraformVersion: json['terraform_version'] ?? '',
      values: json['values'] != null ? TerraformValues.fromJson(json['values']) : null,
    );
  }
}

class TerraformValues {
  final TerraformModule? rootModule;

  TerraformValues({this.rootModule});

  factory TerraformValues.fromJson(Map<String, dynamic> json) {
    return TerraformValues(
      rootModule: json['root_module'] != null ? TerraformModule.fromJson(json['root_module']) : null,
    );
  }
}

class TerraformModule {
  final List<TerraformResource> resources;
  final List<TerraformModule> childModules;

  TerraformModule({
    this.resources = const [],
    this.childModules = const [],
  });

  factory TerraformModule.fromJson(Map<String, dynamic> json) {
    return TerraformModule(
      resources: (json['resources'] as List?)?.map((e) => TerraformResource.fromJson(e)).toList() ?? [],
      childModules: (json['child_modules'] as List?)?.map((e) => TerraformModule.fromJson(e)).toList() ?? [],
    );
  }
}

class TerraformResource {
  final String address;
  final String mode;
  final String type;
  final String name;
  final String providerName;
  final Map<String, dynamic> values;

  TerraformResource({
    required this.address,
    required this.mode,
    required this.type,
    required this.name,
    required this.providerName,
    required this.values,
  });

  factory TerraformResource.fromJson(Map<String, dynamic> json) {
    return TerraformResource(
      address: json['address'] ?? '',
      mode: json['mode'] ?? '',
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      providerName: json['provider_name'] ?? '',
      values: json['values'] ?? {},
    );
  }
}
