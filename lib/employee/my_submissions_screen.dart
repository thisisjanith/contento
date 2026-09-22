import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/post.dart';
import '../state/app_state.dart';
import '../theme/adaptive.dart';
import '../theme/colors.dart';
import 'post_detail_screen.dart';
import 'posts_submissions_view.dart';

/// "My Submissions" — history of everything the employee has turned in,
/// with status and, for anything sent back, feedback inline plus a
/// "Revise" shortcut into the post.
class MySubmissionsScreen extends ConsumerWidget {
  const MySubmissionsScreen({super.key});

  void _openPost(BuildContext context, Post post) {
    Navigator.of(context).push(
      Adaptive.isIOSNative
          ? CupertinoPageRoute(builder: (_) => PostDetailScreen(postId: post.id))
          : MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post.id)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider)!;
    final project = ref.watch(projectForEmployeeProvider(user.id));

    if (project == null) {
      return const Center(child: Text('No project assigned yet.'));
    }

    final body = PostsSubmissionsView(
      projectId: project.id,
      initialTab: 1,
      onOpenPost: (post) => _openPost(context, post),
    );

    if (Adaptive.isIOSNative) {
      return CupertinoPageScaffold(
        backgroundColor: AppColors.background,
        navigationBar: const CupertinoNavigationBar(
          middle: Text('My Submissions'),
          backgroundColor: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Project #${project.number} · ${project.title}', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                Expanded(child: body),
              ],
            ),
          ),
        ),
      );
    }

    if (Adaptive.isAndroidNative) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('My Submissions'), backgroundColor: AppColors.surface, elevation: 2),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Project #${project.number} · ${project.title}', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 14),
              Expanded(child: body),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Submissions', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 4),
          Text('Every post you\'ve turned in under ${project.displayTitle}, and its review status.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          Expanded(child: body),
        ],
      ),
    );
  }
}
