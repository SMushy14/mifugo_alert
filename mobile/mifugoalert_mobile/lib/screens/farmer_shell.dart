import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';
import 'farmer_home_screen.dart';
import 'report_sick_animal_screen.dart';
import 'livestock_screen.dart';
import 'available_vets_screen.dart';
import 'emergency_alert_screen.dart';
import 'notifications_screen.dart';
import 'consultations_screen.dart';
import 'activity_history_screen.dart';
import 'more_drawer.dart';

class FarmerShell extends StatefulWidget {
  const FarmerShell({
    super.key,
    required this.farmerId,
    required this.farmerName,
    required this.farmerArea,
  });

  final String farmerId;
  final String farmerName;
  final String farmerArea;

  @override
  State<FarmerShell> createState() => _FarmerShellState();
}

class _FarmerShellState extends State<FarmerShell> {
  static const _green = Color(0xFF1B7A3D);
  static const _red = Color(0xFFE0322E);
  static const _gray = Color(0xFF6B7280);

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _index = 0;

  void _go(int i) {
    setState(() => _index = i);
    if (i == 5) _markAlertsRead();
  }

  Future<void> _markAlertsRead() async {
    final db = FirebaseFirestore.instance;
    final snap = await db
        .collection('notifications')
        .where('userId', isEqualTo: widget.farmerId)
        .get();
    final batch = db.batch();
    var changed = false;
    for (final d in snap.docs) {
      if ((d.data()['read'] ?? false) == false) {
        batch.update(d.reference, {'read': true});
        changed = true;
      }
    }
    if (changed) await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      FarmerHomeScreen(
        farmerId: widget.farmerId,
        farmerName: widget.farmerName,
        farmerArea: widget.farmerArea,
        onOpenTab: _go,
        onOpenMenu: () => _scaffoldKey.currentState?.openEndDrawer(),
      ),
      ReportSickAnimalScreen(
        farmerId: widget.farmerId,
        farmerName: widget.farmerName,
        farmerArea: widget.farmerArea,
      ),
      MyLivestockScreen(
        farmerId: widget.farmerId,
        farmerName: widget.farmerName,
      ),
      AvailableVetsScreen(
        farmerId: widget.farmerId,
        farmerName: widget.farmerName,
      ),
      EmergencyAlertScreen(
        farmerId: widget.farmerId,
        farmerName: widget.farmerName,
        farmerArea: widget.farmerArea,
        onSent: () => _go(0),
      ),
      NotificationsScreen(
        farmerId: widget.farmerId,
        farmerName: widget.farmerName,
      ),
      ActivityHistoryScreen(
        farmerId: widget.farmerId,
        farmerName: widget.farmerName,
      ),
      ConsultationsScreen(
        farmerId: widget.farmerId,
        farmerName: widget.farmerName,
      ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: MoreDrawer(
        farmerId: widget.farmerId,
        farmerName: widget.farmerName,
        onOpenTab: _go,
      ),
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _bottomNav() {
    Widget tab(IconData icon, String label, int i) {
      final active = _index == i;
      final color = active ? AppColors.gold : Colors.white70;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _go(i),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final sosActive = _index == 4;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          gradient: AppColors.heroGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepGreen.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            tab(Icons.home, 'Home', 0),
            tab(Icons.report_gmailerrorred, 'Report', 1),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _go(4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.maroon,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.gold, width: 2),
                      ),
                      child: const Icon(
                        Icons.notifications_active,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'SOS',
                      style: TextStyle(
                        fontSize: 11,
                        color: sosActive ? AppColors.gold : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            tab(Icons.pets, 'Livestock', 2),
            tab(Icons.notifications_none, 'Alerts', 5),
          ],
        ),
      ),
    );
  }
}
