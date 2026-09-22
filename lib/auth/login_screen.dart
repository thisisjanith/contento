import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_state.dart';
import '../theme/adaptive.dart';
import '../theme/colors.dart';
import '../widgets/app_toast.dart';

/// Real Firebase Auth sign-in. No self-serve signup — accounts are
/// provisioned by an admin (Employees → Add Employee). Role is resolved
/// server-side from the signed-in user's `employees/{uid}` doc, not
/// chosen here — this screen only collects credentials.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      AppToast.show(context, 'Enter your email and password to continue.', isError: true);
      return;
    }
    setState(() => _submitting = true);
    final error = await ref.read(sessionProvider.notifier).signIn(email, password);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error != null) {
      AppToast.show(context, error, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= Adaptive.mobileBreakpoint;
          if (!wide) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _logo(dark: false),
                  const SizedBox(height: 28),
                  _formCard(),
                ],
              ),
            );
          }
          return Row(
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  color: AppColors.primary,
                  padding: const EdgeInsets.fromLTRB(56, 56, 56, 56),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _logo(dark: true),
                      const Spacer(),
                      const Text(
                        'Projects in, posts out.',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        "The internal workspace where Tappyly's content team writes, "
                        "reviews and schedules post copy — without ever seeing which "
                        "client it's for.",
                        style: TextStyle(fontFamily: 'IBM Plex Sans', fontSize: 15, color: Colors.white70, height: 1.5),
                      ),
                      const Spacer(),
                      const Text(
                        'Tappyly Technologies · Internal tool',
                        style: TextStyle(fontFamily: 'IBM Plex Sans', fontSize: 12.5, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 6,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(48),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: _formCard(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _logo({required bool dark}) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            border: Border.all(color: dark ? Colors.white : AppColors.primary, width: 1.6),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(Icons.circle, size: 14, color: dark ? Colors.white : AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text('Contento',
            style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: dark ? Colors.white : AppColors.textDark)),
      ],
    );
  }

  Widget _formCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sign in', style: Theme.of(context).textTheme.displayMedium),
        const SizedBox(height: 6),
        Text('Use your Tappyly email to continue.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        const Text('Email', style: TextStyle(fontFamily: 'IBM Plex Sans', fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'you@tappyly.com'),
        ),
        const SizedBox(height: 16),
        const Text('Password', style: TextStyle(fontFamily: 'IBM Plex Sans', fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: _passwordController,
          obscureText: true,
          onSubmitted: (_) => _signIn(),
          decoration: const InputDecoration(hintText: '••••••••••'),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitting ? null : _signIn,
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Sign in'),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Forgot your password? Contact your workspace admin.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
