  void _showConditionDialog(DiagnosticStep step) {
    String type = 'contains';
    String value = '';
    String action = 'continue';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Condition'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Condition Type'),
                items: const [
                  DropdownMenuItem(value: 'contains', child: Text('Output contains')),
                  DropdownMenuItem(value: 'equals', child: Text('Output equals')),
                  DropdownMenuItem(value: 'starts_with', child: Text('Output starts with')),
                  DropdownMenuItem(value: 'ends_with', child: Text('Output ends with')),
                  DropdownMenuItem(value: 'regex', child: Text('Regex match')),
                  DropdownMenuItem(value: 'exit_code', child: Text('Exit code equals')),
                ],
                onChanged: (v) => setState(() => type = v!),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(labelText: 'Value'),
                onChanged: (v) => value = v,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: action,
                decoration: const InputDecoration(labelText: 'Action if True'),
                items: const [
                  DropdownMenuItem(value: 'continue', child: Text('Continue (Default)')),
                  DropdownMenuItem(value: 'stop', child: Text('Stop Workflow')),
                  DropdownMenuItem(value: 'execute_step', child: Text('Execute Step...')),
                ],
                onChanged: (v) => setState(() => action = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (value.isNotEmpty) {
                  this.setState(() {
                    step.conditions ??= [];
                    step.conditions!.add(StepCondition(
                      type: type,
                      value: value,
                      action: action,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
