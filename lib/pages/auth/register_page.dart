import 'package:flutter/material.dart';
import 'package:study_application/pages/auth/login_page.dart';
import 'package:study_application/utils/theme.dart'; // theme chung

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

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
                    text: const TextSpan(
                      children: [
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
                      ],
                    ),
                  ),
                ),

                Positioned(
                  left: 22,
                  top: 90,
                  child: IgnorePointer(
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),

                // Nội dung form chính
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 20),
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
                            padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    color: Color(0xFF2A2F45),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Fill the form to get started',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
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
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  keyboardType: TextInputType.emailAddress,
                                  decoration:
                                      _decoration('Enter your email address'),
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
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _PasswordField(decoration: _decoration),
                                const SizedBox(height: 14),

                                // Confirm Password
                                Row(
                                  children: const [
                                    Icon(Icons.lock_reset_outlined,
                                        size: 18, color: Color(0xFF6A7280)),
                                    SizedBox(width: 6),
                                    Text(
                                      'Confirm Password',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6A7280),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _PasswordField(decoration: _decoration),
                                const SizedBox(height: 18),

                                _GradientButton(
                                  primaryColor: primaryColor,
                                  onTap: () {
                                    // TODO: gọi hàm đăng ký
                                  },
                                  child: const Text(
                                    'Sign Up',
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
                                    Text(
                                      "Already have an account? ",
                                      style: TextStyle(
                                          color: Colors.grey.shade700),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const LoginPage()),
                                        );
                                      },
                                      child: Text(
                                        'Sign In',
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
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
  final InputDecoration Function(String hint) decoration;
  const _PasswordField({required this.decoration});

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: _obscure,
      decoration: widget.decoration('Enter your password').copyWith(
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final VoidCallback onTap;
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
