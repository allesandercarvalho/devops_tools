import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../widgets/terminal_output.dart';
import '../../../../models/network_tool.dart';
import 'quick_dashboard.dart';

class QuickResultSplitView extends StatelessWidget {
  final NetworkToolExecution? execution;
  final String toolType;
  final VoidCallback onClear;
  
  const QuickResultSplitView({
    super.key,
    required this.execution,
    required this.toolType,
    required this.onClear,
  });



  @override
  Widget build(BuildContext context) {
    if (execution == null) {
      return Center(child: Text('Results will appear here', style: GoogleFonts.inter(color: Colors.white30)));
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side: Terminal Output
          Expanded(
            flex: 3,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return TerminalOutput(
                  output: execution!.output,
                  isRunning: false,
                  onClear: onClear,
                  height: constraints.maxHeight,
                );
              },
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Right Side: Dashboard
          Expanded(
            flex: 2, // 40% width
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1e293b),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.dashboard, color: Colors.white70, size: 20),
                      const SizedBox(width: 8),
                      Text('Result Dashboard', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                       child: QuickDashboard(execution: execution!, toolType: toolType),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
