#import "NotificationIncomingCallPlugin.h"
#if __has_include(<notification_incoming_call/notification_incoming_call-Swift.h>)
#import <notification_incoming_call/notification_incoming_call-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "notification_incoming_call-Swift.h"
#endif

@implementation NotificationIncomingCallPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftNotificationIncomingCallPlugin registerWithRegistrar:registrar];
}
@end
