source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '15.0'

target 'OpenCV' do

    pod 'OpenCV'
    pod 'SnapKit'

end

post_install do |installer|
  
  installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
          config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
          
          config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = ""
          config.build_settings['CODE_SIGNING_REQUIRED'] = "NO"
          config.build_settings['CODE_SIGNING_ALLOWED'] = "NO"
          
          config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"

      end
  end
end
