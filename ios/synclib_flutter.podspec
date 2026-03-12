#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint synclib_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'synclib_flutter'
  s.version          = '0.0.9'
  s.summary          = 'Flutter wrapper for synclib - SQLite with automatic change tracking.'
  s.description      = <<-DESC
Flutter plugin that wraps synclib C library for SQLite operations with automatic change tracking for syncing.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Link with prebuilt synclib static library
  s.libraries = 'c++'

  # Use different library for simulator vs device
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'OTHER_LDFLAGS[sdk=iphoneos*]' => '$(inherited) -force_load $(PODS_TARGET_SRCROOT)/Libraries/libsynclib_device.a',
    'OTHER_LDFLAGS[sdk=iphonesimulator*]' => '$(inherited) -force_load $(PODS_TARGET_SRCROOT)/Libraries/libsynclib_simulator.a'
  }

  s.preserve_paths = ['Libraries/libsynclib_device.a', 'Libraries/libsynclib_simulator.a']
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'synclib_flutter_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
