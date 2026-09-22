import 'package:flutter/material.dart';

import '../models/project.dart';
import '../theme/colors.dart';

/// "YOUR ACTIVE PROJECT" card shown at the top of My Project on web.
class ProjectBanner extends StatelessWidget {
  final Project project;
  final int postCount;
  final int pendingCount;

  const ProjectBanner({
    super.key,
    required this.project,
    required this.postCount,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    final icon = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.dashboard_customize_rounded, color: AppColors.primary, size: 22),
    );
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('YOUR ACTIVE PROJECT', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.primary)),
        const SizedBox(height: 4),
        Text(project.displayTitle, style: Theme.of(context).textTheme.headlineMedium),
      ],
    );
    final count = Text('$postCount posts · $pendingCount pending', style: Theme.of(context).textTheme.bodySmall);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 460) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [icon, const SizedBox(width: 16), Expanded(child: title)]),
                const SizedBox(height: 12),
                count,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 16),
              Expanded(child: title),
              const SizedBox(width: 12),
              count,
            ],
          );
        },
      ),
    );
  }
}
