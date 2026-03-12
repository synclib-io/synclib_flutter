#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint synclib_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'synclib_flutter'
  s.version          = '0.0.1'
  s.summary          = 'Flutter wrapper for synclib - SQLite with automatic change tracking.'
  s.description      = <<-DESC
Flutter plugin that wraps synclib C library for SQLite operations with automatic change tracking for syncing.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.14'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'

  # Link with prebuilt synclib dynamic library
  s.vendored_libraries = 'Libraries/libsynclib.dylib'
  s.preserve_paths = 'Libraries/libsynclib.dylib'
end
