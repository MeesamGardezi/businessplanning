import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String email = '';
  String password = '';
  String confirmPassword = '';
  String error = '';
  bool isPasswordStep = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_emailFocusNode);
    });
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _moveToPasswordStep() {
    setState(() {
      isPasswordStep = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_passwordFocusNode);
    });
  }

  bool _isPasswordValid(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;
    return true;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter a password';
    }
    if (!_isPasswordValid(value)) {
      return '''Password must contain:
• At least 8 characters
• Uppercase and lowercase letters
• Numbers
• Special characters''';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _submitRegistration() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
        error = '';
      });

      Map<String, dynamic> result =
          await _auth.registerWithEmailAndPassword(email, password);

      setState(() {
        isLoading = false;
      });

      if (result['success']) {
        if (mounted) {
          context.go('/complete-profile', extra: result['userId']);
        }
      } else {
        setState(() => error = result['message']);
      }
    }
  }

  void _handleEnterKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter) {
      if (!isPasswordStep) {
        if (_formKey.currentState!.validate()) {
          _moveToPasswordStep();
        }
      } else {
        _submitRegistration();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: _handleEnterKey,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.teal.shade50,
                Colors.grey.shade50,
              ],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // _buildLogo(),
                    // const SizedBox(height: 40),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildRegisterCard(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildLogo() {
  //   return Column(
  //     children: [
  //       Container(
  //         padding: const EdgeInsets.all(16),
  //         decoration: BoxDecoration(
  //           color: Colors.white,
  //           borderRadius: BorderRadius.circular(20),
  //           boxShadow: [
  //             BoxShadow(
  //               color: Colors.teal.shade200.withOpacity(0.3),
  //               blurRadius: 20,
  //               offset: const Offset(0, 4),
  //             ),
  //           ],
  //         ),
  //         child: Icon(
  //           Icons.analytics_outlined,
  //           size: 40,
  //           color: Colors.teal.shade700,
  //         ),
  //       ),
  //       const SizedBox(height: 16),
  //       Text(
  //         'Stratwise',
  //         style: Theme.of(context).textTheme.headlineMedium?.copyWith(
  //           color: Colors.teal.shade700,
  //           fontWeight: FontWeight.bold,
  //           letterSpacing: -0.5,
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildRegisterCard() {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!kIsWeb && (isPasswordStep)) _buildBackButton(),
            Text(
              isPasswordStep ? 'Create a password' : 'Create your account',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              isPasswordStep
                  ? 'Choose a secure password for your account'
                  : 'Start planning your business strategy',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),
            _buildFormFields(),
            const SizedBox(height: 24),
            if (!isPasswordStep) _buildLoginLink(),
            const SizedBox(height: 24),
            _buildActionButton(),
            if (error.isNotEmpty) _buildErrorMessage(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.grey[700]),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: isPasswordStep
            ? () {
                setState(() {
                  isPasswordStep = false;
                  _emailFocusNode.requestFocus();
                });
              }
            : () => context.go('/login'),
      ),
    );
  }

  Widget _buildFormFields() {
    if (!isPasswordStep) {
      return TextFormField(
        focusNode: _emailFocusNode,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Email',
          hintText: 'Enter your business email',
          prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.teal.shade700, width: 2),
          ),
        ),
        validator: (val) => val!.isEmpty ? 'Enter an email' : null,
        onChanged: (val) => setState(() => email = val),
        onFieldSubmitted: (_) => _moveToPasswordStep(),
      );
    } else {
      return Column(
        children: [
          TextFormField(
            focusNode: _passwordFocusNode,
            autofocus: true,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Create a strong password',
              prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.teal.shade700, width: 2),
              ),
            ),
            validator: _validatePassword,
            onChanged: (val) => setState(() => password = val),
            onFieldSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_confirmPasswordFocusNode),
          ),
          const SizedBox(height: 16),
          TextFormField(
            focusNode: _confirmPasswordFocusNode,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              hintText: 'Confirm your password',
              prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.teal.shade700, width: 2),
              ),
            ),
            validator: _validateConfirmPassword,
            onChanged: (val) => setState(() => confirmPassword = val),
            onFieldSubmitted: (_) => _submitRegistration(),
          ),
        ],
      );
    }
  }

  Widget _buildLoginLink() {
    return Align(
      alignment: Alignment.centerLeft,
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          children: [
            const TextSpan(text: 'Already have an account? '),
            TextSpan(
              text: 'Sign in',
              style: TextStyle(
                color: Colors.teal.shade700,
                fontWeight: FontWeight.w600,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => context.go('/login'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade700),
              ),
            )
          : ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  if (!isPasswordStep) {
                    _moveToPasswordStep();
                  } else {
                    _submitRegistration();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isPasswordStep ? 'Create account' : 'Continue',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }

  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[100]!),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 20, color: Colors.red[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error,
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
