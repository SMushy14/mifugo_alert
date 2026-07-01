import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import 'farmer_widgets.dart';

class FarmerHomeScreen extends StatelessWidget {
  const FarmerHomeScreen({
    super.key,
    required this.farmerId,
    required this.farmerName,
    required this.farmerArea,
    this.onOpenTab,
    this.onOpenMenu,
  });

  final String farmerId;
  final String farmerName;
  final String farmerArea;
  final void Function(int index)? onOpenTab;
  final VoidCallback? onOpenMenu;

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    final casesStream = db
        .collection('cases')
        .where('farmerId', isEqualTo: farmerId)
        .snapshots();
    final notifsStream = db
        .collection('notifications')
        .where('userId', isEqualTo: farmerId)
        .snapshots();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: StreamBuilder<QuerySnapshot>(
        stream: casesStream,
        builder: (context, caseSnap) {
          final caseDocs = _sortedByDate(caseSnap.data?.docs ?? []);

          return StreamBuilder<QuerySnapshot>(
            stream: notifsStream,
            builder: (context, notifSnap) {
              final notifDocs = _sortedByDate(notifSnap.data?.docs ?? []);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _heroCard(context),
                              const SizedBox(height: 20),
                              _availableVetsStrip(context),
                              const SizedBox(height: 20),
                              _sectionHeader(
                                'Recent cases',
                                () => onOpenTab?.call(6),
                              ),
                              const SizedBox(height: 8),
                              if (caseDocs.isEmpty)
                                _emptyHint('No cases yet.')
                              else
                                ...caseDocs.take(4).map(_caseCard),
                              const SizedBox(height: 20),
                              _sectionHeader(
                                'Latest notifications',
                                () => onOpenTab?.call(5),
                              ),
                              const SizedBox(height: 8),
                              if (notifDocs.isEmpty)
                                _emptyHint('No notifications yet.')
                              else
                                ...notifDocs.take(4).map(_notifTile),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<QueryDocumentSnapshot> _sortedByDate(List<QueryDocumentSnapshot> docs) {
    final list = [...docs];
    list.sort((a, b) {
      final ta = (a.data() as Map<String, dynamic>)['createdAt'];
      final tb = (b.data() as Map<String, dynamic>)['createdAt'];
      if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
      return 0;
    });
    return list;
  }

  String _val(QueryDocumentSnapshot d, String key) =>
      ((d.data() as Map<String, dynamic>)[key] ?? '').toString();

  String _timeAgo(dynamic ts) {
    if (ts is! Timestamp) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  Widget _emptyHint(String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Text(text, style: const TextStyle(color: AppColors.textSecondary)),
  );

  Widget _heroCard(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(30),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: AppColors.heroGradient,
      boxShadow: [
        BoxShadow(
          color: AppColors.deepGreen.withOpacity(0.25),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              const TextSpan(
                text: 'Karibu, ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextSpan(
                text: farmerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'What can we help you with today?',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 15),
        ),
      ],
    ),
  );

  Widget _availableVetsStrip(BuildContext context) {
    final vetsStream = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'vet')
        .snapshots();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Available vets', () => onOpenTab?.call(3)),
        const SizedBox(height: 10),
        SizedBox(
          height: 132,
          child: StreamBuilder<QuerySnapshot>(
            stream: vetsStream,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final vets = [...(snap.data?.docs ?? [])];
              vets.sort((a, b) {
                final av = ((a.data() as Map)['isAvailable'] ?? false) == true
                    ? 0
                    : 1;
                final bv = ((b.data() as Map)['isAvailable'] ?? false) == true
                    ? 0
                    : 1;
                if (av != bv) return av - bv;
                return ((a.data() as Map)['fullName'] ?? '')
                    .toString()
                    .compareTo(
                      ((b.data() as Map)['fullName'] ?? '').toString(),
                    );
              });

              if (vets.isEmpty) {
                return _emptyHint('No vets registered yet.');
              }

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: vets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) => _vetMiniCard(
                  context,
                  vets[i].data() as Map<String, dynamic>,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _vetMiniCard(BuildContext context, Map<String, dynamic> v) {
    final available = (v['isAvailable'] ?? false) == true;
    final name = (v['fullName'] ?? 'Vet').toString();
    final spec = (v['specialization'] ?? 'Veterinary Officer').toString();
    final area = (v['area'] ?? '').toString();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'V';

    return GestureDetector(
      onTap: () => onOpenTab?.call(3),
      child: Container(
        width: 200,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: available ? AppColors.primary : AppColors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              available ? '$spec · Available' : '$spec · Offline',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: available ? AppColors.primary : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    area.isEmpty ? '—' : area,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, VoidCallback? onViewAll) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.black,
        ),
      ),
      GestureDetector(
        onTap: onViewAll,
        child: const Text(
          'View all',
          style: TextStyle(
            color: AppColors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );

  Widget _caseCard(QueryDocumentSnapshot d) {
    final data = d.data() as Map<String, dynamic>;
    final source = (data['source'] ?? '').toString();
    final status = (data['status'] ?? '').toString();
    final sourceLabel = source == 'ussd' ? 'USSD' : 'Mobile App';
    final statusLabel = status == 'resolved' ? 'Resolved' : 'In Progress';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                (data['caseCode'] ?? '').toString(),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              _pill(sourceLabel, green: source != 'ussd'),
              const Spacer(),
              _pill(statusLabel, green: status == 'resolved'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "${data['species']} · ${data['symptom']}",
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _timeAgo(data['createdAt']),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, {required bool green}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: green ? AppColors.primaryTint : AppColors.goldTint,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: green ? AppColors.primary : AppColors.goldDark,
      ),
    ),
  );

  Widget _notifTile(QueryDocumentSnapshot d) {
    final data = d.data() as Map<String, dynamic>;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.goldTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.notifications_none,
              color: AppColors.goldDark,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        (data['title'] ?? '').toString(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      _timeAgo(data['createdAt']),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  (data['body'] ?? '').toString(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
