import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_application/manager/auth_manager.dart';

import 'package:study_application/pages/auth/register_page.dart';
import 'package:study_application/pages/home_page.dart';
import 'package:study_application/utils/theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isBusy = false;
  String? errorText;

  // InputDecoration dùng chung cho textfield
  InputDecoration _decoration(String hint) => const InputDecoration(
        filled: true,
        fillColor: Color(0xFFF2F3F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ).copyWith(hintText: hint);

  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      isBusy = true;
      errorText = null;
    });
    try {
      await context
          .read<AuthManager>()
          .login(emailCtrl.text.trim(), passCtrl.text);
      if (!mounted) return;

      // Đi tới HomePage (hoặc pop nếu có AuthGate)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (_) => false,
      );
    } catch (e) {
      setState(() {
        errorText = '$e';
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorText!)));
    } finally {
      if (mounted) setState(() => isBusy = false);
    }
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppTheme.mainTeal;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                primaryColor.withOpacity(0.85),
                primaryColor.withOpacity(0.65),
              ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Back button
                Positioned(
                  left: 16,
                  top: 8,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white.withOpacity(0.25),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),

                // Logo chữ StudyTeach
                Positioned(
                  right: 125,
                  left: 125,
                  top: 40,
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(children: [
                      TextSpan(
                        text: 'Study',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      TextSpan(
                        text: 'Teach',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFFD44D),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ]),
                  ),
                ),

                Positioned(
                  left: 22,
                  top: 90,
                  child: IgnorePointer(
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),

                // Nội dung form chính
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 20),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.88,
                            constraints: const BoxConstraints(maxWidth: 420),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(28),
                                topRight: Radius.circular(80),
                                bottomLeft: Radius.circular(80),
                                bottomRight: Radius.circular(28),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                )
                              ],
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(22, 24, 22, 18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Welcome Back',
                                    style: TextStyle(
                                      color: Color(0xFF2A2F45),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Hello there, sign in to continue',
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13),
                                  ),
                                  const SizedBox(height: 18),

                                  // Email
                                  Row(
                                    children: const [
                                      Icon(Icons.mail_outline_outlined,
                                          size: 18, color: Color(0xFF6A7280)),
                                      SizedBox(width: 6),
                                      Text(
                                        'Email',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6A7280),
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: _decoration(
                                        'Enter your username or email'),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Email is required'
                                            : null,
                                  ),
                                  const SizedBox(height: 14),

                                  // Password
                                  Row(
                                    children: const [
                                      Icon(Icons.lock_outline,
                                          size: 18, color: Color(0xFF6A7280)),
                                      SizedBox(width: 6),
                                      Text(
                                        'Password',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6A7280),
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _PasswordField(
                                    controller: passCtrl,
                                    decoration: _decoration,
                                    onSubmitted: (_) => _submit(),
                                  ),
                                  const SizedBox(height: 10),

                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      style: TextButton.styleFrom(
                                        foregroundColor: primaryColor,
                                        padding: EdgeInsets.zero,
                                      ),
                                      onPressed: () {},
                                      child: const Text('Forgot Password?',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  _GradientButton(
                                    primaryColor: primaryColor,
                                    onTap: isBusy ? null : _submit,
                                    child: isBusy
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white),
                                          )
                                        : const Text(
                                            'Sign In',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(height: 14),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text("Don't have an account? ",
                                          style: TextStyle(
                                              color: Colors.grey.shade700)),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const RegisterPage()),
                                          );
                                        },
                                        child: Text(
                                          'Sign Up',
                                          style: TextStyle(
                                              color: primaryColor,
                                              fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                    ],
                                  ),

                                  if (errorText != null) ...[
                                    const SizedBox(height: 12),
                                    Text(errorText!,
                                        style:
                                            const TextStyle(color: Colors.red)),
                                  ],
                                ],
                              ),
                            ),
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

class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final InputDecoration Function(String hint) decoration;
  final ValueChanged<String>? onSubmitted;

  const _PasswordField({
    required this.controller,
    required this.decoration,
    this.onSubmitted,
  });

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      decoration: widget.decoration('Enter your password').copyWith(
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(_obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
            ),
          ),
      validator: (v) =>
          (v == null || v.isEmpty) ? 'Password is required' : null,
      onFieldSubmitted: widget.onSubmitted,
    );
  }
}

class _GradientButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final Color primaryColor;

  const _GradientButton({
    required this.onTap,
    required this.child,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          top: 10,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
            ),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primaryColor.withOpacity(0.9),
                    primaryColor.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: child),
            ),
          ),
        ),
      ],
    );
  }
}
