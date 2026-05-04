import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/brand_header.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref
        .read(authProvider.notifier)
        .login(_emailCtrl.text.trim(), _passCtrl.text);

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
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BrandHeader(subtitle: 'Welcome back — sign in to continue'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  children: [
                    Image.asset('assets/logo.png', width: 110, height: 110),
                    const SizedBox(height: 20),
                    Text(
                      'Sign in',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 24),
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
                          const SizedBox(height: 20),
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
                          if (authState.error != null) ...[
                            const SizedBox(height: 16),
                            _ErrorBanner(message: authState.error!),
                          ],
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: authState.isLoading ? null : _submit,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: authState.isLoading
                                  ? const SizedBox(
                                      key: ValueKey('loading'),
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Sign In',
                                      key: ValueKey('label'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Divider(color: cs.outlineVariant),
                              ),
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
                              Expanded(
                                child: Divider(color: cs.outlineVariant),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          OutlinedButton.icon(
                            onPressed: authState.isLoading
                                ? null
                                : _signInWithGoogle,
                            icon: const Icon(
                              Icons.g_mobiledata_rounded,
                              size: 28,
                              color: Color(0xFFDB4437),
                            ),
                            label: const Text(
                              'Continue with Google',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/register'),
                          child: Text(
                            'Register',
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: cs.onErrorContainer, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: cs.onErrorContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
