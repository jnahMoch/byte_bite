import 'package:flutter/material.dart';

import '../../user_storage.dart';

class HelperSettingsSheet extends StatefulWidget {
  final ScrollController scrollController;
  const HelperSettingsSheet({super.key, required this.scrollController});

  @override
  State<HelperSettingsSheet> createState() => _HelperSettingsSheetState();
}

class _HelperSettingsSheetState extends State<HelperSettingsSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: ListView(
        controller: widget.scrollController,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _sectionTitle('Account'),
          _settingsTile(context, Icons.person_outline, 'Profile',
              'Manage your account', onTap: () {
            Navigator.pop(context);
            _showProfileDialog(context);
          }),
          _settingsTile(context, Icons.lock_outline, 'Change Password',
              'Update your password', onTap: () {
            Navigator.pop(context);
            _showChangePasswordDialog(context);
          }),
          const SizedBox(height: 20),
          _sectionTitle('App'),
          _settingsTile(context, Icons.notifications_outlined, 'Notifications',
              'Manage alerts', onTap: () {
            Navigator.pop(context);
            _showNotificationsDialog(context);
          }),
          const SizedBox(height: 20),
          _sectionTitle('Support'),
          _settingsTile(context, Icons.help_outline, 'Help & Support',
              'Get help with the app', onTap: () {
            Navigator.pop(context);
            _showHelpSupportDialog(context);
          }),
          const SizedBox(height: 20),
          _sectionTitle('Session'),
          _settingsTile(context, Icons.logout, 'Logout',
              'Sign out of your account',
              isDestructive: true, onTap: () {
            Navigator.pop(context);
            _showLogoutConfirmation(context);
          }),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600])),
    );
  }

  Widget _settingsTile(BuildContext context, IconData icon, String title,
      String subtitle,
      {VoidCallback? onTap, bool isDestructive = false}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            color: isDestructive ? Colors.red : const Color(0xFF009661),
            size: 22),
      ),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDestructive ? Colors.red : null)),
      subtitle: Text(subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap ?? () {},
    );
  }

  void _showProfileDialog(BuildContext context) {
    final nameController = TextEditingController(
        text: UserStorage.currentUser ?? 'Helper');
    final emailController = TextEditingController(
        text: 'helper@byteandbite.com');
    final phoneController = TextEditingController(
        text: '+234 812 345 6789');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        shadowColor: Colors.black26,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Profile',
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800)),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.close, size: 20, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF009661).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 48,
                        color: Color(0xFF009661),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      UserStorage.currentUser ?? 'Helper',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Helper Account',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _buildInputField(
                controller: nameController,
                label: 'Username',
                icon: Icons.person_outline,
                readOnly: true,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                readOnly: true,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: phoneController,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                readOnly: false,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Profile updated successfully'),
                          backgroundColor: Color(0xFF009661)),
                    );
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF009661),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Save Changes',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        shadowColor: Colors.black26,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Change Password',
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800)),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.close, size: 20, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildInputField(
                controller: oldPasswordController,
                label: 'Current Password',
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: newPasswordController,
                label: 'New Password',
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: confirmPasswordController,
                label: 'Confirm New Password',
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Password changed successfully'),
                              backgroundColor: Color(0xFF009661)),
                        );
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF009661),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: const Text('Change',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationsDialog(BuildContext context) {
    const notificationTypes = [
      {'icon': Icons.shopping_cart_outlined, 'label': 'Orders', 'desc': 'New order notifications'},
      {'icon': Icons.payment_outlined, 'label': 'Payments', 'desc': 'Payment confirmations'},
      {'icon': Icons.info_outlined, 'label': 'System', 'desc': 'System alerts'},
      {'icon': Icons.local_offer_outlined, 'label': 'Promotions', 'desc': 'Promotional messages'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final notificationPrefs = {
            'orders': true,
            'payments': true,
            'system': false,
            'promotions': false,
          };

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            shadowColor: Colors.black26,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Notifications',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w800)),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.close, size: 20, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Manage which notifications you want to receive',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...List.generate(
                    notificationTypes.length,
                    (index) {
                      final item = notificationTypes[index] as Map<String, dynamic>;
                      final key = item['label'].toString().toLowerCase();
                      return _buildNotificationToggle(
                        icon: item['icon'] as IconData,
                        label: item['label'] as String,
                        description: item['desc'] as String,
                        value: notificationPrefs[key] ?? false,
                        onChanged: (value) {
                          setState(() {
                            notificationPrefs[key] = value;
                          });
                        },
                      );
                    },
                  ).expand((widget) => [widget, const SizedBox(height: 14)]),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Notification settings saved'),
                              backgroundColor: Color(0xFF009661)),
                        );
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF009661),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: const Text('Save Settings',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationToggle({
    required IconData icon,
    required String label,
    required String description,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF009661).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF009661), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(description,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF009661),
          ),
        ],
      ),
    );
  }

  void _showHelpSupportDialog(BuildContext context) {
    final faqs = [
      {
        'question': 'How do I change my password?',
        'answer': 'Go to Settings > Account > Change Password and enter your current and new password.'
      },
      {
        'question': 'Can I customize notifications?',
        'answer': 'Yes! Go to Settings > Notifications to enable or disable different notification types like Orders, Payments, System alerts, and Promotions.'
      },
      {
        'question': 'How do I update my profile information?',
        'answer': 'Go to Settings > Profile to view your account details. You can update your phone number there.'
      },
      {
        'question': 'How do I logout?',
        'answer': 'Go to Settings > Logout to sign out of your account.'
      },
      {
        'question': 'What do I do if I forget my password?',
        'answer': 'Contact your manager or administrator to reset your password.'
      },
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final expandedFaqIndex = ValueNotifier<int?>(-1);

          return ValueListenableBuilder<int?>(
            valueListenable: expandedFaqIndex,
            builder: (context, expanded, _) {
              return Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 8,
                shadowColor: Colors.black26,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                  constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Help & Support',
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.w800)),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(8),
                              child: const Icon(Icons.close,
                                  size: 20, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text('Frequently Asked Questions',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[700])),
                      const SizedBox(height: 14),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: faqs.length,
                          itemBuilder: (context, index) {
                            final faq = faqs[index];
                            final isExpanded = expanded == index;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.grey.shade200, width: 1.5),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    dividerColor: Colors.transparent,
                                  ),
                                  child: ExpansionTile(
                                    tilePadding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    title: Text(faq['question']!,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13)),
                                    trailing: Icon(
                                      isExpanded
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                      color: const Color(0xFF009661),
                                    ),
                                    onExpansionChanged: (value) {
                                      expandedFaqIndex.value =
                                          value ? index : -1;
                                    },
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 12),
                                        child: Text(faq['answer']!,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                height: 1.5)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Need More Help?',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade900)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.email_outlined,
                                    size: 18, color: Colors.blue.shade700),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text('support@byteandbite.com',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.w500)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(Icons.phone_outlined,
                                    size: 18, color: Colors.blue.shade700),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text('+234 800 123 4567',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.w500)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text('App Version 1.0.0',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[400],
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    // Capture navigator reference before creating dialog
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              // Close dialog only
              Navigator.pop(ctx);
              
              // Do logout in background
              UserStorage.logout().then((_) {
                // After logout, wait briefly then navigate
                Future.delayed(const Duration(milliseconds: 600), () {
                  try {
                    // Use the saved navigator reference (not context-dependent)
                    rootNavigator.pushNamedAndRemoveUntil(
                      '/login',
                      (Route<dynamic> route) => false,
                    );
                  } catch (e) {
                    // Silently handle navigation errors
                  }
                });
              }).catchError((_) {
                // Silently handle logout errors
              });
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    bool obscureText = false,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: Colors.grey.shade50,
        prefixIcon: Icon(icon, color: const Color(0xFF009661)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF009661), width: 2),
        ),
      ),
    );
  }
}
