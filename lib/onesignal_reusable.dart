library onesignal_reusable;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';

class OneSignalService {
  static bool _initialized = false;

  /// Initialize OneSignal with App ID
  static Future<void> initialize({
    required String appId,
    bool requireConsent = false,
  }) async {
    if (_initialized) return;

    // Set Log Levels (new API)
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.Debug.setAlertLevel(OSLogLevel.none);

    // Initialize the SDK with your App ID
    OneSignal.initialize(appId);

    // Determine if user consent is required
    // This should be done before OneSignal.initialize is called for GDPR.
    // If requireConsent is true, the SDK will not be fully enabled until
    // OneSignal.consentGiven(true) is called.
    if (requireConsent) {
      OneSignal.consentRequired(true);
    }

    // OneSignal recommends using an In-App Message to prompt for permission
    // instead of calling the prompt method directly.
    // The OneSignal dashboard provides an in-app messaging template for this purpose.
    // If you need to manually request permission, you can use:
    // OneSignal.Notifications.requestPermission(true);

    _initialized = true;
  }

  /// Get external user ID
  static Future<String?> getExternalId() async {
    return OneSignal.User.getExternalId();
  }

  /// Set external user ID
  static Future<void> setExternalId(String externalId) async {
    await OneSignal.login(externalId);
  }

  /// Remove external user ID
  static Future<void> removeExternalId() async {
    await OneSignal.logout();
  }

  /// Get OneSignal user ID (player ID)
  static Future<String?> getUserId() async {
    String? oneSignalId = await OneSignal.User.getOnesignalId();
    return oneSignalId;
  }

  /// Send push notification via OneSignal REST API
  static Future<void> sendNotification({
    required String appId,
    required String restApiKey,
    required String message,
    String? heading,
    List<String>? playerIds,
  }) async {
    final url = Uri.parse("https://onesignal.com/api/v1/notifications");
    final headers = {
      "Content-Type": "application/json; charset=utf-8",
      "Authorization": "Basic $restApiKey",
    };

    final body = {
      "app_id": appId,
      "contents": {"en": message},
    };

    if (heading != null) {
      body["headings"] = {"en": heading};
    }

    if (playerIds != null && playerIds.isNotEmpty) {
      body["include_player_ids"] = playerIds;
    }

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        debugPrint("Notification sent successfully.");
      } else {
        debugPrint(
          "Failed to send notification. Status: ${response.statusCode}",
        );
        debugPrint("Response: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error sending notification: $e");
    }
  }
}
