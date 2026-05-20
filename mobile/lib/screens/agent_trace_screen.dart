import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../main.dart';

class AgentTraceScreen extends StatefulWidget {
  const AgentTraceScreen({super.key});

  @override
  State<AgentTraceScreen> createState() => _AgentTraceScreenState();
}

class _AgentTraceScreenState extends State<AgentTraceScreen> {
  int _simulatedStep = 0;
  Timer? _simTimer;
  final List<String> _simulatedLogs = [
    "Spinning up Antigravity sequential agent framework...",
    "A1: IntentAgent parsing raw natural language query...",
    "Detecting query language and parsing semantic entity...",
    "Resolving geo-spatial coordinates for requested area...",
    "A2: DiscoveryAgent executing matchmaking logic...",
    "Scoring G-13 Islamabad providers...",
    "Running multi-factor scoring (40% distance, 35% rating, 25% availability)...",
    "Finalizing ranking recommendations with Gemini Flash..."
  ];

  @override
  void initState() {
    super.initState();
    // Simulate real-time feedback typing log
    _simTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (_simulatedStep < _simulatedLogs.length - 1) {
        setState(() {
          _simulatedStep++;
        });
      } else {
        _simTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final agentProvider = Provider.of<AgentProvider>(context);
    final trace = agentProvider.trace;
    final isLoading = agentProvider.isLoading;
    final rawInput = agentProvider.rawInput;

    final showActualTrace = !isLoading && trace.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "AI Trace Logs",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            agentProvider.resetSearch();
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Title & Subtitle Info Panel
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFF4BDDB7), size: 22),
                      const SizedBox(width: 8),
                      Text(
                        isLoading ? "AI Processing Your Request" : "AI Routing Completed",
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isLoading
                        ? "Hang tight while we analyze and find the best pros for you."
                        : "Antigravity has successfully routed and scored candidates.",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // 2. "Your Request" Card (Italicized user input)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B2B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF39C12).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.psychology, color: Color(0xFFF39C12), size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "YOUR REQUEST",
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withOpacity(0.3),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            rawInput.isNotEmpty ? '"$rawInput"' : '"Service requested"',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 3. Middle: Vertical Timeline
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: showActualTrace
                    ? _buildActualTraceList(trace)
                    : _buildSimulatedLoadingView(),
              ),
            ),

            // 4. Bottom Action Block
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF0E1322),
                border: Border(top: BorderSide(color: Colors.white10, width: 0.8)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoading) ...[
                    const ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4BDDB7)),
                        minHeight: 5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Antigravity is executing reasoning loop...",
                      style: GoogleFonts.outfit(
                        color: Colors.white38,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ] else if (showActualTrace) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4BDDB7), // Glowing Teal
                          foregroundColor: const Color(0xFF00382B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/results');
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "See Results",
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.08),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Colors.white10),
                          ),
                        ),
                        onPressed: () {
                          agentProvider.resetSearch();
                          Navigator.pop(context);
                        },
                        child: Text(
                          "Reset and Try Again",
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulatedLoadingView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _simulatedStep + 1,
      itemBuilder: (context, idx) {
        final logText = _simulatedLogs[idx];
        final isLast = idx == _simulatedStep;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Custom Timeline Dot Column
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isLast
                          ? const Color(0xFF4BDDB7).withOpacity(0.12)
                          : const Color(0xFF7367F0), // Purple for completed steps
                      border: Border.all(
                        color: isLast ? const Color(0xFF4BDDB7) : const Color(0xFF7367F0),
                        width: 2,
                      ),
                    ),
                    child: isLast
                        ? const Center(
                            child: SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4BDDB7)),
                              ),
                            ),
                          )
                        : const Icon(Icons.check, size: 14, color: Colors.white),
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isLast ? Colors.white12 : const Color(0xFF7367F0).withOpacity(0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Description Box
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        logText,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isLast ? Colors.white : Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isLast ? "Active..." : "Completed",
                        style: TextStyle(
                          fontSize: 12,
                          color: isLast ? const Color(0xFF4BDDB7) : const Color(0xFF7367F0),
                          fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildActualTraceList(List<dynamic> trace) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: trace.length,
      itemBuilder: (context, idx) {
        final step = trace[idx];
        final stepName = step["step"] ?? "Agent";
        final toolCalled = step["tool_called"] ?? "API Tool";
        final inputSummary = step["input_summary"] ?? "";
        final outputSummary = step["output_summary"] ?? "";
        final latency = step["latency_ms"] ?? 0;
        final status = step["status"] ?? "success";

        final isSuccess = status == "success";
        final isLast = idx == trace.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Custom Purple Completed Stepper Icon
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF7367F0), // Purple for completed steps
                      border: Border.all(
                        color: const Color(0xFF7367F0),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      isSuccess ? Icons.check : Icons.warning_amber_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: const Color(0xFF7367F0).withOpacity(0.4),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Content Card
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B2B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              stepName,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "${latency}ms",
                                style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.4)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Tool: $toolCalled",
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFFF39C12),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Input Entity:",
                          style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.25), fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          inputSummary,
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Output Reasoning:",
                          style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.25), fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          outputSummary,
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
