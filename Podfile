# Uncomment the next line to define a global platform for your project
platform :ios, '14.0'
# ignore all warnings from all pods
inhibit_all_warnings!

# ENV Variables
$keyAppKitPath = ENV['KEY_APP_KIT_SWIFT']
$solanaSwiftPath = ENV['SOLANA_SWIFT']
$keyAppUI = ENV['KEY_APP_UI']

puts $keyAppKitPath
puts $keyAppUI

def key_app_kit
  $dependencies = [
    "TransactionParser",
    "NameService",
    "AnalyticsManager",
    "Cache",
    "KeyAppKitLogger",
    "SolanaPricesAPIs",
    "Onboarding",
    "JSBridge",
    "CountriesAPI",
    "KeyAppKitCore",
    "P2PSwift",
    "Solend",
    "Send",
    "History"
  ]

  if $keyAppKitPath
    for $dependency in $dependencies do
      pod $dependency, :path => $keyAppKitPath
    end
  else
    $keyAppKitGit = 'https://github.com/p2p-org/key-app-kit-swift.git'
    $keyAppKitBranch = 'feature/pwn-6024'
    for $dependency in $dependencies do
      pod $dependency, :git => $keyAppKitGit, :branch => $keyAppKitBranch
    end
  end
end

target 'p2p_wallet' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # development pods
  key_app_kit
  pod 'CocoaDebug', :configurations => ['Debug', 'Test']
  pod 'BEPureLayout', :git => 'https://github.com/p2p-org/BEPureLayout.git', :branch => 'master'
  pod 'BECollectionView_Core', :git => 'https://github.com/bigearsenal/BECollectionView.git', :branch => 'master'
  pod 'BECollectionView', :git => 'https://github.com/bigearsenal/BECollectionView.git', :branch => 'master'
  pod 'BECollectionView_Combine', :git => 'https://github.com/bigearsenal/BECollectionView.git', :branch => 'master'
  pod 'FeeRelayerSwift', :git => 'https://github.com/p2p-org/FeeRelayerSwift.git', :branch => 'develop'
  pod 'OrcaSwapSwift', :git => 'https://github.com/p2p-org/OrcaSwapSwift.git', :branch => 'main'
  pod 'RenVMSwift', :git => 'https://github.com/p2p-org/RenVMSwift.git', :branch => 'feature/pwn-6024'
  
  if $solanaSwiftPath
    pod "SolanaSwift", :path => $solanaSwiftPath
  else
    pod 'SolanaSwift', :git => 'https://github.com/p2p-org/solana-swift.git', :branch => 'feature/isOnCurveAsPublic'
  end

  # tools
  pod 'SwiftGen', '~> 6.0'
  pod 'SwiftLint'
  pod 'Periphery'
  pod 'SwiftFormat/CLI', '0.49.6'
  pod 'ReachabilitySwift', '~> 5.0.0'

  # reactive
  pod 'Action', '5.0.0'
  pod 'RxAppState', '1.7.1'
  pod 'RxGesture', '4.0.4'
  pod 'RxSwift', '6.5.0'
  pod 'RxCocoa', '6.5.0'
  pod 'RxConcurrency', :git => 'https://github.com/TrGiLong/RxConcurrency.git', :branch => 'main'
  pod 'RxCombine', '2.0.1'
  pod 'CombineCocoa', '0.4.0'

  # Kits
  pod 'KeychainSwift', '19.0.0'
  pod 'SwiftyUserDefaults', '5.3.0'
  pod 'Intercom', '12.4.3'
  pod 'Down', :git => 'https://github.com/p2p-org/Down.git'

  # ui
  if $keyAppUI
    pod "KeyAppUI", :path => $keyAppUI
  else
    pod 'KeyAppUI', :git => 'git@github.com:p2p-org/KeyAppUI.git', :branch => 'main'
  end

  pod 'Resolver', '1.5.0'
  pod 'JazziconSwift', :git => 'https://github.com/p2p-org/JazziconSwift.git', :branch => 'master'
  pod 'Kingfisher', '~> 7.3.2'
  pod 'ListPlaceholder', :git => 'https://github.com/p2p-org/ListPlaceholder.git', :branch => 'custom_gradient_color'
  pod 'GT3Captcha-iOS'
  pod 'PhoneNumberKit', '3.3.4'
  pod 'SkeletonUI', :git => 'https://github.com/p2p-org/SkeletonUI.git', :branch => 'master'
  pod 'Introspect', '0.1.4'
  pod 'lottie-ios', '~> 3.5.0'

  # Firebase
  pod 'Firebase/Analytics'
  pod 'Firebase/Crashlytics'
  pod 'Firebase/RemoteConfig'

  pod 'SwiftNotificationCenter'
  pod 'GoogleSignIn'

  # Sentry
  pod 'Sentry', :git => 'https://github.com/getsentry/sentry-cocoa.git', :tag => '7.18.1'

  # AppsFlyer
  pod 'AppsFlyerFramework'

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
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = 'NO'
      config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
    end

    if target.name == 'BECollectionView_Combine' || target.name == 'BECollectionView' || target.name == 'BECollectionView_Core'
        target.build_configurations.each do |config|
          config.build_settings['SWIFT_INSTALL_OBJC_HEADER'] = 'No'
        end
    end
  end
end
