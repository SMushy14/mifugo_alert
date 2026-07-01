import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import 'consultations_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class MoreDrawer extends StatelessWidget {
  const MoreDrawer({
    super.key,
    required this.farmerId,
    required this.farmerName,
    this.onOpenTab,
  });

  final String farmerId;
  final String farmerName;
  final void Function(int index)? onOpenTab;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Drawer(
      width: width * 0.78 > 360 ? 360 : width * 0.78,
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          Builder(
            builder: (context) {
              final topInset = MediaQuery.of(context).padding.top;
              return Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(20, topInset + 20, 20, 20),
                decoration: const BoxDecoration(
                  gradient: AppColors.heroGradient,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'More',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white54),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      farmerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Farmer account',
                      style: TextStyle(fontSize: 12, color: AppColors.gold),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _item(
                    context,
                    Icons.medical_services_outlined,
                    'Request Assistance',
                    AppColors.primary,
                    () {
                      Navigator.pop(context);
                      onOpenTab?.call(3);
                    },
                  ),
                  _item(
                    context,
                    Icons.chat_bubble_outline,
                    'Consultations',
                    AppColors.goldDark,
                    () {
                      Navigator.pop(context);
                      onOpenTab?.call(7);
                    },
                  ),
                  _item(
                    context,
                    Icons.menu_book_outlined,
                    'Disease Information',
                    AppColors.primary,
                    () => _comingSoon(context, 'Disease Information'),
                  ),
                  _item(
                    context,
                    Icons.history,
                    'Activity History',
                    AppColors.goldDark,
                    () {
                      Navigator.pop(context);
                      onOpenTab?.call(6);
                    },
                  ),
                  _item(
                    context,
                    Icons.person_outline,
                    'My Profile',
                    AppColors.maroon,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileScreen(
                            farmerId: farmerId,
                            farmerName: farmerName,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  _signOut(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String label,
    Color accent,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _signOut(BuildContext context) {
    return InkWell(
      onTap: () {
        FirebaseAuth.instance.signOut();
        final nav = Navigator.of(context);
        nav.pop();
        nav.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.maroonTint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.maroon.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.logout, color: AppColors.maroon, size: 20),
            SizedBox(width: 12),
            Text(
              'Sign out',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.maroon,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context, String name) {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(SnackBar(content: Text('$name — coming soon')));
  }
}
