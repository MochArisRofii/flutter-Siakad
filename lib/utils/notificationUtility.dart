import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:eschool/app/routes.dart';
import 'package:eschool/data/models/notificationDetails.dart';
import 'package:eschool/data/repositories/authRepository.dart';
import 'package:eschool/data/repositories/notificationRepository.dart';
import 'package:eschool/ui/screens/home/homeScreen.dart';
import 'package:eschool/utils/constants.dart';
import 'package:eschool/utils/utils.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

// ignore: avoid_classes_with_only_static_members
class NotificationUtility {
  static String generalNotificationType = "general";

  static String assignmentlNotificationType = "assignment";
  static String paymentNotificationType = "payment";
  static String notificationType = "Notification";

  static Future<void> setUpNotificationService(
    BuildContext buildContext,
  ) async {
    NotificationSettings notificationSettings =
        await FirebaseMessaging.instance.getNotificationSettings();

    print(notificationSettings.authorizationStatus.toString());

    //ask for permission
    if (notificationSettings.authorizationStatus ==
            AuthorizationStatus.notDetermined ||
        notificationSettings.authorizationStatus ==
            AuthorizationStatus.denied) {
      notificationSettings =
          await FirebaseMessaging.instance.requestPermission();

      //if permission is provisionnal or authorised
      if (notificationSettings.authorizationStatus ==
              AuthorizationStatus.authorized ||
          notificationSettings.authorizationStatus ==
              AuthorizationStatus.provisional) {
        if (buildContext.mounted) {
          initNotificationListener(buildContext);
        }
      }

      //if permission denied
    } else if (notificationSettings.authorizationStatus ==
        AuthorizationStatus.denied) {
      return;
    }
    if (buildContext.mounted) {
      initNotificationListener(buildContext);
    }
  }

  static void initNotificationListener(BuildContext buildContext) {
    // FirebaseMessaging.instance.setForegroundNotificationPresentationOptions();
    FirebaseMessaging.onMessage.listen(foregroundMessageListener);
    FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((remoteMessage) {
      onMessageOpenedAppListener(remoteMessage, buildContext);
    });
  }

  static Future<void> onBackgroundMessage(RemoteMessage remoteMessage) async {
    //perform any background task if needed here
    final type = (remoteMessage.data['type'] ?? "").toString();
    if (type.toLowerCase() == notificationType.toLowerCase()) {
      NotificationRepository.addNotification(
          notificationDetails: NotificationDetails(
              userId: AuthRepository.getIsStudentLogIn()
                  ? (AuthRepository.getStudentDetails().id ?? 0)
                  : (AuthRepository.getParentDetails().id ?? 0),
              attachmentUrl: remoteMessage.data['image'] ?? "",
              body: remoteMessage.notification?.title ?? "",
              createdAt: DateTime.timestamp(),
              title: remoteMessage.notification?.body ?? ""));
    }
  }

  static Future<void> foregroundMessageListener(
    RemoteMessage remoteMessage,
  ) async {
    await FirebaseMessaging.instance.getToken();

    final type = (remoteMessage.data['type'] ?? "").toString();

    if (type == paymentNotificationType) {
      Future.delayed(Duration(seconds: 5), () {
        if (Routes.currentRoute == Routes.confirmPayment) {
          Utils.rootNavigatorKey.currentState?.pop();
        }
      });
    } else if (type.toLowerCase() == notificationType.toLowerCase()) {
      NotificationRepository.addNotification(
          notificationDetails: NotificationDetails(
              userId: AuthRepository.getIsStudentLogIn()
                  ? (AuthRepository.getStudentDetails().id ?? 0)
                  : (AuthRepository.getParentDetails().id ?? 0),
              attachmentUrl: remoteMessage.data['image'] ?? "",
              body: remoteMessage.notification?.title ?? "",
              createdAt: DateTime.timestamp(),
              title: remoteMessage.notification?.body ?? ""));
    }

    createLocalNotification(dimissable: true, message: remoteMessage);
  }

  static void onMessageOpenedAppListener(
    RemoteMessage remoteMessage,
    BuildContext buildContext,
  ) {
    _onTapNotificationScreenNavigateCallback(
      remoteMessage.data['type'] ?? "",
      remoteMessage.data,
    );
  }

  static void _onTapNotificationScreenNavigateCallback(
    String notificationType,
    Map<String, dynamic> data,
  ) {
    if (notificationType == generalNotificationType) {
      Utils.rootNavigatorKey.currentState?.pushNamed(Routes.noticeBoard);
    } else if (notificationType == assignmentlNotificationType) {
      HomeScreen.homeScreenKey.currentState?.navigateToAssignmentContainer();
    } else if (notificationType == paymentNotificationType) {}
  }

  static Future<void> initializeAwesomeNotification() async {
    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: notificationChannelKey,
        channelName: 'Basic notifications',
        channelDescription: 'Notification channel for basic tests',
        vibrationPattern: highVibrationPattern,
      ),
    ]);
  }

  static Future<bool> isLocalNotificationAllowed() async {
    const notificationPermission = Permission.notification;
    final status = await notificationPermission.status;
    return status.isGranted;
  }

  /// Use this method to detect when a new notification or a schedule is created
  static Future<void> onNotificationCreatedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    // Your code goes here
  }

  /// Use this method to detect every time that a new notification is displayed
  static Future<void> onNotificationDisplayedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    // Your code goes here
  }

  /// Use this method to detect if the user dismissed a notification
  static Future<void> onDismissActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    // Your code goes here
  }

  /// Use this method to detect when the user taps on a notification or action button
  static Future<void> onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    _onTapNotificationScreenNavigateCallback(
      (receivedAction.payload ?? {})['type'] ?? "",
      Map.from(receivedAction.payload ?? {}),
    );
  }

  static Future<void> createLocalNotification({
    required bool dimissable,
    required RemoteMessage message,
  }) async {
    final String title = message.notification?.title ?? "";
    final String body = message.notification?.body ?? "";

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        autoDismissible: dimissable,
        title: title,
        body: body,
        id: 1,
        locked: !dimissable,
        payload: {"type": message.data['type'] ?? ""},
        channelKey: notificationChannelKey,
      ),
    );
  }
}
