import 'package:csm_app/core/network/api_client.dart';

import 'notification.dart';

class NotificationRepository {
  NotificationRepository(this._api);

  final ApiClient _api;

  Future<List<AppNotification>> getAll({bool? isRead}) async {
    final endpoint = isRead == null
        ? '/notifications'
        : '/notifications?isRead=$isRead';

    final response = await _api.getList(endpoint);

    return response
        .map(
          (e) => AppNotification.fromJson(
        Map<String, dynamic>.from(e as Map),
      ),
    )
        .toList();
  }

  Future<int> getUnreadCount() async {
    final value = await _api.getValue('/notifications/unread-count');
    return value as int;
  }

  Future<void> markRead(String notificationId, bool isRead) async {
    await _api.patch(
      '/notifications/$notificationId/read',
      body: {
        'isRead': isRead,
      },
    );
  }
}