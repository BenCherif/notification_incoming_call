#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint notification_incoming_call.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'notification_incoming_call'
  s.version          = '1.0.0'
  s.summary          = 'Package to handle incoming call by showing notification on both IOS & Android platforms .'
  s.description      = <<-DESC
Package to handle incoming call by showing notification on both IOS & Android platforms .
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Abderrahim El imame' => 'admin@strolink.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '9.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
