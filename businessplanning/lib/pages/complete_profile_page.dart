// lib/pages/complete_profile_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../state/app_state.dart';
import '../theme.dart';

class CompleteProfilePage extends StatefulWidget {
  final String userId;

  const CompleteProfilePage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  _CompleteProfilePageState createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  // Access global app state
  final AppState _appState = AppState();
  final AuthService _authService = AuthService();
  
  // Form keys and controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _industryController = TextEditingController();
  
  // Local state
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _industryController.dispose();
    super.dispose();
  }

  Future<void> _completeProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Here you would call your backend API to complete the profile
      // For now, we'll simulate a successful profile completion
      await Future.delayed(const Duration(seconds: 1));
      
      // Update user status after profile completion
      // In a real app, this would be handled by your backend
      
      // Navigate to the dashboard on success
      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
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
                  _buildProfileForm(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileForm(ThemeData theme) {
    return Container(
      width: 500,
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
            Text(
              'Complete Your Profile',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spaceSM),
            Text(
              'Please provide some information to set up your account',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spaceXL),
            _buildFormFields(theme),
            const SizedBox(height: AppTheme.spaceLG),
            _buildSubmitButton(theme),
            if (_errorMessage != null) _buildErrorMessage(_errorMessage!, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields(ThemeData theme) {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            hintText: 'Enter your full name',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (val) => val!.isEmpty ? 'Enter your name' : null,
        ),
        const SizedBox(height: AppTheme.spaceMD),
        TextFormField(
          controller: _companyController,
          decoration: const InputDecoration(
            labelText: 'Company',
            hintText: 'Enter your company name',
            prefixIcon: Icon(Icons.business_outlined),
          ),
          validator: (val) => val!.isEmpty ? 'Enter your company' : null,
        ),
        const SizedBox(height: AppTheme.spaceMD),
        TextFormField(
          controller: _industryController,
          decoration: const InputDecoration(
            labelText: 'Industry',
            hintText: 'Select your industry',
            prefixIcon: Icon(Icons.category_outlined),
          ),
          validator: (val) => val!.isEmpty ? 'Select an industry' : null,
        ),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              ),
            )
          : ElevatedButton(
              onPressed: _completeProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
              ),
              child: const Text(
                'Complete Profile',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
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