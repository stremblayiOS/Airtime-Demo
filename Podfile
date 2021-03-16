use_frameworks!
inhibit_all_warnings!

platform :ios, '14.0'
target 'MyRooms' do
    pod 'Alamofire'
    pod 'Swinject'
    pod 'OHHTTPStubs/Swift'
    pod 'SwiftKeychainWrapper'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end
  end
end
