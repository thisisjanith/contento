import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/post.dart';
import '../theme/adaptive.dart';
import '../theme/colors.dart';
import 'status_badge.dart';

final _dueFormat = DateFormat('MMM d');

/// One shared post-row/card component, rendered with per-platform chrome:
/// iOS grouped-list row, Android elevated card, web/desktop card.
class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;

  const PostCard({super.key, required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (Adaptive.isIOSNative) return _iosRow(context);
    if (Adaptive.isAndroidNative) return _androidCard(context);
    return _webCard(context);
  }

  Widget _iosRow(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.displayTitle,
                      style: const TextStyle(
                          fontFamily: 'IBM Plex Sans',
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  Text('Due ${_dueFormat.format(post.dueDate)}',
                      style: const TextStyle(
                          fontFamily: 'IBM Plex Sans', fontSize: 12.5, color: AppColors.textMuted)),
                ],
              ),
            ),
            StatusBadge(status: post.status, dense: true),
            const SizedBox(width: 6),
            const Icon(CupertinoIcons.chevron_right, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _androidCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: post.status == PostStatus.needsRevision
            ? const BorderSide(color: AppColors.accent, width: 1)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.displayTitle,
                        style: const TextStyle(
                            fontFamily: 'IBM Plex Sans', fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 6),
                    Text('Due ${_dueFormat.format(post.dueDate)}',
                        style: const TextStyle(
                            fontFamily: 'IBM Plex Sans', fontSize: 12.5, color: AppColors.textMuted)),
                  ],
                ),
              ),
              StatusBadge(status: post.status, uppercase: true, dense: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _webCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: post.status == PostStatus.needsRevision ? AppColors.accent.withValues(alpha: 0.4) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusBadge(status: post.status),
                const SizedBox(height: 8),
                Text(post.displayTitle, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (post.hasBrief) ...[
                      const Icon(Icons.link_rounded, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text('Source brief attached', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(width: 14),
                    ],
                    const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text('Due ${_dueFormat.format(post.dueDate)}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: post.status == PostStatus.needsRevision ? Colors.white : AppColors.textDark,
              backgroundColor: post.status == PostStatus.needsRevision ? AppColors.accent : Colors.transparent,
              side: BorderSide(color: post.status == PostStatus.needsRevision ? AppColors.accent : AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            child: Text(post.status.actionLabel),
          ),
        ],
      ),
    );
  }
}
