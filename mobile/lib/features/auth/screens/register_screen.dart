import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref
        .read(authProvider.notifier)
        .register(
          _emailCtrl.text.trim(),
          _passCtrl.text,
          _confirmCtrl.text,
          null,
        );

    if (success && mounted) context.go('/');
  }

  Future<void> _signInWithGoogle() async {
    final success = await ref.read(authProvider.notifier).loginWithGoogle();
    if (success && mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 8),
              child: Text(
                'Carlina',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      // ── Logo / header ──────────────────────────────
                      Image.asset('assets/logo.png', width: 142, height: 142),
                      const SizedBox(height: 8),
                      Text(
                        'Create your account',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 30),

                      // ── Form ───────────────────────────────────────
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => v != null && v.contains('@')
                                  ? null
                                  : 'Enter a valid email',
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passCtrl,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePass
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePass = !_obscurePass,
                                  ),
                                ),
                              ),
                              obscureText: _obscurePass,
                              validator: (v) => v != null && v.length >= 8
                                  ? null
                                  : 'Minimum 8 characters',
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmCtrl,
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm,
                                  ),
                                ),
                              ),
                              obscureText: _obscureConfirm,
                              validator: (v) => v == _passCtrl.text
                                  ? null
                                  : 'Passwords do not match',
                            ),
                            const SizedBox(height: 8),

                            // ── Error ──────────────────────────────
                            if (authState.error != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  authState.error!,
                                  style: TextStyle(color: cs.error),
                                ),
                              ),

                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: authState.isLoading ? null : _submit,
                              child: authState.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Create Account'),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    'or',
                                    style: TextStyle(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: authState.isLoading
                                    ? null
                                    : _signInWithGoogle,
                                icon: const Text(
                                  'G',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                label: const Text('Continue with Google'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Already have an account? Sign in'),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
