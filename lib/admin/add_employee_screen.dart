import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/employee.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import '../widgets/app_toast.dart';

/// Admin-side employee provisioning — accounts aren't self-serve (per the
/// brief), so this is how new employee/admin accounts get created.
class AddEmployeeScreen extends ConsumerStatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  ConsumerState<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends ConsumerState<AddEmployeeScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _role = UserRole.employee;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (name.isEmpty || email.isEmpty) {
      AppToast.show(context, 'Add a name and email first.', isError: true);
      return;
    }
    if (password.length < 6) {
      AppToast.show(context, 'Set a temporary password of at least 6 characters.', isError: true);
      return;
    }
    setState(() => _submitting = true);
    try {
      final employee = await ref
          .read(employeesProvider.notifier)
          .addEmployee(name: name, email: email, password: password, role: _role);
      if (!mounted) return;
      AppToast.show(context, 'Account created — ${employee.name}');
      Navigator.of(context).maybePop();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      AppToast.show(context, e.message ?? 'Could not create that account.', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Back to Employees'),
              style: TextButton.styleFrom(foregroundColor: AppColors.textMuted, padding: EdgeInsets.zero),
            ),
            const SizedBox(height: 12),
            Text('New Employee', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 4),
            Text('Accounts are provisioned by an admin — there is no self-serve signup.', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Full name', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    TextField(controller: _nameController, decoration: const InputDecoration(hintText: 'e.g. Priya Fernando')),
                    const SizedBox(height: 18),
                    Text('Email', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'you@tappyly.com')),
                    const SizedBox(height: 18),
                    Text('Temporary password', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(hintText: 'At least 6 characters')),
                    const SizedBox(height: 4),
                    Text("They can sign in with this right away — there's no separate invite step.", style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 18),
                    Text('Role', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _roleToggle(),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: _submitting ? null : _create,
                          child: _submitting
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Create account'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Expanded(child: _roleButton('Employee', UserRole.employee)),
          Expanded(child: _roleButton('Admin', UserRole.admin)),
        ],
      ),
    );
  }

  Widget _roleButton(String label, UserRole role) {
    final selected = _role == role;
    return GestureDetector(
      onTap: () => setState(() => _role = role),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)] : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
            color: selected ? AppColors.primary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
