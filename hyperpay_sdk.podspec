#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint payment.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'hyperpay_sdk'
  s.version          = '7.4.0'
  s.summary          = 'A new Flutter project.'
  s.description      = 'DESC A new Flutter project.DESC'
  s.homepage         = 'https://pub.dev/packages/hyperpay_plugin'
  s.license          = { :file => 'LICENSE' }
  s.author           = { 'chahlaouy' => 'chahlaouy1991@gmail.com' }
  s.source           = { :path => '.' }

  s.preserve_paths = 'OPPWAMobile.xcframework', 'ipworks3ds_sdk.xcframework'
  s.xcconfig = { 'OTHER_LDFLAGS' => '-framework OPPWAMobile -framework ipworks3ds_sdk ' }
  s.vendored_frameworks = 'OPPWAMobile.xcframework', 'ipworks3ds_sdk.xcframework'
  s.static_framework = true 

end