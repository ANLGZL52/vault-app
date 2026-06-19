import 'package:flutter/material.dart';

import '../core/auth_error.dart';
import '../core/validators.dart';
import '../legal/legal_texts.dart';
import '../services/auth_service.dart';
import '../widgets/auth/auth_scaffold.dart';
import '../widgets/auth/auth_text_field.dart';
import '../widgets/auth/primary_auth_button.dart';
import '../widgets/auth/vault_logo.dart';
import '../widgets/legal/legal_text_dialog.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({required this.authService, super.key});

  final AuthService authService;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralCodeController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedLegalTexts = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_acceptedLegalTexts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Devam etmek için sözleşmeleri kabul etmelisin.'),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final referralWarning = await widget.authService.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        referralCode: _referralCodeController.text,
      );
      if (!mounted) return;
      if (referralWarning != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(referralWarning)));
      }
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const VaultLogo(compact: true),
            const SizedBox(height: 28),
            Text(
              'Create account',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start building your personal insight vault.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: const Color(0xFFADB3C2),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 26),
            AuthTextField(
              controller: _nameController,
              label: 'Name',
              icon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: (value) => Validators.required(value, 'Name'),
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              validator: Validators.password,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              icon: Icons.verified_user_outlined,
              obscureText: _obscureConfirmPassword,
              validator: (value) =>
                  Validators.confirmPassword(value, _passwordController.text),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  );
                },
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _referralCodeController,
              label: 'Referans kodu',
              hintText: 'Varsa referans kodunu gir',
              icon: Icons.ios_share_rounded,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 18),
            _LegalAcceptanceTile(
              value: _acceptedLegalTexts,
              onChanged: _isLoading
                  ? null
                  : (value) {
                      setState(() => _acceptedLegalTexts = value ?? false);
                    },
            ),
            const SizedBox(height: 24),
            PrimaryAuthButton(
              label: 'Register',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account?',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Login'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalAcceptanceTile extends StatelessWidget {
  const _LegalAcceptanceTile({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFFFC857),
            checkColor: const Color(0xFF05070D),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 9),
              child: Wrap(
                children: [
                  Text(
                    'Gizlilik Sözleşmesi',
                    style: _linkStyle(context),
                  )._asTapTarget(
                    onTap: () => showLegalTextDialog(
                      context: context,
                      title: 'Gizlilik Sözleşmesi',
                      content: privacyPolicyText,
                    ),
                  ),
                  Text("'ni ve ", style: _bodyStyle(context)),
                  Text(
                    'Kullanıcı Sözleşmesi',
                    style: _linkStyle(context),
                  )._asTapTarget(
                    onTap: () => showLegalTextDialog(
                      context: context,
                      title: 'Kullanıcı Sözleşmesi',
                      content: termsOfUseText,
                    ),
                  ),
                  Text(
                    "'ni okudum, kabul ediyorum.",
                    style: _bodyStyle(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _bodyStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFFADB3C2),
          height: 1.35,
        ) ??
        const TextStyle(color: Color(0xFFADB3C2), height: 1.35);
  }

  TextStyle _linkStyle(BuildContext context) {
    return _bodyStyle(context).copyWith(
      color: const Color(0xFFFFC857),
      fontWeight: FontWeight.w800,
      decoration: TextDecoration.underline,
      decorationColor: const Color(0xFFFFC857),
    );
  }
}

extension on Text {
  Widget _asTapTarget({required VoidCallback onTap}) {
    return GestureDetector(onTap: onTap, child: this);
  }
}
