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

target 'p2p_wallet' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # development pods
  pod 'CocoaDebug', '1.7.2', :configurations => ['Debug', 'Test']
  
  if $solanaSwiftPath
    pod "SolanaSwift", :path => $solanaSwiftPath
  else
    pod 'SolanaSwift', :git => 'https://github.com/p2p-org/solana-swift.git', :branch => 'main'
  end

  # tools
  pod 'SwiftGen', '~> 6.0'
  pod 'SwiftLint'
  pod 'Periphery'
  pod 'SwiftFormat/CLI', '0.49.6'
  pod 'ReachabilitySwift', '~> 5.0.0'

  # Deprecating: BECollectionView_Combine - will be removed soon
  pod 'ListPlaceholder', :git => 'https://github.com/p2p-org/ListPlaceholder.git', :branch => 'custom_gradient_color'

  # Kits
  pod 'KeychainSwift', '19.0.0'
  pod 'SwiftyUserDefaults', '5.3.0'
  pod 'Intercom', '12.4.3'
  pod 'Down', :git => 'https://github.com/p2p-org/Down.git'

  pod 'Resolver', '1.5.0'
  pod 'JazziconSwift', :git => 'https://github.com/p2p-org/JazziconSwift.git', :branch => 'master'
  pod 'Kingfisher', '~> 7.3.2'
  pod 'PhoneNumberKit', '3.3.4'
  pod 'SkeletonUI', :git => 'https://github.com/p2p-org/SkeletonUI.git', :branch => 'master'
  pod 'Introspect', '0.1.4'
  pod 'lottie-ios', '~> 3.5.0'

  # Firebase
  pod 'Firebase/Analytics'
  pod 'Firebase/Crashlytics'
  pod 'Firebase/RemoteConfig'

  pod 'SwiftNotificationCenter'
  pod 'GoogleSignIn', '~> 6.2.4'

  # Sentry
  pod 'Sentry', :git => 'https://github.com/getsentry/sentry-cocoa.git', :tag => '7.31.5'
  
  # AppsFlyer
  pod 'AppsFlyerFramework'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
    end
  end
end
