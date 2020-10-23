# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'
def common_pods
  pod 'Alamofire', '~> 5.2'
  pod "Base58Swift"
end

target 'p2p wallet' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  common_pods
  pod 'BEPureLayout', :git => "https://github.com/bigearsenal/BEPureLayout.git"

  # Pods for p2p wallet

  target 'p2p walletTests' do
    inherit! :search_paths
    common_pods
    # Pods for testing
  end

  target 'p2p walletUITests' do
    # Pods for testing
  end

end
