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
          final active = caseDocs
              .where((d) => _val(d, 'status') != 'resolved')
              .length;
          final sick = caseDocs
              .where((d) => _val(d, 'status') != 'resolved')
              .fold<int>(0, (s, d) {
                final c = (d.data() as Map<String, dynamic>)['count'];
                return s + (c is int ? c : (c is num ? c.toInt() : 1));
              });

          return StreamBuilder<QuerySnapshot>(
            stream: notifsStream,
            builder: (context, notifSnap) {
              final notifDocs = _sortedByDate(notifSnap.data?.docs ?? []);
              final unread = notifDocs
                  .where((d) => (d['read'] ?? false) == false)
                  .length;

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
                              const SizedBox(height: 16),
                              _statsRow(active, sick, unread),
                              const SizedBox(height: 20),
                              const Text(
                                'Quick actions',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _quickActions(context),
                              const SizedBox(height: 20),
                              _sectionHeader(
                                'Recent cases',
                                () => onOpenTab?.call(6),
                              ),
                              const SizedBox(height: 8),
                              if (caseDocs.isEmpty)
                                _emptyHint('No cases yet.')
                              else
                                ...caseDocs.map(_caseCard),
                              const SizedBox(height: 20),
                              _sectionHeader(
                                'Latest notifications',
                                () => onOpenTab?.call(5),
                              ),
                              const SizedBox(height: 8),
                              if (notifDocs.isEmpty)
                                _emptyHint('No notifications yet.')
                              else
                                ...notifDocs.map(_notifTile),
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
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Text(text, style: const TextStyle(color: AppColors.textSecondary)),
  );

  Widget _heroCard(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'KARIBU',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 12,
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          farmerName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          farmerArea,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => onOpenTab?.call(4),
          icon: const Icon(Icons.notifications_active, size: 18),
          label: const Text(
            'Emergency Alert',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.maroon,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _statsRow(int active, int sick, int unread) => Row(
    children: [
      Expanded(
        child: _statCard(
          '$active',
          'ACTIVE CASES',
          AppColors.primaryTint,
          AppColors.primary,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _statCard(
          '$sick',
          'SICK ANIMALS',
          AppColors.goldTint,
          AppColors.goldDark,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _statCard(
          '$unread',
          'UNREAD ALERTS',
          AppColors.maroonTint,
          AppColors.maroon,
        ),
      ),
    ],
  );

  Widget _statCard(String value, String label, Color bg, Color accent) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ],
        ),
      );

  Widget _quickActions(BuildContext context) {
    final items = <List<dynamic>>[
      ['Report sick animal', Icons.report_gmailerrorred],
      ['Request vet visit', Icons.medical_services_outlined],
      ['My livestock', Icons.pets],
      ['Disease info', Icons.menu_book_outlined],
      ['Consultations', Icons.chat_bubble_outline],
      ['Activity history', Icons.history],
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: List.generate(items.length, (i) {
        final it = items[i];
        final tints = [
          [AppColors.primaryTint, AppColors.primary],
          [AppColors.goldTint, AppColors.goldDark],
          [AppColors.maroonTint, AppColors.maroon],
        ];
        final pair = tints[i % tints.length];
        return _actionCard(
          context,
          it[0] as String,
          it[1] as IconData,
          pair[0],
          pair[1],
        );
      }),
    );
  }

  Widget _actionCard(
    BuildContext context,
    String label,
    IconData icon,
    Color iconBg,
    Color iconColor,
  ) => GestureDetector(
    onTap: () {
      if (label == 'Report sick animal') {
        onOpenTab?.call(1);
      } else if (label == 'Request vet visit') {
        onOpenTab?.call(3);
      } else if (label == 'My livestock') {
        onOpenTab?.call(2);
      } else if (label == 'Consultations') {
        onOpenTab?.call(7);
      } else if (label == 'Activity history') {
        onOpenTab?.call(6);
      } else {
        _todo(context, label);
      }
    },
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: iconColor.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: iconColor,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward,
            size: 16,
            color: iconColor.withOpacity(0.7),
          ),
        ],
      ),
    ),
  );

  Widget _sectionHeader(String title, VoidCallback? onViewAll) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      GestureDetector(
        onTap: onViewAll,
        child: const Text(
          'View all',
          style: TextStyle(
            color: AppColors.goldDark,
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
                  color: AppColors.textSecondary,
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
              color: AppColors.textPrimary,
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

  void _todo(BuildContext context, String name) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$name — coming soon')));
  }
}
