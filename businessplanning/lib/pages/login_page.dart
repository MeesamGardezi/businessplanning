import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  final String? redirectUrl;

  const LoginPage({Key? key, this.redirectUrl}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _newPasswordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String error = '';
  bool isPasswordStep = false;
  bool isNewPasswordSetup = false;
  bool isLoading = false;
  bool isEmailValid = true;

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
    _emailController.dispose();
    _passwordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkEmailAndProceed() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
        error = '';
        isEmailValid = true;
      });

      bool emailExists = await _auth.checkEmailExists(_emailController.text);

      setState(() {
        isLoading = false;
      });

      if (emailExists) {
        _moveToPasswordStep();
      } else {
        setState(() {
          isEmailValid = false;
        });
        _emailFocusNode.requestFocus();
      }
    }
  }

  void _moveToPasswordStep() {
    setState(() {
      isPasswordStep = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_passwordFocusNode);
    });
  }

  Future<void> _submitLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
        error = '';
      });

      Map<String, dynamic> result = await _auth.signInWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
      );

      setState(() {
        isLoading = false;
      });

      if (result['success']) {
        if (widget.redirectUrl != null && widget.redirectUrl!.isNotEmpty) {
          context.go(Uri.decodeComponent(widget.redirectUrl!));
        } else {
          context.go('/dashboard');
        }
      } else if (result['needsPasswordSetup'] == true) {
        _moveToNewPasswordSetup();
      } else {
        setState(() => error = result['message'] ?? 'Invalid email or password');
      }
    }
  }

  void _moveToNewPasswordSetup() {
    setState(() {
      isNewPasswordSetup = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_newPasswordFocusNode);
    });
  }

  Future<void> _submitNewPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
        error = '';
      });

      bool result = await _auth.setEmployeePassword(
        _emailController.text,
        _newPasswordController.text,
      );

      setState(() {
        isLoading = false;
      });

      if (result) {
        Map<String, dynamic> loginResult = await _auth.signInWithEmailAndPassword(
          _emailController.text,
          _newPasswordController.text,
        );

        if (loginResult['success']) {
          context.go('/dashboard');
        } else {
          setState(() => error = 'Failed to log in with new password');
        }
      } else {
        setState(() => error = 'Failed to set new password');
      }
    }
  }

  void _handleEnterKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent && 
        event.logicalKey == LogicalKeyboardKey.enter) {
      if (!isPasswordStep) {
        _checkEmailAndProceed();
      } else if (!isNewPasswordSetup) {
        _submitLogin();
      } else {
        _submitNewPassword();
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
                      child: _buildLoginCard(),
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

  Widget _buildLoginCard() {
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
            if (!kIsWeb && (isPasswordStep || isNewPasswordSetup))
              _buildBackButton(),
            Text(
              isNewPasswordSetup
                ? 'Set New Password'
                : (isPasswordStep ? 'Welcome Back' : 'Sign in to Stratwise'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isNewPasswordSetup
                ? 'Create a secure password for your account'
                : (isPasswordStep 
                    ? 'Enter your password to continue'
                    : 'Enter your email to get started'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            _buildFormFields(),
            const SizedBox(height: 24),
            if (!isNewPasswordSetup)
              _buildCreateAccountLink(),
            const SizedBox(height: 24),
            _buildActionButton(),
            if (error.isNotEmpty)
              _buildErrorMessage(),
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
        onPressed: () {
          setState(() {
            if (isNewPasswordSetup) {
              isNewPasswordSetup = false;
            } else {
              isPasswordStep = false;
              _emailFocusNode.requestFocus();
            }
          });
        },
      ),
    );
  }

  Widget _buildFormFields() {
    if (!isPasswordStep) {
      return TextFormField(
        controller: _emailController,
        focusNode: _emailFocusNode,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Email',
          hintText: 'Enter your email',
          prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[600]),
          errorText: !isEmailValid ? 'No account found with this email' : null,
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
        onChanged: (val) => setState(() => isEmailValid = true),
        onFieldSubmitted: (_) => _checkEmailAndProceed(),
      );
    } else if (!isNewPasswordSetup) {
      return TextFormField(
        controller: _passwordController,
        focusNode: _passwordFocusNode,
        autofocus: true,
        obscureText: true,
        decoration: InputDecoration(
          labelText: 'Password',
          hintText: 'Enter your password',
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
        validator: (val) => val!.isEmpty ? 'Enter a password' : null,
        onFieldSubmitted: (_) => _submitLogin(),
      );
    } else {
      return Column(
        children: [
          TextFormField(
            controller: _newPasswordController,
            focusNode: _newPasswordFocusNode,
            autofocus: true,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'New Password',
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
            validator: (val) => val!.isEmpty ? 'Enter a new password' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
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
            validator: (val) {
              if (val!.isEmpty) return 'Confirm your new password';
              if (val != _newPasswordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            onFieldSubmitted: (_) => _submitNewPassword(),
          ),
        ],
      );
    }
  }

  Widget _buildCreateAccountLink() {
    return Align(
      alignment: Alignment.centerLeft,
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          children: [
            const TextSpan(text: 'No account? '),
            TextSpan(
              text: 'Create one',
              style: TextStyle(
                color: Colors.teal.shade700,
                fontWeight: FontWeight.w600,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => context.go('/register'),
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
              if (!isPasswordStep) {
                _checkEmailAndProceed();
              } else if (!isNewPasswordSetup) {
                _submitLogin();
              } else {
                _submitNewPassword();
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
              isNewPasswordSetup
                ? 'Set Password'
                : (isPasswordStep ? 'Sign in' : 'Continue'),
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