import 'package:eschool/data/models/notificationDetails.dart';
import 'package:eschool/data/repositories/authRepository.dart';
import 'package:eschool/utils/api.dart';
import 'package:eschool/utils/errorMessageKeysAndCodes.dart';
import 'package:eschool/utils/hiveBoxKeys.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class NotificationRepository {
  static Future<void> addNotification(
      {required NotificationDetails notificationDetails}) async {
    try {
      await Hive.box(notificationsBoxKey).put(
          notificationDetails.createdAt.toString(),
          notificationDetails.toJson());
    } catch (_) {}
  }

  Future<List<NotificationDetails>> fetchNotifications() async {
    try {
      Box notificationBox = Hive.box(notificationsBoxKey);
      List<NotificationDetails> notifications = [];

      for (var notificationKey in notificationBox.keys.toList()) {
        notifications.add(NotificationDetails.fromJson(
          Map.from(notificationBox.get(notificationKey) ?? {}),
        ));
      }

      final currentUserId = AuthRepository.getIsStudentLogIn()
          ? (AuthRepository.getStudentDetails().id ?? 0)
          : (AuthRepository.getParentDetails().id ?? 0);

      notifications = notifications
          .where((element) => element.userId == currentUserId)
          .toList();

      notifications
          .sort((first, second) => second.createdAt.compareTo(first.createdAt));

      return notifications;
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageKey);
    }
  }
}
