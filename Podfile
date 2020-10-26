# Uncomment the next line to define a global platform for your project
 platform :ios, '11.0'
def common_pods
  pod 'Alamofire', '~> 5.2'
  pod "Base58Swift"
  pod 'SwiftLint'
  pod 'RxAlamofire'
  pod 'RxCocoa'
end

target 'p2p_wallet' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  common_pods
  pod 'BEPureLayout', :git => "https://github.com/bigearsenal/BEPureLayout.git"
  pod 'SwiftGen', '~> 6.0'

  # Pods for p2p wallet

  target 'p2p_walletTests' do
    inherit! :search_paths
    common_pods
    # Pods for testing
  end

  target 'p2p_walletUITests' do
    # Pods for testing
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '11.0'
      config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = 'NO'
    end
  end
end

