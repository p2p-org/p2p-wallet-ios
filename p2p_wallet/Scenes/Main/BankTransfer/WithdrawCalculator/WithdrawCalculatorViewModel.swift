import Combine
import BankTransfer
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import SolanaSwift

final class WithdrawCalculatorViewModel: BaseViewModel, ObservableObject {
    
    // MARK: - Dependencies
    @Injected private var bankTransferService: AnyBankTransferService<StrigaBankTransferUserDataRepository>

    // MARK: - Properties

    let nextPressed = PassthroughSubject<Void, Never>()
    let allButtonPressed = PassthroughSubject<Void, Never>()

    @Published var arePricesLoading = false
    @Published var exchangeRatesInfo: String = "1 EUR ≈ 0.93 USDC"

    @Published var fromAmount: Double?
    @Published var toAmount: Double?

    @Published var isFromFirstResponder: Bool = false
    @Published var isToFirstResponder: Bool = false

    @Published var fromBalance: Double? = 10

    @Published var fromTokenSymbol = Token.usdc.symbol.uppercased()
    @Published var toTokenSymbol = "EUR"

    @Published var fromDecimalLength: Int = 9
    @Published var toDecimalLength: Int = 2

    override init() {
        super.init()
        bindRates()
    }

}

private extension WithdrawCalculatorViewModel {
    func bindRates() {
        Task {
        }
    }
}
