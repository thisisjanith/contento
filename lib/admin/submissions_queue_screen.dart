import 'package:flutter/material.dart';

import 'submissions_queue.dart';

/// Standalone "Submissions Queue" page — the same review queue embedded
/// in Overview, given its own destination with the sidebar filters front
/// and center (no stat cards competing for space).
class SubmissionsQueueScreen extends StatelessWidget {
  const SubmissionsQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Submissions Queue', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 4),
          Text('Every submission awaiting or past review, across all employees.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          const Expanded(child: SubmissionsQueue()),
        ],
      ),
    );
  }
}
