import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_state.dart';
import '../theme/adaptive.dart';
import '../theme/colors.dart';

/// Profile tab — native (iOS/Android) 4th bottom-tab destination, holds
/// account info and sign out.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider)!;
    final body = Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primary,
                child: Text(user.initials, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: Theme.of(context).textTheme.headlineMedium),
                  Text(user.email, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          if (Adaptive.isIOSNative)
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: AppColors.background,
                onPressed: () => ref.read(sessionProvider.notifier).signOut(),
                child: const Text('Sign out', style: TextStyle(color: AppColors.accent)),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => ref.read(sessionProvider.notifier).signOut(),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('SIGN OUT'),
              ),
            ),
        ],
      ),
    );

    if (Adaptive.isIOSNative) {
      return CupertinoPageScaffold(
        backgroundColor: AppColors.background,
        navigationBar: const CupertinoNavigationBar(middle: Text('Profile'), backgroundColor: AppColors.surface),
        child: SafeArea(child: body),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile'), backgroundColor: AppColors.surface, elevation: 2),
      body: body,
    );
  }
}
