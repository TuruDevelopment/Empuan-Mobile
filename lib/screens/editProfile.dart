import 'package:flutter/material.dart';
import 'package:Empuan/config/api_config.dart';
import 'package:Empuan/styles/style.dart';
import 'package:Empuan/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditProfile extends StatefulWidget {
  const EditProfile({
    super.key,
    required this.username,
    required this.profilePicture,
  });

  final String username;
  final String profilePicture;

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      final url = '${ApiConfig.baseUrl}/user/profile';
      final uri = Uri.parse(url);
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer ${AuthService.token}'},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final userData = jsonData['data'];

        if (mounted) {
          setState(() {
            _nameController.text = userData['name'] ?? '';
            _usernameController.text = userData['username'] ?? '';
            _emailController.text = userData['email'] ?? '';
            _isLoadingData = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingData = false);
          _showSnackBar('Failed to load profile data', isError: true);
        }
      }
    } catch (e) {
      print('DEBUG: Error fetching user data: $e');
      if (mounted) {
        setState(() => _isLoadingData = false);
        _showSnackBar('Error loading profile', isError: true);
      }
    }
  }

  Future<void> _updateProfile() async {
    // Validation
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Name cannot be empty', isError: true);
      return;
    }

    if (_usernameController.text.trim().isEmpty) {
      _showSnackBar('Username cannot be empty', isError: true);
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      _showSnackBar('Email cannot be empty', isError: true);
      return;
    }

    // Basic email validation
    if (!_emailController.text.trim().contains('@')) {
      _showSnackBar('Please enter a valid email', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = '${ApiConfig.baseUrl}/user/profile';
      final uri = Uri.parse(url);

      print('DEBUG: Updating profile to URL: $url');
      print('DEBUG: Token: ${AuthService.token?.substring(0, 20)}...');

      // Build request body with all fields
      final Map<String, dynamic> requestBody = {
        'name': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
      };

      print('DEBUG: Request body: $requestBody');

      final response = await http.patch(
        uri,
        headers: {
          'Authorization': 'Bearer ${AuthService.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showSnackBar('Profile updated successfully!');

        // Fetch updated user data to reflect changes immediately
        await _fetchUserData();

        // Wait a bit before closing to show the success message
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          // Return updated name to parent screen
          Navigator.pop(context, _nameController.text.trim());
        }
      } else {
        // Check if response is JSON before trying to decode
        String errorMessage =
            'Failed to update profile (${response.statusCode})';

        try {
          if (response.body.trim().startsWith('{') ||
              response.body.trim().startsWith('[')) {
            final jsonData = jsonDecode(response.body);
            errorMessage =
                jsonData['errors'] ?? jsonData['message'] ?? errorMessage;
          } else {
            // Response is not JSON (likely HTML error page)
            errorMessage =
                'Server error: Unable to update profile. Please check your connection.';
          }
        } catch (jsonError) {
          print('DEBUG: JSON decode error: $jsonError');
        }

        _showSnackBar(errorMessage, isError: true);
      }
    } catch (e) {
      print('DEBUG: Exception caught: $e');
      if (mounted) {
        _showSnackBar('Connection error: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              AppColors.surface,
              AppColors.accent.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Back Button
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Title
                    const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontFamily: 'Brodies',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    // Save Button
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: _isLoading ? null : _updateProfile,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: _isLoadingData
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),

                            // Profile Picture with gradient border
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primaryVariant,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: AppColors.surface,
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  backgroundImage:
                                      AssetImage(widget.profilePicture),
                                  radius: 50,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Name Field (Editable)
                            _buildInputField(
                              label: 'Name',
                              icon: Icons.badge_rounded,
                              controller: _nameController,
                              hint: 'Enter your name',
                            ),
                            const SizedBox(height: 20),

                            // Username Field
                            _buildInputField(
                              label: 'Username',
                              icon: Icons.person_rounded,
                              controller: _usernameController,
                              hint: 'Enter username',
                            ),
                            const SizedBox(height: 20),

                            // Email Field
                            _buildInputField(
                              label: 'Email',
                              icon: Icons.email_rounded,
                              controller: _emailController,
                              hint: 'Enter email address',
                              keyboardType: TextInputType.emailAddress,
                            ),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String hint,
    String? infoText,
    TextInputType? keyboardType,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Input Field
        Container(
          decoration: BoxDecoration(
            color: readOnly
                ? AppColors.surface.withOpacity(0.5)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: readOnly
                  ? AppColors.textSecondary.withOpacity(0.2)
                  : AppColors.accent.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 15,
              color: readOnly ? AppColors.textSecondary : AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              hintText: hint,
              hintStyle: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        if (infoText != null) ...[
          const SizedBox(height: 10),
          // Info Text
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  infoText,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    color: AppColors.textSecondary.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// Remove old code below

