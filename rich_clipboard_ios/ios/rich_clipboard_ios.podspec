#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'rich_clipboard_ios'
  s.version          = '0.0.1'
  s.summary          = 'An iOS implementation of the rich_clipboard plugin.'
  s.description      = <<-DESC
  An iOS implementation of the rich_clipboard plugin.
                       DESC
  s.homepage         = 'https://github.com/BringingFire/rich_clipboard'
  s.license          = { :type => 'BSD', :file => '../LICENSE' }
  s.author           = { 'Bringing Fire' => 'engineering@bringingfire.com' }
  s.source           = { :path => '.' }  
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'

  s.platform = :ios, '9.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }  
end
