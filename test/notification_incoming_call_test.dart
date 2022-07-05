import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notification_incoming_call/notification_incoming_call.dart';

void main() {
  const MethodChannel channel = MethodChannel('notification_incoming_call');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

}
