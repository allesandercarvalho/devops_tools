import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/system_api_service.dart';

class DependencyCheckDialog extends StatefulWidget {
  const DependencyCheckDialog({super.key});

  @override
  State<DependencyCheckDialog> createState() => _DependencyCheckDialogState();
}

class _DependencyCheckDialogState extends State<DependencyCheckDialog> {
  late Future<List<SystemDependency>> _futureDependencies;

  @override
  void initState() {
    super.initState();
    _futureDependencies = SystemApiService.checkDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1e293b),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'System Dependencies',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Flexible(
              child: FutureBuilder<List<SystemDependency>>(
                future: _futureDependencies,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'No dependencies info available',
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  final deps = snapshot.data!;
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: deps.length,
                    separatorBuilder: (context, index) => const Divider(color: Colors.white12),
                    itemBuilder: (context, index) {
                      final dep = deps[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: dep.installed
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            dep.installed ? Icons.check : Icons.warning_amber,
                            color: dep.installed ? Colors.greenAccent : Colors.redAccent,
                          ),
                        ),
                        title: Text(
                          dep.name,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dep.description, style: const TextStyle(color: Colors.white54)),
                            if (!dep.installed && dep.installCmd.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        dep.installCmd,
                                        style: GoogleFonts.jetBrainsMono(
                                          color: Colors.orangeAccent,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () {
                                          Clipboard.setData(ClipboardData(text: dep.installCmd));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Command copied!')),
                                          );
                                        },
                                        child: const Icon(Icons.copy, size: 14, color: Colors.white54),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: dep.installed
                            ? null
                            : TextButton(
                                onPressed: () {
                                   Clipboard.setData(ClipboardData(text: dep.installCmd));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Command copied!')),
                                          );
                                },
                                child: const Text('Install'),
                              ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
