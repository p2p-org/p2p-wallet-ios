# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'
# ignore all warnings from all pods
inhibit_all_warnings!
def common_pods
  pod 'RxSwift', '6.5.0'
  pod 'RxCocoa', '6.5.0'
  pod 'SolanaSwift', :path => 'SolanaSwift'
end

target 'p2p_wallet' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  common_pods
#  pod 'CocoaDebug', :configurations => ['Debug', 'Release']
  pod 'BEPureLayout', :path => 'BEPureLayout'
  pod 'BECollectionView', :path => 'BECollectionView'
  pod 'FeeRelayerSwift', :path => 'FeeRelayerSwift'  
  pod 'OrcaSwapSwift', :path => 'OrcaSwapSwift'
  pod 'RenVMSwift', :path => 'RenVMSwift' 
  pod 'TransactionParser', :path => 'SolanaSwiftMagic'
  pod 'SwiftGen', '~> 6.0'
  pod 'SwiftLint'
  pod 'Action'
  pod 'KeychainSwift', '~> 19.0'
  pod 'TagListView', '~> 1.0'
  pod 'SwiftyUserDefaults', '~> 5.0'
  pod 'UITextView+Placeholder'
  pod 'SubviewAttachingTextView'
  pod 'Charts'
  pod "RxAppState"
  pod "RxGesture"
  pod 'JazziconSwift'
  pod 'Amplitude', '~> 8.3.0'
  pod 'Kingfisher'
  pod 'ListPlaceholder', :git => 'https://github.com/p2p-org/ListPlaceholder.git', :branch => 'custom_gradient_color'
  pod 'Intercom'
  pod 'SwiftFormat/CLI', '0.49.6'
  pod 'Periphery'
  pod 'RxConcurrency', :git => 'https://github.com/TrGiLong/RxConcurrency.git', :branch => 'main'

  # Firebase
  pod 'Firebase/Analytics'
  pod 'Firebase/Crashlytics'
  pod 'Resolver'
  
  pod 'GT3Captcha-iOS'
  pod 'Down', :git => 'https://github.com/p2p-org/Down.git'

#  target 'p2p_walletTests' do
#    inherit! :search_paths
#    common_pods
#    pod 'RxBlocking'
#  end

#  target 'p2p_walletUITests' do
#  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = 'NO'
      config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
    end
  end
end

