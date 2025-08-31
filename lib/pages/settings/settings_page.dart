import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUserPreferences();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          setState(() {
            _userData = doc.data();
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load user data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadUserPreferences() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Load notification preferences
        final notificationDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('preferences')
            .doc('notifications')
            .get();

        // Load privacy preferences
        final privacyDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('preferences')
            .doc('privacy')
            .get();

        // Store preferences for use in dialogs
        if (notificationDoc.exists) {
          // TODO: Use these preferences in notification settings
        }
        if (privacyDoc.exists) {
          // TODO: Use these preferences in privacy settings
        }
      }
    } catch (e) {
      // Silently handle preference loading errors
      debugPrint('Failed to load user preferences: $e');
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      // The AuthWrapper will automatically redirect to login page
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign out failed: $e')),
        );
      }
    }
  }

  Future<void> _showEditProfileDialog() async {
    final TextEditingController ownerNameController = TextEditingController(
      text: _userData?['ownerName'] ?? '',
    );
    final TextEditingController cafeNameController = TextEditingController(
      text: _userData?['cafeName'] ?? '',
    );
    final TextEditingController phoneController = TextEditingController(
      text: _userData?['phone'] ?? '',
    );
    final TextEditingController addressController = TextEditingController(
      text: _userData?['address'] ?? '',
    );

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6F4E37).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF6F4E37),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Edit Profile',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFormField(
                  controller: ownerNameController,
                  label: 'Owner Name',
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Owner name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: cafeNameController,
                  label: 'Cafe Name',
                  icon: Icons.store,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Cafe name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Phone number is required';
                    }
                    if (value.length < 10) {
                      return 'Phone number must be at least 10 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: addressController,
                  label: 'Address',
                  icon: Icons.location_on,
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Address is required';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validate form
                if (ownerNameController.text.isEmpty ||
                    cafeNameController.text.isEmpty ||
                    phoneController.text.isEmpty ||
                    addressController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all required fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                await _updateProfile(
                  ownerNameController.text,
                  cafeNameController.text,
                  phoneController.text,
                  addressController.text,
                );
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6F4E37),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6F4E37)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6F4E37), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Future<void> _updateProfile(
    String ownerName,
    String cafeName,
    String phone,
    String address,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Show loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 16),
                  Text('Updating profile...'),
                ],
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'ownerName': ownerName.trim(),
          'cafeName': cafeName.trim(),
          'phone': phone.trim(),
          'address': address.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Reload user data
        await _loadUserData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _updateProfile(ownerName, cafeName, phone, address),
            ),
          ),
        );
      }
    }
  }

  void _showNotificationSettings() {
    // Create state variables for notification preferences
    bool salesNotifications = true;
    bool inventoryAlerts = true;
    bool financialReports = false;
    bool systemUpdates = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6F4E37).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: Color(0xFF6F4E37),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Notification Settings',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose which notifications you want to receive:',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  _buildNotificationOption(
                    'Sales Notifications',
                    'Get notified about new sales and transactions',
                    Icons.point_of_sale,
                    salesNotifications,
                    (value) {
                      setState(() {
                        salesNotifications = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildNotificationOption(
                    'Inventory Alerts',
                    'Get notified when items are running low',
                    Icons.inventory,
                    inventoryAlerts,
                    (value) {
                      setState(() {
                        inventoryAlerts = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildNotificationOption(
                    'Financial Reports',
                    'Daily/weekly financial summaries',
                    Icons.analytics,
                    financialReports,
                    (value) {
                      setState(() {
                        financialReports = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildNotificationOption(
                    'System Updates',
                    'Important app updates and maintenance',
                    Icons.system_update,
                    systemUpdates,
                    (value) {
                      setState(() {
                        systemUpdates = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Save notification preferences
                    _saveNotificationPreferences(
                      salesNotifications,
                      inventoryAlerts,
                      financialReports,
                      systemUpdates,
                    );
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6F4E37),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Save Settings'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveNotificationPreferences(
    bool salesNotifications,
    bool inventoryAlerts,
    bool financialReports,
    bool systemUpdates,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('preferences')
            .doc('notifications')
            .set({
          'salesNotifications': salesNotifications,
          'inventoryAlerts': inventoryAlerts,
          'financialReports': financialReports,
          'systemUpdates': systemUpdates,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification settings saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save notification settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildNotificationOption(
    String title,
    String subtitle,
    IconData icon,
    bool defaultValue,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6F4E37).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF6F4E37), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: defaultValue,
            onChanged: onChanged,
            activeColor: const Color(0xFF6F4E37),
            activeTrackColor: const Color(0xFF6F4E37).withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  void _showPrivacySecuritySettings() {
    // Create state variables for privacy preferences
    bool twoFactorAuth = false;
    bool biometricAuth = false;
    bool darkMode = false;
    bool autoLock = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6F4E37).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.security_outlined,
                      color: Color(0xFF6F4E37),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Privacy & Security',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manage your privacy and security settings:',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    _buildPrivacyOption(
                      'Enable Two-Factor Authentication',
                      'Add an extra layer of security to your account.',
                      Icons.security,
                      twoFactorAuth,
                      (value) {
                        setState(() {
                          twoFactorAuth = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildPrivacyOption(
                      'Enable Fingerprint/Face ID',
                      'Use biometric authentication for quick access.',
                      Icons.fingerprint,
                      biometricAuth,
                      (value) {
                        setState(() {
                          biometricAuth = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildPrivacyOption(
                      'Enable Dark Mode',
                      'Switch to a darker theme for better readability.',
                      Icons.dark_mode,
                      darkMode,
                      (value) {
                        setState(() {
                          darkMode = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildPrivacyOption(
                      'Enable Auto-Lock',
                      'Lock the app after a period of inactivity.',
                      Icons.lock_open,
                      autoLock,
                      (value) {
                        setState(() {
                          autoLock = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Save privacy preferences
                    _savePrivacyPreferences(
                      twoFactorAuth,
                      biometricAuth,
                      darkMode,
                      autoLock,
                    );
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6F4E37),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Save Settings'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _savePrivacyPreferences(
    bool twoFactorAuth,
    bool biometricAuth,
    bool darkMode,
    bool autoLock,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('preferences')
            .doc('privacy')
            .set({
          'twoFactorAuth': twoFactorAuth,
          'biometricAuth': biometricAuth,
          'darkMode': darkMode,
          'autoLock': autoLock,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Privacy & Security settings saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save privacy settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPrivacyOption(
    String title,
    String subtitle,
    IconData icon,
    bool defaultValue,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6F4E37).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF6F4E37), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: defaultValue,
            onChanged: onChanged,
            activeColor: const Color(0xFF6F4E37),
            activeTrackColor: const Color(0xFF6F4E37).withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  void _showHelpSupport() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Help & Support'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHelpSupportOption(
                  'Frequently Asked Questions (FAQ)',
                  'Find answers to common questions about the app.',
                  Icons.help_outline,
                  () {
                    // TODO: Implement FAQ navigation
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('FAQ - Coming Soon!')),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildHelpSupportOption(
                  'Contact Support',
                  'Get in touch with our support team for assistance.',
                  Icons.support_agent,
                  () {
                    // TODO: Implement Contact Support navigation
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contact Support - Coming Soon!')),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildHelpSupportOption(
                  'Report an Issue',
                  'Help us improve the app by reporting bugs or feature requests.',
                  Icons.bug_report,
                  () {
                    // TODO: Implement Report Issue navigation
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Report Issue - Coming Soon!')),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Help & Support settings saved!')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpSupportOption(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFF6F4E37),
          size: 28,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showDataBackupSettings() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Data & Backup Settings'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDataBackupOption(
                  'Auto Backup',
                  'Automatically backup your data to cloud storage',
                  Icons.cloud_upload,
                  true,
                  (value) {
                    // TODO: Implement auto backup setting
                  },
                ),
                const SizedBox(height: 16),
                _buildDataBackupOption(
                  'Export Data',
                  'Export your data as CSV/Excel files',
                  Icons.file_download,
                  false,
                  (value) {
                    // TODO: Implement data export
                  },
                ),
                const SizedBox(height: 16),
                _buildDataBackupOption(
                  'Sync Across Devices',
                  'Keep your data synchronized across all devices',
                  Icons.sync,
                  true,
                  (value) {
                    // TODO: Implement cross-device sync
                  },
                ),
                const SizedBox(height: 16),
                _buildDataBackupOption(
                  'Data Retention',
                  'Keep data for specified period (30/90/365 days)',
                  Icons.history,
                  false,
                  (value) {
                    // TODO: Implement data retention settings
                  },
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement manual backup
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Starting manual backup...')),
                      );
                    },
                    icon: const Icon(Icons.backup),
                    label: const Text('Create Manual Backup Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6F4E37),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data & Backup settings saved!')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDataBackupOption(
    String title,
    String subtitle,
    IconData icon,
    bool defaultValue,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6F4E37)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: defaultValue,
          onChanged: onChanged,
          activeColor: const Color(0xFF6F4E37),
        ),
      ],
    );
  }

  void _showAppPreferences() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('App Preferences'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAppPreferenceOption(
                  'Language',
                  'Choose your preferred language',
                  Icons.language,
                  'English',
                  () {
                    _showLanguageSelector();
                  },
                ),
                const SizedBox(height: 16),
                _buildAppPreferenceOption(
                  'Currency',
                  'Set your local currency for transactions',
                  Icons.attach_money,
                  'USD (\$)',
                  () {
                    _showCurrencySelector();
                  },
                ),
                const SizedBox(height: 16),
                _buildAppPreferenceOption(
                  'Date Format',
                  'Choose your preferred date format',
                  Icons.date_range,
                  'MM/DD/YYYY',
                  () {
                    _showDateFormatSelector();
                  },
                ),
                const SizedBox(height: 16),
                _buildAppPreferenceOption(
                  'Time Format',
                  'Choose 12-hour or 24-hour format',
                  Icons.access_time,
                  '12-hour',
                  () {
                    _showTimeFormatSelector();
                  },
                ),
                const SizedBox(height: 16),
                                  _buildAppPreferenceOption(
                    'Decimal Places',
                    'Number of decimal places for prices',
                    Icons.format_list_numbered,
                    '2',
                    () {
                      _showDecimalPlacesSelector();
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('App preferences saved!')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppPreferenceOption(
    String title,
    String subtitle,
    IconData icon,
    String currentValue,
    VoidCallback onTap,
  ) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6F4E37)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Text(
          currentValue,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
      ],
    );
  }

  void _showLanguageSelector() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption('English', 'en', true),
              _buildLanguageOption('Spanish', 'es', false),
              _buildLanguageOption('French', 'fr', false),
              _buildLanguageOption('German', 'de', false),
              _buildLanguageOption('Hindi', 'hi', false),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageOption(String name, String code, bool isSelected) {
    return ListTile(
      title: Text(name),
      trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF6F4E37)) : null,
      onTap: () {
        // TODO: Implement language change
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Language changed to $name')),
        );
      },
    );
  }

  void _showCurrencySelector() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Currency'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCurrencyOption('USD (\$)', 'USD', true),
              _buildCurrencyOption('EUR (€)', 'EUR', false),
              _buildCurrencyOption('GBP (£)', 'GBP', false),
              _buildCurrencyOption('INR (₹)', 'INR', false),
              _buildCurrencyOption('JPY (¥)', 'JPY', false),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCurrencyOption(String display, String code, bool isSelected) {
    return ListTile(
      title: Text(display),
      trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF6F4E37)) : null,
      onTap: () {
        // TODO: Implement currency change
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Currency changed to $code')),
        );
      },
    );
  }

  void _showDateFormatSelector() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Date Format'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDateFormatOption('MM/DD/YYYY', 'MM/DD/YYYY', true),
              _buildDateFormatOption('DD/MM/YYYY', 'DD/MM/YYYY', false),
              _buildDateFormatOption('YYYY-MM-DD', 'YYYY-MM-DD', false),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateFormatOption(String display, String format, bool isSelected) {
    return ListTile(
      title: Text(display),
      trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF6F4E37)) : null,
      onTap: () {
        // TODO: Implement date format change
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Date format changed to $format')),
        );
      },
    );
  }

  void _showTimeFormatSelector() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Time Format'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTimeFormatOption('12-hour (AM/PM)', '12', true),
              _buildTimeFormatOption('24-hour', '24', false),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimeFormatOption(String display, String format, bool isSelected) {
    return ListTile(
      title: Text(display),
      trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF6F4E37)) : null,
      onTap: () {
        // TODO: Implement time format change
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Time format changed to $format')),
        );
      },
    );
  }

  void _showDecimalPlacesSelector() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Decimal Places'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDecimalPlacesOption('0', '0', false),
              _buildDecimalPlacesOption('1', '1', false),
              _buildDecimalPlacesOption('2', '2', true),
              _buildDecimalPlacesOption('3', '3', false),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDecimalPlacesOption(String display, String places, bool isSelected) {
    return ListTile(
      title: Text(display),
      trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF6F4E37)) : null,
      onTap: () {
        // TODO: Implement decimal places change
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Decimal places changed to $places')),
        );
      },
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6F4E37).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: Color(0xFF6F4E37),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Change Password',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPasswordField(
                    controller: currentPasswordController,
                    label: 'Current Password',
                    icon: Icons.lock,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Current password is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    controller: newPasswordController,
                    label: 'New Password',
                    icon: Icons.lock_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'New password is required';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]').hasMatch(value)) {
                        return 'Password must contain uppercase, lowercase, number & special character';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    controller: confirmPasswordController,
                    label: 'Confirm New Password',
                    icon: Icons.lock_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Password Requirements:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          '• At least 8 characters long\n• Include uppercase and lowercase letters\n• Include at least one number\n• Include at least one special character (@\$!%*?&)',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  await _changePassword(
                    currentPasswordController.text,
                    newPasswordController.text,
                  );
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6F4E37),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Change Password'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6F4E37)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6F4E37), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Future<void> _changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Re-authenticate user before changing password
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        
        await user.reauthenticateWithCredential(credential);
        
        // Change password
        await user.updatePassword(newPassword);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password changed successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to change password: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
        backgroundColor: const Color(0xFF6F4E37),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF6F4E37), Color(0xFF8B6B4A)],
                ),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _loadUserData();
                    await _loadUserPreferences();
                  },
                  color: const Color(0xFF6F4E37),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        
                        // User Profile Section
                        _buildUserProfileCard(),
                        
                        const SizedBox(height: 30),

                        // Account Settings Section
                        _buildSectionHeader('Account Settings', Icons.person),
                        const SizedBox(height: 16),
                        _buildSettingTile(
                          icon: Icons.person_outline,
                          title: 'Edit Profile',
                          subtitle: 'Update your personal information',
                          onTap: () {
                            _showEditProfileDialog();
                          },
                        ),
                        _buildSettingTile(
                          icon: Icons.lock_outline,
                          title: 'Change Password',
                          subtitle: 'Update your account password',
                          onTap: () {
                            _showChangePasswordDialog();
                          },
                        ),

                        const SizedBox(height: 30),

                        // Preferences Section
                        _buildSectionHeader('Preferences', Icons.tune),
                        const SizedBox(height: 16),
                        _buildSettingTile(
                          icon: Icons.notifications_outlined,
                          title: 'Notifications',
                          subtitle: 'Manage notification preferences',
                          onTap: () {
                            _showNotificationSettings();
                          },
                        ),
                        _buildSettingTile(
                          icon: Icons.settings_applications_outlined,
                          title: 'App Preferences',
                          subtitle: 'Customize app appearance and behavior',
                          onTap: () {
                            _showAppPreferences();
                          },
                        ),

                        const SizedBox(height: 30),

                        // Security Section
                        _buildSectionHeader('Security & Privacy', Icons.security),
                        const SizedBox(height: 16),
                        _buildSettingTile(
                          icon: Icons.security_outlined,
                          title: 'Privacy & Security',
                          subtitle: 'Manage your privacy settings',
                          onTap: () {
                            _showPrivacySecuritySettings();
                          },
                        ),

                        const SizedBox(height: 30),

                        // Data Section
                        _buildSectionHeader('Data & Backup', Icons.backup),
                        const SizedBox(height: 16),
                        _buildSettingTile(
                          icon: Icons.backup_outlined,
                          title: 'Data & Backup',
                          subtitle: 'Manage your data and backup settings',
                          onTap: () {
                            _showDataBackupSettings();
                          },
                        ),

                        const SizedBox(height: 30),

                        // Support Section
                        _buildSectionHeader('Support & Information', Icons.help),
                        const SizedBox(height: 16),
                        _buildSettingTile(
                          icon: Icons.help_outline,
                          title: 'Help & Support',
                          subtitle: 'Get help and contact support',
                          onTap: () {
                            _showHelpSupport();
                          },
                        ),
                        _buildSettingTile(
                          icon: Icons.info_outline,
                          title: 'About',
                          subtitle: 'App version and information',
                          onTap: () {
                            showAboutDialog(
                              context: context,
                              applicationName: 'Cafe App',
                              applicationVersion: '1.0.0',
                              applicationIcon: const Icon(Icons.local_cafe),
                              children: [
                                const Text('A comprehensive cafe management application.'),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 40),

                        // Logout Button
                        _buildLogoutButton(),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildUserProfileCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFF6F4E37),
              child: Icon(
                Icons.person,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _userData?['ownerName'] ?? 'User',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _userData?['cafeName'] ?? 'Cafe',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _auth.currentUser?.email ?? '',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6F4E37), size: 28),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6F4E37).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF6F4E37),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutConfirmation(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.logout, size: 24),
        label: const Text(
          'Sign Out',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.logout,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Sign Out',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to sign out? You will need to sign in again to access your account.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }
}
