# Uncomment the next line to define a global platform for your project
platform :ios, '14.0'
# ignore all warnings from all pods
inhibit_all_warnings!

target 'p2p_wallet' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # development pods
  pod 'CocoaDebug', '1.7.2', :configurations => ['Debug', 'Test']

  # tools
  pod 'SwiftGen', '~> 6.0', :configurations => ['Debug', 'Test']
  pod 'SwiftLint', :configurations => ['Debug', 'Test']
  pod 'Periphery', :configurations => ['Debug', 'Test']
  pod 'SwiftFormat/CLI', '0.49.6', :configurations => ['Debug', 'Test']
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
    end
  end
end
