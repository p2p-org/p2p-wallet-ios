# Declarative syntax for writing UI

The declarative syntax has been used in many frameworks like React, SwiftUI and Flutter and has many advantages in
comparison to imperative syntax.

#### Advantages:

1. Easy to write and maintain UI code.
2. Less code (reduce 10-15% lines).
3. Easy to create a new components and reuse them.

#### Disadvantages:

1. Some on-chain methods suppose to reduce code, but not because of the limitation of swift language.

#### New approach

Reduce number of classes that required to create a view (scene) from 4 to 3. In the most of the cases the ViewController
class in the old approach responses only for handling navigation. All nested VCs has empty navigation logic and only
contains UI part because the navigation is being handling by their parent VC. Moving to coordinator pattern in the
future also removes this response.

*File structure*

1. SomeScene.ViewController.swift
2. SomeScene.ViewModel.swift
3. SomeScene.swift

New pattern:

```swift
extension SomeScene {
    final class ViewController: BEScene {
        override var preferredNavigationBarStype: NavigationBarStyle { .hidden }
        
        private let viewModel: ViewModel
        
        init(viewModel: ViewModel) {
            self.viewModel = viewModel
            super.init()
        }
        
        // All UI components should be declare here 
        override func build() -> UIView {
            BECenter {
                UILabel(text: "Hello world!")
            }
        }
    }
}
```

### Code example

Old code (128 lines)

```swift
extension SendToken.SelectNetwork {
    final class ViewController: SendToken.BaseViewController {
        // MARK: - Properties
        private let viewModel: SendTokenSelectNetworkViewModelType
        private var selectedNetwork: SendToken.Network {
            didSet {
                reloadData()
            }
        }
        
        // MARK: - Subviews
        private lazy var networkViews: [_NetworkView] = {
            let prices = viewModel.getSOLAndRenBTCPrices()
            var networkViews = viewModel.getSelectableNetworks()
                .map { network -> _NetworkView in
                    let view = _NetworkView()
                    view.network = network
                    view.setUp(network: network, prices: prices)
                    if network == .solana {
                        view.insertArrangedSubview(
                            UILabel(text: L10n.paidByP2p, textSize: 13, textColor: .h34c759)
                                .withContentHuggingPriority(.required, for: .horizontal)
                                .padding(.init(x: 12, y: 8), backgroundColor: .f5fcf7, cornerRadius: 12)
                                .border(width: 1, color: .h34c759)
                                .withContentHuggingPriority(.required, for: .horizontal),
                            at: 2
                        )
                    }
                    return view.onTap(self, action: #selector(networkViewDidTouch(_:)))
                }
            
            return networkViews
        }()
        
        // MARK: - Initializers
        init(viewModel: SendTokenSelectNetworkViewModelType) {
            self.viewModel = viewModel
            self.selectedNetwork = viewModel.getSelectedNetwork()
            super.init()
        }
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            // navigation bar
            navigationBar.titleLabel.text = L10n.chooseTheNetwork
            
            // container
            let rootView = ScrollableVStackRootView()
            view.addSubview(rootView)
            rootView.autoPinEdge(.top, to: .bottom, of: navigationBar)
            rootView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
            rootView.stackView.spacing = 0
            rootView.stackView.addArrangedSubviews {
                UIView.greyBannerView {
                    UILabel(text: L10n.P2PWaletWillAutomaticallyMatchYourWithdrawalTargetAddressToTheCorrectNetworkForMostWithdrawals.howeverBeforeSendingYourFundsMakeSureToDoubleCheckTheSelectedNetwork, textSize: 15, numberOfLines: 0)
                }
                
                BEStackViewSpacing(10)
            }
            
            // networks
            for (index, view) in networkViews.enumerated() {
                rootView.stackView.addArrangedSubview(view.padding(.init(x: 0, y: 26)))
                if index < networkViews.count - 1 {
                    rootView.stackView.addArrangedSubview(.separator(height: 1, color: .separator))
                }
            }
            
            reloadData()
        }
        
        private func reloadData() {
            for view in self.networkViews {
                view.tickView.alpha = view.network == selectedNetwork ? 1 : 0
            }
        }
        
        // MARK: - Actions
        @objc private func networkViewDidTouch(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view as? _NetworkView, let network = view.network else {
                return
            }
            // save previous state and assign new one
            let originalSelectedNetwork = selectedNetwork
            selectedNetwork = network
            
            // alert if needed
            if !isAddressValidForNetwork() {
                let networkName = viewModel.getSelectedNetwork().rawValue.uppercaseFirst
                showAlert(
                    title: L10n.changeTheNetwork,
                    message: L10n.ifTheNetworkIsChangedToTheAddressFieldMustBeFilledInWithA(networkName, L10n.compatibleAddress(networkName)),
                    buttonTitles: [L10n.discard, L10n.change],
                    highlightedButtonIndex: 1,
                    destroingIndex: 0
                ) { [weak self] index in
                    if index == 0 {
                        self?.selectedNetwork = originalSelectedNetwork
                        self?._back()
                    } else {
                        self?.save()
                        self?.viewModel.navigateToChooseRecipientAndNetworkWithPreSelectedNetwork(network)
                    }
                }
            }
        }
        
        // MARK: - Helpers
        override func _back() {
            save()
            super._back()
        }
        
        private func isAddressValidForNetwork() -> Bool {
            guard let address = viewModel.getSelectedRecipient()?.address else { return true }
            switch selectedNetwork {
            case .bitcoin:
                return address.matches(allOfRegexes: .bitcoinAddress(isTestnet: viewModel.getAPIClient().isTestNet()))
            case .solana:
                return address.matches(oneOfRegexes: .publicKey)
            }
        }
        
        private func save() {
            viewModel.selectNetwork(selectedNetwork)
        }
    }
}
```

