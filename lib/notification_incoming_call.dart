import 'dart:async';

import 'package:flutter/services.dart';

/// Instance to use library functions.
/// * showCallkitIncoming(dynamic)
/// * startCall(dynamic)
/// * endCall(dynamic)
/// * endAllCalls()
///
class NotificationIncomingCall {
  int fakeVariable = 0;//to avoid lint warnings "the class can not contain just static functions"
  static const MethodChannel _channel =
      MethodChannel('notification_incoming_call');
  static const EventChannel _eventChannel =
      EventChannel('notification_incoming_call_events');

  /// Listen to event callback from [NotificationIncomingCall].
  ///
  /// NotificationIncomingCall.onEvent.listen((event) {
  /// CallEvents.actionCallIncoming - Received an incoming call
  /// CallEvents.actionCallStart - Started an outgoing call
  /// CallEvents.actionCallAccept - Accepted an incoming call
  /// CallEvents.actionCallDecline - Declined an incoming call
  /// CallEvents.actionCallEnded - Ended an incoming/outgoing call
  /// CallEvents.actionCallTimeout - Missed an incoming call
  /// CallEvents.actionCallCallback - only Android (click action `Call back` from missed call notification)
  /// CallEvents.actionCallToggleHold - only iOS
  /// CallEvents.actionCallToggleMute - only iOS
  /// CallEvents.actionCallToggleDmtf - only iOS
  /// CallEvents.actionCallToggleGroup - only iOS
  /// CallEvents.actionCallToggleAudioSession - only iOS
  /// }
  static Stream<CallEvents?> get onEvent =>
      _eventChannel.receiveBroadcastStream().map(_receiveCallEvents);

  /// Show Callkit Incoming.
  /// On iOS, using Callkit. On Android, using a custom UI.
  static Future showCallkitIncoming(dynamic params) async {
    await _channel.invokeMethod("showCallkitIncoming", params);
  }

  /// Start an Outgoing call.
  /// On iOS, using Callkit(create a history into the Phone app).
  /// On Android, Nothing(only callback event listener).
  static Future startCall(dynamic params) async {
    await _channel.invokeMethod("startCall", params);
  }

  /// End an Incoming/Outgoing call.
  /// On iOS, using Callkit(update a history into the Phone app).
  /// On Android, Nothing(only callback event listener).
  static Future endCall(dynamic params) async {
    await _channel.invokeMethod("endCall", params);
  }

  /// End all calls.
  static Future endAllCalls() async {
    await _channel.invokeMethod("endAllCalls");
  }

  /// Get active calls.
  /// On iOS: return active calls from Callkit.
  /// On Android: only return last call
  static Future activeCalls() async => _channel.invokeMethod("activeCalls");

  static CallEvents? _receiveCallEvents(dynamic data) {
    var event = "";
    dynamic body = {};
    if (data is Map) {
      event = data['event'];
      body = Map<String, dynamic>.from(data['body']);
    }
    return CallEvents(event, body);
  }
}

class CallEvents {
  static const String actionCallIncoming =
      "co.strolink.notification_incoming_call.actionCallIncoming";
  static const String actionCallStart =
      "co.strolink.notification_incoming_call.actionCallStart";
  static const String actionCallAccept =
      "co.strolink.notification_incoming_call.actionCallAccept";
  static const String actionCallDecline =
      "co.strolink.notification_incoming_call.actionCallDecline";
  static const String actionCallEnded =
      "co.strolink.notification_incoming_call.actionCallEnded";
  static const String actionCallTimeout =
      "co.strolink.notification_incoming_call.actionCallTimeout";
  static const String actionCallCallback =
      "co.strolink.notification_incoming_call.actionCallCallback";
  static const String actionCallToggleHold =
      "co.strolink.notification_incoming_call.actionCallToggleHold";
  static const String actionCallToggleMute =
      "co.strolink.notification_incoming_call.actionCallToggleMute";
  static const String actionCallToggleDmtf =
      "co.strolink.notification_incoming_call.actionCallToggleDmtf";
  static const String actionCallToggleGroup =
      "co.strolink.notification_incoming_call.actionCallToggleGroup";
  static const String actionCallToggleAudioSession =
      "co.strolink.notification_incoming_call.actionCallToggleAudioSession";

  late String name;
  late dynamic body;

  CallEvents(this.name, this.body);

  @override
  String toString() =>
      "{ event: ${name.toString()}, body: ${body.toString()} }";
}
