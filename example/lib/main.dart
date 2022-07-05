import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:notification_incoming_call/notification_incoming_call.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _uuid = const Uuid();
  String? _currentUuid;
  String textEvents = "";

  @override
  void initState() {
    super.initState();
    listenerEvent();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> listenerEvent() async {
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      NotificationIncomingCall.onEvent.listen((event) {
        if (kDebugMode) {
          print(event);
        }
        if (!mounted) return;
        switch (event!.name) {
          case CallEvents.actionCallIncoming:
            // TODO: received an incoming call
            break;
          case CallEvents.actionCallStart:
            // TODO: started an outgoing call
            // TODO: show screen calling in Flutter
            break;
          case CallEvents.actionCallAccept:
            // TODO: accepted an incoming call
            // TODO: show screen calling in Flutter
            break;
          case CallEvents.actionCallDecline:
            // TODO: declined an incoming call
            break;
          case CallEvents.actionCallEnded:
            // TODO: ended an incoming/outgoing call
            break;
          case CallEvents.actionCallTimeout:
            // TODO: missed an incoming call
            break;
          case CallEvents.actionCallCallback:
            // TODO: only Android - click action `Call back` from missed call notification
            break;
          case CallEvents.actionCallToggleHold:
            // TODO: only iOS
            break;
          case CallEvents.actionCallToggleMute:
            // TODO: only iOS
            break;
          case CallEvents.actionCallToggleDmtf:
            // TODO: only iOS
            break;
          case CallEvents.actionCallToggleGroup:
            // TODO: only iOS
            break;
          case CallEvents.actionCallToggleAudioSession:
            // TODO: only iOS
            break;
        }
        setState(() {
          textEvents += "${event.toString()}\n";
        });
      });
    } on Exception {
      if (kDebugMode) {
        print('ext');
      }
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Plugin example app'),
            actions: <Widget>[
              IconButton(
                icon: const Icon(
                  Icons.call,
                  color: Colors.white,
                ),
                onPressed: () async {
                  makeFakeCallInComing();
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.call_end,
                  color: Colors.white,
                ),
                onPressed: () async {
                  endCurrentCall();
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.call_made,
                  color: Colors.white,
                ),
                onPressed: () async {
                  startOutGoingCall();
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.call_merge,
                  color: Colors.white,
                ),
                onPressed: () async {
                  activeCalls();
                },
              )
            ],
          ),
          body: LayoutBuilder(
            builder:
                (BuildContext context, BoxConstraints viewportConstraints) =>
                    SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: viewportConstraints.maxHeight,
                ),
                child: Text(textEvents),
              ),
            ),
          ),
        ),
      );

  Future<void> makeFakeCallInComing() async {
    await Future.delayed(const Duration(seconds: 2), () async {
      _currentUuid = _uuid.v4();
      final params = <String, dynamic>{
        'id': _currentUuid,
        'nameCaller': 'Bencherif',
        'appName': 'Strolink',
        'avatar': 'https://i.strolink.co/100',
        'isGroup': false,
        'handle': '',
        'type': 1,
        'duration': 30000,
        'extra': <String, dynamic>{'userId': '1a2b3c4d'},
        'headers': <String, dynamic>{
          'apiKey': 'Abc@123!',
          'platform': 'flutter'
        },
        'android': <String, dynamic>{
          'isCustomNotification': true,
          'isShowLogo': false,
          // 'ringtonePath': 'ringtone_default',
          'backgroundColor': '#ffffff',
          'background': 'https://i.pravatar.cc/500',
          'actionColor': '#0ecb76'
        },
        'ios': <String, dynamic>{
          'iconName': 'AppIcon40x40',
          'handleType': '',
          'supportsVideo': true,
          'maximumCallGroups': 2,
          'maximumCallsPerCallGroup': 1,
          'audioSessionMode': 'default',
          'audioSessionActive': true,
          'audioSessionPreferredSampleRate': 44100.0,
          'audioSessionPreferredIOBufferDuration': 0.005,
          'supportsDTMF': true,
          'supportsHolding': true,
          'supportsGrouping': false,
          'supportsUngrouping': false,
          'ringtonePath': 'Ringtone.caf'
        }
      };
      await NotificationIncomingCall.showCallkitIncoming(params);
    });
  }

  Future<void> endCurrentCall() async {
    final params = <String, dynamic>{'id': _currentUuid};
    await NotificationIncomingCall.endCall(params);
  }

  Future<void> startOutGoingCall() async {
    _currentUuid = _uuid.v4();
    final params = <String, dynamic>{
      'id': _currentUuid,
      'nameCaller': 'Bencherif',
      'handle': '0123456789',
      'type': 1,
      'extra': <String, dynamic>{'userId': '1a2b3c4d'},
      'ios': <String, dynamic>{'handleType': 'number'}
    }; //number/email
    await NotificationIncomingCall.startCall(params);
  }

  Future<void> activeCalls() async {
    final calls = await NotificationIncomingCall.activeCalls();
    if (kDebugMode) {
      print(calls);
    }
  }
}