New code (93 lines)

```swift
extension SendToken.SelectNetwork {
    final class ViewController: BEScene {
        override var preferredNavigationBarStype: NavigationBarStyle { .hidden }
        
        private let viewModel: SendTokenSelectNetworkViewModelType
        
        // Internal state
        private let selectedNetwork: BehaviorRelay<SendToken.Network>
        
        init(viewModel: SendTokenSelectNetworkViewModelType) {
            self.viewModel = viewModel
            self.selectedNetwork = BehaviorRelay(value: viewModel.getSelectedNetwork())
            super.init()
        }
        
        override func build() -> UIView {
            UIStackView(axis: .vertical, alignment: .fill) {
                NewWLNavigationBar(title: L10n.chooseTheNetwork, separatorEnable: false)
                    .onBack { [unowned self] in self.back() }
                
                BEScrollView(contentInsets: .init(x: 18, y: 4)) {
                    // Description
                    UIView.greyBannerView {
                        UILabel(
                            text: L10n
                                .P2PWaletWillAutomaticallyMatchYourWithdrawalTargetAddressToTheCorrectNetworkForMostWithdrawals
                                .howeverBeforeSendingYourFundsMakeSureToDoubleCheckTheSelectedNetwork,
                            textSize: 15,
                            numberOfLines: 0)
                    }.padding(.init(only: .bottom, inset: 35))
                    
                    // Solana cell
                    if viewModel.getSelectableNetworks().contains(.solana) {
                        _NetworkView()
                            .setUp(network: .solana, prices: viewModel.getSOLAndRenBTCPrices())
                            .setupWithType(_NetworkView.self) { view in
                                selectedNetwork.asDriver()
                                    .map { network in network != .solana }
                                    .drive(view.tickView.rx.isHidden)
                                    .disposed(by: disposeBag)
                            }
                            .onTap { [unowned self] in self.switchNetwork(to: .solana) }
                        
                        UIView.greenBannerView(contentInset: .init(x: 12, y: 8)) {
                            UILabel(
                                text: L10n
                                    .OnTheSolanaNetworkTheFirst100TransactionsInADayArePaidByP2P
                                    .Org
                                    .subsequentTransactionsWillBeChargedBasedOnTheSolanaBlockchainGasFee,
                                textColor: .h34c759,
                                numberOfLines: 5
                            )
                        }.padding(.init(only: .top, inset: 18))
                    }
                    
                    // Bitcoin cell
                    if viewModel.getSelectableNetworks().contains(.bitcoin) {
                        UIView.defaultSeparator().padding(.init(top: 16, left: 0, bottom: 25, right: 0))
                        _NetworkView()
                            .setUp(network: .bitcoin, prices: viewModel.getSOLAndRenBTCPrices())
                            .setupWithType(_NetworkView.self) { view in
                                selectedNetwork.asDriver()
                                    .map { network in network != .bitcoin }
                                    .drive(view.tickView.rx.isHidden)
                                    .disposed(by: disposeBag)
                            }
                            .onTap { [unowned self] in self.switchNetwork(to: .bitcoin) }
                    }
                
                }
            }
        }
        
        private func switchNetwork(to network: SendToken.Network) {
            let networkName = viewModel.getSelectedNetwork().rawValue.uppercaseFirst
            
            showAlert(
                title: L10n.changeTheNetwork,
                message: L10n.ifTheNetworkIsChangedToTheAddressFieldMustBeFilledInWithA(networkName, L10n.compatibleAddress(networkName)),
                buttonTitles: [L10n.discard, L10n.change],
                highlightedButtonIndex: 1,
                destroingIndex: 0
            ) { [weak self] index in
                if index == 0 {
                    self?.back()
                } else {
                    self?.selectedNetwork.accept(network)
                    self?.viewModel.selectNetwork(network)
                    self?.viewModel.navigateToChooseRecipientAndNetworkWithPreSelectedNetwork(network)
                }
            }
        }
    }
}
```

We have reduced number of lines from 128 to 93 (-27%). 