// lib/pages/register_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../state/app_state.dart';
import '../theme.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Access global app state
  final AppState _appState = AppState();
  final AuthService _auth = AuthService();

  // Form keys and controllers
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Focus nodes
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  // Local state as ValueNotifiers
  final ValueNotifier<bool> _isPasswordStep = ValueNotifier<bool>(false);
  final ValueNotifier<String> _email = ValueNotifier<String>('');
  final ValueNotifier<String> _password = ValueNotifier<String>('');
  final ValueNotifier<String> _confirmPassword = ValueNotifier<String>('');
  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<String?> _errorMessage = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();

    // Set up controller listeners
    _emailController.addListener(() {
      _email.value = _emailController.text;
    });

    _passwordController.addListener(() {
      _password.value = _passwordController.text;
    });

    _confirmPasswordController.addListener(() {
      _confirmPassword.value = _confirmPasswordController.text;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_emailFocusNode);
      }
    });
  }

  @override
  void dispose() {
    // Dispose controllers
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    // Dispose focus nodes
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();

    // Dispose ValueNotifiers
    _isPasswordStep.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _isLoading.dispose();
    _errorMessage.dispose();

    super.dispose();
  }

  void _moveToPasswordStep() {
    if (!mounted) return;

    if (_formKey.currentState!.validate()) {
      _isPasswordStep.value = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          FocusScope.of(context).requestFocus(_passwordFocusNode);
        }
      });
    }
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
    if (value != _password.value) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _submitRegistration() async {
    if (!mounted) return;

    if (_formKey.currentState!.validate()) {
      _isLoading.value = true;
      _errorMessage.value = null;

      try {
        final result = await _auth.registerWithEmailAndPassword(
            _email.value, _password.value);

        if (!mounted) return;

        if (result['success']) {
          // Get the user ID from the result
          final userId = result['userId'] as String?;

          if (userId != null && userId.isNotEmpty) {
            // Navigate with userId as a route parameter
            context.go('/complete-profile/$userId');
          } else {
            // Fallback - navigate without the userId
            context.go('/complete-profile');
          }
        } else {
          _errorMessage.value = result['message'] ?? 'Registration failed';
        }
      } catch (e) {
        if (mounted) {
          _errorMessage.value = e.toString();
        }
      } finally {
        if (mounted) {
          _isLoading.value = false;
        }
      }
    }
  }

  void _handleEnterKey(RawKeyEvent event) {
    if (!mounted) return;

    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter) {
      if (!_isPasswordStep.value) {
        _moveToPasswordStep();
      } else {
        _submitRegistration();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                padding: const EdgeInsets.all(AppTheme.spaceLG),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedOpacity(
                      opacity: 1.0,
                      duration: Duration.zero,
                      child: _buildRegisterCard(theme),
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

  Widget _buildRegisterCard(ThemeData theme) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(AppTheme.spaceXL),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: theme.isDarkMode
            ? AppTheme.shadowMediumDark
            : AppTheme.shadowMedium,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: _isPasswordStep,
              builder: (context, isPasswordStep, _) {
                if (!kIsWeb && isPasswordStep) {
                  return _buildBackButton(theme);
                }
                return const SizedBox.shrink();
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _isPasswordStep,
              builder: (context, isPasswordStep, _) {
                return Text(
                  isPasswordStep ? 'Create a password' : 'Create your account',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimaryColor,
                  ),
                );
              },
            ),
            const SizedBox(height: AppTheme.spaceSM),
            ValueListenableBuilder<bool>(
              valueListenable: _isPasswordStep,
              builder: (context, isPasswordStep, _) {
                return Text(
                  isPasswordStep
                      ? 'Choose a secure password for your account'
                      : 'Start planning your business strategy',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.textSecondaryColor,
                  ),
                );
              },
            ),
            const SizedBox(height: AppTheme.spaceXL),
            _buildFormFields(theme),
            const SizedBox(height: AppTheme.spaceLG),
            ValueListenableBuilder<bool>(
              valueListenable: _isPasswordStep,
              builder: (context, isPasswordStep, _) {
                if (!isPasswordStep) {
                  return _buildLoginLink(theme);
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: AppTheme.spaceLG),
            _buildActionButton(theme),
            ValueListenableBuilder<String?>(
              valueListenable: _errorMessage,
              builder: (context, error, _) {
                if (error != null && error.isNotEmpty) {
                  return _buildErrorMessage(error, theme);
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceLG),
      child: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: theme.textSecondaryColor,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: () {
          _isPasswordStep.value = false;
          if (mounted) {
            _emailFocusNode.requestFocus();
          }
        },
      ),
    );
  }

  Widget _buildFormFields(ThemeData theme) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isPasswordStep,
      builder: (context, isPasswordStep, _) {
        if (!isPasswordStep) {
          // Email step
          return TextFormField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your business email',
              prefixIcon: Icon(
                Icons.email_outlined,
                color: theme.textSecondaryColor,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                borderSide: BorderSide(color: theme.primaryColor, width: 2),
              ),
            ),
            validator: (val) => val!.isEmpty ? 'Enter an email' : null,
            onFieldSubmitted: (_) => _moveToPasswordStep(),
          );
        } else {
          // Password step
          return Column(
            children: [
              ValueListenableBuilder<String>(
                valueListenable: _password,
                builder: (context, password, _) {
                  return TextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    autofocus: true,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Create a strong password',
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: theme.textSecondaryColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        borderSide:
                            BorderSide(color: theme.colorScheme.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        borderSide:
                            BorderSide(color: theme.primaryColor, width: 2),
                      ),
                    ),
                    validator: _validatePassword,
                    onFieldSubmitted: (_) {
                      if (mounted) {
                        FocusScope.of(context)
                            .requestFocus(_confirmPasswordFocusNode);
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: AppTheme.spaceMD),
              ValueListenableBuilder<String>(
                valueListenable: _confirmPassword,
                builder: (context, confirmPassword, _) {
                  return TextFormField(
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocusNode,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      hintText: 'Confirm your password',
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: theme.textSecondaryColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        borderSide:
                            BorderSide(color: theme.colorScheme.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        borderSide:
                            BorderSide(color: theme.primaryColor, width: 2),
                      ),
                    ),
                    validator: _validateConfirmPassword,
                    onFieldSubmitted: (_) => _submitRegistration(),
                  );
                },
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildLoginLink(ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 14,
            color: theme.textSecondaryColor,
          ),
          children: [
            const TextSpan(text: 'Already have an account? '),
            TextSpan(
              text: 'Sign in',
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  if (mounted) {
                    context.go('/login');
                  }
                },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ValueListenableBuilder<bool>(
        valueListenable: _isLoading,
        builder: (context, isLoading, _) {
          if (isLoading) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              ),
            );
          }

          return ValueListenableBuilder<bool>(
            valueListenable: _isPasswordStep,
            builder: (context, isPasswordStep, _) {
              return ElevatedButton(
                onPressed: () {
                  if (!isPasswordStep) {
                    _moveToPasswordStep();
                  } else {
                    _submitRegistration();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding:
                      const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                ),
                child: Text(
                  isPasswordStep ? 'Create account' : 'Continue',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildErrorMessage(String error, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spaceMD),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceMD),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              size: 20,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: Text(
                error,
                style: TextStyle(
                  color: theme.colorScheme.error,
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
