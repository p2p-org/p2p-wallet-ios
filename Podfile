# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'
# ignore all warnings from all pods
inhibit_all_warnings!

def key_app_kit
  pod 'TransactionParser', :path => 'KeyAppKit'
  pod 'NameService', :path => 'KeyAppKit'
  pod 'AnalyticsManager', :path => 'KeyAppKit'
  pod 'SolanaPricesAPIs', :path => 'KeyAppKit'
end

target 'p2p_wallet' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # development pods
  key_app_kit
  pod 'SolanaSwift', :path => 'SolanaSwift'
  pod 'BEPureLayout', :path => 'BEPureLayout'
  pod 'BECollectionView', :path => 'BECollectionView'
  pod 'FeeRelayerSwift', :path => 'FeeRelayerSwift'  
  pod 'OrcaSwapSwift', :path => 'OrcaSwapSwift'
  pod 'RenVMSwift', :path => 'RenVMSwift'

  # debuging
  #  pod 'CocoaDebug', :configurations => ['Debug', 'Release']

  # tools
  pod 'SwiftGen', '~> 6.0'
  pod 'SwiftLint'
  pod 'Periphery'
  pod 'SwiftFormat/CLI', '0.49.6'

  # reactive
  pod 'Action'
  pod "RxAppState"
  pod "RxGesture"
  pod 'RxSwift', '6.5.0'
  pod 'RxCocoa', '6.5.0'
  pod 'RxConcurrency', :git => 'https://github.com/TrGiLong/RxConcurrency.git', :branch => 'main'

  # kits
  pod 'KeychainSwift', '~> 19.0'
  pod 'SwiftyUserDefaults', '~> 5.0'
  pod 'Intercom'
  pod 'Down', :git => 'https://github.com/p2p-org/Down.git'

  # ui
  pod 'Resolver'
  pod 'TagListView', '~> 1.0'
  pod 'UITextView+Placeholder'
  pod 'SubviewAttachingTextView'
  pod 'Charts'
  pod 'JazziconSwift'
  pod 'Kingfisher'
  pod 'ListPlaceholder', :git => 'https://github.com/p2p-org/ListPlaceholder.git', :branch => 'custom_gradient_color'
  pod 'GT3Captcha-iOS'

  # Firebase
  pod 'Firebase/Analytics'
  pod 'Firebase/Crashlytics'
  pod 'Firebase/RemoteConfig'

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

