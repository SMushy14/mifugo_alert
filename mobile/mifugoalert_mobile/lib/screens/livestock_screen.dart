import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import 'farmer_widgets.dart';
import 'add_animal_screen.dart';

class MyLivestockScreen extends StatelessWidget {
  const MyLivestockScreen({
    super.key,
    required this.farmerId,
    required this.farmerName,
    this.onOpenTab,
    this.onOpenMenu,
  });

  final String farmerId;
  final String farmerName;
  final void Function(int)? onOpenTab;
  final VoidCallback? onOpenMenu;

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('animals')
        .where('ownerId', isEqualTo: farmerId)
        .snapshots();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          farmerTopBar(
            farmerName,
            farmerId: farmerId,
            onBell: () => onOpenTab?.call(5),
            onMenu: () => onOpenMenu?.call(),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: StreamBuilder<QuerySnapshot>(
                stream: stream,
                builder: (context, snap) {
                  final List<QueryDocumentSnapshot> animals =
                      [...(snap.data?.docs ?? [])]..sort(
                        (a, b) => (a['name'] ?? '').toString().compareTo(
                          (b['name'] ?? '').toString(),
                        ),
                      );

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _header(context, animals.length),
                        const SizedBox(height: 12),
                        if (snap.connectionState == ConnectionState.waiting)
                          const Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (animals.isEmpty)
                          _emptyState()
                        else
                          ...animals.map(_animalCard),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => Container(
    margin: const EdgeInsets.only(top: 24),
    padding: const EdgeInsets.all(24),
    width: double.infinity,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.pets, color: AppColors.primary, size: 28),
        ),
        const SizedBox(height: 12),
        const Text(
          'No animals yet',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tap Add to register your first animal.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    ),
  );

  Widget _header(BuildContext context, int count) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My livestock',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$count animals registered',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.heroGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepGreen.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddAnimalScreen(farmerId: farmerId),
            ),
          ),
          icon: const Icon(Icons.add, size: 18),
          label: const Text(
            'Add',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _animalCard(QueryDocumentSnapshot d) {
    final a = d.data() as Map<String, dynamic>;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              iconForSpecies((a['species'] ?? '').toString()),
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: (a['name'] ?? '').toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: '   ${a['species']} · ${a['breed']}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tag ${a['tagId']} · ${a['sex']} · ${a['age']} · Checkup ${_timeAgo(a['lastCheckup'])}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _statusPill((a['status'] ?? '').toString()),
        ],
      ),
    );
  }

  Widget _statusPill(String status) {
    late Color bg, fg;
    late String label;
    switch (status) {
      case 'sick':
        bg = AppColors.maroonTint;
        fg = AppColors.maroon;
        label = 'Sick';
        break;
      case 'recovering':
        bg = AppColors.goldTint;
        fg = AppColors.goldDark;
        label = 'Recovering';
        break;
      case 'vaccinated':
        bg = AppColors.primaryTint;
        fg = AppColors.primary;
        label = 'Vaccinated';
        break;
      default:
        bg = AppColors.primaryTint;
        fg = AppColors.primary;
        label = 'Healthy';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _timeAgo(dynamic ts) {
    if (ts is! Timestamp) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}
