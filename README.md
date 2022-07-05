# notification_incoming_call


A Flutter plugin to show incoming call notification in your Flutter app(Custom for Android/iOS).

## :star: Features

* Show an incoming call
* Start an outgoing call

  <br>

## 🚀&nbsp; Installation

1. Install Packages

  * Run this command:
    ```console
    flutter pub add notification_incoming_call
    ```
  * Add pubspec.yaml:
    ```console
        dependencies:
          notification_incoming_call: any
    ```
2. Configure Project
  * Android
     * AndroidManifest.xml
     ```
      <manifest...>
          ...
          <!-- 
              Using for load image from internet
          -->
          <uses-permission android:name="android.permission.INTERNET"/>
      </manifest>
     ```
  * iOS
     * Info.plist
      ```
      <key>UIBackgroundModes</key>
      <array>
          <string>processing</string>
          <string>remote-notification</string>
          <string>voip</string>
      </array>
      ```

3. Usage
  * Import
    ```console
    import 'package:notification_incoming_call/notification_incoming_call.dart';
    ``` 
  * Received an incoming call
    ```dart
      this._currentUuid = _uuid.v4();
      var params = <String, dynamic>{
        'id': _currentUuid,
        'nameCaller': 'Bencherif',
        'appName': 'Strolink',
        'avatar': 'https://i.strolink.co/100',
        'handle': '0123456789',
        'type': 0,
        'duration': 30000,
        'extra': <String, dynamic>{'userId': '1a2b3c4d'},
        'headers': <String, dynamic>{'apiKey': 'Abc@123!', 'platform': 'flutter'},
        'android': <String, dynamic>{
          'isCustomNotification': true,
          'isShowLogo': false,
          'backgroundColor': '#ffffff',
          'backgroundUrl': 'https://i.pravatar.cc/500',
          'actionColor': '#0ecb76'
        },
        'ios': <String, dynamic>{
          'iconName': 'AppIcon40x40',
          'handleType': 'generic',
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
    ```

  * Started an outgoing call
    ```dart
      this._currentUuid = _uuid.v4();
      var params = <String, dynamic>{
        'id': this._currentUuid,
        'nameCaller': 'Bencherif',
        'handle': '0123456789',
        'type': 1,
        'extra': <String, dynamic>{'userId': '1a2b3c4d'},
        'ios': <String, dynamic>{'handleType': 'generic'}
      };
      await NotificationIncomingCall.startCall(params);
    ```

  * Ended an incoming/outgoing call
    ```dart
      var params = <String, dynamic>{'id': this._currentUuid};
      await NotificationIncomingCall.endCall(params);
    ```

  * Ended all calls
    ```dart
      await NotificationIncomingCall.endAllCalls();
    ```

  * Get active calls. iOS: return active calls from Callkit, Android: only return last call
    ```dart
      await NotificationIncomingCall.activeCalls();
    ```
    Output
    ```json
    [{"id": "8BAA2B26-47AD-42C1-9197-1D75F662DF78", ...}]
    ```

  * Listen events
    ```dart
      NotificationIncomingCall.onEvent.listen((event) {
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
      });
    ```
  * Call from Native (iOS PushKit) 
    ```java
      var info = [String: Any?]()
      info["id"] = "44d915e1-5ff4-4bed-bf13-c423048ec97a"
      info["nameCaller"] = "Bencherif"
      info["handle"] = "0123456789"
      SwiftNotificationIncomingCallPlugin.sharedInstance?.showCallkitIncoming(notification_incoming_call.Data(args: info), fromPushKit: true)
    ```
