// lib/pages/login_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../state/app_state.dart';
import '../theme.dart';

class LoginPage extends StatefulWidget {
  final String? redirectUrl;

  const LoginPage({Key? key, this.redirectUrl}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Access global app state
  final AppState _appState = AppState();
  final AuthService _auth = AuthService();
  
  // Form keys and controllers
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Focus nodes
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _newPasswordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  
  // Local state as ValueNotifiers
  final ValueNotifier<bool> _isPasswordStep = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isNewPasswordSetup = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isEmailValid = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<String?> _errorMessage = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    
    // Check for existing token and clear if invalid
    _checkExistingSession();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_emailFocusNode);
      }
    });
  }

  Future<void> _checkExistingSession() async {
    if (!mounted) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString('access_token') != null) {
        // We have a token, but need to verify if it's still valid
        final isLoggedIn = await _auth.isLoggedIn();
        if (!isLoggedIn && mounted) {
          // If not valid, make sure we're properly logged out
          await _auth.setLoggedOut();
          _errorMessage.value = 'Your session has expired. Please log in again.';
        }
      }
    } catch (e) {
      // Error occurred while checking login status
      if (mounted) {
        print('Session validation error: $e');
        await _auth.setLoggedOut();
        _errorMessage.value = 'Session verification error: $e';
      }
    }
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
    _isPasswordStep.dispose();
    _isNewPasswordSetup.dispose();
    _isEmailValid.dispose();
    _isLoading.dispose();
    _errorMessage.dispose();
    super.dispose();
  }

  Future<void> _checkEmailAndProceed() async {
    if (!mounted) return;
    
    if (_formKey.currentState!.validate()) {
      _isLoading.value = true;
      _errorMessage.value = null;
      _isEmailValid.value = true;

      try {
        bool emailExists = await _auth.checkEmailExists(_emailController.text);

        if (mounted) {
          if (emailExists) {
            _moveToPasswordStep();
          } else {
            _isEmailValid.value = false;
            _emailFocusNode.requestFocus();
          }
          _isLoading.value = false;
        }
      } catch (e) {
        if (mounted) {
          _errorMessage.value = e.toString();
          _isLoading.value = false;
        }
      }
    }
  }

  void _moveToPasswordStep() {
    if (!mounted) return;
    
    _isPasswordStep.value = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_passwordFocusNode);
      }
    });
  }

  Future<void> _submitLogin() async {
    if (!mounted) return;
    
    if (_formKey.currentState!.validate()) {
      _isLoading.value = true;
      _errorMessage.value = null;

      try {
        Map<String, dynamic> result = await _auth.signInWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
        );

        if (!mounted) return;

        if (result['success']) {
          if (widget.redirectUrl != null && widget.redirectUrl!.isNotEmpty) {
            context.go(Uri.decodeComponent(widget.redirectUrl!));
          } else {
            context.go('/dashboard');
          }
        } else if (result['needsPasswordSetup'] == true) {
          _moveToNewPasswordSetup();
        } else {
          _errorMessage.value = result['message'] ?? 'Invalid email or password';
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

  void _moveToNewPasswordSetup() {
    if (!mounted) return;
    
    _isNewPasswordSetup.value = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_newPasswordFocusNode);
      }
    });
  }

  Future<void> _submitNewPassword() async {
    if (!mounted) return;
    
    if (_formKey.currentState!.validate()) {
      _isLoading.value = true;
      _errorMessage.value = null;

      try {
        bool result = await _auth.setEmployeePassword(
          _emailController.text,
          _newPasswordController.text,
        );

        if (!mounted) return;

        if (result) {
          Map<String, dynamic> loginResult = await _auth.signInWithEmailAndPassword(
            _emailController.text,
            _newPasswordController.text,
          );

          if (!mounted) return;

          if (loginResult['success']) {
            context.go('/dashboard');
          } else {
            _errorMessage.value = 'Failed to log in with new password';
          }
        } else {
          _errorMessage.value = 'Failed to set new password';
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
        _checkEmailAndProceed();
      } else if (!_isNewPasswordSetup.value) {
        _submitLogin();
      } else {
        _submitNewPassword();
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
                      child: _buildLoginCard(theme),
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

  Widget _buildLoginCard(ThemeData theme) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(AppTheme.spaceXL),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: theme.isDarkMode ? AppTheme.shadowMediumDark : AppTheme.shadowMedium,
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
                return ValueListenableBuilder<bool>(
                  valueListenable: _isNewPasswordSetup,
                  builder: (context, isNewPasswordSetup, _) {
                    if (!kIsWeb && (isPasswordStep || isNewPasswordSetup)) {
                      return _buildBackButton(theme);
                    }
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _isPasswordStep,
              builder: (context, isPasswordStep, _) {
                return ValueListenableBuilder<bool>(
                  valueListenable: _isNewPasswordSetup,
                  builder: (context, isNewPasswordSetup, _) {
                    return Text(
                      isNewPasswordSetup
                        ? 'Set New Password'
                        : (isPasswordStep ? 'Welcome Back' : 'Sign in to Stratwise'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimaryColor,
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: AppTheme.spaceSM),
            ValueListenableBuilder<bool>(
              valueListenable: _isPasswordStep,
              builder: (context, isPasswordStep, _) {
                return ValueListenableBuilder<bool>(
                  valueListenable: _isNewPasswordSetup,
                  builder: (context, isNewPasswordSetup, _) {
                    return Text(
                      isNewPasswordSetup
                        ? 'Create a secure password for your account'
                        : (isPasswordStep 
                            ? 'Enter your password to continue'
                            : 'Enter your email to get started'),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.textSecondaryColor,
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: AppTheme.spaceXL),
            _buildFormFields(theme),
            const SizedBox(height: AppTheme.spaceLG),
            ValueListenableBuilder<bool>(
              valueListenable: _isNewPasswordSetup,
              builder: (context, isNewPasswordSetup, _) {
                if (!isNewPasswordSetup) {
                  return _buildCreateAccountLink(theme);
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
          if (_isNewPasswordSetup.value) {
            _isNewPasswordSetup.value = false;
          } else {
            _isPasswordStep.value = false;
            if (mounted) {
              _emailFocusNode.requestFocus();
            }
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
          return ValueListenableBuilder<bool>(
            valueListenable: _isEmailValid,
            builder: (context, isEmailValid, _) {
              return TextFormField(
                controller: _emailController,
                focusNode: _emailFocusNode,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  prefixIcon: Icon(
                    Icons.email_outlined, 
                    color: theme.textSecondaryColor,
                  ),
                  errorText: !isEmailValid ? 'No account found with this email' : null,
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
                onChanged: (val) => _isEmailValid.value = true,
                onFieldSubmitted: (_) => _checkEmailAndProceed(),
              );
            },
          );
        } else {
          // Password or New Password setup
          return ValueListenableBuilder<bool>(
            valueListenable: _isNewPasswordSetup,
            builder: (context, isNewPasswordSetup, _) {
              if (!isNewPasswordSetup) {
                // Password step
                return TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  autofocus: true,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: Icon(
                      Icons.lock_outline, 
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
                  validator: (val) => val!.isEmpty ? 'Enter a password' : null,
                  onFieldSubmitted: (_) => _submitLogin(),
                );
              } else {
                // New password setup
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
                        prefixIcon: Icon(
                          Icons.lock_outline, 
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
                      validator: (val) => val!.isEmpty ? 'Enter a new password' : null,
                    ),
                    const SizedBox(height: AppTheme.spaceMD),
                    TextFormField(
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
                          borderSide: BorderSide(color: theme.colorScheme.outline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                          borderSide: BorderSide(color: theme.primaryColor, width: 2),
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
            },
          );
        }
      },
    );
  }

  Widget _buildCreateAccountLink(ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 14, 
            color: theme.textSecondaryColor,
          ),
          children: [
            const TextSpan(text: 'No account? '),
            TextSpan(
              text: 'Create one',
              style: TextStyle(
                color: theme.primaryColor,
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
              return ValueListenableBuilder<bool>(
                valueListenable: _isNewPasswordSetup,
                builder: (context, isNewPasswordSetup, _) {
                  return ElevatedButton(
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
                      backgroundColor: theme.primaryColor,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
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
                  );
                },
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