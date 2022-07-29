# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'
# ignore all warnings from all pods
inhibit_all_warnings!

def key_app_kit
  $keyAppKitGit = 'git@github.com:p2p-org/key-app-kit-swift.git'
  $keyAppKitBranch = 'develop'

  pod 'TransactionParser', :git => $keyAppKitGit, :branch => $keyAppKitBranch
  pod 'NameService', :git => $keyAppKitGit, :branch => $keyAppKitBranch
  pod 'AnalyticsManager', :git => $keyAppKitGit, :branch => $keyAppKitBranch
  pod 'Cache', :git => $keyAppKitGit, :branch => $keyAppKitBranch
  pod 'KeyAppKitLogger', :git => $keyAppKitGit, :branch => $keyAppKitBranch
  pod 'SolanaPricesAPIs', :git => $keyAppKitGit, :branch => $keyAppKitBranch
  pod 'Onboarding', :git => $keyAppKitGit, :branch => $keyAppKitBranch
  pod 'JSBridge', :git => $keyAppKitGit, :branch => $keyAppKitBranch
  pod 'CountriesAPI', :git => $keyAppKitGit, :branch => $keyAppKitBranch
end

target 'p2p_wallet' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # development pods
  key_app_kit
  pod 'CocoaDebug', :configurations => ['Debug', 'Test']
  pod 'SolanaSwift', :git => 'https://github.com/p2p-org/solana-swift.git', :branch => 'main'
  pod 'BEPureLayout', :git => 'https://github.com/p2p-org/BEPureLayout.git', :branch => 'master'
  pod 'BECollectionView_Core', :git => 'https://github.com/bigearsenal/BECollectionView.git', :branch => 'master'
  pod 'BECollectionView', :git => 'https://github.com/bigearsenal/BECollectionView.git', :branch => 'master'
  pod 'BECollectionView_Combine', :git => 'https://github.com/bigearsenal/BECollectionView.git', :branch => 'master'
  pod 'FeeRelayerSwift', :git => 'https://github.com/p2p-org/FeeRelayerSwift.git', :branch => 'master'
  pod 'OrcaSwapSwift', :git => 'https://github.com/p2p-org/OrcaSwapSwift.git', :branch => 'main'
  pod 'RenVMSwift', :git => 'https://github.com/p2p-org/RenVMSwift.git', :branch => 'master'

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
  pod 'CombineCocoa'

  # kits
  pod 'KeychainSwift', '~> 19.0'
  pod 'SwiftyUserDefaults', '~> 5.0'
  pod 'Intercom'
  pod 'Down', :git => 'https://github.com/p2p-org/Down.git'

  # ui
  pod 'KeyAppUI', :git => 'git@github.com:p2p-org/KeyAppUI.git', :branch => 'develop'
  pod 'Resolver'
  pod 'TagListView', '~> 1.0'
  pod 'UITextView+Placeholder'
  pod 'SubviewAttachingTextView'
  pod 'Charts'
  pod 'JazziconSwift', '~> 1.1.0'
  pod 'Kingfisher'
  pod 'ListPlaceholder', :git => 'https://github.com/p2p-org/ListPlaceholder.git', :branch => 'custom_gradient_color'
  pod 'GT3Captcha-iOS'
  pod 'PhoneNumberKit', '~> 3.3.4'

  # Firebase
  pod 'Firebase/Analytics'
  pod 'Firebase/Crashlytics'
  pod 'Firebase/RemoteConfig'
  
  pod 'SwiftNotificationCenter'
  pod 'GoogleSignIn'

  # Others
  pod 'SwiftJWT'
  
  # Sentry
  pod 'Sentry', :git => 'https://github.com/getsentry/sentry-cocoa.git', :tag => '7.18.1'

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
    
    if target.name == 'BECollectionView_Combine' || target.name == 'BECollectionView' || target.name == 'BECollectionView_Core'
        target.build_configurations.each do |config|
          config.build_settings['SWIFT_INSTALL_OBJC_HEADER'] = 'No'
        end
    end
  end
end
