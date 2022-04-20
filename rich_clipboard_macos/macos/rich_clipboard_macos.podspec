#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint rich_clipboard.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'rich_clipboard_macos'
  s.version          = '0.0.1'
  s.summary          = 'macOS implementation of the rich_clipboard plugin.'
  s.description      = <<-DESC
Provides access to additional data types from NSClipboard via a method channel.
                       DESC
  s.homepage         = 'http://github.com/BringingFire/rich_clipboard'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Bringing Fire' => 'engineering@bringingfire.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
