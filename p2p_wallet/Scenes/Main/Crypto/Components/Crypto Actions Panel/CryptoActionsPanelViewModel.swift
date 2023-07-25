import Combine
import Foundation
import Resolver
import KeyAppBusiness
import KeyAppKitCore
import SolanaSwift
import Sell

/// ViewModel of `CryptoActionsPanel` scene
final class CryptoActionsPanelViewModel: BaseViewModel, ObservableObject {
    
    // MARK: - Dependencies
    
    @Injected var solanaAccountsService: SolanaAccountsService
    
    // MARK: - Properties
    
    @Published private(set) var balance: String = ""
    @Published private(set) var actions: [WalletActionType] = []
    
    let navigation: PassthroughSubject<CryptoNavigation, Never>
    
    // MARK: - Initialization
    
    init(
        sellDataService: any SellDataService = Resolver.resolve(),
        navigation: PassthroughSubject<CryptoNavigation, Never>
    ) {
        self.navigation = navigation
        
        super.init()
        
        actions = [.receive, .swap]
        
        bind()
    }
    
    // MARK: - Binding
    
    private func bind() {
        solanaAccountsService.statePublisher
            .map { (state: AsyncValueState<[SolanaAccountsService.Account]>) -> String in
                let equityValue: Double = state.value
                    .filter { !$0.isUSDC }
                    .reduce(0) {
                        if $1.token.keyAppExtensions.ruleOfProcessingTokenPriceWS == .byCountOfTokensValue {
                            return $0 + $1.amount
                        } else {
                            return $0 + $1.amountInFiatDouble
                        }
                    }
                return "\(Defaults.fiat.symbol)\(equityValue.toString(maximumFractionDigits: 2, roundingMode: .down))"
            }
            .receive(on: RunLoop.main)
            .assignWeak(to: \.balance, on: self)
            .store(in: &subscriptions)
    }
    
    // MARK: - Actions
    
    func actionClicked(_ action: WalletActionType) {
        switch action {
        case .receive:
            guard let pubkey = try? PublicKey(string: solanaAccountsService.state.value.nativeWallet?.address)
            else { return }
            navigation.send(.receive(publicKey: pubkey))
        case .swap:
            navigation.send(.swap)
        default: break
        }
    }
}

