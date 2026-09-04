import 'package:flutter/material.dart';
import 'cv_api_service.dart';

class ResultsScreen extends StatelessWidget {
  final AnalysisResult result;

  const ResultsScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Analysis Report'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ATS Score Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'ATS Match Score',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${result.atsScore.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _getScoreColor(result.atsScore),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text('Role: ${result.predictedCategory}'),
                      backgroundColor:
                          theme.colorScheme.primary.withOpacity(0.1),
                      labelStyle: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Matched Skills
              _buildSectionCard(
                title: 'Matched Skills',
                icon: Icons.check_circle_outline,
                iconColor: Colors.green,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: result.matchedSkills
                        .map((skill) => Chip(
                              label: Text(skill),
                              backgroundColor: Colors.green[50],
                              side: BorderSide(color: Colors.green[200]!),
                            ))
                        .toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Missing Skills
              _buildSectionCard(
                title: 'Missing Skills',
                icon: Icons.warning_amber_rounded,
                iconColor: Colors.orange,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: result.missingSkills
                        .map((skill) => Chip(
                              label: Text(skill),
                              backgroundColor: Colors.orange[50],
                              side: BorderSide(color: Colors.orange[200]!),
                            ))
                        .toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Actionable Recommendations
              _buildSectionCard(
                title: 'Recommendations',
                icon: Icons.lightbulb_outline_rounded,
                iconColor: Colors.blue,
                children: result.recommendations
                    .map(
                      (rec) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(
                                child: Text(rec,
                                    style: const TextStyle(height: 1.3))),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 70) return Colors.green;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
