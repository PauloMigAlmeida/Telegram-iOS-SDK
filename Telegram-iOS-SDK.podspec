#
# Be sure to run `pod lib lint Telegram-iOS-SDK.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "Telegram-iOS-SDK"
  s.version          = "0.0.5"
  s.summary          = "Telegram-iOS-SDK. Source code of Telegram 2.8 ported to pods"
  s.description      = <<-DESC
                       arm64 compatible. Work in progress.
                       Feel free to contribute.
                       DESC
  s.homepage         = "https://github.com/batkov/Telegram-iOS-SDK"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'GPLv2'
  s.author           = { "Hariton Batkov" => "batkov@i.ua" }
  s.source           = { :git => "https://github.com/batkov/Telegram-iOS-SDK.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/batkov111'

  s.platform     = :ios, '6.0'
  s.requires_arc = 'Pod/Classes/ARC/**/*'
  s.xcconfig = { 'OTHER_LDFLAGS' => '-lstdc++ -ObjC', 'ENABLE_BITCODE' => 'NO' }
  s.source_files = 'Pod/Classes/**/*.{h,m,c,cpp,mm}'
  s.compiler_flags = '-Wall'
  s.resource_bundles = {
    'Telegram-iOS-SDK' => ['Pod/Assets/**/*']
  }
  s.frameworks = 'AddressBook', 'AddressBookUI', 'CoreLocation'
  s.dependency 'BLPhoneFormat'
  s.dependency 'BLContactsViewController'   
  s.dependency 'pop'
  s.ios.vendored_library = 'Pod/Libs/**'
  s.library = 'z', 'crypto'
   
end
