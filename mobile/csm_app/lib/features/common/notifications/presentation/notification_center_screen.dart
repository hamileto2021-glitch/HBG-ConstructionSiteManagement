import 'package:flutter/material.dart';
import 'package:csm_app/core/network/api_client.dart';

import '../data/notification.dart';
import '../data/notification_repository.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends State<NotificationCenterScreen> {
  late final NotificationRepository _repository;
  List<AppNotification> _notifications = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _repository = NotificationRepository(ApiClient());
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final result = await _repository.getAll();

      setState(() {
        _notifications = result;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _markRead(AppNotification notification) async {
    if (notification.isRead) return;

    await _repository.markRead(notification.id, true);
    await _load();
  }

  IconData _icon(String type) {
    switch (type.toLowerCase()) {
      case 'safety':
        return Icons.health_and_safety;
      case 'inventory':
        return Icons.inventory;
      case 'procurement':
        return Icons.shopping_cart;
      case 'finance':
        return Icons.account_balance_wallet;
      case 'hrm':
        return Icons.people;
      case 'project':
        return Icons.engineering;
      case 'compliance':
        return Icons.rule;
      default:
        return Icons.notifications;
    }
  }
  List<AppNotification> get _filtered {
    if (_filter == 'all') return _notifications;

    if (_filter == 'unread') {
      return _notifications.where((e) => !e.isRead).toList();
    }

    return _notifications
        .where((e) => e.type.toLowerCase() == _filter)
        .toList();
  }
  Widget _chip(String value, String label) {
    final selected = _filter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _filter = value);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? const Center(
        child: Text('No notifications'),
      )
          : RefreshIndicator(
        onRefresh: _load,
        child: Column(
          children: [
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _chip('all', 'All'),
                  _chip('unread', 'Unread'),
                  _chip('safety', 'Safety'),
                  _chip('project', 'Projects'),
                  _chip('finance', 'Finance'),
                  _chip('inventory', 'Inventory'),
                  _chip('hrm', 'HR'),
                  _chip('compliance', 'Compliance'),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: _filtered.length,
                separatorBuilder: (context, index) =>
                const Divider(height: 1),
                itemBuilder: (context, index) {
                  final n = _filtered[index];

                  return ListTile(
                    leading: CircleAvatar(
                      child: Icon(_icon(n.type)),
                    ),
                    title: Text(
                      n.title,
                      style: TextStyle(
                        fontWeight: n.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      n.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      '${n.createdAtUtc.day}/${n.createdAtUtc.month}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onTap: () => _markRead(n),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}