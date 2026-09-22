import 'package:flutter/material.dart';

import '../models/post.dart';
import '../theme/colors.dart';

/// The one shared status-color pill, used on every screen on every
/// platform. Never reimplement status colors/labels elsewhere.
class StatusBadge extends StatelessWidget {
  final PostStatus status;
  final bool dense;
  final bool uppercase;

  const StatusBadge({
    super.key,
    required this.status,
    this.dense = false,
    this.uppercase = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.statusColor(status);
    final bg = AppColors.statusBackground(status);
    final label = uppercase ? status.label.toUpperCase() : status.label;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'IBM Plex Sans',
              fontSize: dense ? 10.5 : 12,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: uppercase ? 0.4 : 0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small filled dot only — used in dense calendar cells.
class StatusDot extends StatelessWidget {
  final PostStatus status;
  final double size;

  const StatusDot({super.key, required this.status, this.size = 7});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.statusColor(status),
        shape: BoxShape.circle,
      ),
    );
  }
}
