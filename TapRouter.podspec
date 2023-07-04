
Pod::Spec.new do |s|
  s.name             = 'TapRouter'
  s.version          = '0.0.10'
  s.summary          = 'A short description of TapRouter.'
  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://git.gametaptap.com/ios/sdk/taprouter.git'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'TapTap' => 'zhangxuanhe@xd.com' }
  s.source           = { :git => 'git@git.gametaptap.com:ios/universal/taprouter.git', :tag => s.version.to_s }
  
  s.swift_version = "5.0"
  s.ios.deployment_target = '12.0'
  s.source_files = 'TapRouter/Classes/**/*'
  s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit', 'Foundation'
end
