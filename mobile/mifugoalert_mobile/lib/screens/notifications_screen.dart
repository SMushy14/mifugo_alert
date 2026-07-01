import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import 'farmer_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({
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
        .collection('notifications')
        .where('userId', isEqualTo: farmerId)
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
                  if (snap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Could not load notifications:\n${snap.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.maroon),
                        ),
                      ),
                    );
                  }
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final List<QueryDocumentSnapshot> notifs =
                      [...(snap.data?.docs ?? [])]..sort((a, b) {
                        final ta =
                            (a.data() as Map<String, dynamic>)['createdAt'];
                        final tb =
                            (b.data() as Map<String, dynamic>)['createdAt'];
                        if (ta is Timestamp && tb is Timestamp) {
                          return tb.compareTo(ta);
                        }
                        return 0;
                      });

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Notifications',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (notifs.isNotEmpty)
                              TextButton.icon(
                                onPressed: () =>
                                    _confirmClearAll(context, notifs),
                                icon: const Icon(
                                  Icons.delete_sweep_outlined,
                                  size: 18,
                                  color: AppColors.maroon,
                                ),
                                label: const Text(
                                  'Clear all',
                                  style: TextStyle(color: AppColors.maroon),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Alerts, SMS updates and case news.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (notifs.isEmpty)
                          _emptyState()
                        else
                          ...notifs.map((d) => _dismissibleCard(context, d)),
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
    child: const Column(
      children: [
        Icon(
          Icons.notifications_off_outlined,
          color: AppColors.textSecondary,
          size: 32,
        ),
        SizedBox(height: 10),
        Text(
          'No notifications yet.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    ),
  );

  Widget _dismissibleCard(BuildContext context, QueryDocumentSnapshot d) {
    return Dismissible(
      key: ValueKey(d.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.maroon,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete notification?'),
                content: const Text('This notification will be removed.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.maroon,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) async {
        try {
          await FirebaseFirestore.instance
              .collection('notifications')
              .doc(d.id)
              .delete();
        } catch (_) {}
      },
      child: _card(d),
    );
  }

  Widget _card(QueryDocumentSnapshot d) {
    final n = d.data() as Map<String, dynamic>;
    final read = (n['read'] ?? false) == true;
    final type = (n['type'] ?? '').toString();
    final accent = _accentFor(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: read ? AppColors.surface : accent.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: read ? AppColors.border : accent.withOpacity(0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.16),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_iconFor(type), color: accent, size: 20),
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
                                  (n['title'] ?? '').toString(),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (!read)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Text(
                                _timeAgo(n['createdAt']),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (n['body'] ?? '').toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                          if ((n['vetPhone'] ?? '').toString().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _callChip((n['vetPhone']).toString()),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _callChip(String phone) => Builder(
    builder: (context) => GestureDetector(
      onTap: () async {
        final uri = Uri.parse(
          'tel:${phone.replaceAll(RegExp(r'[^0-9+]'), '')}',
        );
        if (await canLaunchUrl(uri)) await launchUrl(uri);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: AppColors.goldGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.call, size: 15, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              'Call $phone',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _confirmClearAll(
    BuildContext context,
    List<QueryDocumentSnapshot> notifs,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text('This will remove all notifications permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.maroon),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    for (final d in notifs) {
      batch.delete(db.collection('notifications').doc(d.id));
    }
    await batch.commit();
  }

  Color _accentFor(String type) {
    switch (type) {
      case 'emergency':
        return AppColors.maroon;
      case 'vet_assigned':
      case 'consultation':
        return AppColors.primary;
      case 'reminder':
        return AppColors.goldDark;
      default:
        return AppColors.primary;
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'reminder':
        return Icons.chat_bubble_outline;
      case 'emergency':
        return Icons.warning_amber_rounded;
      case 'consultation':
        return Icons.info_outline;
      case 'vet_assigned':
        return Icons.medical_services_outlined;
      default:
        return Icons.notifications_none;
    }
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