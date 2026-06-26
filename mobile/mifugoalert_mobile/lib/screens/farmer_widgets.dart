import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';

Widget farmerTopBar(
  String farmerName, {
  required String farmerId,
  VoidCallback? onBell,
  VoidCallback? onMenu,
}) {
  return Builder(
    builder: (context) {
      final topInset = MediaQuery.of(context).padding.top;
      return Container(
        padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 14),
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                'assets/images/logo2.png',
                width: 38,
                height: 38,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MifugoAlert',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'FARMER · ${farmerName.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.gold,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Spacer(),
            _TopBarBell(userId: farmerId, onTap: onBell),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onMenu,
              child: const Icon(Icons.menu, color: Colors.white),
            ),
          ],
        ),
      );
    },
  );
}

class _TopBarBell extends StatelessWidget {
  const _TopBarBell({required this.userId, this.onTap});
  final String userId;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots();
    return GestureDetector(
      onTap: onTap,
      child: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          final count = (snap.data?.docs ?? [])
              .where((d) => (d['read'] ?? false) == false)
              .length;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(
                  Icons.notifications_none,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              if (count > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.maroon,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$count',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
