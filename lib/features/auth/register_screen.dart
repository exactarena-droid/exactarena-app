import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/result.dart';
import '../../data/auth_controller.dart';
import '../../theme/terrace_theme.dart';
import '../../theme/terrace_tokens.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _otp = TextEditingController();
  Map<String, List<String>>? _fieldErrors;
  String? _error;
  bool _codeSent = false;
  bool _sendingCode = false;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Enter your email first.');
      return;
    }
    setState(() {
      _sendingCode = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).requestOtp(email: email, purpose: 'register');
      if (mounted) {
        setState(() => _codeSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('We sent a 6-digit code to your email.')),
        );
      }
    } on AppFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _sendingCode = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _error = null;
      _fieldErrors = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).register(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            otp: _otp.text.trim(),
            username: _username.text.trim().isEmpty ? null : _username.text.trim(),
          );
      if (mounted) context.pop();
    } on AppFailure catch (e) {
      setState(() {
        _error = e.isValidation ? null : e.message;
        _fieldErrors = e.fieldErrors;
      });
    }
  }

  String? _serverError(String field) => _fieldErrors?[field]?.first;

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    final loading = ref.watch(authControllerProvider).isLoading;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Join Terrace', style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 6),
                Text('Create a free account to follow, react and post.',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 28),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: t.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(TerraceRadii.md),
                    ),
                    child: Text(_error!, style: TextStyle(color: t.danger)),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    prefixIcon: const Icon(LucideIcons.user, size: 20),
                    errorText: _serverError('name'),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _username,
                  decoration: InputDecoration(
                    labelText: 'Username (optional)',
                    prefixIcon: const Icon(LucideIcons.atSign, size: 20),
                    errorText: _serverError('username'),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(LucideIcons.mail, size: 20),
                    errorText: _serverError('email'),
                  ),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(LucideIcons.lock, size: 20),
                    errorText: _serverError('password'),
                  ),
                  validator: (v) => (v == null || v.length < 8) ? 'At least 8 characters' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _otp,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          labelText: 'Verification code',
                          counterText: '',
                          prefixIcon: const Icon(LucideIcons.shieldCheck, size: 20),
                          errorText: _serverError('otp'),
                        ),
                        validator: (v) => (v == null || v.trim().length != 6) ? 'Enter the 6-digit code' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: OutlinedButton(
                        onPressed: _sendingCode ? null : _sendCode,
                        child: _sendingCode
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(_codeSent ? 'Resend' : 'Send code'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: loading ? null : _submit,
                  child: loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Create account'),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => context.pushReplacement('/login'),
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium,
                        children: [
                          const TextSpan(text: 'Already have an account? '),
                          TextSpan(
                            text: 'Sign in',
                            style: TextStyle(color: t.brand, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
