import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/post.dart';
import '../state/app_state.dart';
import '../theme/adaptive.dart';
import '../theme/colors.dart';
import '../widgets/project_banner.dart';
import 'new_post_screen.dart';
import 'post_detail_screen.dart';
import 'posts_submissions_view.dart';

/// "My Project" — the employee's daily-use dashboard: their one active
/// project banner, then Posts/Submissions tabs (Posts selected).
class ProjectHomeScreen extends ConsumerWidget {
  const ProjectHomeScreen({super.key});

  void _openPost(BuildContext context, Post post) {
    Navigator.of(context).push(
      Adaptive.isIOSNative
          ? CupertinoPageRoute(builder: (_) => PostDetailScreen(postId: post.id))
          : MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post.id)),
    );
  }

  void _addPost(BuildContext context, String projectId) {
    Navigator.of(context).push(
      Adaptive.isIOSNative
          ? CupertinoPageRoute(builder: (_) => NewPostScreen(projectId: projectId))
          : MaterialPageRoute(builder: (_) => NewPostScreen(projectId: projectId)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider)!;
    final project = ref.watch(projectForEmployeeProvider(user.id));

    if (project == null) {
      return const Center(child: Text('No project assigned yet.'));
    }

    final posts = currentBatchPosts(ref.watch(postsByProjectProvider(project.id)));
    final pending = posts.where((p) => p.status == PostStatus.pending).length;

    final body = PostsSubmissionsView(
      projectId: project.id,
      initialTab: 0,
      onOpenPost: (post) => _openPost(context, post),
    );

    if (Adaptive.isIOSNative) {
      return CupertinoPageScaffold(
        backgroundColor: AppColors.background,
        navigationBar: CupertinoNavigationBar(
          middle: const Text('My Project'),
          backgroundColor: AppColors.surface,
          border: const Border(bottom: BorderSide(color: AppColors.border)),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _addPost(context, project.id),
            child: const Icon(CupertinoIcons.add),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Project #${project.number} · ${project.title}',
                    style: Theme.of(context).textTheme.bodySmall),
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
        appBar: AppBar(
          title: const Text('My Project'),
          backgroundColor: AppColors.surface,
          elevation: 2,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _addPost(context, project.id),
          child: const Icon(Icons.add_rounded),
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Project #${project.number} · ${project.title}',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 14),
              Expanded(child: body),
            ],
          ),
        ),
      );
    }

    // Web/desktop.
    final search = TextField(
      decoration: const InputDecoration(hintText: 'Search posts', prefixIcon: Icon(Icons.search_rounded, size: 20)),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 520;
              final heading = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    narrow ? 'Hi, ${user.name.split(' ').first}' : 'Welcome back, ${user.name.split(' ').first}',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 4),
                  Text('You have $pending open posts this week.', style: Theme.of(context).textTheme.bodyMedium),
                ],
              );
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [heading, const SizedBox(height: 14), search],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: heading),
                  SizedBox(width: 240, child: search),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          ProjectBanner(project: project, postCount: posts.length, pendingCount: pending),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _addPost(context, project.id),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Post'),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: body),
        ],
      ),
    );
  }
}
