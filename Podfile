# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'
# ignore all warnings from all pods
inhibit_all_warnings!
def common_pods
  pod 'RxCocoa'
  pod 'SolanaSwift', :git => 'https://github.com/p2p-org/solana-swift.git'
end

target 'p2p_wallet' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  common_pods
  pod 'BEPureLayout', :git => 'https://github.com/bigearsenal/BEPureLayout.git'
  pod 'LazySubject', :git => 'https://github.com/bigearsenal/LazySubject.git'
  pod 'THPinViewController', :git => 'https://github.com/p2p-org/THPinViewController.git'
  pod 'BECollectionView', :git => 'https://github.com/bigearsenal/BECollectionView.git'
  pod 'SwiftGen', '~> 6.0'
  pod 'SwiftLint'
  pod 'Action'
  pod 'KeychainSwift', '~> 19.0'
  pod 'MBProgressHUD', '~> 1.2.0'
  pod 'TagListView', '~> 1.0'
  pod 'SwiftyUserDefaults', '~> 5.0'
  pod 'SDWebImage'
  pod 'UITextView+Placeholder'
  pod 'SubviewAttachingTextView'
  pod 'Charts'
  pod 'RxBiBinding'
  pod "RxAppState"
  pod 'JazziconSwift'
  pod 'Amplitude', '~> 8.3.0'
  
  # Firebase
  pod 'Firebase/Analytics'
  pod 'Firebase/Crashlytics'

  target 'p2p_walletTests' do
    inherit! :search_paths
    common_pods
    # Pods for testing
    pod 'RxBlocking'
  end

  target 'p2p_walletUITests' do
    # Pods for testing
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = 'NO'
    end
  end
end

