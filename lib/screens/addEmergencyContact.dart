import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:Empuan/config/api_config.dart';
import 'package:Empuan/services/auth_service.dart';
import 'package:Empuan/styles/style.dart';
import 'package:http/http.dart' as http;

class AddEmergencyContact extends StatefulWidget {
  const AddEmergencyContact({super.key});

  @override
  State<AddEmergencyContact> createState() => _AddEmergencyContactState();
}

class _AddEmergencyContactState extends State<AddEmergencyContact> {
  bool isLoading = true;

  void initState() {
    super.initState();
    getData();
  }

  List<dynamic> dataMore = [];

  TextEditingController nameController = TextEditingController();
  TextEditingController numberController = TextEditingController();
  TextEditingController relationController = TextEditingController();

  late String name;
  late String number;
  late String image;
  late String email;
  late String address;

  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
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
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Add Emergency Contact',
                        style: TextStyle(
                          fontFamily: 'Brodies',
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Avatar with error gradient border
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.error,
                              AppColors.error.withOpacity(0.6)
                            ],
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                          ),
                          child: const CircleAvatar(
                            backgroundImage:
                                AssetImage('images/profileDefault.jpg'),
                            radius: 50,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Import from Contacts Button
                      Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: TextButton.icon(
                          onPressed: _importFromContacts,
                          icon: Icon(
                            Icons.contact_phone_rounded,
                            color: AppColors.error,
                            size: 20,
                          ),
                          label: const Text(
                            'Import from Contacts',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.error,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Name Field
                      _buildModernTextField(
                        controller: nameController,
                        hintText: 'Full Name',
                        icon: Icons.person_rounded,
                      ),

                      const SizedBox(height: 16),

                      // Phone Number Field
                      _buildModernTextField(
                        controller: numberController,
                        hintText: 'Phone Number',
                        icon: Icons.phone_rounded,
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 16),

                      // Relation Field
                      _buildModernTextField(
                        controller: relationController,
                        hintText: 'Relation (e.g., Mother, Father)',
                        icon: Icons.people_rounded,
                      ),

                      const SizedBox(height: 40),

                      // Save Button with error theme
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              AppColors.error,
                              AppColors.error.withOpacity(0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.error.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            if (nameController.text.trim().isEmpty ||
                                numberController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: const [
                                      Icon(Icons.warning_rounded,
                                          color: Colors.white),
                                      SizedBox(width: 12),
                                      Text(
                                        'Please fill name and phone number',
                                        style: TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                              return;
                            }
                            await submitData();
                            if (mounted) {
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.emergency_rounded,
                                size: 24,
                                color: Colors.white,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Save Emergency Contact',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
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

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 15,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 15,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppColors.error,
              size: 20,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Future<void> _importFromContacts() async {
    try {
      // Request permission using permission_handler first
      var status = await Permission.contacts.status;
      print('📱 Current contacts permission status: $status');

      if (status.isDenied) {
        print('📱 Contacts permission denied, requesting...');
        status = await Permission.contacts.request();
        print('📱 Contacts permission request result: $status');
      }

      if (status.isPermanentlyDenied) {
        print('📱 Contacts permission permanently denied');
        if (mounted) {
          // Show dialog to open app settings
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Permission Required'),
              content: const Text(
                  'Contacts permission is permanently denied. Please enable it in app settings to import contacts.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    openAppSettings();
                    Navigator.pop(context);
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
        }
        return;
      }

      if (!status.isGranted) {
        // Permission denied (but not permanently)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.warning_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Permission denied. Please allow contacts access.',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
        return;
      }

      print('✅ Contacts permission granted, opening contact picker...');

      // Permission granted, open contact picker
      final contact = await FlutterContacts.openExternalPick();

      if (contact != null) {
        // Get full contact details
        final fullContact = await FlutterContacts.getContact(contact.id);

        if (fullContact != null) {
          setState(() {
            nameController.text = fullContact.displayName;

            // Get the first phone number if available
            if (fullContact.phones.isNotEmpty) {
              numberController.text = fullContact.phones.first.number;
            }
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: const [
                    Icon(Icons.check_circle_rounded, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      'Contact imported successfully!',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.secondary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error importing contact: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to import contact. Please try again.',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> submitData() async {
    setState(() {
      isLoading = true;
    });
    final name = nameController.text.trim();
    final number = numberController.text.trim();
    final relation = relationController.text.trim();

    final body = {
      'name': name,
      'phoneNumber': number,
      'relation': relation,
    };

    final url = "${ApiConfig.baseUrl}/kontak-aman";
    final uri = Uri.parse(url);

    // Debug: Print request details
    print('═══════════════════════════════════════════════════════');
    print('🔍 CREATE EMERGENCY CONTACT - Debug Info:');
    print('───────────────────────────────────────────────────────');
    print('Request URL: $url');
    print('Request Body: ${jsonEncode(body)}');
    print('Token (first 30 chars): ${AuthService.token?.substring(0, 30)}...');
    print('═══════════════════════════════════════════════════════');

    try {
      final response = await http.post(uri, body: jsonEncode(body), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.token}'
      });

      print('─────────────────────────────────────────────────────');
      print('📡 Response Status: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      // Parse response to check user_id
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['data'] != null) {
          final savedUserId = responseData['data']['user_id'];
          print('───────────────────────────────────────────────────');
          print('✅ Data saved successfully!');
          print('🆔 Saved with user_id: $savedUserId');
          if (savedUserId == 1 || savedUserId == 2) {
            print('⚠️  WARNING: Still using OLD user_id ($savedUserId)!');
            print('⚠️  Please logout and login with Michael or Yongky!');
          } else {
            print('✅ Correct user_id! ($savedUserId)');
          }
          print('═══════════════════════════════════════════════════════');
        }
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'Emergency contact added successfully!',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.secondary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error submitting data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to add contact. Please try again.',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> getData() async {
    setState(() {
      isLoading = true;
    });
    // get data from form
    // submit data to the server
    final url = '${ApiConfig.baseUrl}/kontak-aman';
    final uri = Uri.parse(url);
    final response = await http
        .get(uri, headers: {'Authorization': 'Bearer ${AuthService.token}'});
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map;
      print('items kita' + json['data'].toString());
      final result = json['data'] ?? [] as List;
      setState(() {
        dataMore = result;
      });
    }

    setState(() {
      isLoading = false;
    });
    // showsuccess or fail message based on status
    print(response.statusCode);
    print('data pas api tarik' + response.body);
  }
}
